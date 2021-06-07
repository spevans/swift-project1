//
//  kernel/devices/PNPDevice.swift
//  project1
//
//  Created by Simon Evans on 07/06/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//
//  Device representing hardware identified by a _HID or _CID ACPI name,
//  non-PCI, usually ISA or ACPI devices.

final class PNPDevice: Device {
    private unowned let _acpiDevice: AMLDefDevice
    private(set) var pnpDeviceDriver: PNPDeviceDriver?
    private(set) var resources = ISABus.Resources([])
    unowned let parentBus: Bus
    let pnpName: String
    var enabled = false

    var acpiDevice: AMLDefDevice? { _acpiDevice }
    var fullName: String { _acpiDevice.fullname() }
    var deviceDriver: DeviceDriver? { pnpDeviceDriver }
    var description: String { "ISA: \(pnpName) \(fullName) \(resources)" }


    init(parentBus: Bus, acpiDevice: AMLDefDevice, pnpName: String) {
        self._acpiDevice = acpiDevice
        self.parentBus = parentBus
        self.pnpName = pnpName
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

    func initialiseDevice() -> Bool {
        guard _acpiDevice.initialiseIfPresent() else {
            print("\(fullName): initialiseIfPresent() failed")
            return false
        }
        if let crs = _acpiDevice.currentResourceSettings() {
            resources = ISABus.Resources(crs)
        }
        self.enabled = true
        return true
    }
}
