//
//  usb-keyboard.swift
//  project1
//
//  Created by Simon Evans on 12/05/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//

final class KeyboardHID: HID {
    private let keyboard: USBKeyboard

    init(keyboard: USBKeyboard) {
        self.keyboard = keyboard
    }

    override func readNextEvent() -> HIDEvent? {
        return keyboard.readNextEvent()
    }
}


private let keyMap: InlineArray<232, HIDEvent.Key> = [ //] [UInt8 : HIDEvent.Key] = [
   /* 0x00: */ .INVALID,  // Reserved
   /* 0x01: */ .INVALID,  // Keyboard ErrorRollOver
   /* 0x02: */ .INVALID,  // Keyboard POSTFail
   /* 0x03: */ .INVALID,  // Keyboard ErrorUndefined
   /* 0x04: */ .KEY_A,
   /* 0x05: */ .KEY_B,
   /* 0x06: */ .KEY_C,
   /* 0x07: */ .KEY_D,
   /* 0x08: */ .KEY_E,
   /* 0x09: */ .KEY_F,
   /* 0x0a: */ .KEY_G,
   /* 0x0b: */ .KEY_H,
   /* 0x0c: */ .KEY_I,
   /* 0x0d: */ .KEY_J,
   /* 0x0e: */ .KEY_K,
   /* 0x0f: */ .KEY_L,
   /* 0x10: */ .KEY_M,
   /* 0x11: */ .KEY_N,
   /* 0x12: */ .KEY_O,
   /* 0x13: */ .KEY_P,
   /* 0x14: */ .KEY_Q,
   /* 0x15: */ .KEY_R,
   /* 0x16: */ .KEY_S,
   /* 0x17: */ .KEY_T,
   /* 0x18: */ .KEY_U,
   /* 0x19: */ .KEY_V,
   /* 0x1a: */ .KEY_W,
   /* 0x1b: */ .KEY_X,
   /* 0x1c: */ .KEY_Y,
   /* 0x1d: */ .KEY_Z,
   /* 0x1e: */ .KEY_1,
   /* 0x1f: */ .KEY_2,
   /* 0x20: */ .KEY_3,
   /* 0x21: */ .KEY_4,
   /* 0x22: */ .KEY_5,
   /* 0x23: */ .KEY_6,
   /* 0x24: */ .KEY_7,
   /* 0x25: */ .KEY_8,
   /* 0x26: */ .KEY_9,
   /* 0x27: */ .KEY_0,
   /* 0x28: */ .KEY_RETURN,
   /* 0x29: */ .KEY_ESCAPE,
   /* 0x2a: */ .KEY_BACKSPACE,
   /* 0x2b: */ .KEY_TAB,
   /* 0x2c: */ .KEY_SPACE,
   /* 0x2d: */ .KEY_MINUS,
   /* 0x2e: */ .KEY_EQUALS,
   /* 0x2f: */ .KEY_LEFT_SQUARE_BRACKET,
   /* 0x30: */ .KEY_RIGHT_SQUARE_BRACKET,
   /* 0x31: */ .KEY_BACK_SLASH,
   /* 0x33: */ .KEY_SEMICOLON,
   /* 0x34: */ .KEY_SINGLE_QUOTE,
   /* 0x35: */ .KEY_TILDE,
   /* 0x36: */ .KEY_COMMA,
   /* 0x37: */ .KEY_PERIOD,
   /* 0x38: */ .KEY_FORWARD_SLASH,
   /* 0x39: */ .KEY_CAPS_LOCK,
   /* 0x3a: */ .KEY_FN_1,
   /* 0x3b: */ .KEY_FN_2,
   /* 0x3c: */ .KEY_FN_3,
   /* 0x3d: */ .KEY_FN_4,
   /* 0x3e: */ .KEY_FN_5,
   /* 0x3f: */ .KEY_FN_6,
   /* 0x40: */ .KEY_FN_7,
   /* 0x41: */ .KEY_FN_8,
   /* 0x42: */ .KEY_FN_9,
   /* 0x43: */ .KEY_FN_10,
   /* 0x44: */ .KEY_FN_11,
   /* 0x45: */ .KEY_FN_12,
   /* 0x4f: */ .KEY_RIGHT_ARROW,
   /* 0x50: */ .KEY_LEFT_ARROW,
   /* 0x51: */ .KEY_DOWN_ARROW,
   /* 0x52: */ .KEY_UP_ARROW,
               .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
               .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
                .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
               .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
               .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
               .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID, .INVALID,
   /* 0xE0: */ .KEY_LEFT_CTRL,
   /* 0xE1: */ .KEY_LEFT_SHIFT,
   /* 0xE2: */ .KEY_LEFT_ALT,
   /* 0xE3: */ .KEY_LEFT_GUI,
   /* 0xE4: */ .KEY_RIGHT_CTRL,
   /* 0xE5: */ .KEY_RIGHT_SHIFT,
   /* 0xE6: */ .KEY_RIGHT_ALT,
   /* 0xE7: */ .KEY_RIGHT_GUI,
]

