//
//  kernel/devices/device.swift
//
//  Created by Simon Evans on 30/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//

protocol Device: AnyObject, CustomStringConvertible {
    var parentBus: Bus { get }
    var acpiDevice: AMLDefDevice? { get }
    var fullName: String { get }
    var enabled: Bool { get set }
    var deviceDriver: DeviceDriver? { get }

    func initialise() -> Bool
    func setDriver(_ driver: DeviceDriver)
}

// Generic Keyboard device
protocol Keyboard {
    func readKeyboard() -> UnicodeScalar?
    // TODO: Add some key modifier state
}
