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
    private(set) var devices: [Device]?
    let className: String
    let deviceName: String

    var busDeviceName: String
    // FIXME, need to decide what these should actually represent or if even needed
    var enabled = false

    var isBus: Bool { devices != nil }
    var description: String { deviceName }

    init(parent: Device, className: String, busDeviceName: String) {
        self.parent = parent
        self.className = className
        self.deviceName = "dev\(nextDeviceId())"
        self.busDeviceName = busDeviceName
        parent.addChild(device: self)
    }

    init() {
        self.parent = nil
        self.className = "GenericDevice"
        self.deviceName = "dev\(nextDeviceId())"
        self.busDeviceName = "MasterBus"
    }

    func setAsBus() {
        guard self.devices == nil else {
            fatalError("\(self.deviceName) is already a bus")
        }
        self.devices = []
    }

    func addChild(device: Device) {
        guard self.devices != nil else {
            let driver = self.deviceDriver?.driverName ?? "none"
            fatalError("\(self.deviceName): trying to add child device \(device.className) to a non-bus \(self.className), driver: \(driver)")
        }
        self.devices?.append(device)
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
