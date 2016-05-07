/*
 * kernel/devices/kbd8042.swift
 *
 * Created by Simon Evans on 08/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * 8042 PS/2 keyboard controller
 *
 */


struct KBD8042 {

    private struct StatusRegister {
        var status: UInt8

        // Bit masks
        private let OutputFull:    UInt8 = 0x01   // Output FROM 8042
        private let InputFull:     UInt8 = 0x02   // Input TO 8042 (cmds etc)
        private let System:        UInt8 = 0x04
        private let Command:       UInt8 = 0x08   // Command or Data
        private let Inhibit:       UInt8 = 0x10
        private let TransmitError: UInt8 = 0x20
        private let TimeOut:       UInt8 = 0x40
        private let ParityError:   UInt8 = 0x80

        private func bit(_ bit: UInt8) -> Bool { return (status & bit) == bit }
        var outputFull:    Bool { return bit(OutputFull) }
        var inputFull:     Bool { return bit(InputFull) }
        var system:        Bool { return bit(System) }
        var command:       Bool { return bit(Command) }
        var inhibit:       Bool { return bit(Inhibit) }
        var transmitError: Bool { return bit(TransmitError)  }
        var timeOut:       Bool { return bit(TimeOut) }
        var parityError:   Bool { return bit(ParityError) }

        init() {
            status = inb(STATUS_REGISTER)
        }
    }


    private struct CommandRegister {
        var rawValue: UInt8

        // Bit masks
        private let Interrupt1:      UInt8 = 0x01
        private let Interrupt2:      UInt8 = 0x02
        private let System:          UInt8 = 0x04    // Set/clear System flag in status
        private let Port1Disable:    UInt8 = 0x10
        private let Port2Disable:    UInt8 = 0x20
        private let TranslateEnable: UInt8 = 0x40

        private mutating func bit(_ bit: UInt8, _ flag: Bool) {
            if flag {
                rawValue |= bit
            } else {
                rawValue &= ~bit
            }
        }

        private func bit(_ bit: UInt8) -> Bool {
            return (rawValue & bit) == bit
        }

        var interrupt1: Bool {
            get { return bit(Interrupt1) }
            set(value) { bit(Interrupt1, value) }
        }

        var interrupt2: Bool {
            get { return bit(Interrupt2) }
            set(value) { bit(Interrupt2, value) }
        }

        var system: Bool {
            get { return bit(System) }
            set(value) { bit(System, value) }
        }

        var port1Disable: Bool {
            get { return bit(Port1Disable) }
            set(value) { bit(Port1Disable, value) }
        }

        var port2Disable: Bool {
            get { return bit(Port2Disable) }
            set(value) { bit(Port2Disable, value) }
        }

        var translateEnable: Bool {
            get { return bit(TranslateEnable) }
            set(value) { bit(TranslateEnable, value) }
        }

        init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }


    enum I8042Command: UInt8 {
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
    }


    enum PS2KeyboardCommand: UInt8 {
        case SetLeds            = 0xED
        case Echo               = 0xEE
        case ScanCodeSet        = 0xF0  // Used for both get and set
        case SendID             = 0xF2
        case SetTypematic       = 0xF3
        case EnableScanning     = 0xF4
        case DisableScanning    = 0xF5
        case SetDefaultParams   = 0xF6
        case ResendLastByte     = 0xFE
        case ResetAndSelfTest   = 0xFF
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


    static private let DATA_PORT:        UInt16 = 0x60
    static private let STATUS_REGISTER:  UInt16 = 0x64
    static private let COMMAND_REGISTER: UInt16 = 0x64

    /* Bits for the KB_KBD_SET_LEDS command. */
    static private let KB_LED_SCROLL_LOCK:  UInt8 = 0x01
    static private let KB_LED_NUM_LOCK:     UInt8 = 0x02
    static private let KB_LED_CAPS_LOCK:    UInt8 = 0x04

    static private let I8042_BUFFER_SIZE = 16
    static private let POLL_LOOP_COUNT = 0x1000
    static private(set) var dualChannel: Bool = false


