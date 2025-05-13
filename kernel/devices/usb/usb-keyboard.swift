//
//  usb-keyboard.swift
//  project1
//
//  Created by Simon Evans on 12/05/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//

fileprivate struct ModifierKeys: CustomStringConvertible {
    let modifierKeys: BitArray8

    init(_ modifierKeys: UInt8) {
        self.modifierKeys = BitArray8(modifierKeys)
    }

    func events(fromPrev prev: ModifierKeys, into result: inout [HIDEvent]) {
        if leftControl != prev.leftControl {
            result.append(leftControl ? .keyDown(.KEY_LEFT_CTRL) : .keyUp(.KEY_LEFT_CTRL))
        }
        if leftShift != prev.leftShift {
            result.append(leftShift ? .keyDown(.KEY_LEFT_SHIFT) : .keyUp(.KEY_LEFT_SHIFT))
        }
        if leftAlt != prev.leftAlt {
            result.append(leftAlt ? .keyDown(.KEY_LEFT_ALT) : .keyUp(.KEY_LEFT_ALT))
        }
        if leftGUI != prev.leftGUI {
            result.append(leftGUI ? .keyDown(.KEY_LEFT_GUI) : .keyUp(.KEY_LEFT_GUI))
        }
        if rightControl != prev.rightControl {
            result.append(rightControl ? .keyDown(.KEY_RIGHT_CTRL) : .keyUp(.KEY_RIGHT_CTRL))
        }
        if rightShift != prev.rightShift {
            result.append(rightShift ? .keyDown(.KEY_RIGHT_SHIFT) : .keyUp(.KEY_RIGHT_SHIFT))
        }
        if rightAlt != prev.rightAlt {
            result.append(rightAlt ? .keyDown(.KEY_RIGHT_ALT) : .keyUp(.KEY_RIGHT_ALT))
        }
        if rightGUI != prev.rightGUI {
            result.append(rightGUI ? .keyDown(.KEY_RIGHT_GUI) : .keyUp(.KEY_RIGHT_GUI))
        }
    }

    var leftControl: Bool { modifierKeys[0] == 1 }
    var leftShift: Bool { modifierKeys[1] == 1 }
    var leftAlt: Bool { modifierKeys[2] == 1 }
    var leftGUI: Bool { modifierKeys[3] == 1 }
    var rightControl: Bool { modifierKeys[4] == 1 }
    var rightShift: Bool { modifierKeys[5] == 1 }
    var rightAlt: Bool { modifierKeys[6] == 1 }
    var rightGUI: Bool { modifierKeys[7] == 1 }

    var description: String {
        var result = ""
        if leftControl { result.append(" LCtrl") }
        if leftShift { result.append(" LShift") }
        if leftAlt { result.append(" LAlt") }
        if leftGUI { result.append(" LGUI") }
        if rightControl { result.append(" LCtrl") }
        if rightShift { result.append(" LShift") }
        if rightAlt { result.append(" LAlt") }
        if rightGUI { result.append(" LGUI") }
        return result
    }
}

final class USBKeyboard: HID {
    let description = "USBKeyboard"
    private var prevModifierKeys = ModifierKeys(0)
    private var oldkeys: [UInt8] = []
    private var buffer: [HIDEvent] = []
    private var keys: [UInt8] = []

    private let device: USBDevice
    private let interface: USB.InterfaceDescriptor
    private var intrPipe: USBPipe


    init(device: USBDevice, interface: USB.InterfaceDescriptor, intrPipe: USBPipe) {
        #kprint("USB-HID: Creating USBKeyboard")
        self.device = device
        self.interface = interface
        self.intrPipe = intrPipe
    }

    func initialise() -> Bool {
        return true
    }


