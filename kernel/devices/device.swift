//
//  kernel/devices/device.swift
//
//  Created by Simon Evans on 30/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//

class BusDevice: CustomStringConvertible {
    var description: String { "Generic BusDevice" }
    var className: String { "BusDevice" }
    let device: Device
    var busDeviceName: String

    init(device: Device, busDeviceName: String) {
        self.device = device
        self.busDeviceName = busDeviceName
        device.setBusDevice(self)
    }

    func info() -> String {
        return description
    }
}

private var _nextDeviceId = 0
private func nextDeviceId() -> Int {
    return atomic_inc(&_nextDeviceId)
}


final class Device: CustomStringConvertible {

    private(set) var deviceDriver: DeviceDriver?
    private(set) var busDevice: BusDevice?
    /*unowned*/ let parent: Device?
    private(set) var devices: [Device] = []
    let deviceName: String
    var enabled = false
    var initialised = false

    var isBus: Bool { devices.count > 0 }
    var description: String { deviceName }

    init(parent: Device) {
        self.parent = parent
        self.deviceName = "dev\(nextDeviceId())"
        parent.devices.append(self)
    }

    init() {
        self.parent = nil
        self.deviceName = "dev\(nextDeviceId())"
    }

    #if false
    func initialise() -> Bool {
        self.initialised = true
        return false
    }
    #endif

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
