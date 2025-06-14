//
//  usb-mouse.swift
//  project1
//
//  Created by Simon Evans on 17/05/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//

final class MouseHID: HID {
    private let mouse: USBMouse

    init(mouse: USBMouse) {
        self.mouse = mouse
    }

    override func readNextEvent() -> HIDEvent? {
        return mouse.readNextEvent()
    }
}


final class USBMouse: USBDeviceDriver {
    private let interface: USB.InterfaceDescriptor
    private var intrPipe: USBPipe?
    private var prevEvent = MouseEvent()
    private var buffer: [HIDEvent] = []
    private var data: InlineArray<4, UInt8> = .init(repeating: 0)

    init?(usbDevice: USBDevice, interface: USB.InterfaceDescriptor) {
        #kprint("USB-HID: Creating USBMouse")
        self.interface = interface
        super.init(driverName: "usb-mouse", usbDevice: usbDevice)
    }

    override func initialise() -> Bool {
        // Check the interface is valid
        // Find the INTR endpoint
        guard let intrEndpoint = interface.endpointMatching(transferType: .interrupt) else {
            #kprint("USB-MOU: Cant find an interrupt endpoint")
            return false
        }
        // Create a pipe for the interrupt endpoint and add it to the active queues
        guard let _intrPipe = usbDevice.bus.allocatePipe(usbDevice, intrEndpoint) else {
            #kprint("Cannot allocate Interupt pipe")
            return false
        }

        self.intrPipe = _intrPipe

        let idleRequest = USBHIDDriver.setIdleRequest(for: interface, idleMs: 0)
        #kprint("USB-MOU: setIdle to 0")
        guard usbDevice.sendControlRequest(request: idleRequest) else {
            #kprint("USB-MOU: Cannot set idleRequest")
            return false
        }

        return true
    }

    func hid() -> HID {
        return MouseHID(mouse: self)
    }


    func readNextEvent() -> HIDEvent? {
        if buffer.isEmpty {
            var dataSpan = data.mutableSpan

        // Now poll the interrupt to look for mouse changes
            sleep(milliseconds: 10)
            guard let intrPipe, intrPipe.pollInterruptPipe(into: &dataSpan) == 4 else {
                return nil
            }
            guard let event = MouseEvent(data: dataSpan) else {
                #kprint("usb-mouse, no event")
                return nil
            }
            event.events(fromPrev: prevEvent, into: &buffer)
            prevEvent = event
        }
        if buffer.count > 0 {
            return buffer.removeFirst()
        }
        return nil
    }
}

extension USBMouse {
    // Mouse Interface
    fileprivate struct MouseEvent: CustomStringConvertible {
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

        init?(data: borrowing MutableSpan<UInt8>) {
            guard data.count >= 3 else {
                #kprint("USB-Mouse, not enough data: \(data.count)")
                return nil
            }
            buttons = BitArray8(data[0])
            xMovement = Int8(bitPattern: data[1])
            yMovement = Int8(bitPattern: data[2])
        }

        func events(fromPrev prev: MouseEvent, into events: inout [HIDEvent]) {
            if leftButton != prev.leftButton {
                events.append(leftButton ? .buttonDown(.BUTTON_1) : .buttonUp(.BUTTON_1))
            }

            if middleButton != prev.middleButton {
                events.append(middleButton ? .buttonDown(.BUTTON_2) : .buttonUp(.BUTTON_2))
            }

            if rightButton != prev.rightButton {
                events.append(rightButton ? .buttonDown(.BUTTON_3) : .buttonUp(.BUTTON_3))
            }

            if xMovement != 0 {
                events.append(.xAxisMovement(Int16(xMovement)))
            }
            if yMovement != 0 {
                events.append(.yAxisMovement(Int16(yMovement)))
            }
        }
    }
}
