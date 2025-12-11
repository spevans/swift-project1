//
//  HID.swift
//  project1
//
//  Created by Simon Evans on 13/05/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//

enum HIDEvent {

    enum Key: CustomStringConvertible {
        case KEY_LEFT_CTRL
        case KEY_LEFT_SHIFT
        case KEY_LEFT_ALT
        case KEY_LEFT_GUI
        case KEY_RIGHT_CTRL
        case KEY_RIGHT_SHIFT
        case KEY_RIGHT_ALT
        case KEY_RIGHT_GUI
        case KEY_A
        case KEY_B
        case KEY_C
        case KEY_D
        case KEY_E
        case KEY_F
        case KEY_G
        case KEY_H
        case KEY_I
        case KEY_J
        case KEY_K
        case KEY_L
        case KEY_M
        case KEY_N
        case KEY_O
        case KEY_P
        case KEY_Q
        case KEY_R
        case KEY_S
        case KEY_T
        case KEY_U
        case KEY_V
        case KEY_W
        case KEY_X
        case KEY_Y
        case KEY_Z
        case KEY_0
        case KEY_1
        case KEY_2
        case KEY_3
        case KEY_4
        case KEY_5
        case KEY_6
        case KEY_7
        case KEY_8
        case KEY_9

        case KEY_BACK_SLASH
        case KEY_BACKSPACE
        case KEY_COMMA
        case KEY_EQUALS
        case KEY_ESCAPE
        case KEY_FORWARD_SLASH
        case KEY_LEFT_ARROW
        case KEY_MINUS
        case KEY_PERIOD
        case KEY_RETURN
        case KEY_RIGHT_ARROW
        case KEY_SEMICOLON
        case KEY_SINGLE_QUOTE
        case KEY_SPACE
        case KEY_TAB
        case KEY_TILDE
        case KEY_LEFT_SQUARE_BRACKET
        case KEY_RIGHT_SQUARE_BRACKET
        case KEY_UP_ARROW
        case KEY_DOWN_ARROW
        case KEY_CAPS_LOCK
        case KEY_NUM_LOCK
        case KEY_KEYPAD_0
        case KEY_KEYPAD_1
        case KEY_KEYPAD_2
        case KEY_KEYPAD_3
        case KEY_KEYPAD_4
        case KEY_KEYPAD_5
        case KEY_KEYPAD_6
        case KEY_KEYPAD_7
        case KEY_KEYPAD_8
        case KEY_KEYPAD_9
        case KEY_KEYPAD_EQUALS
        case KEY_KEYPAD_DIVIDE
        case KEY_KEYPAD_ASTERISK
        case KEY_KEYPAD_MINUS
        case KEY_KEYPAD_PLUS
        case KEY_KEYPAD_ENTER
        case KEY_KEYPAD_PERIOD
        case KEY_PAUSE
        case KEY_INSERT
        case KEY_DELETE
        case KEY_HOME
        case KEY_END
        case KEY_PAGE_UP
        case KEY_PAGE_DOWN
        case KEY_FN_1
        case KEY_FN_2
        case KEY_FN_3
        case KEY_FN_4
        case KEY_FN_5
        case KEY_FN_6
        case KEY_FN_7
        case KEY_FN_8
        case KEY_FN_9
        case KEY_FN_10
        case KEY_FN_11
        case KEY_FN_12
        case KEY_FN_13
        case KEY_FN_14
        case KEY_FN_15
        case KEY_FN_16
        case KEY_FN_17
        case KEY_FN_18
        case KEY_FN_19
        case KEY_FN_20
        case KEY_FN_21
        case KEY_FN_22
        case KEY_FN_23
        case KEY_FN_24
        case INVALID

