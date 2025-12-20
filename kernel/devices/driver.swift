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
        #sprintf("%s: Driver does not override info() method.", self.driverName)
    }

    func debug(arguments: [String]) {
        #kprintf("Device: %s does not support debug commands\n", device.description)
    }

    func setInstanceName(to newName: String) {
        guard self.instanceName == "" else {
            fatalError("instanceName alread set to \(self.instanceName)")
        }
        self.instanceName = newName
    }
}
