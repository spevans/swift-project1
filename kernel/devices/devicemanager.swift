//
//  kernel/devices/devicemanager.swift
//  acpi
//
//  Created by Simon Evans on 07/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//


class Device {}

final class DeviceManager {
    let acpi: ACPI
    private(set) var interruptManager: InterruptManager
    private(set) var devices: [Device]


    init(acpiTables: ACPI) {
        acpi = acpiTables
        devices = []
        interruptManager = InterruptManager(acpiTables: acpi)
        set_interrupt_manager(&interruptManager)
    }


    func initialiseDevices() {
        let isaBus = ISABus(acpi: acpi)
        isaBus.initialiseBusDevices(deviceManager: self)
        PCI.scan(mcfgTable: acpi.mcfg)
        // Set the timer interrupt for 200Hz
        timer?.setChannel(.CHANNEL_0, mode: .MODE_3, hz: 20)
        print(timer!)
        TTY.sharedInstance.scrollTimingTest()
    }


    func addDevice(_ device: Device) {
        devices.append(device)
    }


    var keyboard: Keyboard? {
        return devices.filter { $0 is Keyboard }.first as? Keyboard
    }


    var timer: PIT8254? {
        return devices.filter { $0 is PIT8254 }.first as? PIT8254
    }
}
