/*
 * kernel/devices/usb/uhci-hcd.swift
 *
 * Created by Simon Evans on 04/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * UHCI HCD driver.
 *
 */


internal let UHCI_DEBUG = true
internal func uhciDebug(_ msg: Any...) {
    if UHCI_DEBUG {
        print("UHCI: ", terminator: "")
        for m in msg {
            print(m, terminator: " ")
        }
        print("")
    }
}


final class HCD_UHCI: PCIDeviceDriver, CustomStringConvertible {

    static private let GLOBAL_RESET_TRIES = 5

    private var deviceFunction: PCIDeviceFunction       // The device (upstream) side of the bridge
    fileprivate let ioBasePort: UInt16
    private var maxAddress: UInt8 = 1
    private(set) var controlQH = PhysQueueHead(address: PhysAddress(0))
    let allocator: UHCIAllocator

    // FIXME: Should guarantee being 32bit phys
    let frameListPage = alloc(pages: 1)

    let acpiDevice: AMLDefDevice?
    var enabled = true

    var description: String { "UHCI: driver @ IO 0x\(String(ioBasePort, radix: 16))" }

    init?(pciDevice: PCIDevice) {
        uhciDebug("init")

        guard pciDevice.deviceFunction.deviceClass == PCIDeviceClass(classCode: .serialBusController,
                                                                     subClassCode: PCISerialBusControllerSubClass.usb.rawValue,
                                                                     progInterface: PCIUSBProgrammingInterace.uhci.rawValue) else {
            uhciDebug("\(pciDevice) is not a UHCI Device")
            return nil
        }

        guard let generalDevice = pciDevice.deviceFunction.generalDevice else {
            uhciDebug("Not a PCI generalDevice")
            return nil
        }

        guard let pciIOBar = PCIIOBar(bar: generalDevice.bar4) else {
            print("PCI BAR4 \(String(generalDevice.bar4, radix: 16)) is not an IO port BAR")
            return nil
        }

        ioBasePort = pciIOBar.ioPort
        uhciDebug("IO 0x\(String(ioBasePort, radix: 16))")
        allocator = UHCIAllocator()

        self.deviceFunction = pciDevice.deviceFunction
        self.acpiDevice = pciDevice.acpiDevice

        let sbrn = deviceFunction.configSpace.readConfigByte(atByteOffset: 0x60)
        uhciDebug("bus release number 0x\(String(sbrn, radix: 16))")

        // Disable PCI interrupts, set IOSpace and busMaster active
        var pciCommand = deviceFunction.command
        pciCommand.ioSpace = true
        pciCommand.interruptDisable = true
        pciCommand.busMaster = true
        deviceFunction.command = pciCommand
        uhciDebug("PCICommand:", deviceFunction.command)
    }


    func initialiseDevice() {
        uhciDebug("driver init")

        // Disable Legacy Support (SMI/PS2 emulation) and PIRQ
        uhciDebug("PCIStatus:", deviceFunction.status)
        uhciDebug("PCICommand:", deviceFunction.command)
        deviceFunction.configSpace.writeConfigWord(atByteOffset: 0xC0, value: 0x8F00)

        // Save SOF to restore after reset
        let savedSOF = self.startOfFrame
        // Disable interrupts
        self.interruptEnableRegister = InterruptEnable(rawValue: 0)
        globalReset()
        hcdReset()
        // Restore SOF
        self.startOfFrame = savedSOF


        // Setup the framelist, with default QueueHeads
        uhciDebug("frameListPage:", frameListPage, "vaddr:", String(frameListPage.vaddr, radix: 16))
        let ptr = UnsafeMutablePointer<FrameListPointer>(bitPattern: frameListPage.vaddr)!
        uhciDebug("ptr:", ptr)
        let frameList = UnsafeMutableBufferPointer(start: ptr, count: Int(frameListPage.regionSize) / MemoryLayout<FrameListPointer>.stride)
        uhciDebug("frameList:", frameList)
        assert(frameList.count == 1024)

        // Create a QueueHead which teminates both the QH and Element Links and store this in the every elemet of the frame list
        // This forms the last node in a list of Control QueueHeads. The QueueHeads points to a terminating TransferDescriptor.
        // This is to workaround a bug in PIIX chipsets which need to set the terminating TD.
        let terminatingTD = allocator.allocTransferDescriptor()
        uhciDebug("Allocated terminatingTD")
        terminatingTD.setTD(TransferDescriptor(
            linkPointer: TransferDescriptor.LinkPointer.terminator(),
            controlStatus: TransferDescriptor.ControlStatus(),
            token: TransferDescriptor.Token(pid: .pidIn, deviceAddress: 0x7f, endpoint: 0, dataToggle: false, maximumLength: 0),
            bufferPointer: 0
        ))
        uhciDebug("terminatingTD:", terminatingTD)

        // FIXME: Dealloc this
        let terminatingQH = allocator.allocQueueHead()
        uhciDebug("Allocated terminatingQH with terminatingTD:", terminatingTD.physAddress)
        terminatingQH.setQH(QueueHead(
            headLinkPointer: QueueHead.QueueHeadLinkPointer.terminator(),
            elementLinkPointer: QueueHead.QueueElementLinkPointer(transferDescriptorAddress: terminatingTD.physAddress)
        ))
        uhciDebug("terminatingQH:", terminatingQH)

        // Create the start node in the list which has a terminating element and points to the last node as the link pointer
        controlQH = allocator.allocQueueHead()
        uhciDebug("allocated controlQH, with terminatingQH:", terminatingQH.physAddress)
        controlQH.setQH(QueueHead(
            headLinkPointer: QueueHead.QueueHeadLinkPointer(queueHeadAddress: terminatingQH.physAddress),
            elementLinkPointer: QueueHead.QueueElementLinkPointer.terminator()
        ))
        uhciDebug("ControQH:", controlQH)

        let flp = FrameListPointer(queueHead: controlQH.physAddress)
        uhciDebug("flp:", flp)
        frameList.assign(repeating: flp)
        dumpAndCheckFrameList()

        // Point to the frame list and set frame number to 0
        frameListBaseAddress = UInt32(frameListPage.address.value)
        frameNumberRegister = 0

        statusRegister = Status(rawValue: 0)
        var cmd = Command()
        cmd.maxPacket64Bytes = true
        cmd.configureFlag = true
        cmd.run = true
        cmdRegister = cmd
        uhciDebug("Enabled USB")
        sleep(milliseconds: 10)
        registerDump()
        usbBus!.enumerate(hub: self)
    }