        var description: String {
            return switch self {
                case .KEY_LEFT_CTRL: "KEY_LEFT_CTRL"
                case .KEY_LEFT_SHIFT: "KEY_LEFT_SHIFT"
                case .KEY_LEFT_ALT: "KEY_LEFT_ALT"
                case .KEY_LEFT_GUI: "KEY_LEFT_GUI"
                case .KEY_RIGHT_CTRL: "KEY_RIGHT_CTRL"
                case .KEY_RIGHT_SHIFT: "KEY_RIGHT_SHIFT"
                case .KEY_RIGHT_ALT: "KEY_RIGHT_ALT"
                case .KEY_RIGHT_GUI: "KEY_RIGHT_GUI"
                case .KEY_A: "KEY_A"
                case .KEY_B: "KEY_B"
                case .KEY_C: "KEY_C"
                case .KEY_D: "KEY_D"
                case .KEY_E: "KEY_E"
                case .KEY_F: "KEY_F"
                case .KEY_G: "KEY_G"
                case .KEY_H: "KEY_H"
                case .KEY_I: "KEY_I"
                case .KEY_J: "KEY_J"
                case .KEY_K: "KEY_K"
                case .KEY_L: "KEY_L"
                case .KEY_M: "KEY_M"
                case .KEY_N: "KEY_N"
                case .KEY_O: "KEY_O"
                case .KEY_P: "KEY_P"
                case .KEY_Q: "KEY_Q"
                case .KEY_R: "KEY_R"
                case .KEY_S: "KEY_S"
                case .KEY_T: "KEY_T"
                case .KEY_U: "KEY_U"
                case .KEY_V: "KEY_V"
                case .KEY_W: "KEY_W"
                case .KEY_X: "KEY_X"
                case .KEY_Y: "KEY_Y"
                case .KEY_Z: "KEY_Z"
                case .KEY_0: "KEY_0"
                case .KEY_1: "KEY_1"
                case .KEY_2: "KEY_2"
                case .KEY_3: "KEY_3"
                case .KEY_4: "KEY_4"
                case .KEY_5: "KEY_5"
                case .KEY_6: "KEY_6"
                case .KEY_7: "KEY_7"
                case .KEY_8: "KEY_8"
                case .KEY_9: "KEY_9"
                case .KEY_BACK_SLASH: "KEY_BACK_SLASH"
                case .KEY_BACKSPACE: "KEY_BACKSPACE"
                case .KEY_COMMA: "KEY_COMMA"
                case .KEY_EQUALS: "KEY_EQUALS"
                case .KEY_ESCAPE: "KEY_ESCAPE"
                case .KEY_FORWARD_SLASH: "KEY_FORWARD_SLASH"
                case .KEY_LEFT_ARROW: "KEY_LEFT_ARROW"
                case .KEY_MINUS: "KEY_MINUS"
                case .KEY_PERIOD: "KEY_PERIOD"
                case .KEY_RETURN: "KEY_RETURN"
                case .KEY_RIGHT_ARROW: "KEY_RIGHT_ARROW"
                case .KEY_SEMICOLON: "KEY_SEMICOLON"
                case .KEY_SINGLE_QUOTE: "KEY_SINGLE_QUOTE"
                case .KEY_SPACE: "KEY_SPACE"
                case .KEY_TAB: "KEY_TAB"
                case .KEY_TILDE: "KEY_TILDE"
                case .KEY_LEFT_SQUARE_BRACKET: "KEY_LEFT_SQUARE_BRACKET"
                case .KEY_RIGHT_SQUARE_BRACKET: "KEY_RIGHT_SQUARE_BRACKET"
                case .KEY_UP_ARROW: "KEY_UP_ARROW"
                case .KEY_DOWN_ARROW: "KEY_DOWN_ARROW"
                case .KEY_CAPS_LOCK: "KEY_CAPS_LOCK"
                case .KEY_NUM_LOCK: "KEY_NUM_LOCK"
                case .KEY_KEYPAD_0: "KEY_KEYPAD_0"
                case .KEY_KEYPAD_1: "KEY_KEYPAD_1"
                case .KEY_KEYPAD_2: "KEY_KEYPAD_2"
                case .KEY_KEYPAD_3: "KEY_KEYPAD_3"
                case .KEY_KEYPAD_4: "KEY_KEYPAD_4"
                case .KEY_KEYPAD_5: "KEY_KEYPAD_5"
                case .KEY_KEYPAD_6: "KEY_KEYPAD_6"
                case .KEY_KEYPAD_7: "KEY_KEYPAD_7"
                case .KEY_KEYPAD_8: "KEY_KEYPAD_8"
                case .KEY_KEYPAD_9: "KEY_KEYPAD_9"
                case .KEY_KEYPAD_EQUALS: "KEY_KEYPAD_EQUALS"
                case .KEY_KEYPAD_DIVIDE: "KEY_KEYPAD_DIVIDE"
                case .KEY_KEYPAD_ASTERISK: "KEY_KEYPAD_ASTERISK"
                case .KEY_KEYPAD_MINUS: "KEY_KEYPAD_MINUS"
                case .KEY_KEYPAD_PLUS: "KEY_KEYPAD_PLUS"
                case .KEY_KEYPAD_ENTER: "KEY_KEYPAD_ENTER"
                case .KEY_KEYPAD_PERIOD: "KEY_KEYPAD_PERIOD"
                case .KEY_PAUSE: "KEY_PAUSE"
                case .KEY_INSERT: "KEY_INSERT"
                case .KEY_DELETE: "KEY_DELETE"
                case .KEY_HOME: "KEY_HOME"
                case .KEY_END: "KEY_END"
                case .KEY_PAGE_UP: "KEY_PAGE_UP"
                case .KEY_PAGE_DOWN: "KEY_PAGE_DOWN"
                case .KEY_FN_1: "KEY_FN_1"
                case .KEY_FN_2: "KEY_FN_2"
                case .KEY_FN_3: "KEY_FN_3"
                case .KEY_FN_4: "KEY_FN_4"
                case .KEY_FN_5: "KEY_FN_5"
                case .KEY_FN_6: "KEY_FN_6"
                case .KEY_FN_7: "KEY_FN_7"
                case .KEY_FN_8: "KEY_FN_8"
                case .KEY_FN_9: "KEY_FN_9"
                case .KEY_FN_10: "KEY_FN_10"
                case .KEY_FN_11: "KEY_FN_11"
                case .KEY_FN_12: "KEY_FN_12"
                case .KEY_FN_13: "KEY_FN_13"
                case .KEY_FN_14: "KEY_FN_14"
                case .KEY_FN_15: "KEY_FN_15"
                case .KEY_FN_16: "KEY_FN_16"
                case .KEY_FN_17: "KEY_FN_17"
                case .KEY_FN_18: "KEY_FN_18"
                case .KEY_FN_19: "KEY_FN_19"
                case .KEY_FN_20: "KEY_FN_20"
                case .KEY_FN_21: "KEY_FN_21"
                case .KEY_FN_22: "KEY_FN_22"
                case .KEY_FN_23: "KEY_FN_23"
                case .KEY_FN_24: "KEY_FN_24"
                case .INVALID: "INVALID"

            }
        }
    }

    enum Button: CustomStringConvertible {
        case BUTTON_1
        case BUTTON_2
        case BUTTON_3

        var description: String {
            return switch self {
                case .BUTTON_1: "BUTTON_1"
                case .BUTTON_3: "BUTTON_3"
                case .BUTTON_2: "BUTTON_2"
            }
        }
    }

    case keyDown(Key)
    case keyUp(Key)
    case buttonDown(Button)
    case buttonUp(Button)
    case xAxisMovement(Int16)
    case yAxisMovement(Int16)
}

class HID {

    func readNextEvent() -> HIDEvent? {
        return nil
    }

    func flushInput() {
    }
}
