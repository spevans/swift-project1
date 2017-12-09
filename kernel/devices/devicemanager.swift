//
//  kernel/devices/devicemanager.swift
//  acpi
//
//  Created by Simon Evans on 07/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//


class Device {}

// Generic Keyboard device
protocol Keyboard {
    func readKeyboard() -> UnicodeScalar?
    // TODO: Add some key modifier state
}

// Generic Timer device
protocol Timer {
    func enablePeriodicInterrupt(hz: Int, _ callback: @escaping () -> ()) -> Bool
}


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
        if let timer = timer {
            _ = timer.enablePeriodicInterrupt(hz: 20, timerCallback)
            print(timer)
        }
        TTY.sharedInstance.scrollTimingTest()
    }


    func addDevice(_ device: Device) {
        devices.append(device)
    }


    var keyboard: Keyboard? {
        return devices.filter { $0 is Keyboard }.first as? Keyboard
    }


    var timer: Timer? {
        return devices.filter { $0 is Timer }.first as? Timer
    }
}

// FIXME: This is unsafe, needs atomic read/write or some locking
private var ticks: UInt64 = 0

func timerCallback() {
    ticks = ticks &+ 1
    if (ticks % 0x200) == 0 {
        printf("\ntimerInterrupt: %#016X\n", ticks)
    }
    // Do nothing for now
}

