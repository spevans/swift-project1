/*
 * kernel/devices/usb/uhci-hcd.swift
 *
 * Created by Simon Evans on 04/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * UHCI HCD driver.
 *
 */


final class HCD_UHCI: PCIDeviceDriver, CustomStringConvertible {

    static private let GLOBAL_RESET_TRIES = 5

    private var deviceFunction: PCIDeviceFunction       // The device (upstream) side of the bridge
    fileprivate let ioBasePort: UInt16
    private var maxAddress: UInt8 = 1
    private(set) var qhStart = PhysQueueHead(address: PhysAddress(0))
    let allocator: UHCIAllocator

    // FIXME: Should guarantee being 32bit phys
    let frameListPage = alloc(pages: 1)

    let acpiDevice: AMLDefDevice?
    var enabled = true

    var description: String { "UHCI: driver @ IO 0x\(String(ioBasePort, radix: 16))" }

    init?(pciDevice: PCIDevice) {
        print("UHCI: init")

        guard pciDevice.deviceFunction.deviceClass == PCIDeviceClass(classCode: .serialBusController,
                                                                     subClassCode: PCISerialBusControllerSubClass.usb.rawValue,
                                                                     progInterface: PCIUSBProgrammingInterace.uhci.rawValue) else {
            print("UHCI: \(pciDevice) is not a UHCI Device")
            return nil
        }

        guard let generalDevice = pciDevice.deviceFunction.generalDevice else {
            print("UHCI: Not a PCI generalDevice")
            return nil
        }

        let bar4 = generalDevice.bar4
        guard bar4 & 1 == 1 else {
            print("UHCI: BAR4 address 0x\(String(bar4, radix: 16)) is not an IO resource")
            return nil
        }

        allocator = UHCIAllocator()


        ioBasePort = UInt16(truncatingIfNeeded: bar4 & 0xffe0)
        print("UHCI: IO 0x\(String(ioBasePort, radix: 16))")
        self.deviceFunction = pciDevice.deviceFunction
        self.acpiDevice = pciDevice.acpiDevice

        let sbrn = deviceFunction.configSpace.readConfigByte(atByteOffset: 0x60)
        print("UHCI: bus release number 0x\(String(sbrn, radix: 16))")

        // Disable PCI interrupts, set IOSpace active
        var pciCommand = deviceFunction.command
        pciCommand.ioSpace = true
        pciCommand.interruptDisable = true
        deviceFunction.command = pciCommand
        print("UHCI: PCICommand:", deviceFunction.command)
    }


    func initialiseDevice() {
        print("UHCI: driver init")

        // Disable Legacy Support (SMI/PS2 emulation)
        print("UHCI: PCIStatus:", deviceFunction.status)
        print("UHCI: PCICommand:", deviceFunction.command)
        deviceFunction.configSpace.writeConfigWord(atByteOffset: 0xC0, value: 0xF800)

        // Save SOF to restore after reset
        let savedSOF = self.startOfFrame
        // Disable interrupts
        self.interruptEnableRegister = InterruptEnable(rawValue: 0)
        globalReset()
        hcdReset()
        // Restore SOF
        self.startOfFrame = savedSOF


        // Setup the framelist, with default QueueHeads
        print("UHCI: frameListPage:", frameListPage)
        let ptr = UnsafeMutablePointer<FrameListPointer>(bitPattern: frameListPage.vaddr)!
        let frameList = UnsafeMutableBufferPointer(start: ptr, count: Int(frameListPage.regionSize) / MemoryLayout<FrameListPointer>.stride)
        assert(frameList.count == 1024)

        // Create a QueueHead which teminates both the QH and Element Links and store this in the every elemet of the frame list
        // This forms the last node in a list of Control QueueHeads. The QueueHeads points to a terminating TransferDescriptor.
        // This is to workaround a bug in PIIX chipsets which need to set the terminating TD.
        let terminatingTD = allocator.allocTransferDescriptor()
        terminatingTD.pointer.pointee = TransferDescriptor(
            linkPointer: TransferDescriptor.LinkPointer.terminator(),
            controlStatus: TransferDescriptor.ControlStatus(),
            token: TransferDescriptor.Token(pid: .pidIn, deviceAddress: 0x7f, endpoint: 0, dataToggle: false, maximumLength: 0),
            bufferPointer: 0
        )

        let terminatingQH = allocator.allocQueueHead()
        terminatingQH.pointer.pointee = QueueHead(
            headLinkPointer: QueueHead.QueueHeadLinkPointer.terminator(),
            elementLinkPointer: QueueHead.QueueElementLinkPointer(transferDescriptorAddress: terminatingTD.physAddress)
        )

        // Create the start node in the list which has a terminating element and points to the last node as the link pointer
        qhStart = allocator.allocQueueHead()
        qhStart.pointer.pointee = QueueHead(
            headLinkPointer: QueueHead.QueueHeadLinkPointer(queueHeadAddress: terminatingQH.physAddress),
            elementLinkPointer: QueueHead.QueueElementLinkPointer.terminator()
        )

        let flp = FrameListPointer(queueHead: qhStart.physAddress)
        frameList.assign(repeating: flp)

        // Point to the frame list and set frame number to 0
        frameListBaseAddress = UInt32(frameListPage.address.value)
        frameNumberRegister = 0

//        startOfFrame = 64
        statusRegister = Status(rawValue: 0)
        var cmd = Command()
        cmd.maxPacket64Bytes = true
        cmd.configureFlag = true
        cmd.run = true
        cmdRegister = cmd
        print("UHCI: Enabled USB")
        sleep(milliseconds: 10)
        registerDump()
        usbBus!.enumerate(hub: self)
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
        print("UHCI: HCD did not reset")
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
        print("UHCI: Reseting port:", port)
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
        print("UHCI: port status, ", status)
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
            print("UHCI: reset status \(i): \(status)")
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

        print("UHCI: Port \(port) reset", resetOK ? "OK" : "Failed")
        return resetOK
    }


    func detectConnected(port: Int) -> USB.Speed? {
        let status = portStatus(port: port)
        print("UHCI: detectConnected, status: ", status)
        guard status.currentConnectStatus else {
            print("UHCI: no device detected")
            return nil
        }
        let speed = status.lowSpeedDeviceAttached ? USB.Speed.lowSpeed : USB.Speed.fullSpeed
        print("UHCI: device connected at speed:", speed)
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
        print("UHCI:", self.cmdRegister)
        print("UHCI:", self.statusRegister)
        print("UHCI:", self.interruptEnableRegister)
        print("UHCI: FrameNumberRegister: 0x\(String(self.frameNumberRegister, radix: 16))")
        print("UHCI: FrameListBaseAddress: 0x\(String(self.frameListBaseAddress, radix: 16))")
        print("UHCI: startOfFrame:", self.startOfFrame)
        print("UHCI: Port0:", portStatus(port: 0))
        print("UHCI: Port1:", portStatus(port: 1))
    }
}

