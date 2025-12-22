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


private let keyMap: InlineArray<232, HIDEvent.Key> = [
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
   /* 0x32: */ .INVALID,    //Keyboard Non-US # and £ (UK)
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
   /* 0x46: */ .KEY_FN_13,
   /* 0x47: */ .KEY_FN_14,
   /* 0x48: */ .KEY_FN_15,
   /* 0x49: */ .KEY_INSERT,
   /* 0x4a: */ .KEY_HOME,
   /* 0x4b: */ .KEY_PAGE_UP,
   /* 0x4c: */ .KEY_DELETE,
   /* 0x4d: */ .KEY_END,
   /* 0x4e: */ .KEY_PAGE_DOWN,
   /* 0x4f: */ .KEY_RIGHT_ARROW,
   /* 0x50: */ .KEY_LEFT_ARROW,
   /* 0x51: */ .KEY_DOWN_ARROW,
   /* 0x52: */ .KEY_UP_ARROW,
   /* 0x53: */ .KEY_NUM_LOCK,
   /* 0x54: */ .KEY_KEYPAD_DIVIDE,
   /* 0x55: */ .KEY_KEYPAD_ASTERISK,
   /* 0x56: */ .KEY_KEYPAD_MINUS,
   /* 0x57: */ .KEY_KEYPAD_PLUS,
   /* 0x58: */ .KEY_KEYPAD_ENTER,
   /* 0x59: */ .KEY_KEYPAD_1,
   /* 0x5A: */ .KEY_KEYPAD_2,
   /* 0x5B: */ .KEY_KEYPAD_3,
   /* 0x5C: */ .KEY_KEYPAD_4,
   /* 0x5D: */ .KEY_KEYPAD_5,
   /* 0x5E: */ .KEY_KEYPAD_6,
   /* 0x5F: */ .KEY_KEYPAD_7,
   /* 0x60: */ .KEY_KEYPAD_8,
   /* 0x61: */ .KEY_KEYPAD_9,
   /* 0x62: */ .KEY_KEYPAD_0,
   /* 0x63: */ .KEY_KEYPAD_PERIOD,
   /* 0x64: */ .INVALID,
   /* 0x65: */ .INVALID,
   /* 0x66: */ .INVALID,
   /* 0x67: */ .INVALID,
   /* 0x68: */ .KEY_KEYPAD_EQUALS,
   /* 0x69: */ .KEY_FN_14,
   /* 0x6a: */ .KEY_FN_15,
   /* 0x6b: */ .KEY_FN_16,
   /* 0x6c: */ .KEY_FN_17,
   /* 0x6d: */ .KEY_FN_18,
   /* 0x6e: */ .KEY_FN_19,
   /* 0x6f: */ .KEY_FN_20,
   /* 0x70: */ .KEY_FN_21,
   /* 0x71: */ .KEY_FN_22,
   /* 0x72: */ .KEY_FN_23,
   /* 0x73: */ .KEY_FN_24,
   /* 0x70: */ .INVALID,

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
               .INVALID, .INVALID, .INVALID,
   /* 0xE0: */ .KEY_LEFT_CTRL,
   /* 0xE1: */ .KEY_LEFT_SHIFT,
   /* 0xE2: */ .KEY_LEFT_ALT,
   /* 0xE3: */ .KEY_LEFT_GUI,
   /* 0xE4: */ .KEY_RIGHT_CTRL,
   /* 0xE5: */ .KEY_RIGHT_SHIFT,
   /* 0xE6: */ .KEY_RIGHT_ALT,
   /* 0xE7: */ .KEY_RIGHT_GUI,
]

final class USBKeyboard: DeviceDriver {
    private let usbDevice: USBDevice
    private let interface: USB.InterfaceDescriptor
    private var prevModifierKeys = UInt8(0)
    private var prevKeys: InlineArray<8, UInt8> = .init(repeating: 0)
    private var keys: InlineArray<8, UInt8> = .init(repeating: 0)
    // FIXME: This is accessed by the irqHandler so should NOT be a heap allocated collection
    private var buffer: [HIDEvent] = []

    private var intrPipe: USBPipe?
    private var physBuffer: MMIOSubRegion?

    init?(usbDevice: USBDevice, interface: USB.InterfaceDescriptor) {
        #kprint("USB-HID: Creating USBKeyboard")
        self.usbDevice = usbDevice
        self.interface = interface
        self.buffer.reserveCapacity(32)
        let device = Device(parent: usbDevice, className: "USBHIDDevice", busDeviceName: "USBKeyboard")
        super.init(driverName: "usb-kbd", device: device)
        self.setInstanceName(to: "usb-kbd0")
    }

