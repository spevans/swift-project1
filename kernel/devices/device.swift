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
    func setDriver(_ driver: DeviceDriver)
}


protocol PNPDevice: Device {
    var pnpName: String { get }
    var resources: ISABus.Resources { get }
}

final class ACPIDevice: PNPDevice {
    unowned let parentBus: Bus
    let acpiDevice: AMLDefDevice?
    let fullName: String
    let pnpName: String
    let resources: ISABus.Resources
    private(set) var pnpDeviceDriver: PNPDeviceDriver?
    var deviceDriver: DeviceDriver? { pnpDeviceDriver }
    var enabled: Bool = true

    var description: String { "ACPIDevice \(pnpName) \(fullName)" }

    init(parentBus: Bus, pnpName: String, acpiDevice: AMLDefDevice) {
        self.parentBus = parentBus
        self.acpiDevice = acpiDevice
        self.pnpName = pnpName
        self.fullName = acpiDevice.fullname()

        if let crs = acpiDevice.currentResourceSettings() {
            self.resources = ISABus.Resources(crs)
        } else {
            self.resources = ISABus.Resources([])
        }
    }

    func setDriver(_ driver: DeviceDriver) {
        if let deviceDriver = deviceDriver {
            fatalError("\(self) already has a device driver: \(deviceDriver)")
        }

        guard let pnpDriver = driver as? PNPDeviceDriver else {
            fatalError("\(self): \(driver) is not for a PNP Device")
        }
        pnpDeviceDriver = pnpDriver
    }

    func initialiseDevice() {
    }
}

// Generic Keyboard device
protocol Keyboard {
    func readKeyboard() -> UnicodeScalar?
    // TODO: Add some key modifier state
}
