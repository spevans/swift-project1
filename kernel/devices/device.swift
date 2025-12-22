//
//  kernel/devices/device.swift
//
//  Created by Simon Evans on 30/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//


private var _nextDeviceId = 0
private func nextDeviceId() -> Int {
    return atomic_inc(&_nextDeviceId)
}


class Device: CustomStringConvertible {

    private(set) var deviceDriver: DeviceDriver?
    /*unowned*/ let parent: Device?
    private(set) var devices: [Device] = []
    let className: String
    let deviceName: String

    var busDeviceName: String
    // FIXME, need to decide what these should actually represent or if even needed
    var enabled = false
    var initialised = false

    var isBus: Bool { devices.count > 0 }
    var description: String { deviceName }

    init(parent: Device, className: String, busDeviceName: String) {
        self.parent = parent
        self.className = className
        self.deviceName = "dev\(nextDeviceId())"
        self.busDeviceName = busDeviceName

        parent.devices.append(self)
    }

    init() {
        self.parent = nil
        self.className = "GenericDevice"
        self.deviceName = "dev\(nextDeviceId())"
        self.busDeviceName = "MasterBus"
    }

    func info() -> String {
        #sprintf("%s: Driver does not override info() method.", self.deviceName)
    }

    func setDriver(_ driver: DeviceDriver) {
        if let deviceDriver = deviceDriver {
            fatalError("\(self) already has a device driver: \(deviceDriver)")
        }
        deviceDriver = driver
    }
}
