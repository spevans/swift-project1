/*
 * kernel/devices/kbd8042.swift
 *
 * Created by Simon Evans on 08/01/2016.
 * Copyright © 2016, 2026 Simon Evans. All rights reserved.
 *
 * 8042 PS/2 keyboard/mouse controller
 *
 * This controller acts as a bus device and creates down downstream
 * devices representing each port.
 * This device is currently only discovered via ACPI although it could
 * be probed as it is a common platofrm device on most x86 PCs and the
 * IO Ports and IRQs are at standard locations.
 *
 * The controller adds itself as a child of the ACPI node's parent or
 * alternativey directly onto the system bus. This is not necesary as
 * the device hirearchy is flat anyway and there is not power save
 * associated with these devices. It is mostly to provide a more logical
 * view in the device tree.
 *
 * The controller is mostly complete but does require some more work
 * with regard to locking between activity on both ports as all
 * comunication with the controller goes through 1 pair of ports whether
 * commnunicating with the controller of downstream devices.
 *
 * The interrupt handler would also require synchronisation with any
 * commands being send to the controller or devices to ensure that response
 * bytes are not interpreted as data.
 *
 */


private var KBD8042Debug = false

// For the keyboard and mouse
class PS2Device: Device {
    typealias Writer = (UInt8) -> Bool

    private let controller: KBD8042
    private let port: Int
    private(set) var receivedData: Writer? = nil


    init(parent: Device, controller: KBD8042, port: Int) {
        self.controller = controller
        self.port = port
        super.init(
            parent: parent,
            className: "PS2Device",
            busDeviceName: #sprintf("ps2/port%d", self.port)
        )
    }

    func sendCommandGetResponse(_ cmd: UInt8, data: UInt8? = nil) -> UInt8? {
        if KBD8042Debug {
            #kprintf("i8042: port %d sending command: 0x%2.2x haveData: %s, awaiting response\n",
                     port, cmd, data != nil)
        }
        if port == 1 {
            if self.controller.sendCommand1stPort(cmd, data: data) {
                return self.controller.getResponse()
            } else {
                if KBD8042Debug { #kprintf("i8042: port1 send command failed\n", port) }
                return nil
            }
        } else if port == 2 {
            if self.controller.sendCommand2ndPort(cmd, data: data) {
                return self.controller.getResponse()
            } else {
                if KBD8042Debug { #kprintf("i8042: port2 send command failed\n", port) }
                return nil
            }
        }
        return nil
    }

    func sendCommand(_ cmd: UInt8, data: UInt8? = nil) -> Bool {
        if KBD8042Debug {
            #kprintf("i8042: port %d sending command: 0x%2.2x\n", port, cmd)
        }
        if port == 1 {
            return self.controller.sendCommand1stPort(cmd, data: data)
        } else if port == 2 {
            return self.controller.sendCommand2ndPort(cmd, data: data)
        } else {
            return false
        }
    }

    func readData() -> UInt8? {
        return self.controller.getResponse()
    }

    func enablePort() -> Bool {
        if port == 1 {
            self.controller.sendCommand(.Enable1stPort)
        } else if port == 2 {
            self.controller.sendCommand(.Enable2ndPort)
        } else {
            false
        }
    }

    func disablePort() -> Bool {
        if port == 1 {
            self.controller.sendCommand(.Disable1stPort)
        } else if port == 2 {
            self.controller.sendCommand(.Disable2ndPort)
        } else {
            false
        }
    }

    func setReceivedData(to writer: Writer?) {
        // FIXME: should the individual ports interrupt bits be set/cleared if interrupts are
        // not to be processed?
//        if (!self.controller.setInterrupt(forPort: self.port, to: writer != nil)) {
//            #kprint("port: %d failed to set interrupt to %s\n", port, writer != nil)
//        }
        self.receivedData = writer
    }
}


final class KBD8042: DeviceDriver {

