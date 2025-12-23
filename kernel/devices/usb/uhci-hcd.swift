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


internal let UHCI_DEBUG = false
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

final class HCD_UHCI: DeviceDriver {
    static private let GLOBAL_RESET_TRIES = 5

    let allocator: UHCIAllocator
    var enabled = true

    private let pciDevice: PCIDevice
    fileprivate let ioBasePort: UInt16
    private var addressAllocator = BitmapAllocator128()
    private var controlQH = PhysQueueHead(mmioSubRegion: MMIOSubRegion(baseAddress: PhysAddress(0), count: 0))
    private var interruptQHs: [PhysQueueHead] = []
    private var interuptHandler: InterruptHandler?
    private var urbs: InlineArray<4, USB.Request?> = .init(repeating: nil)


    init?(pciDevice: PCIDevice) {
        guard pciDevice.deviceFunction.deviceClass == PCIDeviceClass(
            classCode: .serialBusController,
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

        // Valid USB device addresses are 1-127 so a 128bit allocator is used.
        // Get the first entry (0) from the allocator/ as it is not a valid address - it is used
        // for unaddressed devices. Also allocate address 1 for this HCD as it is a Root Hub
        var addr = addressAllocator.allocate()
        assert(addr == 0)

        addr = addressAllocator.allocate()
        assert(addr == 1)

        self.pciDevice = pciDevice
        ioBasePort = pciIOBar.portAddress
        allocator = UHCIAllocator()
        super.init(driverName: "uhci", device: pciDevice)
        guard self.initialise() else {
            return nil
        }
        self.setInstanceName(to: "uhci\(uhciNumber)")
        uhciNumber += 1
    }


    private func initialise() -> Bool {
        var deviceFunction = self.pciDevice.deviceFunction

        // Find the Interrupt
        guard let interrupt = self.pciDevice.findInterrupt() else {
            #kprintf("UHCI: %s: Failed to find interrupt\n", self.instanceName)
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
        #uhciDebug("UHCI: \(self.instanceName): statusRegister after HCD Reset:", self.statusRegister)
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

        let busId = system.deviceManager.usb!.nextBusId()
        let usbBus = USBBus(
            busId: busId,
            allocateBuffer: { self.allocator.allocPhysBuffer(length: $0) },
            freeBuffer: { self.allocator.freePhysBuffer($0) },
            allocatePipe: { self.allocatePipe(device: $0, endpointDescriptor: $1) },
            setAddress: { self.setAddress($0) },
            submitURB: { self.submitURB($0) },
        )

        guard let rootHubDevice = HCDRootHub(
            parent: self.pciDevice,
            bus: usbBus,
            hcd: HCDRootHub.HCDDeviceFunctions(
                processURB: { self.processURB($0, into: $1) }
            )
        ) else {
            #kprint("uhci: Failed to create root hub device")
            return false
        }
        return system.deviceManager.usb!.addRootDevice(rootHubDevice)
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
                fatalError("Failed to find QH \(queueHead) in list of control queueheads")


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
        #kprint("UHCI: \(self.instanceName): Dumping frame list at:", frameList)

        for idx in 0..<frameList.count {
            let entry = frameList[idx]
            let address = frameList.physicalAddress + (4 * UInt32(idx))
            if previousFLEntries.contains(entry.address) { continue }
            #kprintf("UHCI: %s: FL%3d: [0x%8.8x] %s\n", self.instanceName, idx, address, entry.description)

            var nextAddress = entry.framePointer
            var maxDepth = 32
            var isQH = entry.isQueueHead

            while maxDepth >= 0, let address = nextAddress {
                let region = allocator.fromPhysical(address: address)
                if isQH {
                    let qh = PhysQueueHead(mmioSubRegion: region)
                    #kprintf("UHCI: %s\t [0x%8.8x] QH %s", self.instanceName, address, qh.dump(allocator: allocator))
                    isQH = qh.headLinkPointer.isQueueHead
                    nextAddress = qh.headLinkPointer.nextQHAddress
                } else {
                    let td = PhysTransferDescriptor(mmioSubRegion: region).getTD()
                    #kprintf("UHCI: %s\t [0x%8.8x] TD %s\n", self.instanceName, address, td.description)
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
        #uhciDebug(self.instanceName, "did not reset")
    }

    // USBBus functions
    private var currentURBs: InlineArray<4, USB.Request?> = .init(repeating: nil)
    // Fixme this needs to do locking etc
    func submitURB(_ urb: USB.Request) {
        for idx in currentURBs.indices {
            if currentURBs[idx] == nil {
                currentURBs[idx] = urb
                urb.pipe.submitURB(urb)
                return
            }
        }
        fatalError("UHCI: No more space for URBs!")
    }

    private func setAddress(_ usbDevice: USBDevice) -> UInt8? {
        guard let _address = addressAllocator.allocate() else {
            return nil
        }
        let address = UInt8(_address)

        return usbDevice.setAddress(address) ? address : nil
    }


    fileprivate var interruptOccurred = false
    private func uhciInterrupt() -> Bool {
        let status = statusRegister

        self.interruptOccurred = status.interrupt || status.errorInterrupt
        // The status register is WriteClear so any bits set in the status will be cleared when it is written back.
        // This acknowledges the interrupt
        statusRegister = status

        if !interruptOccurred {
            return false
        }
//        #kprintf("UHCI: Got interrupt %2.2x\n", status.rawValue)

        var haveURBs = false

        for idx in currentURBs.indices {
            guard let urb = currentURBs[idx] else { continue }
            haveURBs = true

            let status = urb.pipe.pollPipe(status.errorInterrupt)
            if status == .inprogress { continue }
//            #kprintf("URB of type %s has status of %s\n", urb.transferType.description, status.description)
            currentURBs[idx] = nil
            // FIXME, find the correct number
            let bytes = (status == .finished) ? urb.buffer?.count ?? 0 : 0
            let response = USB.Response(status: status, bytesTransferred: bytes)
            urb.completionHandler(urb, response)
        }
        if !haveURBs {
            #kprint("UHCI: pollURBs - no URBs")
        }
        return interruptOccurred
    }

    func pollInterrupt() -> Bool {
        defer { interruptOccurred = false }
        return interruptOccurred
    }

    // USBHub functions
    var portCount: UInt8 { 2 }

    func processURB(_ setupRequest: USB.ControlRequest, into buffer: MMIOSubRegion?) -> USB.Response {

        let okResponse = USB.Response(status: .finished, bytesTransferred: 0)
        let errorResponse = USB.Response(status: .stalled, bytesTransferred: 0)

        guard let requestCode = setupRequest.requestCode else {
            #kprint("uhci-root: Invalid request code")
            return errorResponse
        }

        let deviceRequest = USB.ControlRequest.BMRequestType(
            direction: .deviceToHost, requestType: .klass, recipient: .device
        ).rawValue

        let toPortRequest = USB.ControlRequest.BMRequestType(
            direction: .hostToDevice, requestType: .klass, recipient: .other(0)
        ).rawValue

        let fromPortRequest = USB.ControlRequest.BMRequestType(
            direction: .deviceToHost, requestType: .klass, recipient: .other(0)
        ).rawValue

        let standardDtoH = USB.ControlRequest.BMRequestType(
            direction: .deviceToHost, requestType: .standard, recipient: .device
        ).rawValue

        func getPort() -> Int? {
            guard setupRequest.wIndex > 0
                    && setupRequest.wIndex <= UInt16(self.portCount) else {
                #kprintf("uhci-root: Invalid port %d\n", setupRequest.wIndex)
                return nil
            }

            let port = Int(setupRequest.wIndex) - 1 // Convert from 1based ports to 0based ports
            return port
        }


        switch (setupRequest.bmRequestType, requestCode) {
            case (standardDtoH, .GET_STATUS):
                guard var buffer = buffer else { return errorResponse }
                buffer[0] = 0
                buffer[1] = 0
                return USB.Response(status: .finished, bytesTransferred: 2)

            case (deviceRequest, .GET_DESCRIPTOR):
                // FIXME, use the returned length in a URB response
                guard var buffer = buffer else { return errorResponse }
                let hubDescriptor = USB.HUBDescriptor(ports: portCount)
                let length = hubDescriptor.descriptorAsBuffer(wLength: setupRequest.wLength, into: &buffer)
                return USB.Response(status: .finished, bytesTransferred: length)

            case (fromPortRequest, .GET_STATUS):
                guard let port = getPort() else { return errorResponse }
                guard var buffer = buffer else { return errorResponse }
                let portStatus = self.portStatus(port)
                let length = portStatus.asBytes(into: &buffer, maxLength: 4)
                return USB.Response(status: .finished, bytesTransferred: length)

            case (toPortRequest, .SET_FEATURE), (toPortRequest, .CLEAR_FEATURE):
                guard let port = getPort() else { return errorResponse }
                guard let feature = USBHubDriver.FEATURE_SELECTOR(rawValue: setupRequest.wValue) else {
                    #kprintf("uhci-root: Invalid FEATURE_SELECTOR: %4.4x\n", setupRequest.wValue)
                    return errorResponse
                }

                switch (requestCode, feature) {
                    case (.SET_FEATURE, .PORT_POWER):
                        return okResponse

                    case (.SET_FEATURE, .PORT_RESET):
                        return self.reset(port: port) ? okResponse : errorResponse

                    case (.CLEAR_FEATURE, .C_PORT_CONNECTION):
                        self.clearConnectStatus(port: port)
                        return okResponse

                    default:
                        #kprintf("xhci-root: Unsupported Port Feature %s request: %2.2x\n",
                                 requestCode.description, setupRequest.wValue)
                        return errorResponse
                }

            default:
                break
        }
        #kprint("uhci-root: Failed to handle request:", setupRequest)
        return errorResponse
    }


    func reset(port: Int) -> Bool {
        precondition(port < portCount)
        #uhciDebug("\(self.instanceName): Reseting port: \(port)")

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
        #uhciDebug(self.instanceName + " port status0, ", portStatus(port: port))

        // Clear Port Reset Bit
        mask = PortStatusControl(rawValue: 0xfcb1)
        status = portStatus(port: port)
        status = PortStatusControl(rawValue: status.rawValue & mask.rawValue)
        portControl(port: port, data: status)
        sleep(milliseconds: 1)
        #uhciDebug(self.instanceName + " port status1, ", portStatus(port: port))

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
        #uhciDebug(self.instanceName + " Port \(port) Final status: \(status) reset", resetOK ? "OK" : "Failed")
        return resetOK
    }

    func portStatus(_ port: Int) -> USBHubDriver.PortStatus {
        let status = portStatus(port: port)
        #kprintf("USB-UHCI: port: %d connected: %s\n", port + 1, status.currentConnectStatus)

        let speed = status.lowSpeedDeviceAttached ? USB.Speed.lowSpeed : USB.Speed.fullSpeed
        return USBHubDriver.PortStatus(
            deviceAttached: status.currentConnectStatus,
            isEnabled: status.portEnabled,
            isSuspended: status.suspend,
            isOverCurrent: status.overCurrentCondition,
            isInReset: status.portReset,
            isPowered: true,
            speed: speed,
            currentConnectChange: status.connectStatusChange,
            portEnabledChange: status.portEnabledChange,
            suspendChange: false,
            overCurrentIndicatorChanged: status.overCurrentConditionChange,
            resetComplete: false
        )
    }

    func clearConnectStatus(port: Int) {
        var status = portStatus(port: port)
        status.clearConnectStatusChange()
        portControl(port: port, data: status)
    }


    // HCD Register access
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


    func registerDump() {
        #uhciDebug(self.instanceName + " **** START registerDump")
        #uhciDebug(self.instanceName + " cmdRegister:", self.cmdRegister)
        #uhciDebug(self.instanceName + " statusRegister:", self.statusRegister)
        #uhciDebug(self.instanceName + " interruptEnableRegister:", self.interruptEnableRegister)
        #uhciDebug(self.instanceName + " FrameNumberRegister: 0x\(String(self.frameNumberRegister, radix: 16))")
        #uhciDebug(self.instanceName + " FrameListBaseAddress: 0x\(String(self.frameListBaseAddress, radix: 16))")
        #uhciDebug(self.instanceName + " startOfFrame:", self.startOfFrame)
        #uhciDebug(self.instanceName + " Port0:", portStatus(port: 0))
        #uhciDebug(self.instanceName + " Port1:", portStatus(port: 1))
        #uhciDebug(self.instanceName + " **** END registerDump")
    }
}


