/*
 * kernel/devices/ps2mouse.swift
 *
 * Created by Simon Evans on 26/12/2025.
 * Copyright © 2025 Simon Evans. All rights reserved.
 *
 * PS/2 Mouse driver. Decodes 3-byte movement packets into HID events.
 * Very basic implementation.
 *
 */


private var PS2MouseDebug = false

final class PS2MouseHID: HID {
    private let mouse: PS2Mouse

    init(mouse: PS2Mouse) {
        self.mouse = mouse
    }

    override func readNextEvent() -> HIDEvent? {
        return mouse.readNextEvent()
    }
}

final class PS2Mouse: DeviceDriver {

    private let device: PS2Device
    private var inputBuffer = CircularBuffer<UInt8>(item: 0, capacity: 16)
    private var eventBuffer = CircularBuffer<HIDEvent?>(item: nil, capacity: 32)
    private var mouseType: UInt8 = 0   // Generic PS/2 Intelliexplorer etc
    private var bytesPerReport = 3
    private var bytesReceived = 0
    private var bytesRead: InlineArray<4, UInt8> = [0, 0, 0, 0]
    private var prevButtons: InlineArray<3, Bool> = [false, false, false]


    init(device: PS2Device) {
        self.device = device
        super.init(driverName: "ps2mouse", device: device)
        self.setInstanceName(to: "ps2mouse0")

        if let resp = self.device.sendCommandGetResponse(0xff) {
            if PS2MouseDebug { #kprintf("ps2mouse: Reset %2x\n", resp) }
            if let mouseType = self.device.readData() {
                if PS2MouseDebug { #kprintf("ps2mouse: Type: 0x%2.2x\n", mouseType) }
                self.mouseType = mouseType
                // TODO, set bytesPerReport based on mouseType
            } else {
                if PS2MouseDebug { #kprint("Failed to get mouse type") }
            }
        } else {
            if PS2MouseDebug { #kprint("ps2mouse: Reset failed") }
        }

        if self.device.sendCommand(0xF4) {
            if PS2MouseDebug { #kprint("ps2mouse: Sent enable scanning for mouse") }
        } else {
            #kprint("ps2mouse: Failed to send enable scanning command")
        }
        device.setReceivedData(to: { self.inputBuffer.add($0) })
        let hid = PS2MouseHID(mouse: self)
        #if !TEST
        system.deviceManager.mouse = Mouse(hid: hid)
        #endif

        #kprintf("ps2mouse: Initialised type: %u\n", mouseType)
    }

    deinit {
        self.device.setReceivedData(to: nil)
    }

    func readNextEvent() -> HIDEvent? {
        while let data = inputBuffer.remove() {
            if self.bytesReceived == 0{
                if data & 0x8 == 0 {
                    // First byte of packet should always have bit3 set
                    continue
                }
                bytesRead[0] = data
                self.bytesReceived = 1
            } else {
                bytesRead[self.bytesReceived] = data
                self.bytesReceived += 1
            }

            if self.bytesReceived == self.bytesPerReport {
                let bytes = self.bytesRead
                self.bytesRead = [0, 0, 0, 0]
                self.bytesReceived = 0
                self.decode(bytes)
            }
        }
        guard let event = eventBuffer.remove() else {
            return nil
        }
        return event
    }


    private func decode(_ bytes: InlineArray<4, UInt8>) {
        if PS2MouseDebug {
            #kprintf("decoding: %02x %02x %02 %02x moue: %d\n",
                     bytes[0], bytes[1], bytes[2], bytes[3], self.mouseType)
        }
        let byte0 = BitArray8(bytes[0])

        // Bytes 1 and 2 are the low 8 bits of signed 9-bit movement values.
        // Bit 4 (X-sign) and bit 5 (Y-sign) of byte 0 are the 9th (sign) bits.
        // Sign-extend: subtract 256 when the sign bit is set.
        let xAxis = Int16(bytes[1]) - (byte0[4] == 1 ? 256 : 0)
        if xAxis != 0 {
            eventBuffer.add(.xAxisMovement(xAxis))
        }

        let yAxis = Int16(bytes[2]) - (byte0[5] == 1 ? 256 : 0)
        if yAxis != 0 {
            eventBuffer.add(.yAxisMovement(yAxis))
        }

        if self.bytesPerReport == 4 {
            // zAxis is an Int4 2s compliment values -8 to 7, sign extend upto 16 bits
            let zAxis = bytes[3].bit(3) ? Int16(bitPattern:0xfff0) | Int16(bytes[3]) : Int16(bytes[3])
            if zAxis != 0 {
                eventBuffer.add(.zAxisMovement(zAxis))
            }
        }

        let leftButton = byte0[0] == 1
        if leftButton != prevButtons[0] {
            eventBuffer.add(leftButton ? .buttonDown(.BUTTON_1) : .buttonUp(.BUTTON_1))
            prevButtons[0] = leftButton
        }

        let rightButton = byte0[1] == 1
        if rightButton != prevButtons[1] {
            eventBuffer.add(rightButton ? .buttonDown(.BUTTON_2) : .buttonUp(.BUTTON_2))
            prevButtons[1] = rightButton
        }
        let middleButton = byte0[2] == 1
        if middleButton != prevButtons[2] {
            eventBuffer.add(middleButton ? .buttonDown(.BUTTON_3) : .buttonUp(.BUTTON_3))
            prevButtons[2] = middleButton
        }
    }
}