    private var counter: UInt64 = 0
    override func readNextEvent() -> HIDEvent? {
        // Now poll the interrupt to look for keypresses

//        #kprint("usb-keyboard readNextEvent, buffer.count:", buffer.count)
        if buffer.isEmpty {
            sleep(milliseconds: 10)
            keys.removeAll(keepingCapacity: true)
            guard intrPipe.pollInterruptPipe(into: &keys) else {
                counter += 1
                if counter % 1000 == 0 {
//                    device.hub.dumpState()
//                    sti()
                }
//                #kprint("interupt pipe returned no data")
                return nil
            }

//            #kprint("Interrupt pipe returned data")
            guard let mkeys = keys.first else {
                #kprint("No modifier data")
                return nil
            }
            keys.removeFirst(2)
            let modifierKeys = ModifierKeys(mkeys)
            modifierKeys.events(fromPrev: prevModifierKeys, into: &buffer)

            let (keysDown, keysUp) = removeDuplicates(array1: keys, array2: oldkeys)

            for keyCode in keysDown {
                if let key = keyMap[keyCode] {
                    buffer.append(.keyDown(key))
                } else {
                    #kprintf("usb: Unknown keycode: %2.2x\n", keyCode)
                }
            }
            for keyCode in keysUp {
                if let key = keyMap[keyCode] {
                    buffer.append(.keyUp(key))
                } else {
                    #kprintf("usb: Unknown keycode: %2.2x\n", keyCode)
                }
            }
            prevModifierKeys = modifierKeys
            oldkeys = keys
        }
        if buffer.count > 0 {
            //kprint("usb-keyboard, returning data")
            return buffer.removeFirst()
        }
        return nil
    }

    // Remove element from the 2 input arrays that appear in both arrays
    private func removeDuplicates(array1: [UInt8], array2: [UInt8]) -> ([UInt8], [UInt8]) {
        var newArray1: [UInt8] = []
        var newArray2: [UInt8] = []

        for entry in array1 {
            if entry > 1, !array2.contains(entry), !newArray1.contains(entry) {
                newArray1.append(entry)
            }
        }

        for entry in array2 {
            if entry > 1, !array1.contains(entry), !newArray2.contains(entry) {
                newArray2.append(entry)
            }
        }
        return (newArray1, newArray2)
    }

    private let keyMap: [UInt8: HIDEvent.Key] = [
        0x04: .KEY_A,
        0x05: .KEY_B,
        0x06: .KEY_C,
        0x07: .KEY_D,
        0x08: .KEY_E,
        0x09: .KEY_F,
        0x0a: .KEY_G,
        0x0b: .KEY_H,
        0x0c: .KEY_I,
        0x0d: .KEY_J,
        0x0e: .KEY_K,
        0x0f: .KEY_L,
        0x10: .KEY_M,
        0x11: .KEY_N,
        0x12: .KEY_O,
        0x13: .KEY_P,
        0x14: .KEY_Q,
        0x15: .KEY_R,
        0x16: .KEY_S,
        0x17: .KEY_T,
        0x18: .KEY_U,
        0x19: .KEY_V,
        0x1a: .KEY_W,
        0x1b: .KEY_X,
        0x1c: .KEY_Y,
        0x1d: .KEY_Z,
        0x1e: .KEY_1,
        0x1f: .KEY_2,
        0x20: .KEY_3,
        0x21: .KEY_4,
        0x22: .KEY_5,
        0x23: .KEY_6,
        0x24: .KEY_7,
        0x25: .KEY_8,
        0x26: .KEY_9,
        0x27: .KEY_0,
        0x28: .KEY_RETURN,
        0x29: .KEY_ESCAPE,
        0x2a: .KEY_BACKSPACE,
        0x2b: .KEY_TAB,
        0x2c: .KEY_SPACE,
        0x2d: .KEY_MINUS,
        0x2e: .KEY_EQUALS,
        0x2f: .KEY_LEFT_SQUARE_BRACKET,
        0x30: .KEY_RIGHT_SQUARE_BRACKET,
        0x31: .KEY_BACK_SLASH,
        0x33: .KEY_SEMICOLON,
        0x34: .KEY_SINGLE_QUOTE,
        0x35: .KEY_TILDE,
        0x36: .KEY_COMMA,
        0x37: .KEY_PERIOD,
        0x38: .KEY_FORWARD_SLASH,
        0x39: .KEY_CAPS_LOCK,
        0x3a: .KEY_FN_1,
        0x3b: .KEY_FN_2,
        0x3c: .KEY_FN_3,
        0x3d: .KEY_FN_4,
        0x3e: .KEY_FN_5,
        0x3f: .KEY_FN_6,
        0x40: .KEY_FN_7,
        0x41: .KEY_FN_8,
        0x42: .KEY_FN_9,
        0x43: .KEY_FN_10,
        0x44: .KEY_FN_11,
        0x45: .KEY_FN_12,
        0x4f: .KEY_RIGHT_ARROW,
        0x50: .KEY_LEFT_ARROW,
        0x51: .KEY_DOWN_ARROW,
        0x52: .KEY_UP_ARROW,
    ]
}
