//
//  kernel/devices/piix.swift
//  PIIX - PCI ISA IDE XCELERATOR
//
//  Created by Simon Evans on 16/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

// Bare minium support for PIIX3/4 just so that the ISA bridge/bus behind it
// can be initialised.


final class PIIX: Device, PCIDevice, CustomStringConvertible {
    let deviceFunction: PCIDeviceFunction
    var description: String { return deviceFunction.description + ": PIIX" }

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction) {
        self.deviceFunction = deviceFunction
    }

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpi: AMLDefDevice? = nil) {
        self.deviceFunction = deviceFunction
        print("PIIX: Adding ISA bus")

        let isaBus = ISABus(parentBus: parentBus, acpi: acpi)
        isaBus.initialiseDevices()
        parentBus.addDevice(isaBus)
    }
}