    func addQueueHead(_ queueHead: PhysQueueHead, transferType: USB.EndpointDescriptor.TransferType, interval: UInt8) {
        uhciDebug("addQueueHead:", queueHead, transferType)
        dumpAndCheckFrameList()

        var queueHead = queueHead
        switch transferType {
            case .control:
                // For Control Pipes, add the QueueHead into the
                queueHead.headLinkPointer = controlQH.headLinkPointer
                controlQH.headLinkPointer = QueueHead.QueueHeadLinkPointer(queueHeadAddress: queueHead.physAddress)

            case .interrupt:
                // Determine the frequency of the interrupt to know which slots to add it to
                let frequency = 1024 / Int(interval)
                uhciDebug("interval: \(interval)ms frequency: \(frequency)")
                let ptr = UnsafeMutablePointer<FrameListPointer>(bitPattern: frameListPage.vaddr)!
                let frameList = UnsafeMutableBufferPointer(start: ptr, count: Int(frameListPage.regionSize) / MemoryLayout<FrameListPointer>.stride)
                assert(frameList.count == 1024)

                queueHead.headLinkPointer = QueueHead.QueueHeadLinkPointer(queueHeadAddress: controlQH.physAddress)
                for idx in stride(from: 0, to: frameList.count, by: frequency) {
                    frameList[idx] = FrameListPointer(queueHead: queueHead.physAddress)
                }

            default:
                fatalError("UHCI: Pipes of type \(transferType) are not currently supported")
        }
        dumpAndCheckFrameList()
        uhciDebug("Added QH")
    }


    func removeQueueHead(_ queueHead: PhysQueueHead, transferType: USB.EndpointDescriptor.TransferType) {
        uhciDebug("removeQueueHEad", queueHead)
        dumpAndCheckFrameList()

        switch transferType {
            case .control:
                // The queueHead that is being searched for
                //let queueHeadLP = QueueHead.QueueHeadLinkPointer(queueHeadAddress: queueHead.physAddress)
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

                    guard let next = qh.headLinkPointer.nextQH else {
                        fatalError("UHCI-HCD: removeQueueHead: Reached end of QHs")
                    }
                    qh = next
                    qhlp = qh.headLinkPointer
                }
                fatalError("Cant find QH \(queueHead) in list of control queueheads")


            case .interrupt:
                // Loop through eqvery frame list entry to
                fallthrough

            default:
                fatalError("Pipes of type \(transferType) are not currently supported")
        }

