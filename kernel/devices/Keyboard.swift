//
//  Keyboard.swift
//  project1
//
//  Created by Simon Evans on 13/05/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//


// Generic Keyboard device that reads key events from a HID
final class Keyboard {
    // Keyboard state
    private var leftShift = false
    private var rightShift = false
    private var leftCtrl = false
    private var rightCtrl = false
    private let hid: HID

    init(hid: HID) {
        self.hid = hid
    }

    func initialise() -> Bool {
        return true
    }

    func readHidEvent() -> HIDEvent? {
        return hid.readNextEvent()
    }


    func readKeyboard() -> UnicodeScalar? {
        guard let event = hid.readNextEvent() else {
            return nil
        }

        //#kprint("Got keyboard event")
        switch event {
            case .keyDown(let key):
                switch key {
                    case .KEY_LEFT_CTRL: leftCtrl = true
                    case .KEY_LEFT_SHIFT: leftShift = true
                    case .KEY_RIGHT_SHIFT: rightShift = true
                    case .KEY_LEFT_ARROW: return UnicodeScalar(2)   // CTRL-B readline move back
                    case .KEY_RIGHT_ARROW: return UnicodeScalar(6)  // CTRL-F readline move forward
                    case .KEY_UP_ARROW: return UnicodeScalar(16)    // CTRL-P readline previous line
                    case .KEY_DOWN_ARROW: return UnicodeScalar(14)  // CTRL-N readline next line
                    default:
                        if leftCtrl {
                            return ctrlMap[key]
                        }
                        if leftShift || rightShift {
                            return shiftedMap[key]
                        } else {
                            return unshiftedMap[key]
                        }
                }
            case .keyUp(let key):
                switch key {
                    case .KEY_LEFT_CTRL: leftCtrl = false
                    case .KEY_LEFT_SHIFT: leftShift = false
                    case .KEY_RIGHT_SHIFT: rightShift = false
                    default:
                        return nil
                }
            default:
                // Ignore non-keyboard events
                break
        }
        return nil
    }

    // FIXME: Need to be arrays
    private let unshiftedMap: [HIDEvent.Key: UnicodeScalar] = [
        .KEY_A: UnicodeScalar("a"),
        .KEY_B: UnicodeScalar("b"),
        .KEY_C: UnicodeScalar("c"),
        .KEY_D: UnicodeScalar("d"),
        .KEY_E: UnicodeScalar("e"),
        .KEY_F: UnicodeScalar("f"),
        .KEY_G: UnicodeScalar("g"),
        .KEY_H: UnicodeScalar("h"),
        .KEY_I: UnicodeScalar("i"),
        .KEY_J: UnicodeScalar("j"),
        .KEY_K: UnicodeScalar("k"),
        .KEY_L: UnicodeScalar("l"),
        .KEY_M: UnicodeScalar("m"),
        .KEY_N: UnicodeScalar("n"),
        .KEY_O: UnicodeScalar("o"),
        .KEY_P: UnicodeScalar("p"),
        .KEY_Q: UnicodeScalar("q"),
        .KEY_R: UnicodeScalar("r"),
        .KEY_S: UnicodeScalar("s"),
        .KEY_T: UnicodeScalar("t"),
        .KEY_U: UnicodeScalar("u"),
        .KEY_V: UnicodeScalar("v"),
        .KEY_W: UnicodeScalar("w"),
        .KEY_X: UnicodeScalar("x"),
        .KEY_Y: UnicodeScalar("y"),
        .KEY_Z: UnicodeScalar("z"),
        .KEY_0: UnicodeScalar("0"),
        .KEY_1: UnicodeScalar("1"),
        .KEY_2: UnicodeScalar("2"),
        .KEY_3: UnicodeScalar("3"),
        .KEY_4: UnicodeScalar("4"),
        .KEY_5: UnicodeScalar("5"),
        .KEY_6: UnicodeScalar("6"),
        .KEY_7: UnicodeScalar("7"),
        .KEY_8: UnicodeScalar("8"),
        .KEY_9: UnicodeScalar("9"),
        .KEY_BACK_SLASH: UnicodeScalar("\\"),
        .KEY_BACKSPACE: UnicodeScalar(8),
        .KEY_COMMA: UnicodeScalar(","),
        .KEY_EQUALS: UnicodeScalar("="),
        .KEY_ESCAPE: UnicodeScalar(27),
        .KEY_FORWARD_SLASH: UnicodeScalar("/"),
        .KEY_LEFT_ARROW: UnicodeScalar(2), // left arrow = ctrl-b
        .KEY_LEFT_SQUARE_BRACKET: UnicodeScalar("["),
        .KEY_MINUS: UnicodeScalar("-"),
        .KEY_PERIOD: UnicodeScalar("."),
        .KEY_RETURN: UnicodeScalar("\r"),
        .KEY_RIGHT_ARROW: UnicodeScalar(6), // right arrow = ctrl-f
        .KEY_RIGHT_SQUARE_BRACKET: UnicodeScalar("]"),
        .KEY_SEMICOLON: UnicodeScalar(";"),
        .KEY_SINGLE_QUOTE: UnicodeScalar("'"),
        .KEY_SPACE: UnicodeScalar(" "),
        .KEY_TAB: UnicodeScalar("\t"),
        .KEY_TILDE: UnicodeScalar("`"),
    ]


