//
//  driver.swift
//  project1
//
//  Created by Simon Evans on 26/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//


class DeviceDriver: CustomStringConvertible {
    let driverName: String
    private(set) var instanceName = ""
    var description: String { driverName }
    // Note the device itself is not held in this as it is usually a subsclass of Device
    // so is better to hold the correct subclass to avoid lots of as! casting

    init(driverName: String, device: Device) {
        self.driverName = driverName
        device.setDriver(self)
    }

    func initialise() -> Bool {
        return false
    }

    func info() -> String {
        #sprintf("%s: Driver does not override info() method.", self.driverName)
    }

    func debug(arguments: [String]) {
        #kprintf("%s: Driver: does not support debug commands\n", self.driverName)
    }

    func setInstanceName(to newName: String) {
        guard self.instanceName == "" else {
            fatalError("instanceName alread set to \(self.instanceName)")
        }
        self.instanceName = newName
    }
}
