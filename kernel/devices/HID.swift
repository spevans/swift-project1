//
//  HID.swift
//  project1
//
//  Created by Simon Evans on 13/05/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//

enum HIDEvent {

    enum Key {
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
        case INVALID
    }

    enum Button {
        case BUTTON_1
        case BUTTON_2
        case BUTTON_3
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