    private let shiftedMap: [HIDEvent.Key: UnicodeScalar] = [
        .KEY_A: UnicodeScalar("A"),
        .KEY_B: UnicodeScalar("B"),
        .KEY_C: UnicodeScalar("C"),
        .KEY_D: UnicodeScalar("D"),
        .KEY_E: UnicodeScalar("E"),
        .KEY_F: UnicodeScalar("F"),
        .KEY_G: UnicodeScalar("G"),
        .KEY_H: UnicodeScalar("H"),
        .KEY_I: UnicodeScalar("I"),
        .KEY_J: UnicodeScalar("J"),
        .KEY_K: UnicodeScalar("K"),
        .KEY_L: UnicodeScalar("L"),
        .KEY_M: UnicodeScalar("M"),
        .KEY_N: UnicodeScalar("N"),
        .KEY_O: UnicodeScalar("O"),
        .KEY_P: UnicodeScalar("P"),
        .KEY_Q: UnicodeScalar("Q"),
        .KEY_R: UnicodeScalar("R"),
        .KEY_S: UnicodeScalar("S"),
        .KEY_T: UnicodeScalar("T"),
        .KEY_U: UnicodeScalar("U"),
        .KEY_V: UnicodeScalar("V"),
        .KEY_W: UnicodeScalar("W"),
        .KEY_X: UnicodeScalar("X"),
        .KEY_Y: UnicodeScalar("Y"),
        .KEY_Z: UnicodeScalar("Z"),
        .KEY_0: UnicodeScalar(")"),
        .KEY_1: UnicodeScalar("!"),
        .KEY_2: UnicodeScalar("@"),
        .KEY_3: UnicodeScalar("#"),
        .KEY_4: UnicodeScalar("$"),
        .KEY_5: UnicodeScalar("%"),
        .KEY_6: UnicodeScalar("^"),
        .KEY_7: UnicodeScalar("&"),
        .KEY_8: UnicodeScalar("*"),
        .KEY_9: UnicodeScalar("("),
        .KEY_BACK_SLASH: UnicodeScalar("|"),
        .KEY_BACKSPACE: UnicodeScalar(8),
        .KEY_COMMA: UnicodeScalar("<"),
        .KEY_EQUALS: UnicodeScalar("+"),
        .KEY_ESCAPE: UnicodeScalar(27),
        .KEY_FORWARD_SLASH: UnicodeScalar("?"),
        .KEY_LEFT_ARROW: UnicodeScalar(2), // left arrow = ctrl-b
        .KEY_LEFT_SQUARE_BRACKET: UnicodeScalar("{"),
        .KEY_MINUS: UnicodeScalar("_"),
        .KEY_PERIOD: UnicodeScalar(">"),
        .KEY_RETURN: UnicodeScalar("\r"),
        .KEY_RIGHT_ARROW: UnicodeScalar(6), // right arrow = ctrl-f
        .KEY_RIGHT_SQUARE_BRACKET: UnicodeScalar("}"),
        .KEY_SEMICOLON: UnicodeScalar(":"),
        .KEY_SINGLE_QUOTE: UnicodeScalar("\""),
        .KEY_SPACE: UnicodeScalar(" "),
        .KEY_TAB: UnicodeScalar("\t"),
        .KEY_TILDE: UnicodeScalar("~"),
    ]


    private let ctrlMap: [HIDEvent.Key: UnicodeScalar] = [
        .KEY_A: UnicodeScalar(1),
        .KEY_B: UnicodeScalar(2),
        .KEY_C: UnicodeScalar(3),
        .KEY_D: UnicodeScalar(4),
        .KEY_E: UnicodeScalar(5),
        .KEY_F: UnicodeScalar(6),
        .KEY_G: UnicodeScalar(7),
        .KEY_H: UnicodeScalar(8),
        .KEY_I: UnicodeScalar(9),
        .KEY_J: UnicodeScalar(10),
        .KEY_K: UnicodeScalar(11),
        .KEY_L: UnicodeScalar(12),
        .KEY_M: UnicodeScalar(13),
        .KEY_N: UnicodeScalar(14),
        .KEY_O: UnicodeScalar(15),
        .KEY_P: UnicodeScalar(16),
        .KEY_Q: UnicodeScalar(17),
        .KEY_R: UnicodeScalar(18),
        .KEY_S: UnicodeScalar(19),
        .KEY_T: UnicodeScalar(20),
        .KEY_U: UnicodeScalar(21),
        .KEY_V: UnicodeScalar(22),
        .KEY_W: UnicodeScalar(23),
        .KEY_X: UnicodeScalar(24),
        .KEY_Y: UnicodeScalar(25),
        .KEY_Z: UnicodeScalar(26),
    ]
}