final class USBKeyboard: USBDeviceDriver {
    private var prevModifierKeys = UInt8(0)
    private var prevKeys: InlineArray<8, UInt8> = .init(repeating: 0)
    private var keys: InlineArray<8, UInt8> = .init(repeating: 0)
    private var buffer: [HIDEvent] = []

    private let interface: USB.InterfaceDescriptor
    private var intrPipe: USBPipe?


    init?(usbDevice: USBDevice, interface: USB.InterfaceDescriptor) {
        #kprint("USB-HID: Creating USBKeyboard")
        self.interface = interface
        super.init(driverName: "usb-kbd", usbDevice: usbDevice)
    }

    override func initialise() -> Bool {

        // Check the interface is valid
        // Find the INTR endpoint
        guard let intrEndpoint = interface.endpointMatching(transferType: .interrupt) else {
            #kprint("USB-KBD: Cant find an interrupt endpoint")
            return false
        }
        // Create a pipe for the interrupt endpoint and add it to the active queues
        guard let _intrPipe = usbDevice.bus.allocatePipe(usbDevice, intrEndpoint) else {
            #kprint("Cannot allocate Interupt pipe")
            return false
        }

        self.intrPipe = _intrPipe

        let idleRequest = USBHIDDriver.setIdleRequest(for: interface, idleMs: 33)
        #kprint("USB-KBD: keyboard setIdle to 33")
        guard usbDevice.sendControlRequest(request: idleRequest) else {
            #kprint("USB-HID: keyboard  Cant set idleRequest")
            return false
        }

        return true
    }

    func hid() -> HID {
        return KeyboardHID(keyboard: self)
    }


    func readNextEvent() -> HIDEvent? {
        // Now poll the interrupt to look for keypresses
        if buffer.isEmpty {
            sleep(milliseconds: 10)
            var keysSpan = keys.mutableSpan
            let prevKeysSpan = prevKeys.mutableSpan

            guard let intrPipe, intrPipe.pollInterruptPipe(into: &keysSpan) == 8 else {
                return nil
            }

            // Modifier keys
            let mkeys = keysSpan[0]
            keysSpan[0] = 0
            keysSpan[1] = 0
            // The eight modifier keys in the byte0 bitmap match the
            // values from 0xE0 to 0xE7
            let changedMKeys = prevModifierKeys ^ mkeys
            let changedMkeysArray = BitArray8(changedMKeys)
            let mKeysArray = BitArray8(mkeys)
            for idx in 0..<8 {
                if changedMkeysArray[idx] == 1 {
                    let key = keyMap[0xe0 + idx]
                    let keyDown = mKeysArray[idx] == 1
                    buffer.append(keyDown ? .keyDown(key) : .keyUp(key))
                }
            }
            prevModifierKeys = mkeys

            // 6 bytes, 6 keys that are currently pressed
            precondition(keysSpan.count == 8)
            precondition(prevKeysSpan.count == 8)
            for idx in 2..<8 {
                // Key that is down, see if it was already down in the previous input
                let newKeyCode = keysSpan[idx]
                if !span(prevKeysSpan, contains: newKeyCode) {
                    if Int(newKeyCode) < keyMap.count {
                        let key = keyMap[Int(newKeyCode)]
                        if key != .INVALID {
                            buffer.append(.keyDown(key))
                        }
                    } else {
                        #kprintf("usb: Unknown keycode: %2.2x\n", newKeyCode)
                    }
                }

                // See if key that was previously down is now up.
                let oldKeyCode = prevKeysSpan[idx]
                if !span(keysSpan, contains: oldKeyCode) {
                    if Int(oldKeyCode) < keyMap.count {
                        let key = keyMap[Int(oldKeyCode)]
                        if key != .INVALID {
                            buffer.append(.keyUp(key))
                        }
                    } else {
                        #kprintf("usb: Unknown keycode: %2.2x\n", oldKeyCode)
                     }
                }
            }
            prevKeys = keys
        }
        if buffer.count > 0 {
            //kprint("usb-keyboard, returning data")
            return buffer.removeFirst()
        }
        return nil
    }

    private func span(_ span: borrowing MutableSpan<UInt8>, contains value: UInt8) -> Bool {
        for idx in span.indices {
            if span[idx] == value {
                return true
            }
        }
        return false
    }
}