    /* Bits for the KB_KBD_SET_LEDS command. */
    static private let KB_LED_SCROLL_LOCK:  UInt8 = 0x01
    static private let KB_LED_NUM_LOCK:     UInt8 = 0x02
    static private let KB_LED_CAPS_LOCK:    UInt8 = 0x04

    static private let I8042_BUFFER_SIZE = 16
    static private let POLL_LOOP_COUNT = 0x1000


    private struct StatusRegister {
        let rawValue: UInt8

        var outputFull:    Bool { return rawValue.bit(0) } // Output FROM 8042
        var inputFull:     Bool { return rawValue.bit(1) } // Input TO 8042 (cmds etc)
        var system:        Bool { return rawValue.bit(2) }
        var command:       Bool { return rawValue.bit(3) } // Command or Data
        var inhibit:       Bool { return rawValue.bit(4) } // Aux/mouse data in output buffer
        var auxOutputFull: Bool { return rawValue.bit(5) }
        var timeOut:       Bool { return rawValue.bit(6) }
        var parityError:   Bool { return rawValue.bit(7) }

        init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }


    private struct CommandRegister {
        var rawValue: UInt8

        // Bit masks
        private let Interrupt1      = 0
        private let Interrupt2      = 1
        private let System          = 2    // Set/clear System flag in status
        private let Port1Disable    = 4
        private let Port2Disable    = 5
        private let TranslateEnable = 6


        var interrupt1: Bool {
            get { rawValue.bit(Interrupt1) }
            set { rawValue.bit(Interrupt1, newValue) }
        }

        var interrupt2: Bool {
            get { rawValue.bit(Interrupt2) }
            set { rawValue.bit(Interrupt2, newValue) }
        }

        var system: Bool {
            get { rawValue.bit(System) }
            set { rawValue.bit(System, newValue) }
        }

        var port1Disable: Bool {
            get { rawValue.bit(Port1Disable) }
            set { rawValue.bit(Port1Disable, newValue) }
        }

        var port2Disable: Bool {
            get { rawValue.bit(Port2Disable) }
            set { rawValue.bit(Port2Disable, newValue) }
        }

        var translateEnable: Bool {
            get { rawValue.bit(TranslateEnable) }
            set { rawValue.bit(TranslateEnable, newValue) }
        }

        init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }


    enum I8042Command: UInt8, CustomStringConvertible {
        case ReadCommandByte            = 0x20
        case WriteCommandByte           = 0x60
        case PasswordInstalled          = 0xA4
        case PasswordSet                = 0xA5
        case PasswordEnable             = 0xA6
        case Disable2ndPort             = 0xA7
        case Enable2ndPort              = 0xA8
        case SelfTest2ndPort            = 0xA9
        case SelfTestController         = 0xAA
        case SelfTest1stPort            = 0xAB
        case DisagnosticDump            = 0xAC
        case Disable1stPort             = 0xAD
        case Enable1stPort              = 0xAE
        case ReadControllerInputPort    = 0xC0
        case ReadControllerOutputPort   = 0xD0
        case WriteControllerOutputPort  = 0xD1
        case Write2ndPortOutput         = 0xD4
        case PulseOutputPort            = 0xF0

        var description: String {
            switch self {
            case .ReadCommandByte:           "ReadCommandByte"
            case .WriteCommandByte:          "WriteCommandByte"
            case .PasswordInstalled:         "PasswordInstalled"
            case .PasswordSet:               "PasswordSet"
            case .PasswordEnable:            "PasswordEnable"
            case .Disable2ndPort:            "Disable2ndPort"
            case .Enable2ndPort:             "Enable2ndPort"
            case .SelfTest2ndPort:           "SelfTest2ndPort"
            case .SelfTestController:        "SelfTestController"
            case .SelfTest1stPort:           "SelfTest1stPort"
            case .DisagnosticDump:           "DisagnosticDump"
            case .Disable1stPort:            "Disable1stPort"
            case .Enable1stPort:             "Enable1stPort"
            case .ReadControllerInputPort:   "ReadControllerInputPort"
            case .ReadControllerOutputPort:  "ReadControllerOutputPort"
            case .WriteControllerOutputPort: "WriteControllerOutputPort"
            case .Write2ndPortOutput:        "Write2ndPortOutput"
            case .PulseOutputPort:           "PulseOutputPort"
            }
        }
    }


