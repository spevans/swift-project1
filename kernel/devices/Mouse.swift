//
//  Mouse.swift
//  project1
//
//  Created by Simon Evans on 17/05/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//

// Generic mouse device that reads HID events

class Mouse {

    private var leftButtonDown = false
    private var middleButtonDown = false
    private var rightButtonDown = false
    private var xAxis: Int16 = 0
    private var yAxis: Int16 = 0


    private let hid: HID

    init(hid: HID) {
        self.hid = hid
    }

    func initialise() -> Bool {
        return true
    }

    func flushInput() {
        hid.flushInput()
    }

    func readHidEvent() -> HIDEvent? {
        return hid.readNextEvent()
    }

    func readMouse() {
        if let event = hid.readNextEvent() {

            switch event {
                case .buttonDown(let button):
                    switch button {
                        case .BUTTON_1: leftButtonDown = true
                        case .BUTTON_2: middleButtonDown = true
                        case .BUTTON_3: rightButtonDown = true
                    }

                case .buttonUp(let button):
                    switch button {
                        case .BUTTON_1: leftButtonDown = false
                        case .BUTTON_2: middleButtonDown = false
                        case .BUTTON_3: rightButtonDown = false
                    }

                case .xAxisMovement(let value):
                    let x = Int32(xAxis) + Int32(value)
                    if x < Int32(Int16.min) {
                        xAxis = Int16.min
                    } else if x > Int32(Int16.max) {
                        xAxis = Int16.max
                    } else {
                        xAxis = Int16(truncatingIfNeeded: x)
                    }

                case .yAxisMovement(let value):
                    let y = Int32(yAxis) + Int32(value)
                    if y < Int32(Int16.min) {
                        yAxis = Int16.min
                    } else if y > Int32(Int16.max) {
                        yAxis = Int16.max
                    } else {
                        yAxis = Int16(truncatingIfNeeded: y)
                    }

                default:
                    // Ignore other HID devices
                    break
            }
            #kprintf("Mouse: x: %d y: %d button: %d/%d/%d\n",
                     xAxis, yAxis, leftButtonDown, middleButtonDown, rightButtonDown)
        }
    }
}
