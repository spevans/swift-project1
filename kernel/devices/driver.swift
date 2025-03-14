//
//  driver.swift
//  project1
//
//  Created by Simon Evans on 26/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//


class DeviceDriver: CustomStringConvertible {
    var description: String { "Unnamed device" }
    let device: Device
    func initialise() -> Bool {
        return false
    }

    init(device: Device) {
        self.device = device
    }
}


class PNPDeviceDriver: DeviceDriver {
    override var description: String { "A PNP device" }
    init?(pnpDevice: PNPDevice) {
        super.init(device: pnpDevice.device)
    }
}


class PCIDeviceDriver: DeviceDriver {
    override var description: String { "A PCI device" }
    init?(pciDevice: PCIDevice) {
        super.init(device: pciDevice.device)
    }
}