    static func initKbd() {
        if BootParams.vendor == "Apple Inc." {
            print("i8042: Skipping on:", BootParams.vendor)
            return
        }

        // 1. Flush output buffer
        if flushOutput() == false { // No device
            print("i8042: Cant find i8042")
            return
        }

        // 2. Disable devices
        sendCommand(.Disable1stPort)
        sendCommand(.Disable2ndPort)

        // 3. Set controller config byte
        if let cmdByte = sendCommandGetResponse(.ReadCommandByte) {
            var command = CommandRegister(rawValue: cmdByte)
            // Only set if dual channel
            dualChannel = command.port2Disable
            if dualChannel {
                print("i8042: 2nd PS2 port found")
            }
            command.interrupt1 = false
            command.interrupt2 = false
            command.translateEnable = false
            sendCommand(.WriteCommandByte, data: command.rawValue)
        } else {
            print("i8042: Cant get command byte")
            return
        }

        // 4. Send POST to controller
        if let postResult = sendCommandGetResponse(.SelfTestController) {
            if (postResult == 0x55) {
                print("i8042: POST ok")
            } else {
                printf("i8042: POST returned: %X\n", postResult)
                return
            }
        } else {
            print("i8042: cant send POST")
        }

        // 5. Interface tests
        if let resp = sendCommandGetResponse(.SelfTest1stPort) {
            if resp != 0 {
                printf("i8042: port 1 test failed: %2.2x\n", resp)
            }
            if dualChannel {
                if let resp = sendCommandGetResponse(.SelfTest2ndPort) {
                    if resp != 0 {
                        printf("i8042: port 2 test failed: %2.2x\n", resp)
                    }
                }
            }
        }

        // 6. Enable devices
        sendCommand(.Enable1stPort)
        if let cmdByte = sendCommandGetResponse(.ReadCommandByte) {
            var command = CommandRegister(rawValue: cmdByte)
            command.interrupt1 = true
            sendCommand(.WriteCommandByte, data: command.rawValue)
        }
        // 7. Reset
        if sendCommand1stPort(.ResetAndSelfTest) {
            if let resp = getResponse() {
                printf("kbd: Reset 1st port: %2x\n", resp)
            } else {
                printf("kbd: Reset 1st port: failed\n");
            }
        }

        if sendCommand1stPort(.ScanCodeSet, data: 0) {
            if let resp = getResponse() {
                printf("kbd: Current scan code set: %d\n", resp)
                if resp != 2 {
                    sendCommand1stPort(.ScanCodeSet, data: 2)
                }
            } else {
                print("kbd: Cant get scan code set")
            }
        }

        flushOutput()
        setIrqHandler(1, handler: kbdInterrupt)
        print("i8042: kbd initialised")
    }


    private static func readStatus() -> StatusRegister {
        return StatusRegister()
    }


    private static func readData() -> UInt8 {
        return inb(DATA_PORT)
    }


    private static func writeData(_ data: UInt8) {
        outb(DATA_PORT, data)
    }


    // Wait until the input buffer of the 8042 has data
    static func waitForInput() -> Bool {
        for _ in 1...POLL_LOOP_COUNT {
            if readStatus().inputFull {
                return true
            }
        }
        return false
    }


    static func waitForInputEmpty() -> Bool {
        for _ in 1...POLL_LOOP_COUNT {
            if !readStatus().inputFull {
                return true
            }
        }
        return false
    }


    // returns true if controller flushed ok
    static func flushOutput() -> Bool {
        var count = I8042_BUFFER_SIZE
        while count >= 0 && readStatus().outputFull {
            count -= 1
            readData()
        }
        return count >= 0
    }


    // Wait until the output buffer of the 8042 is empty
    static func waitForOutputEmpty() -> Bool {
        for _ in 1...POLL_LOOP_COUNT {
            if !readStatus().outputFull {
                return true
            }
        }
        return false
    }


    static func waitForOutput() -> Bool {
        for _ in 1...POLL_LOOP_COUNT {
            if readStatus().outputFull {
                return true
            }
        }
        return false
    }


    static func sendCommand(_ cmd: I8042Command) -> Bool {
        if waitForInputEmpty() {
            outb(COMMAND_REGISTER, cmd.rawValue)
            return true
        } else {
            print("i8042: Error sending command:", cmd)
            return false
        }
    }


