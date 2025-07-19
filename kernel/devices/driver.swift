//
//  driver.swift
//  project1
//
//  Created by Simon Evans on 26/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//


class DeviceDriver: CustomStringConvertible {
    let driverName: String
    let device: Device
    var description: String { driverName }

    init(driverName: String, device: Device) {
        self.driverName = driverName
        self.device = device
    }

    func initialise() -> Bool {
        return false
    }

    func info() -> String {
        return "Invalid device driver"
    }

    func debug(arguments: [String]) {
        #kprintf("Device: %s does not support debug commands\n", device.description)
    }
}


//FIXME: are these needed?
class PNPDeviceDriver: DeviceDriver {
    init?(driverName: String, pnpDevice: PNPDevice) {
        super.init(driverName: driverName, device: pnpDevice.device)
    }
}


class PCIDeviceDriver: DeviceDriver {
    init?(driverName: String, pciDevice: PCIDevice) {
        super.init(driverName: driverName, device: pciDevice.device)
    }
}


class USBDeviceDriver: DeviceDriver {
    let usbDevice: USBDevice

    init(driverName: String, usbDevice: USBDevice) {
        self.usbDevice = usbDevice
        super.init(driverName: driverName, device: usbDevice.device)
    }

    init(driverName: String, usbDevice: USBDevice, device: Device) {
        self.usbDevice = usbDevice
        super.init(driverName: driverName, device: device)
    }
}
