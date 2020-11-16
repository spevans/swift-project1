/*
 * kernel/devices/usb/uhci-hid.swift
 *
 * Created by Simon Evans on 09/11/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB HID Device Driver for keyboard and mouse.
 *
 */


final class USBHIDDriver: DeviceDriver {
    private let device: USBDevice
    private let interface: USB.InterfaceDescriptor
    private var intrPipe: USBPipe!


    // bRequest for Class specific request
    enum HIDRequest: UInt8 {
        case GET_REPORT = 0x1
        case GET_IDLE = 0x2
        case GET_PROTOCOL = 0x3
        case SET_REPORT = 0x9
        case SET_IDLE = 0xA
        case SET_PROTOCOL = 0xB
    }

    enum HIDProtocol: UInt16 {
        case boot = 0x0
        case report = 0x1
    }

    enum HIDInterfaceProtocol: UInt8 {
        case none = 0x0
        case keyboard = 0x1
        case mouse = 0x2
    }

    enum HIDReport: UInt8 {
        case input = 0x1
        case output = 0x2
        case feature = 0x3
    }


    init?(device: USBDevice, interface: USB.InterfaceDescriptor) {
        self.device = device
        self.interface = interface

        guard case .hid = interface.interfaceClass else {
            print("USB-HID: interface is not a HID")
            return nil
        }

        guard interface.bInterfaceSubClass == 0x1, let interfaceProtocol = HIDInterfaceProtocol(rawValue: interface.bInterfaceProtocol) else {
            print("USB-HID: Device has no boot protocol or cant determine device type (subClass=\(interface.bInterfaceSubClass), protocol=\(interface.bInterfaceProtocol)")
            return nil
        }

        if case .none = interfaceProtocol {
            print("USB-HID: Device is not a keyboard or mouse")
            return nil
        }
    }


    func initialise() -> Bool {
        print("USB: Setting protocol to GetReport")
        // Set protocol to 'GetReport'

        let request = setProtocolRequest(hidProtocol: .report)
        print("USB: request:", request)
        guard device.sendControlRequest(request: request) else {
            print("USB: Cant set HID Protocol to Report Protocol")
            return false
        }

        // Find the INTR endpoint
        guard let intrEndpoint = interface.endpointMatching(transferType: .interrupt) else {
            print("USB-HID: Cant find an interrupt endpoint")
            return false
        }
        print("USB-HID: Interrupt endpoint:", intrEndpoint)

        // Create a pipe for the interrupt endpoint and add it to the active queues
        intrPipe = device.hub.allocatePipe(device: device, endpointDescriptor: intrEndpoint)

        return true
    }

    // FIXME: Remove when interrupts work fully, polling test for now
    func read() {
        if let interfaceProtocol = HIDInterfaceProtocol(rawValue: interface.bInterfaceProtocol) {
            switch interfaceProtocol {
                case .keyboard: readKeyboard()
                case .mouse: readMouse()
                default: return
            }
        }
    }
}


// Mouse Interface
extension USBHIDDriver {
    struct MouseEvent: CustomStringConvertible {
        let buttons: BitArray8
        let xMovement: Int8
        let yMovement: Int8

        var leftButton: Bool { buttons[0] == 1 }
        var middleButton: Bool { buttons[1] == 1 }
        var rightButton: Bool { buttons[2] == 1 }
        var movement: Bool { xMovement != 0 || yMovement != 0 }

        var description: String {
            return "X: \(xMovement)\tY: \(yMovement)\t" + (leftButton ? "left " : "") + (middleButton ? "middle " : "") + (rightButton ? "right" : "")
        }

        init() {
            buttons = BitArray8(0)
            xMovement = 0
            yMovement = 0
        }

        init(data: [UInt8]) {
            precondition(data.count >= 3)
            buttons = BitArray8(data[0])
            xMovement = Int8(bitPattern: data[1])
            yMovement = Int8(bitPattern: data[2])
        }
    }