    static func sendCommand(_ cmd: I8042Command, data: UInt8) -> Bool {
        if sendCommand(cmd) {
            writeData(data)
            return true
        } else {
            return false
        }
    }


    static func getResponse() -> UInt8? {
        if waitForOutput() {
            return readData()
        }

        return nil
    }


    static func sendCommandGetResponse(_ cmd: I8042Command) -> UInt8? {
        if sendCommand(cmd) {
            return getResponse()
        }
        print("i8042: Timed out getting response to comand:", cmd)

        return nil
    }


    static func sendData1stPort(_ data: UInt8) -> Bool {
        if waitForInputEmpty() {
            writeData(data)
            if waitForOutput() {
                let data = readData()
                if let resp = PS2KeyboardResponse(rawValue: data) {
                    if resp == .Ack {
                        return true
                    }
                    if resp == .Resend {
                        print("kbd: got resend")
                        return false
                    }
                }
                printf("kbd: Got unexpected response: %2.2x\n", data)
            }
        }

        return false
    }


    static func sendCommand1stPort(_ cmd: PS2KeyboardCommand) -> Bool {
        return sendData1stPort(cmd.rawValue)
    }


    static func sendCommand1stPort(_ cmd: PS2KeyboardCommand, data: UInt8) -> Bool {
        if sendCommand1stPort(cmd) {
            if sendData1stPort(data) {
                return true
            }
        }
        return false
    }


    static func sendCommand2ndPort(cmd: PS2KeyboardCommand) -> Bool{
        sendCommand(.Write2ndPortOutput)
        return sendCommand1stPort(cmd)
    }


    enum E0_ScanCodes: UInt8 {
    case Slash          = 0x4A
    case PrintScreen    = 0x36
    case RightAlt       = 0x6A
    case RightCtrl      = 0x14
    case Break          = 0x3E
    case Home           = 0x6C
    case Up             = 0x75
    case PageUp         = 0x7d
    case Left           = 0x6b
    case Right          = 0x74
    case End            = 0x69
    case Down           = 0x72
    case PageDown       = 0x7A
    case Insert         = 0x52
    case Delete         = 0x71
    case Pause          = 0x77
    }


    private static var prevScanCode: UInt16 = 0
    private static var breakCode: UInt8 = 0

    static func readKeyboard() {
        sendCommand(.Disable1stPort)
        while readStatus().outputFull {
            let scanCode = readData()
            kprint("kbd: scanCode:")
            kprint_byte(scanCode)
            kprint("\n")


            if scanCode == 0xf0 {
                breakCode = 0xff
                continue
            }

            if scanCode == 0xe0 || scanCode == 0xe1 {
                prevScanCode = UInt16(scanCode)
            } else {
                var keyCode = scanCode & 0x7f
                let upCode = breakCode | (scanCode & 0x80)
                breakCode = 0
                if prevScanCode == 0xe0 {
                    if keyCode != 0x2a && keyCode != 0x36 {
                        if let key = E0_ScanCodes(rawValue: keyCode) {
                            keyCode = key.rawValue
                        } else {
                            keyCode = 0
                        }
                    } else {
                        kprint("kbd: Ignoring E0 sequence (")
                        kprint_word(prevScanCode)
                        kprint(" ")
                        kprint_byte(keyCode)
                        kprint("\n")
                        keyCode = 0
                    }
                    prevScanCode = 0
                } else if prevScanCode == 0xe1 && keyCode == 0x1d {
                    keyCode = 0
                    prevScanCode = 0x100
                } else if prevScanCode == 0x100 && keyCode == 0x45 {
                    keyCode = E0_ScanCodes.Pause.rawValue
                    prevScanCode = 0
                }
                kprint("keyCode: ")
                kprint_byte(keyCode)
                kprint(upCode != 0 ? ", Up\n" : ", Down\n")
            }
        }
        sendCommand(.Enable1stPort)
    }
}


public func kbdInterrupt(irq: Int) {
    KBD8042.readKeyboard()
}


public func mouseInterrupt(irq: Int) {
    KBD8042.readKeyboard()
}
