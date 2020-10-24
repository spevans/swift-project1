//
//  kernel/devices/devicemanager.swift
//  acpi
//
//  Created by Simon Evans on 07/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//


internal var usbBus: USB!

final class DeviceManager {
    let acpiTables: ACPI
    private(set) var interruptManager: InterruptManager
    private(set) var devices: [DeviceDriver] = []
    private(set) var masterBus: MasterBus


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


    private func pnpDevices(on bus: Bus, pnpName: String, body: (PNPDevice) -> ()) {
        for device in bus.devices {
            if let pnpDevice = device as? PNPDevice, pnpDevice.pnpName == pnpName {
                body(pnpDevice)
            }
            if let bus = device.deviceDriver as? Bus {
                pnpDevices(on: bus, pnpName: pnpName, body: body)
            }
        }
    }


    // Setup devices required for other device setup. This includes timers which are used for to
    // implement sleep() etc, used by more complex devices eg USB Host Controllers when initialising.
    // Currently this setups all of the pnp ISA devices but this should be restricted to timers.
    func initialiseEarlyDevices() {
        print("initialiseEarlyDevices start")
        masterBus.initialiseDevices(acpiDevice: nil)

        // Find a timer
        pnpDevices(on: masterBus, pnpName: "PNP0100") {
            guard let pnpDevice = $0 as? ISADevice, pnpDevice.pnpDeviceDriver == nil else { return }
            if let driverType = pnpDriverById(pnpName: pnpDevice.pnpName), let driver = driverType.init(pnpDevice: pnpDevice) {
                print("Found early PNP device:", driverType)
                pnpDevice.pnpDeviceDriver = driver
                system.deviceManager.addDevice(driver)
            }
        }

        // Set the timer interrupt for 1kHz
        if let timer = timer {
            _ = timer.enablePeriodicInterrupt(hz: 1000, timer_callback)
            print(timer)
            print("Timer setup for 1000Hz")
        } else {
            fatalError("Cant find a timer")
        }
        print("initialiseEarlyDevices done")
    }

    // Setup the rest of the devices.
    func initialiseDevices() {
        print("MasterBus.initialiseDevices")
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

        print("Initialising USB")
        usbBus = USB()
        usbBus.initialiseDevices()
        print("USB initialised, looking at rest of devices")
        if let rootPCIBus = masterBus.rootPCIBus() {
            rootPCIBus.devicesMatching() {
                print("Found pcidevice: \($0) deviceClass: \($1)")
                guard $0.pciDeviceDriver == nil else { return }
            }
        } else {
            print("Error: Cant Find ROOT PCI Bus")
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


public func sleep(milliseconds: Int) {
    let current = current_ticks()
    let required = current + UInt64(milliseconds)
    //print("Sleeping for \(milliseconds), current ticks:", current, "required ticks:", required)
    while required > current_ticks() {
        hlt()
    }
    //print("Ticks now:", current_ticks())
}