    func readMouse() {
        // Now poll the interrupt to look for mouse changes
        var oldEvent = MouseEvent()
        while true {
            sleep(milliseconds: 10)
            guard let data = intrPipe.pollInterruptPipe() else { continue }
            guard data.count >= 3 else {
                print("USB-Mouse, not enough data: \(data.count)")
                continue
            }
            let event = MouseEvent(data: data)
            if event.buttons != oldEvent.buttons || event.movement {
                print(event)
                oldEvent = event
            }
        }
    }
}


// Keyboard Interface
extension USBHIDDriver {
    struct KeyEvent: CustomStringConvertible {
        let modifierKeys: BitArray8
        let keyCode: UInt8
        let keyDown: Bool

        init(keyDown code: UInt8, modifierKeys: UInt8) {
            keyDown = true
            keyCode = code
            self.modifierKeys = BitArray8(modifierKeys)
        }

        init(keyUp code: UInt8, modifierKeys: UInt8) {
            keyDown = false
            keyCode = code
            self.modifierKeys = BitArray8(modifierKeys)
        }

        var keyUp: Bool { !keyDown }
        var leftControl: Bool { modifierKeys[0] == 1 }
        var leftShift: Bool { modifierKeys[1] == 1 }
        var leftAlt: Bool { modifierKeys[2] == 1 }
        var leftGUI: Bool { modifierKeys[3] == 1 }
        var rightControl: Bool { modifierKeys[4] == 1 }
        var rightShift: Bool { modifierKeys[5] == 1 }
        var rightAlt: Bool { modifierKeys[6] == 1 }
        var rightGUI: Bool { modifierKeys[7] == 1 }

        var description: String {
            var result = keyDown ? "KeyDown: " : "KeyUp: "
            result.append(String(keyCode, radix: 16))
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


    func readKeyboard() {
        // Now poll the interrupt to look for keypresses
        var oldkeys: [UInt8] = []

        while true {
            sleep(milliseconds: 10)
            guard var keys = intrPipe.pollInterruptPipe() else { continue }

            guard let modifierKeys = keys.first else {
                print("No modifier data")
                return
            }
            keys.removeFirst(2)

            let (keysDown, keysUp) = removeDuplicates(array1: keys, array2: oldkeys)

            for key in keysDown {
                let event = KeyEvent(keyDown: key, modifierKeys: modifierKeys)
                print(event)
            }
            for key in keysUp {
                let event = KeyEvent(keyUp: key, modifierKeys: modifierKeys)
                print(event)
            }
            oldkeys = keys
        }
    }
}


// HID Class specific control requests
extension USBHIDDriver {
    private func getReportRequest(report: HIDReport, reportId: UInt8 = 0) -> USB.ControlRequest {
        let recipient = USB.ControlRequest.Recipient.interface(interface.bInterfaceNumber)
        let wLength = interface.endpoint0.wMaxPacketSize
        let wValue = UInt16(report.rawValue) << 8 | UInt16(reportId)
        return USB.ControlRequest.classSpecificRequest(direction: .deviceToHost, recipient: recipient, bRequest: HIDRequest.GET_REPORT.rawValue, wValue: wValue, wLength: wLength)
    }


    private func setReportRequest(report: HIDRequest, reportId: UInt8 = 0, dataLength: UInt16) -> USB.ControlRequest {
        let recipient = USB.ControlRequest.Recipient.interface(interface.bInterfaceNumber)
        let wValue = UInt16(report.rawValue) << 8 | UInt16(reportId)
        return USB.ControlRequest.classSpecificRequest(direction: .deviceToHost, recipient: recipient, bRequest: HIDRequest.SET_REPORT.rawValue, wValue: wValue, wLength: dataLength)
    }


    private func setProtocolRequest(hidProtocol: HIDProtocol) -> USB.ControlRequest {
        let recipient = USB.ControlRequest.Recipient.interface(interface.bInterfaceNumber)
        return USB.ControlRequest.classSpecificRequest(direction: .hostToDevice, recipient: recipient, bRequest: HIDRequest.SET_PROTOCOL.rawValue, wValue: hidProtocol.rawValue, wLength: 0)
    }
}
