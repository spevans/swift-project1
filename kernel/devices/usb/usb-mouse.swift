//
//  usb-mouse.swift
//  project1
//
//  Created by Simon Evans on 17/05/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//

final class USBMouse: HID {

    let description = "USBMouse"

    private let device: USBDevice
    private let interface: USB.InterfaceDescriptor
    private var intrPipe: USBPipe
    private var prevEvent = MouseEvent()
    private var buffer: [HIDEvent] = []
    private var data: [UInt8] = []

    init(device: USBDevice, interface: USB.InterfaceDescriptor, intrPipe: USBPipe) {
        #kprint("USB-HID: Creating USBMouse")
        self.device = device
        self.interface = interface
        self.intrPipe = intrPipe
    }

    func initialise() -> Bool {
        return true
    }


    override func readNextEvent() -> HIDEvent? {

        if buffer.isEmpty {
        // Now poll the interrupt to look for mouse changes
            sleep(milliseconds: 10)
            data.removeAll()
            guard intrPipe.pollInterruptPipe(into: &data) else {
                return nil
            }
            guard let event = MouseEvent(data: data) else {
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

        init?(data: [UInt8]) {
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