    enum PS2KeyboardResponse: UInt8 {
        case OverRun            = 0x00
        case SelfTestOK         = 0xAA
        case EchoResponse       = 0xEE
        case KeyBreak           = 0xF0
        case Ack                = 0xFA
        case SelfTestFailed     = 0xFC
        case Resend             = 0xFE
        case KeyError           = 0xFF
    }

    private let dataPort:        UInt16
    private let statusRegister:  UInt16
    private let commandRegister: UInt16
    private let port1irq: IRQSetting
    private let port2irq: IRQSetting

    let busDevice: Device   // The 8042 device itself
    private var dualChannel: Bool = false
    private var port1InterruptHandler: InterruptHandler?
    private var port2InterruptHandler: InterruptHandler?

    private var port1device: PS2Device? = nil
    private var port2device: PS2Device? = nil


    override func info() -> String {
        #sprintf("i8042 bus: port1: %s port2: %s",
                 port1device?.deviceName ?? "none",
                 port2device?.deviceName ?? "none"
        )
    }

    init?(parent: Device?, dataPort: UInt16, statusPort: UInt16,
          keyboardIrq: IRQSetting, mouseIrq: IRQSetting) {
        #if TEST
        let parent = parent ?? Device()
        #else
        let parent = parent ?? system.deviceManager.masterBus.device
        #endif
        self.busDevice = Device(parent: parent, className: "PS2", busDeviceName: "i8042")
        self.busDevice.setAsBus()

        if KBD8042Debug {
            #kprintf("i8042: ports 0x%2.2x, 0x%2.2x kbdIrq: %d mouseIrq: %d\n",
                     dataPort, statusPort, keyboardIrq.irq, mouseIrq.irq)
        }
        self.dataPort = dataPort
        self.statusRegister = statusPort
        self.commandRegister = statusPort
        self.port1irq = keyboardIrq
        self.port2irq = mouseIrq

