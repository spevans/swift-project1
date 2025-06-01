/*
 * kernel/devices/usb/uhci-hcd.swift
 *
 * Created by Simon Evans on 04/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * UHCI HCD driver.
 *
 */

@freestanding(expression)
macro uhciDebug(_ item: CustomStringConvertible, _ items: CustomStringConvertible...) -> () = #externalMacro(module: "PrintfMacros", type: "DebugMacro")


internal let UHCI_DEBUG = true
internal func _uhciDebug(_ items: String...) {
    if UHCI_DEBUG {
        _kprint("UHCI:", terminator: "")
        for item in items {
            _kprint(" ", item, terminator: "")
        }
        _kprint("")
    }
}

private var uhciNumber = 0

final class HCD_UHCI: PCIDeviceDriver {

    static private let GLOBAL_RESET_TRIES = 5

    fileprivate let ioBasePort: UInt16
    private var addressAllocator = BitmapAllocator128()
    private(set) var controlQH = PhysQueueHead(mmioSubRegion: MMIOSubRegion(baseAddress: PhysAddress(0), count: 0))
    private var interruptQHs: [PhysQueueHead] = []
    let allocator: UHCIAllocator
    var enabled = true
    private var interuptHandler: InterruptHandler?

    private let _description: String
    override var description: String { _description }


    override init?(pciDevice: PCIDevice) {
        guard pciDevice.deviceFunction.deviceClass == PCIDeviceClass(classCode: .serialBusController,
                                                                     subClassCode: PCISerialBusControllerSubClass.usb.rawValue,
                                                                     progInterface: PCIUSBProgrammingInterface.uhci.rawValue) else {
            #uhciDebug("\(pciDevice) is not a UHCI Device")
            return nil
        }

        guard let generalDevice = pciDevice.deviceFunction.generalDevice else {
            #uhciDebug("Not a PCI generalDevice")
            return nil
        }

        let pciIOBar = PCI_BAR(rawValue: generalDevice.bar4)
        guard pciIOBar.isValid, pciIOBar.isPort else {
            #kprint("PCI BAR4 \(String(generalDevice.bar4, radix: 16)) is not an IO port BAR")
            return nil
        }

        // Valid USB device addresses are 1-127 so a 128bit allocator is used. Get the first entry (0) from the allocator
        // as it is not a valid address - it is used for unaddressed devices
        let addr = addressAllocator.allocate()
        assert(addr == 0)

        ioBasePort = pciIOBar.portAddress
        allocator = UHCIAllocator()
        _description = "hcd\(uhciNumber)"
        uhciNumber += 1
        super.init(pciDevice: pciDevice)
    }


    override func initialise() -> Bool {
        guard let pciDevice = self.device.busDevice as? PCIDevice else { return false }
        var deviceFunction = pciDevice.deviceFunction

        // Find the Interrupt
        guard let interrupt = pciDevice.findInterrupt() else {
            #kprintf("UHCI: %s: Cant find interrupt\n", self._description)
            return false
        }
        deviceFunction.interruptLine = UInt8(interrupt.irq)

        var pciCommand = deviceFunction.command
        pciCommand.ioSpace = true
        pciCommand.interruptDisable = true
        pciCommand.busMaster = true
        deviceFunction.command = pciCommand

        // Disable Legacy Support (SMI/PS2 emulation) and PIRQ
        deviceFunction.writeConfigWord(atByteOffset: 0xC0, value: 0x8F00)

        // Save SOF to restore after reset
        let savedSOF = self.startOfFrame
        // Disable interrupts
        self.interruptEnableRegister = InterruptEnable(rawValue: 0)
        globalReset()
        // Clear status register by writing 1's to clear them
        let status = statusRegister
        if status.rawValue != 0 {
            statusRegister = status
        }
        hcdReset()
        #uhciDebug("UHCI: \(self._description): statusRegister after HCD Reset:", self.statusRegister)
        // Restore SOF
        self.startOfFrame = savedSOF

        setupInitialFrames()
        writeMemoryBarrier()

        // Point to the frame list and set frame number to 0
        let frameListPage = allocator.frameListPage
        frameListBaseAddress = frameListPage.physicalAddress
        frameNumberRegister = 0

        statusRegister = Status(rawValue: 0)
        var cmd = Command()
        cmd.maxPacket64Bytes = true
        cmd.configureFlag = true
        cmd.run = true
        cmdRegister = cmd

        let handler = InterruptHandler(name: "uhci-hcd", handler: uhciInterrupt)
        self.interuptHandler = handler
        system.deviceManager.setIrqHandler(handler, forInterrupt: interrupt)
        pciCommand = deviceFunction.command
        pciCommand.interruptDisable = false
        #uhciDebug("enabling pci interrupts PCICommand:", deviceFunction.command)
        deviceFunction.command = pciCommand
        interruptEnableRegister = InterruptEnable.all()
        #uhciDebug("Enabled All USB Interrupts")

        deviceFunction.writeConfigWord(atByteOffset: 0xC0, value: 0x2000)
        sleep(milliseconds: 50)
        usbBus!.enumerate(hub: .uhci(self))
        return true
    }

