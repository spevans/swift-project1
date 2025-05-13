/*
 * kernel/devices/ps2keyboard.swift
 *
 * Created by Simon Evans on 05/04/2017.
 * Copyright © 2017 Simon Evans. All rights reserved.
 *
 * PS/2 Keyboard driver. Converts scancodes to keyboard events.
 * Very basic implentation.
 *
 */


final class PS2Keyboard: HID {
    let description = "PS2Keyboard"
    private var prevScanCode: UInt16 = 0
    private var breakCode: UInt8 = 0

    enum E0_ScanCodes: UInt8 {
        case Slash          = 0x4A
        case PrintScreen    = 0x36
        case RightAlt       = 0x6A
        case LeftCtrl       = 0x20
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

    private let keyMap: [UInt8: HIDEvent.Key] = [
        1: .KEY_FN_9,
        3: .KEY_FN_5,
        4: .KEY_FN_3,
        5: .KEY_FN_1,
        6: .KEY_FN_2,
        7: .KEY_FN_12,
        9: .KEY_FN_10,
        10: .KEY_FN_8,
        11: .KEY_FN_6,
        131: .KEY_FN_7,
        12: .KEY_FN_4,
        120: .KEY_FN_11,
        13: .KEY_TAB,
        14: .KEY_TILDE,
        18: .KEY_LEFT_SHIFT,
        20: .KEY_LEFT_CTRL,
        21: .KEY_Q,
        22: .KEY_1,
        26: .KEY_Z,
        27: .KEY_S,
        28: .KEY_A,
        29: .KEY_W,
        30: .KEY_2,
        33: .KEY_C,
        34: .KEY_X,
        35: .KEY_D,
        36: .KEY_E,
        37: .KEY_4,
        38: .KEY_3,
        41: .KEY_SPACE,
        42: .KEY_V,
        43: .KEY_F,
        44: .KEY_T,
        45: .KEY_R,
        46: .KEY_5,
        49: .KEY_N,
        50: .KEY_B,
        51: .KEY_H,
        52: .KEY_G,
        53: .KEY_Y,
        54: .KEY_6,
        58: .KEY_M,
        59: .KEY_J,
        60: .KEY_U,
        61: .KEY_7,
        62: .KEY_8,
        65: .KEY_COMMA,
        66: .KEY_K,
        67: .KEY_I,
        68: .KEY_O,
        69: .KEY_0,
        70: .KEY_9,
        73: .KEY_PERIOD,
        74: .KEY_FORWARD_SLASH,
        75: .KEY_L,
        76: .KEY_SEMICOLON,
        77: .KEY_P,
        78: .KEY_MINUS,
        82: .KEY_SINGLE_QUOTE,
        84: .KEY_LEFT_SQUARE_BRACKET,
        85: .KEY_EQUALS,
        88: .KEY_CAPS_LOCK,
        89: .KEY_RIGHT_SHIFT,
        90: .KEY_RETURN,
        91: .KEY_RIGHT_SQUARE_BRACKET,
        93: .KEY_BACK_SLASH,
        102: .KEY_BACKSPACE,
        107: .KEY_LEFT_ARROW,
        114: .KEY_DOWN_ARROW,
        116: .KEY_RIGHT_ARROW,
        117: .KEY_UP_ARROW,
        118: .KEY_ESCAPE,
    ]


    private var inputBuffer: CircularBuffer<UInt8>

    init(buffer: CircularBuffer<UInt8>) {
        inputBuffer = buffer
        #kprint("kbd: initialised")
    }

    func initialise() -> Bool { true }


    override func readNextEvent() -> HIDEvent? {
        while let scanCode = inputBuffer.remove() {
            //#serialPrintf("kbd: scanCode: %#02x\n", scanCode)

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
                if keyCode != 0 {
                    if let input = keyboardInput(keyCode: keyCode,
                                                 keyDown: (upCode == 0)) {
                        return input
                    }
                }
            }
        }
        return nil
    }


    private func keyboardInput(keyCode: UInt8, keyDown: Bool)
    -> HIDEvent? {
        guard let key = keyMap[keyCode] else {
            #kprintf("ps2: Unknown keycode: %d\n", keyCode)
            return nil
        }
        return keyDown ? .keyDown(key) : .keyUp(key)
    }
}