        super.init(driverName: "i8042", device: self.busDevice)
        // FIXME: This driver should just drive the i8042 as a bus and
        // have seperate keyboard and mouse drivers
        guard self.initialise() else {
            return nil
        }
    }

    private func initialise() -> Bool {
        // 1. Flush output buffer
        if flushOutput() == false { // No device
            #kprint("i8042: Failed to find i8042")
            return false
        }

        // 2. Disable devices
        sendCommand(.Disable1stPort)
        sendCommand(.Disable2ndPort)

        // 3. Set controller config byte
        if let cmdByte = sendCommandGetResponse(.ReadCommandByte) {
            var command = CommandRegister(rawValue: cmdByte)
            // Only set if dual channel
            dualChannel = command.port2Disable
            if !dualChannel {
                #kprint("i8042: 2nd PS2 port not found")
            }
            command.interrupt1 = false
            command.interrupt2 = false
            command.translateEnable = false
            command.port2Disable = true
            sendCommand(.WriteCommandByte, data: command.rawValue)
            //sendCommand(.Disable2ndPort)
        } else {
            #kprint("i8042: Failed to get command byte")
            return false
        }

        // 4. Send POST to controller
        if let postResult = sendCommandGetResponse(.SelfTestController) {
            if postResult != 0x55 {
                #kprintf("i8042: POST returned: %X\n", postResult)
                return false
            }
        } else {
            #kprint("i8042: Failed to send POST")
        }
        self.setInstanceName(to: "i8042")

        // 5. Interface tests
        if KBD8042Debug { #kprint("i8042: Testing 1st port") }
        if let resp = sendCommandGetResponse(.SelfTest1stPort) {
            if resp != 0 {
                #kprintf("i8042: port 1 test failed: %2.2x\n", resp)
            } else {
                if KBD8042Debug { #kprint("i8042: 1st port ok") }
            }
        } else {
            #kprint("i8042: No reply to test from 1st port")
        }
        if dualChannel {
            if KBD8042Debug { #kprint("i8042: Testing 2nd port") }
            if let resp = sendCommandGetResponse(.SelfTest2ndPort) {
                if resp != 0 {
                    #kprintf("i8042: port 2 test failed: %2.2x\n", resp)
                } else {
                    if KBD8042Debug { #kprint("i8042: 2nd port ok") }
                }
            } else {
                #kprint("i8042: No reply to test from 2nd port")
            }
        } else {
            #kprint("i8042: no 2nd port detected")
        }

        // 6. Enable devices
        sendCommand(.Enable1stPort)
        if dualChannel {
            sendCommand(.Enable2ndPort)
        }

        flushOutput()
        let kbdDevice = PS2Device(parent: self.busDevice, controller: self, port: 1)
        self.port1device = kbdDevice
        _ = PS2Keyboard(device: kbdDevice)

        flushOutput()
        if dualChannel {
            let auxDevice = PS2Device(parent: self.busDevice,  controller: self, port: 2)
            self.port2device = auxDevice
            _ = PS2Mouse(device: auxDevice)
        }

        if let cmdByte = sendCommandGetResponse(.ReadCommandByte) {
            var command = CommandRegister(rawValue: cmdByte)
            command.interrupt1 = true
            if dualChannel {
                command.interrupt2 = true
            }
            sendCommand(.WriteCommandByte, data: command.rawValue)
        }

        flushOutput()
        // Setup interrupt handlers
        // FIXME: determine correct irq
        let handler = InterruptHandler(name: "i8042port1", handler: port1Interrupt)
        self.port1InterruptHandler = handler
        system.deviceManager.setIrqHandler(handler, forInterrupt: self.port1irq)
        if dualChannel {
            let handler = InterruptHandler(name: "i8042port2", handler: port2Interrupt)
            self.port2InterruptHandler = handler
            system.deviceManager.setIrqHandler(handler, forInterrupt: self.port2irq)

        }

        return true
    }


    private func readStatus() -> StatusRegister {
        return StatusRegister(rawValue: inb(self.statusRegister))
    }


    private func readData() -> UInt8 {
        return inb(self.dataPort)
    }


    private func writeData(_ data: UInt8) {
        outb(self.dataPort, data)
    }


    // Wait until the input buffer of the 8042 has data
    private func waitForInput() -> Bool {
        for _ in 1...KBD8042.POLL_LOOP_COUNT {
            if readStatus().inputFull {
                return true
            }
        }
        return false
    }


    private func waitForInputEmpty() -> Bool {
        for _ in 1...KBD8042.POLL_LOOP_COUNT {
            if !readStatus().inputFull {
                return true
            }
        }
        return false
    }


    // returns true if controller flushed ok
    @discardableResult
    private func flushOutput() -> Bool {
        var count = KBD8042.I8042_BUFFER_SIZE
        while count >= 0 && readStatus().outputFull {
            count -= 1
            _ = readData()
        }
        return count >= 0
    }


    // Wait until the output buffer of the 8042 is empty
    private func waitForOutputEmpty() -> Bool {
        for _ in 1...KBD8042.POLL_LOOP_COUNT {
            if !readStatus().outputFull {
                return true
            }
        }
        return false
    }


    private func waitForOutput() -> Bool {
        for _ in 1...KBD8042.POLL_LOOP_COUNT {
            if readStatus().outputFull {
                return true
            }
        }
        return false
    }


    @discardableResult
    fileprivate func sendCommand(_ cmd: I8042Command) -> Bool {
        if waitForInputEmpty() {
            outb(self.commandRegister, cmd.rawValue)
            return true
        } else {
            #kprint("i8042: Error sending command:", cmd)
            return false
        }
    }


    @discardableResult
    private func sendCommand(_ cmd: I8042Command, data: UInt8) -> Bool {
        if sendCommand(cmd) {
            writeData(data)
            return true
        } else {
            return false
        }
    }


    fileprivate func getResponse() -> UInt8? {
        if waitForOutput() {
            return readData()
        }

        return nil
    }


    private func sendCommandGetResponse(_ cmd: I8042Command) -> UInt8? {
        if sendCommand(cmd) {
            return getResponse()
        }
        #kprint("i8042: Timed out getting response to comand:", cmd)

        return nil
    }


    // MARK: Control for each individual port including sending commands and data
    // to the downstream devices.
    fileprivate func setInterrupt(forPort port: Int, to: Bool) -> Bool {
        if KBD8042Debug {
            #kprintf("i8042: Setting interrupt for port %d to %s\n", port, to)
        }
        if let cmdByte = sendCommandGetResponse(.ReadCommandByte) {
            var command = CommandRegister(rawValue: cmdByte)
            if port == 1 {
                command.interrupt1 = to
            } else if port == 2 {
                command.interrupt2 = to
            }
            return sendCommand(.WriteCommandByte, data: command.rawValue)
        } else {
            return false
        }
    }

    private func sendData1stPort(_ data: UInt8) -> Bool {
        if waitForInputEmpty() {
            writeData(data)
            while waitForOutput() {
                let data = readData()
                if let resp = PS2KeyboardResponse(rawValue: data) {
                    if resp == .Ack {
                        return true
                    }
                    if resp == .Resend {
                        #kprint("i8042: got resend")
                        return false
                    }
                }
                #kprintf("i8042: Got unexpected response: %2.2x\n", data)
            }
        }

        return false
    }


    @discardableResult
    fileprivate func sendCommand1stPort(_ cmd: UInt8) -> Bool {
        return sendData1stPort(cmd)
    }


    @discardableResult
    fileprivate func sendCommand1stPort(_ cmd: UInt8, data: UInt8? = nil) -> Bool {
        if KBD8042Debug {
            #kprintf("i8042: sendCommand1stPort: cmd: 0x%2.2x haveData: %s\n", cmd, data != nil)
        }
        if sendCommand1stPort(cmd) {
            if KBD8042Debug { #kprintf("i8042: sent command 0x%2.2x to port1 ok\n", cmd) }
            if let data {
                if KBD8042Debug {
                    #kprintf("i8042: sendCommand1stPort: data: 0x%2.2x\n", data)
                }
                return sendData1stPort(data)
            } else {
                return true
            }
        }
        #kprintf("i8042: failed to send command to port 1: 0x%2.2x\n", cmd)
        return false
    }


    fileprivate func sendCommand2ndPort(_ cmd: UInt8) -> Bool {
        sendCommand(.Write2ndPortOutput)
        return sendCommand1stPort(cmd)
    }

    @discardableResult
    fileprivate func sendCommand2ndPort(_ cmd: UInt8, data: UInt8? = nil) -> Bool {
        if sendCommand(.Write2ndPortOutput) && sendCommand1stPort(cmd) {
            if let data = data {
                return sendCommand(.Write2ndPortOutput) && sendData1stPort(data)
            } else {
                return true
            }
        }
        return false
    }

    // TODO: These could probably be merged into one handler and better handle errors
    private func port1Interrupt() -> Bool {
        while true {
            let status = readStatus()
            guard status.outputFull else { break }
            let data = readData()
            // Bit 5 of the status register indicates aux (mouse) data.
            // Route to the appropriate buffer so mouse bytes are not
            // misinterpreted as keyboard scan codes.
            if status.auxOutputFull, let writer = self.port2device?.receivedData {
                _ = writer(data)
            } else {
                if let writer = self.port1device?.receivedData {
                    _ = writer(data)
                }
            }
        }
        return true
    }

    private func port2Interrupt() -> Bool {
        while readStatus().auxOutputFull {
            let data = readData()
            if let writer = self.port2device?.receivedData {
                _ = writer(data)
            }
        }
        return true
    }
}
