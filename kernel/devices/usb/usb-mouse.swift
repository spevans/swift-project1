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

    override func flushInput() {
        mouse.flushInput()
    }
}


final class USBMouse: USBDeviceDriver {
    private let interface: USB.InterfaceDescriptor
    private var intrPipe: USBPipe?
    private var physBuffer: MMIOSubRegion?
    private var prevEvent = MouseEvent()
    private var eventBuffer = CircularBuffer<HIDEvent?>(item: nil, capacity: 32)


    init?(device: Device, usbDevice: USBDevice, interface: USB.InterfaceDescriptor) {
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
        guard let _intrPipe = usbDevice.bus.allocatePipe(intrEndpoint) else {
            #kprint("Cannot allocate Interupt pipe")
            return false
        }

        self.intrPipe = _intrPipe
        physBuffer = _intrPipe.allocateBuffer(length: Int(intrEndpoint.maxPacketSize))

        let idleRequest = USBHIDDriver.setIdleRequest(for: interface, idleMs: 0)
        #kprint("USB-MOU: setIdle to 0")
        guard usbDevice.sendControlRequest(request: idleRequest) else {
            #kprint("USB-MOU: Cannot set idleRequest")
            return false
        }
        self.setInstanceName(to: "usb-mouse0")

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
        return MouseHID(mouse: self)
    }

    func flushInput() {
        eventBuffer.clear()
    }

    func readNextEvent() -> HIDEvent? {
        // Now poll the interrupt to look for keypresses

        if let event = eventBuffer.remove() {
            return event
        }
        sleep(milliseconds: 10)
        return nil
    }

    private func irqHandler(_ request: USB.Request, response: USB.Response) {

        if let physBuffer, let event = MouseEvent(data: physBuffer) {

            if event.leftButton != prevEvent.leftButton {
                eventBuffer.add(event.leftButton ? .buttonDown(.BUTTON_1) : .buttonUp(.BUTTON_1))
            }

            if event.middleButton != prevEvent.middleButton {
                eventBuffer.add(event.middleButton ? .buttonDown(.BUTTON_2) : .buttonUp(.BUTTON_2))
            }

            if event.rightButton != prevEvent.rightButton {
                eventBuffer.add(event.rightButton ? .buttonDown(.BUTTON_3) : .buttonUp(.BUTTON_3))
            }

            if event.xMovement != 0 {
                eventBuffer.add(.xAxisMovement(Int16(event.xMovement)))
            }
            if event.yMovement != 0 {
                eventBuffer.add(.yAxisMovement(Int16(event.yMovement)))
            }
            prevEvent = event

        } else {
            #kprint("usb-mouse, no event")
        }

        // Resubmit the IRQ
        usbDevice.bus.submitURB(request)
    }
}

extension USBMouse {
    // Mouse Interface
    fileprivate struct MouseEvent {
        let buttons: BitArray8
        let xMovement: Int8
        let yMovement: Int8

        var leftButton: Bool { buttons[0] == 1 }
        var middleButton: Bool { buttons[1] == 1 }
        var rightButton: Bool { buttons[2] == 1 }
        var movement: Bool { xMovement != 0 || yMovement != 0 }


        init() {
            buttons = BitArray8(0)
            xMovement = 0
            yMovement = 0
        }

        init?(data: MMIOSubRegion) {
            guard data.count >= 3 else {
                #kprint("USB-Mouse, not enough data: \(data.count)")
                return nil
            }
            buttons = BitArray8(data[0])
            xMovement = Int8(bitPattern: data[1])
            yMovement = Int8(bitPattern: data[2])
        }
    }
}
