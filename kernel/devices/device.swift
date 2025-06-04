//
//  kernel/devices/device.swift
//
//  Created by Simon Evans on 30/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//

class BusDevice: CustomStringConvertible {
    var description: String { "Generic BusDevice" }
    let device: Device

    init?(device: Device) {
        self.device = device
    }

    func info() -> String {
        return description
    }
}

private var nextDeviceId = 1
final class Device: CustomStringConvertible {

    let acpiDeviceConfig: ACPIDeviceConfig?
    private(set) var deviceDriver: DeviceDriver?
    private(set) var busDevice: BusDevice?
    /*unowned*/ let parent: Device?
    private(set) var devices: [Device] = []
    var enabled = false
    var initialised = false
    var isBus: Bool { devices.count > 0 }
    var deviceName: String = "unnamed"
    var description: String { deviceName }


    init(parent: Device?, acpiDeviceConfig: ACPIDeviceConfig? = nil) {
        self.parent = parent
        self.acpiDeviceConfig = acpiDeviceConfig
        self.deviceName = "dev\(nextDeviceId)"
        nextDeviceId += 1
        parent?.devices.append(self)
    }

    func initialise() -> Bool {
        self.initialised = true
        return false
    }

    func setBusDevice(_ device: BusDevice) {
        if let busDevice = self.busDevice {
            fatalError("busDevice already set to \(busDevice)")
        }
        self.busDevice = device
    }

    func setDriver(_ driver: DeviceDriver) {
        if let deviceDriver = deviceDriver {
            fatalError("\(self) already has a device driver: \(deviceDriver)")
        }
        deviceDriver = driver
    }
}