    private func setupInitialFrames() {
        // Setup the framelist, with default QueueHeads
        var frameListPage = allocator.frameListPage
        precondition(frameListPage.count == 1024)

        // Create a QueueHead which teminates both the QH and Element Links and store this in the every elemet of the frame list
        // This forms the last node in a list of Control QueueHeads. The QueueHeads points to a terminating TransferDescriptor.
        // This is to workaround a bug in PIIX chipsets which need to set the terminating TD.
        let terminatingTD = allocator.allocTransferDescriptor()
        terminatingTD.setTD(TransferDescriptor(
            linkPointer: TransferDescriptor.LinkPointer.terminator(),
            controlStatus: TransferDescriptor.ControlStatus(),
            token: TransferDescriptor.Token(rawValue: 0),
            bufferPointer: 0
        ))

        // FIXME: Dealloc this
        let terminatingQH = allocator.allocQueueHead()
        terminatingQH.setQH(QueueHead(
            headLinkPointer: QueueHead.QueueHeadLinkPointer.terminator(),
            elementLinkPointer: QueueHead.QueueElementLinkPointer(transferDescriptorAddress: terminatingTD.physAddress)
        ))

        // Create the start node in the list which has a terminating element and points to the last node as the link pointer
        controlQH = allocator.allocQueueHead()
        controlQH.setQH(QueueHead(
            headLinkPointer: QueueHead.QueueHeadLinkPointer(queueHeadAddress: terminatingQH.physAddress),
            elementLinkPointer: QueueHead.QueueElementLinkPointer.terminator()
        ))

        // Setup the interrupt Queue heads. Theses are added for power of 2 intervals from 2^0 .. 2^8
        // The 2^0 QH needs to fire on every interval and the other QHs added to the frame list need to
        // call the 2^0 entry. The maximum interrupt interval is 256ms
        let intr0QH = allocator.allocQueueHead()
        intr0QH.setQH(QueueHead(
            headLinkPointer: QueueHead.QueueHeadLinkPointer(queueHeadAddress: controlQH.physAddress),
            elementLinkPointer: QueueHead.QueueElementLinkPointer.terminator()
        ))
        interruptQHs.reserveCapacity(9)
        interruptQHs.append(intr0QH)
        for _ in 1...8 {
            let intrQH = allocator.allocQueueHead()
            intrQH.setQH(QueueHead(
                headLinkPointer: QueueHead.QueueHeadLinkPointer(queueHeadAddress: intr0QH.physAddress),
                elementLinkPointer: QueueHead.QueueElementLinkPointer.terminator()
            ))
            interruptQHs.append(intrQH)
        }
        // Add the interrupt QHs into the Frame List. Use the low bit to determine the period of the interrupt
        for entry in 1...1024 {
            let interrupt = UInt8(truncatingIfNeeded: entry).trailingZeroBitCount
            let flp = FrameListPointer(queueHead: interruptQHs[Int(interrupt)].physAddress)
            frameListPage[entry - 1] = flp
        }
    }


    func addQueueHead(_ queueHead: PhysQueueHead, transferType: USB.EndpointDescriptor.TransferType, interval: UInt8) {
        var queueHead = queueHead
        switch transferType {
            case .control:
                // For Control Pipes, add the QueueHead into the
                queueHead.headLinkPointer = controlQH.headLinkPointer
                controlQH.headLinkPointer = QueueHead.QueueHeadLinkPointer(queueHeadAddress: queueHead.physAddress)

            case .interrupt:
                // Determine the period of this interrupt pipe which is rounded up to the next power of 2
                // Trim to max interval and round up to next power of 2 if not an exact power of 2.
                var intrQH = (interval.bitWidth - interval.leadingZeroBitCount) - 1
                if interval.nonzeroBitCount > 1 { intrQH += 1 }
                #uhciDebug("UHCI-PIPE: Adding interrupt, interval \(interval) -> period \(intrQH)")
                var qh = interruptQHs[intrQH]
                queueHead.headLinkPointer = qh.headLinkPointer
                qh.headLinkPointer = QueueHead.QueueHeadLinkPointer(queueHeadAddress: queueHead.physAddress)

            default:
                fatalError("UHCI: \(self.description) Pipes of type \(transferType) are not currently supported")
        }
    }


