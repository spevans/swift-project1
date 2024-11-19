//
//  driver.swift
//  project1
//
//  Created by Simon Evans on 26/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//


class DeviceDriver {
    let device: Device
    func initialise() -> Bool {
        return false
    }

    init(device: Device) {
        self.device = device
    }
}


class PNPDeviceDriver: DeviceDriver {
    init?(pnpDevice: PNPDevice) {
        super.init(device: pnpDevice.device)
    }
}


class PCIDeviceDriver: DeviceDriver {
    init?(pciDevice: PCIDevice) {
        super.init(device: pciDevice.device)
    }
}
