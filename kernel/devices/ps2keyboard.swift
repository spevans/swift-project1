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
    private var makeKey = true

    private let E0_ScanCodes: [UInt8: HIDEvent.Key] = [
        0x11: .KEY_RIGHT_ALT,
        0x14: .KEY_RIGHT_CTRL,
        0x1F: .KEY_LEFT_GUI,
        0x27: .KEY_RIGHT_GUI,
        0x4A: .KEY_KEYPAD_DIVIDE,
        0x5A: .KEY_KEYPAD_ENTER,
        0x6B: .KEY_LEFT_ARROW,
        0x6C: .KEY_HOME,
        0x69: .KEY_END,
        0x71: .KEY_DELETE,
        0x72: .KEY_DOWN_ARROW,
        0x74: .KEY_RIGHT_ARROW,
        0x75: .KEY_UP_ARROW,
        0x7A: .KEY_PAGE_DOWN,
        0x7D: .KEY_PAGE_UP,
    ]

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
        12: .KEY_FN_4,
        13: .KEY_TAB,
        14: .KEY_TILDE,
        15: .KEY_KEYPAD_EQUALS,
        17: .KEY_LEFT_ALT,
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
        105: .KEY_KEYPAD_1,
        107: .KEY_KEYPAD_4,
        108: .KEY_KEYPAD_7,
        112: .KEY_KEYPAD_0,
        113: .KEY_KEYPAD_PERIOD,
        114: .KEY_KEYPAD_2,
        115: .KEY_KEYPAD_5,
        116: .KEY_KEYPAD_6,
        117: .KEY_KEYPAD_8,
        118: .KEY_ESCAPE,
        119: .KEY_FN_15,
        120: .KEY_FN_11,
        121: .KEY_KEYPAD_PLUS,
        122: .KEY_KEYPAD_3,
        123: .KEY_KEYPAD_MINUS,
        124: .KEY_KEYPAD_ASTERISK,
        125: .KEY_KEYPAD_9,
        126: .KEY_FN_14,
        131: .KEY_FN_7
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
                makeKey = false
                continue
            }

            if scanCode == 0xe0 || scanCode == 0xe1 {
                prevScanCode = UInt16(scanCode)
            } else {
                let keyDown = makeKey
                makeKey = true
                if prevScanCode == 0xe0 {
                    prevScanCode = 0
                    if let key = E0_ScanCodes[scanCode] {
                        return keyDown ? .keyDown(key) : .keyUp(key)
                    } else {
                        #kprintf("ps2: Unknown E0 code: %#02x\n", scanCode)
                        continue
                    }
                // Special Handling for 0xE1, 0x14, 0x77
                } else if prevScanCode == 0xe1 && scanCode == 0x14 {
                    prevScanCode = 0x100
                    continue
                } else if prevScanCode == 0x100 && scanCode == 0x77 {
                    prevScanCode = 0
                    return keyDown ? .keyDown(.KEY_PAUSE) : .keyUp(.KEY_PAUSE)
                }
                if let input = keyboardInput(keyCode: scanCode,
                                             keyDown: keyDown) {
                    return input
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