    func removeQueueHead(_ queueHead: PhysQueueHead, transferType: USB.EndpointDescriptor.TransferType) {

        switch transferType {
            case .control:
                // The queueHead that is being searched for
                var qh = controlQH
                var qhlp = qh.headLinkPointer

                var maxLoops = 8    // Debugging
                while !qhlp.isTerminator {
                    maxLoops -= 1
                    if maxLoops <= 0 { fatalError("removeQueueHead exceeded maxLoops") }

                    // qhlp points to the queueHead to remove
                    if qhlp.address == queueHead.physAddress {
                        // Point it to the next pointer of the QH to remove
                        qh.headLinkPointer = queueHead.headLinkPointer
                        return
                    }

                    guard let address = qh.headLinkPointer.nextQHAddress else {
                        fatalError("UHCI-HCD: removeQueueHead: Reached end of QHs")
                    }
                    let region = allocator.fromPhysical(address: address)
                    qh = PhysQueueHead(mmioSubRegion: region)
                    qhlp = qh.headLinkPointer
                }
                fatalError("Cant find QH \(queueHead) in list of control queueheads")


            case .interrupt:
                // Loop through every frame list entry to
                fallthrough

            default:
                fatalError("Pipes of type \(transferType) are not currently supported")
        }

        #uhciDebug("\(self.description) Removed QH")
    }


    // Dump and check the framelist PTRs and QHs
    func dumpAndCheckFrameList() {
        guard UHCI_DEBUG else { return }

        // Keep track of FL entries already seen to avoid deupliacting work
        var previousFLEntries: [UInt32] = []
        previousFLEntries.reserveCapacity(16)

        let frameList = allocator.frameListPage
        #kprint("UHCI: \(self._description): Dumping frame list at:", frameList)

        for idx in 0..<frameList.count {
            let entry = frameList[idx]
            let address = frameList.physicalAddress + (4 * UInt32(idx))
            if previousFLEntries.contains(entry.address) { continue }
            #kprintf("UHCI: %s: FL%3d: [0x%8.8x] %s\n", self._description, idx, address, entry.description)

            var nextAddress = entry.framePointer
            var maxDepth = 32
            var isQH = entry.isQueueHead

            while maxDepth >= 0, let address = nextAddress {
                let region = allocator.fromPhysical(address: address)
                if isQH {
                    let qh = PhysQueueHead(mmioSubRegion: region)
                    #kprintf("UHCI: %s\t [0x%8.8x] QH %s", self._description, address, qh.dump(allocator: allocator))
                    isQH = qh.headLinkPointer.isQueueHead
                    nextAddress = qh.headLinkPointer.nextQHAddress
                } else {
                    let td = PhysTransferDescriptor(mmioSubRegion: region).getTD()
                    #kprintf("UHCI: %s\t [0x%8.8x] TD %s\n", self._description, address, td.description)
                    isQH = td.linkPointer.isQueueHead
                    nextAddress = td.linkPointer.address == 0 ? nil : td.linkPointer.physAddress
                }

                maxDepth -= 1
            }
            previousFLEntries.append(entry.address)
        }
    }


    private func globalReset() {
        var cmd = Command()
        cmd.globalReset = true
        cmdRegister = cmd
        // GRESET on
        sleep(milliseconds: 100)
        // GRESET off, Run/Stop = STOP
        cmdRegister = Command()
    }


    private func hcdReset() {
        var cmd = Command()
        cmd.hostControllerReset = true
        cmdRegister = cmd
        // The HCD sets .hostControllerReset to false when the reset is finished
        for _ in 0..<100 {
            let status = cmdRegister
            if status.hostControllerReset == false { // All done
                return
            }
            sleep(milliseconds: 1)
        }
        #uhciDebug(self._description, "did not reset")
    }


    fileprivate var interruptOccurred = false
    private func uhciInterrupt() -> Bool {
        let status = statusRegister

        self.interruptOccurred = status.interrupt || status.errorInterrupt
        // The status register is WriteClear so any bits set in the status will be cleared when it is written back.
        // This acknowledges the interrupt
        statusRegister = status
        return interruptOccurred
    }
}


extension HCD_UHCI {

    func pollInterrupt() -> Bool {
        defer { interruptOccurred = false }
        return interruptOccurred
    }
}


// USBHub functions
extension HCD_UHCI {

    var portCount: Int { 2 }

