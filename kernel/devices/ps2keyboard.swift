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



final class PS2Keyboard: Device, PS2Device, Keyboard {

    private var prevScanCode: UInt16 = 0
    private var breakCode: UInt8 = 0

    // Keyboard state
    private var leftShift = false
    private var rightShift = false
    private var leftCtrl = false
    private var rightCtrl = false


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


    // FIXME: Need to be arrays
    private let unshiftedMap: [UInt8: UnicodeScalar] = [
        13: UnicodeScalar("\t"),
        14: UnicodeScalar("`"),
        21: UnicodeScalar("q"),
        22: UnicodeScalar("1"),
        26: UnicodeScalar("z"),
        27: UnicodeScalar("s"),
        28: UnicodeScalar("a"),
        29: UnicodeScalar("w"),
        30: UnicodeScalar("2"),
        33: UnicodeScalar("c"),
        34: UnicodeScalar("x"),
        35: UnicodeScalar("d"),
        36: UnicodeScalar("e"),
        37: UnicodeScalar("4"),
        38: UnicodeScalar("3"),
        41: UnicodeScalar(" "),
        42: UnicodeScalar("v"),
        43: UnicodeScalar("f"),
        44: UnicodeScalar("t"),
        45: UnicodeScalar("r"),
        46: UnicodeScalar("5"),
        49: UnicodeScalar("n"),
        50: UnicodeScalar("b"),
        51: UnicodeScalar("h"),
        52: UnicodeScalar("g"),
        53: UnicodeScalar("y"),
        54: UnicodeScalar("6"),
        58: UnicodeScalar("m"),
        59: UnicodeScalar("j"),
        60: UnicodeScalar("u"),
        61: UnicodeScalar("7"),
        62: UnicodeScalar("8"),
        65: UnicodeScalar(","),
        66: UnicodeScalar("k"),
        67: UnicodeScalar("i"),
        68: UnicodeScalar("o"),
        69: UnicodeScalar("0"),
        70: UnicodeScalar("9"),
        73: UnicodeScalar("."),
        74: UnicodeScalar("/"),
        75: UnicodeScalar("l"),
        76: UnicodeScalar(";"),
        77: UnicodeScalar("p"),
        78: UnicodeScalar("-"),
        82: UnicodeScalar("'"),
        85: UnicodeScalar("="),
        90: UnicodeScalar("\r"),
        93: UnicodeScalar("\\"),
        102: UnicodeScalar(8),
        118: UnicodeScalar(27),

        0x6b: UnicodeScalar(2), // left arrow = ctrl-b
        0x74: UnicodeScalar(6), // right arrow = ctrl-f
    ]


    private let shiftedMap: [UInt8: UnicodeScalar] = [
        13: UnicodeScalar("\t"),
        14: UnicodeScalar("~"),
        21: UnicodeScalar("Q"),
        22: UnicodeScalar("!"),
        26: UnicodeScalar("Z"),
        27: UnicodeScalar("S"),
        28: UnicodeScalar("A"),
        29: UnicodeScalar("W"),
        30: UnicodeScalar("@"),
        33: UnicodeScalar("C"),
        34: UnicodeScalar("X"),
        35: UnicodeScalar("D"),
        36: UnicodeScalar("E"),
        37: UnicodeScalar("$"),
        38: UnicodeScalar("#"),
        41: UnicodeScalar(" "),
        42: UnicodeScalar("V"),
        43: UnicodeScalar("F"),
        44: UnicodeScalar("T"),
        45: UnicodeScalar("R"),
        46: UnicodeScalar("%"),
        49: UnicodeScalar("N"),
        50: UnicodeScalar("B"),
        51: UnicodeScalar("H"),
        52: UnicodeScalar("G"),
        53: UnicodeScalar("Y"),
        54: UnicodeScalar("^"),
        58: UnicodeScalar("M"),
        59: UnicodeScalar("J"),
        60: UnicodeScalar("U"),
        61: UnicodeScalar("&"),
        62: UnicodeScalar("*"),
        65: UnicodeScalar("<"),
        66: UnicodeScalar("K"),
        67: UnicodeScalar("I"),
        68: UnicodeScalar("O"),
        69: UnicodeScalar(")"),
        70: UnicodeScalar("("),
        73: UnicodeScalar(">"),
        74: UnicodeScalar("?"),
        75: UnicodeScalar("L"),
        76: UnicodeScalar(":"),
        77: UnicodeScalar("P"),
        78: UnicodeScalar("_"),
        82: UnicodeScalar("\""),
        85: UnicodeScalar("+"),
        90: UnicodeScalar("\r"),
        93: UnicodeScalar("|"),
        102: UnicodeScalar(8),
        118: UnicodeScalar(27)
    ]


    private let ctrlMap: [UInt8: UnicodeScalar] = [
        21: UnicodeScalar(17),
        26: UnicodeScalar(26),
        27: UnicodeScalar(19),
        28: UnicodeScalar(1),
        29: UnicodeScalar(23),
        33: UnicodeScalar(3),
        34: UnicodeScalar(24),
        35: UnicodeScalar(4),
        36: UnicodeScalar(5),
        42: UnicodeScalar(22),
        43: UnicodeScalar(6),
        44: UnicodeScalar(20),
        45: UnicodeScalar(18),
        49: UnicodeScalar(14),
        50: UnicodeScalar(2),
        51: UnicodeScalar(8),
        52: UnicodeScalar(7),
        53: UnicodeScalar(25),
        58: UnicodeScalar(13),
        59: UnicodeScalar(10),
        60: UnicodeScalar(21),
        66: UnicodeScalar(11),
        67: UnicodeScalar(9),
        68: UnicodeScalar(15),
        75: UnicodeScalar(12),
        77: UnicodeScalar(16),
        102: UnicodeScalar(8),
        118: UnicodeScalar(27),
    ]


    private var inputBuffer: CircularBuffer<UInt8>

    init(buffer: CircularBuffer<UInt8>) {
        inputBuffer = buffer
        print("kbd: initialised")
    }


    public func readKeyboard() -> UnicodeScalar? {
        while let scanCode = inputBuffer.remove() {
            serialPrintf("kbd: scanCode: %#02x\n", scanCode)

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
        -> UnicodeScalar? {
        if keyDown {
            switch keyCode {
            case 0x12: leftShift = true
            case 0x59: rightShift = true
            case 0x14: leftCtrl = true
            default:
                guard let char = readKeymap(scanCode: keyCode) else {
                    print("kbd: Unknown keycode down: \(keyCode)")
                    return nil
                }
                return char
            }
        } else {
            switch keyCode {
            case 0x12: leftShift = false
            case 0x59: rightShift = false
            case 0x14: leftCtrl = false
            default:
                return nil
            }
        }
        return nil
    }


    private func readKeymap(scanCode: UInt8) -> UnicodeScalar? {
        if leftCtrl {
            return ctrlMap[scanCode]
        }
        if leftShift || rightShift {
            return shiftedMap[scanCode]
        } else {
            return unshiftedMap[scanCode]
        }
    }
}