        uhciDebug("Removed QH")
        dumpAndCheckFrameList()
    }


    // Dump and check the framelist PTRs and QHs
    private func dumpAndCheckFrameList() {
        guard UHCI_DEBUG else { return }

        // Keep track of FL entries already seen to avoid deupliacting work
        var previousFLEntries: [UInt32] = []
        previousFLEntries.reserveCapacity(16)

        let ptr = UnsafeMutablePointer<FrameListPointer>(bitPattern: frameListPage.vaddr)!
        let frameList = UnsafeMutableBufferPointer(start: ptr, count: Int(frameListPage.regionSize) / MemoryLayout<FrameListPointer>.stride)
        print("UHCI: Dumping frame list at:", ptr)

        for idx in 0..<frameList.count {
            let entry = frameList[idx]
            if previousFLEntries.contains(entry.address) { continue }
            print("UHCI:\(idx): \(entry): ", terminator: " ")
            var next = entry.physQueueHead
            var maxDepth = 32

            while maxDepth >= 0, let qhlp = next {
                maxDepth -= 1
                print("UHCI: ->", qhlp, terminator: "")
                next = qhlp.headLinkPointer.nextQH
            }

            previousFLEntries.append(entry.address)
        }
        print("\n")
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
        uhciDebug("HCD did not reset")
    }

}


extension HCD_UHCI: USBHCD {

    func pollInterrupt() -> Bool {
        return false
    }
}

extension HCD_UHCI: USBHub {

    var portCount: Int { 2 }

    func reset(port: Int) -> Bool {
        precondition(port < portCount)
        uhciDebug("Reseting port:", port)
        var status = portStatus(port: port)

        var mask = PortStatusControl(rawValue: 0)
        mask.portEnabled = true
        mask.resumeDetect = true
        mask.portReset = true
        mask.suspend = true

        status = PortStatusControl(rawValue: status.rawValue & mask.rawValue)
        status.portReset = true
        portControl(port: port, data: status)
        sleep(milliseconds: 100)

        status = portStatus(port: port)
        uhciDebug("port status, ", status)
        status = PortStatusControl(rawValue: status.rawValue & mask.rawValue)
        status.portReset = false
        portControl(port: port, data: status)
        sleep(milliseconds: 1)

        status = portStatus(port: port)
        status = PortStatusControl(rawValue: status.rawValue & mask.rawValue)
        status.portEnabled = true
        portControl(port: port, data: status)

        var resetOK = false

        for i in 1...10 {
            sleep(milliseconds: 50)
            var status = portStatus(port: port)
            uhciDebug("reset status \(i): \(status)")
            if !status.currentConnectStatus {
                resetOK = true
                break
            }

            if status.portEnabledChange || status.connectStatusChange {
                status = PortStatusControl(rawValue: status.rawValue & mask.rawValue)
                status.clearConnectStatusChange()
                status.clearPortEnabledDisabledChange()
                portControl(port: port, data: status)
                continue
            }

            if status.portEnabled {
                resetOK = true
                break
            }
        }

        uhciDebug("Port \(port) reset", resetOK ? "OK" : "Failed")
        return resetOK
    }


    func detectConnected(port: Int) -> USB.Speed? {
        let status = portStatus(port: port)
        uhciDebug("detectConnected, status: ", status)
        guard status.currentConnectStatus else {
            uhciDebug("no device detected")
            return nil
        }
        let speed = status.lowSpeedDeviceAttached ? USB.Speed.lowSpeed : USB.Speed.fullSpeed
        uhciDebug("device connected at speed:", speed)
        return speed
    }


    func nextAddress() -> UInt8? {
        defer { maxAddress += 1 }
        return maxAddress
    }


}


// HCD Register access
fileprivate extension HCD_UHCI {
    var cmdRegister: Command {
        get { Command(rawValue: inw(ioBasePort)) }
        set { outw(ioBasePort, newValue.rawValue) }
    }

    var statusRegister: Status {
        get { Status(rawValue: inw(ioBasePort + 2)) }
        set { outw(ioBasePort + 2, newValue.rawValue) }
    }

    var interruptEnableRegister: InterruptEnable {
        get { InterruptEnable(rawValue: inw(ioBasePort + 4)) }
        set { outw(ioBasePort + 4, newValue.rawValue) }
    }

    var frameNumberRegister: UInt16 {
        get { inw(ioBasePort + 6) }
        set {
            precondition(newValue & 0xf800 == 0)
            outw(ioBasePort + 6, newValue)

        }
    }

    var frameListBaseAddress: UInt32 {
        get { inl(ioBasePort + 8) }
        set {
            precondition(newValue & 0x0000_0fff == 0)
            outl(ioBasePort + 8, newValue)
        }
    }

    var startOfFrame: UInt8 {
        get { inb(ioBasePort + 0xc) }
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
        uhciDebug("registerDump")
        uhciDebug("cmdRegister:", self.cmdRegister)
        uhciDebug("statusRegister:", self.statusRegister)
        uhciDebug("interruptEnableRegister:", self.interruptEnableRegister)
        uhciDebug("FrameNumberRegister: 0x\(String(self.frameNumberRegister, radix: 16))")
        uhciDebug("FrameListBaseAddress: 0x\(String(self.frameListBaseAddress, radix: 16))")
        uhciDebug("startOfFrame:", self.startOfFrame)
        uhciDebug("Port0:", portStatus(port: 0))
        uhciDebug("Port1:", portStatus(port: 1))
    }
}

