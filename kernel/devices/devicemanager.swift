//
//  kernel/devices/devicemanager.swift
//  acpi
//
//  Created by Simon Evans on 07/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//


final class DeviceManager {
    let acpiTables: ACPI
    private(set) var interruptManager: InterruptManager
    private(set) var devices: [DeviceDriver] = []
    private(set) var masterBus: Bus


    init(acpiTables: ACPI) {
        acpiTables.parseAMLTables()
        guard let (sb, _) = acpiTables.globalObjects.getGlobalObject(currentScope: AMLNameString("\\"),
                                                                     name: AMLNameString("_SB")) else {
            fatalError("No \\_SB system bus node")
        }
        self.acpiTables = acpiTables
        interruptManager = InterruptManager(acpiTables: acpiTables)
        set_interrupt_manager(&interruptManager)

        // Set _PIC mode to APIC (1)
        do {
            // APIC
            _ = try AMLMethodInvocation(method: AMLNameString("\\_PIC"), AMLDataObject.integer(1))
            print("ACPI: _PIC mode set to APIC")
        } catch {
            print("ACPI: Cant set _PIC mode to APIC:", error)
        }
        masterBus = MasterBus(acpiSystemBus: sb)
    }


    func initialiseDevices() {
        masterBus.initialiseDevices(acpiDevice: nil)

        // Now load device drivers for any known devices, ISA/PNP first
        func initPnpDevices(on bus: Bus) {
            for device in bus.devices {
                if let pnpDevice = device as? ISADevice, device.deviceDriver == nil {
                    if let driverType = pnpDriverById(pnpName: pnpDevice.pnpName), let driver = driverType.init(pnpDevice: pnpDevice) {
                        pnpDevice.pnpDeviceDriver = driver
                        system.deviceManager.addDevice(driver)
                    }
                }
                if let bus = device.deviceDriver as? Bus {
                    initPnpDevices(on: bus)
                }
            }
        }
        initPnpDevices(on: masterBus)

        // Set the timer interrupt for 20Hz
        if let timer = timer {
            _ = timer.enablePeriodicInterrupt(hz: 20, timerCallback)
            print(timer)
        }
        TTY.sharedInstance.scrollTimingTest()
        dumpDeviceTree()
    }

    func addDevice(_ device: DeviceDriver) {
        devices.append(device)
    }


    private func dumpBus(_ bus: Bus, depth: Int) {
        let spaces = String(repeating: " ", count: depth * 6)
        for device in bus.devices {
            print("\(spaces)+--- \(device)")
            if let bus = device.deviceDriver as? Bus {
                dumpBus(bus, depth: depth + 1)
            }
        }
    }


    func dumpDeviceTree() {
        print(masterBus)
        dumpBus(masterBus, depth: 0)
    }

    func dumpDevices() {
        for device in devices {
            print("DEV:", device)
        }
    }

    func dumpPCIDevices(bus: Bus? = nil) {
        for device in (bus ?? masterBus).devices {
            if let pciDevice = device as? PCIDevice {
                print(pciDevice)
            }
            if let bus = device.deviceDriver as? Bus {
                dumpPCIDevices(bus: bus)
            }
        }
    }

    func dumpPNPDevices(bus: Bus? = nil) {
        for device in (bus ?? masterBus).devices {
            if let pnpDevice = device as? PNPDevice {
                print(pnpDevice.pnpName)
            }
            if let bus = device.deviceDriver as? Bus {
                dumpPNPDevices(bus: bus)
            }
        }
    }


    var keyboard: Keyboard? {
        return devices.filter { $0 is Keyboard }.first as? Keyboard
    }


    var timer: Timer? {
        return devices.filter { $0 is Timer }.first as? Timer
    }

    var rtc: CMOSRTC? {
        return devices.filter { $0 is CMOSRTC }.first as? CMOSRTC
    }
}

// FIXME: This is unsafe, needs atomic read/write or some locking
private var ticks: UInt64 = 0

func timerCallback() {
    ticks = ticks &+ 1
    if (ticks % 0x200) == 0 {
        //printf("\ntimerInterrupt: %#016X\n", ticks)
    }
    // Do nothing for now
}