    func reset(port: Int) -> Bool {
        precondition(port < portCount)
        #uhciDebug("\(self._description): Reseting port: \(port)")

        var mask = PortStatusControl(rawValue: 0)
        mask.portEnabled = true
        mask.resumeDetect = true
        mask.portReset = true
        mask.suspend = true

        // Enable Port Reset Bit
        var status = portStatus(port: port)
        status.portReset = true
        portControl(port: port, data: status)
        sleep(milliseconds: 50)
        #uhciDebug(self._description + " port status0, ", portStatus(port: port))

        // Clear Port Reset Bit
        mask = PortStatusControl(rawValue: 0xfcb1)
        status = portStatus(port: port)
        status = PortStatusControl(rawValue: status.rawValue & mask.rawValue)
        portControl(port: port, data: status)
        sleep(milliseconds: 1)
        #uhciDebug(self._description + " port status1, ", portStatus(port: port))

        // CSC bit must be clear before the enable bit is set
        status = portStatus(port: port)
        status.clearConnectStatusChange()
        portControl(port: port, data: status)
        status = portStatus(port: port)
        status.portEnabled = true
        portControl(port: port, data: status)
        // wait for it to be enabled
        sleep(milliseconds: 1)

        status = portStatus(port: port)
        status.clearConnectStatusChange()
        status.portEnabled = true
        status.clearPortEnabledDisabledChange()
        portControl(port: port, data: status)
        sleep(milliseconds: 50)

        status = portStatus(port: port)
        let resetOK = status.portEnabled
        #uhciDebug(self._description + " Port \(port) Final status: \(status) reset", resetOK ? "OK" : "Failed")
        return resetOK
    }


    func detectConnected(port: Int) -> USB.Speed? {
        let status = portStatus(port: port)
        #uhciDebug("detectConnected, status: ", status)
        guard status.currentConnectStatus else {
            #uhciDebug("no device detected")
            return nil
        }
        let speed = status.lowSpeedDeviceAttached ? USB.Speed.lowSpeed : USB.Speed.fullSpeed
        #uhciDebug(self._description + " device on port \(port) connected at speed:", speed)
        return speed
    }


    func nextAddress() -> UInt8? {
        guard let address = addressAllocator.allocate() else {
            return nil
        }
        return UInt8(address)
    }


    func registerDump() {
        #uhciDebug(self._description + " **** START registerDump")
        #uhciDebug(self._description + " cmdRegister:", self.cmdRegister)
        #uhciDebug(self._description + " statusRegister:", self.statusRegister)
        #uhciDebug(self._description + " interruptEnableRegister:", self.interruptEnableRegister)
        #uhciDebug(self._description + " FrameNumberRegister: 0x\(String(self.frameNumberRegister, radix: 16))")
        #uhciDebug(self._description + " FrameListBaseAddress: 0x\(String(self.frameListBaseAddress, radix: 16))")
        #uhciDebug(self._description + " startOfFrame:", self.startOfFrame)
        #uhciDebug(self._description + " Port0:", portStatus(port: 0))
        #uhciDebug(self._description + " Port1:", portStatus(port: 1))
        #uhciDebug(self._description + " **** END registerDump")
    }
}


// HCD Register access
extension HCD_UHCI {
    var cmdRegister: Command {
        get {
            return Command(rawValue: inw(ioBasePort))
        }
        set {
            outw(ioBasePort, newValue.rawValue)
        }
    }

    var statusRegister: Status {
        get {
            return Status(rawValue: inw(ioBasePort + 2))
        }
        set {
            outw(ioBasePort + 2, newValue.rawValue)
        }
    }

    var interruptEnableRegister: InterruptEnable {
        get {
            return InterruptEnable(rawValue: inw(ioBasePort + 4))
        }
        set {
            outw(ioBasePort + 4, newValue.rawValue)
        }
    }

    var frameNumberRegister: UInt16 {
        get {
            return inw(ioBasePort + 6)
        }
        set {
            precondition(newValue & 0xf800 == 0)
            outw(ioBasePort + 6, newValue)
        }
    }

    var frameListBaseAddress: UInt32 {
        get {
            return inl(ioBasePort + 8)
        }
        set {
            precondition(newValue & 0x0000_0fff == 0)
            outl(ioBasePort + 8, newValue)
        }
    }

    var startOfFrame: UInt8 {
        get {
            return inb(ioBasePort + 0xc)
        }
        set {
            precondition(newValue & 0x80 == 0)
            outb(ioBasePort + 0xc, newValue)
        }
    }

    func portStatus(port: Int) -> PortStatusControl {
        precondition(port < 2)
        let ioPort = ioBasePort + UInt16(0x10 + (port * 2))
        return PortStatusControl(rawValue: inw(ioPort))
    }

    func portControl(port: Int, data: PortStatusControl) {
        precondition(port < 2)
        let ioPort = ioBasePort + UInt16(0x10 + (port * 2))
        outw(ioPort, data.rawValue)
    }

    var port0: PortStatusControl {
        get { portStatus(port: 0) }
        set { portControl(port: 0, data: newValue) }
    }

    var port1: PortStatusControl {
        get { portStatus(port: 1) }
        set { portControl(port: 1, data: newValue) }
    }
}
