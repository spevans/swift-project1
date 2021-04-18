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

    //init(parentBus: Bus, acpiDevice: AMLDefDevice?)
    func initialiseDevice()
}


protocol PNPDevice: Device {
    var pnpName: String { get }
}

final class ACPIDevice: Device, PNPDevice {
    let parentBus: Bus
    let acpiDevice: AMLDefDevice?
    let fullName: String
    let pnpName: String
    var enabled: Bool = true
    private(set) var deviceDriver: DeviceDriver? = nil


    var description: String { "ACPIDevice \(pnpName) \(fullName)" }

    init(parentBus: Bus, pnpName: String, acpiDevice: AMLDefDevice) {
        self.parentBus = parentBus
        self.acpiDevice = acpiDevice
        self.pnpName = pnpName
        self.fullName = acpiDevice.fullname()
    }

    func initialiseDevice() {
    }
}

// Generic Keyboard device
protocol Keyboard {
    func readKeyboard() -> UnicodeScalar?
    // TODO: Add some key modifier state
}