    override func initialise() -> Bool {

        // Check the interface is valid
        // Find the INTR endpoint
        guard let intrEndpoint = interface.endpointMatching(transferType: .interrupt) else {
            #kprint("USB-KBD: Cant find an interrupt endpoint")
            return false
        }
        // Create a pipe for the interrupt endpoint and add it to the active queues
        guard let _intrPipe = usbDevice.allocatePipe(intrEndpoint) else {
            #kprint("Cannot allocate Interupt pipe")
            return false
        }
        self.intrPipe = _intrPipe
        physBuffer = _intrPipe.allocateBuffer(length: Int(intrEndpoint.maxPacketSize))

        let idleRequest = USBHIDDriver.setIdleRequest(for: interface, idleMs: 33)
        #kprint("USB-KBD: keyboard setIdle to 33")
        guard usbDevice.sendControlRequest(request: idleRequest) else {
            #kprint("USB-HID: keyboard  Cant set idleRequest")
            return false
        }

        let urb = USB.Request(
            usbDevice: self.usbDevice,
            transferType: .interrupt,
            direction: .deviceToHost,
            pipe: _intrPipe,
            completionHandler: irqHandler,
            setupRequest: nil,
            buffer: physBuffer,
            bytesToTransfer: Int(intrEndpoint.maxPacketSize)
        )
        usbDevice.bus.submitURB(urb)

        return true
    }

    deinit {
        if let intrPipe, let physBuffer  {
            intrPipe.freeBuffer(physBuffer)
        }
    }

    func hid() -> HID {
        return KeyboardHID(keyboard: self)
    }

    func readNextEvent() -> HIDEvent? {
        // Now poll the interrupt to look for keypresses

        if buffer.count > 0 {
            //kprint("usb-keyboard, returning data")
            return buffer.removeFirst()
        }
        sleep(milliseconds: 10)
        return nil
    }


    private func irqHandler(_ request: USB.Request, response: USB.Response) {
//        #kprintf("USB-KBD: IRQ status: %s bytes: %d\n", response.status.description, response.bytesTransferred)

        guard var physBuffer = physBuffer else { return }
        let byteCount = response.bytesTransferred
//        #kprintf("usb-keyboard, byteCount: %d physBuffer.count: %d\n", byteCount, physBuffer.count)

        var prevKeysSpan = prevKeys.mutableSpan
        // Modifier keys
        let mkeys = physBuffer[0]
        physBuffer[0] = 0
        physBuffer[1] = 0
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
//        #kprintf("usb-keyboard: checking against previous keys, prevKeysSpan.count: %d\n", prevKeysSpan.count)
        // 6 bytes, 6 keys that are currently pressed
        //precondition(keysSpan.count == 8)
        precondition(prevKeysSpan.count == 8)

        func mapCode(_ keyCode: UInt8) -> HIDEvent.Key? {
            if Int(keyCode) < keyMap.count {
                let key = keyMap[Int(keyCode)]
                if key != .INVALID {
                    return key
                }
            }
            #kprintf("usb-keyboard: Unknown keycode: 0x%2.2x\n", keyCode)
            return nil
        }


        for idx in 2..<8 {
            // Key that is down, see if it was already down in the previous input
            let newKeyCode = physBuffer[idx]
            if !span(prevKeysSpan, contains: newKeyCode), let key = mapCode(newKeyCode) {
                buffer.append(.keyDown(key))
            }

            // See if key that was previously down is now up.
            let oldKeyCode = prevKeysSpan[idx]
            if !mmioRegion(physBuffer, contains: oldKeyCode), let key = mapCode(oldKeyCode) {
                buffer.append(.keyUp(key))
            }
        }
//        #kprintf("usb-keyboard: Copying %d bytes to prevKeysSpan\n", min(byteCount, physBuffer.count))
        for idx in 0..<min(byteCount, physBuffer.count) {
            prevKeysSpan[idx] = physBuffer[idx]
        }

        // Resubmit the IRQ
        usbDevice.bus.submitURB(request)
    }

    private func mmioRegion(_ region: MMIOSubRegion, contains value: UInt8) -> Bool {
        for idx in 0..<region.count {
            if region[idx] == value {
                return true
            }
        }
        return false
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
