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

    var keyboard: Keyboard?
    var timer: Timer?
    var rtc: CMOSRTC?

    init(acpiTables: ACPI) {
        acpiTables.parseAMLTables()
        guard let (sb, _) = acpiTables.globalObjects.getGlobalObject(currentScope: AMLNameString("\\"),
                                                                     name: AMLNameString("_SB")) else {
            fatalError("No \\_SB system bus node")
        }
        self.acpiTables = acpiTables
        interruptManager = InterruptManager(acpiTables: acpiTables)
        set_interrupt_manager(&interruptManager)
        masterBus = MasterBus(acpiSystemBus: sb)
    }


    func findPNPDevice(withName pnpName: String) {
        pnpDevices(on: masterBus, pnpName: pnpName) { pnpDevice in
            print("Found early PNP device:", pnpDevice)
            initPnpDevice(pnpDevice)
        }
    }


    // Setup devices required for other device setup. This includes timers which are used to
    // implement sleep() etc, used by more complex devices eg USB Host Controllers when initialising.
    // Currently this setups all of the pnp ISA devices but this should be restricted to timers.
    func initialiseEarlyDevices() {
        print("initialiseEarlyDevices start")
        interruptManager.enableGpicMode()

        // Step 1. Assign a Device (PCIDevice, PNPDevice) to every ACPI AMLDefDevice Node
        // Devices arent initialised except for Buses/Bridges which are needed to allow the Devices under them
        // to have the correct resource (esp PCIDevices)
        //masterBus.initialiseDevices(acpiDevice: nil)
        _ = masterBus.initialise()

        // Step 2.
        // Check that every AMLDefDevice in the ACPI tree has a Device set
        masterBus.acpiSystemBus.walkNode { (name, object) in
            guard let amldev = object as? AMLDefDevice else { return }
            if let device = amldev.device {
                print("DEV: \(name): \(device)")
            } else {
                print("DEV: \(name) has no device set")
            }
        }

        // Step 3:
        // Walk the device tree and for any Buses, call initialiseDevice() to allow
        // the underlying hardware to be setup correectly (calling ._INI) and also
        // scan the buss for extra devices not in ACPI (eg on PCI busses)
        walkDeviceTree() { device in
            if let bus = device.deviceDriver, bus is Bus {
                print("DEV: Secondary initialisation of \(bus)")
                if !bus.initialise() {
                    print("DEV: Failed to initialise \(bus)")
                }
            }
        }

        dumpPNPDevices()
        findPNPDevice(withName: "PNP0100")  // Look for a PIT timer and add to device tree if found
        findPNPDevice(withName: "PNP0C0F")  // PCI Interrupt Link Devices
        guard setupPeriodicTimer() else {
            koops("Cant find a timer to use for periodic clock")
        }
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


    private func initPnpDevices(on bus: Bus) {
        for device in bus.devices {
            if let bus = device.deviceDriver as? Bus {
                initPnpDevices(on: bus)
                continue
            }
            guard let pnpDevice = device as? PNPDevice else { continue }
            initPnpDevice(pnpDevice)
        }
    }


    private func initPnpDevice(_ pnpDevice: PNPDevice) {
        guard pnpDevice.deviceDriver == nil else { return }
        guard let driverType = pnpDriverById(pnpName: pnpDevice.pnpName) else {
            print("Cant find driver for:", pnpDevice.pnpName)
            return
        }
        guard pnpDevice.initialise() else {
            print("PNP: Cant initialise \(pnpDevice.pnpName)")
            return
        }
        guard let driver = driverType.init(pnpDevice: pnpDevice) else {
            print("PNP: Cant init \(pnpDevice.pnpName) with driver")
            return
        }
        if driver.initialise() {
            pnpDevice.setDriver(driver)
            system.deviceManager.addDevice(driver)
        } else {
            print("Couldnt initialise device")
        }
    }


    // Setup the rest of the devices.
    func initialiseDevices() {
        print("MasterBus.initialiseDevices")
        // Now load device drivers for any known devices, ISA/PNP first
        initPnpDevices(on: masterBus)

        print("Initialising USB")
        usbBus = USB()
        usbBus.initialiseDevices()
        print("USB initialised, looking at rest of devices")

        if let rootPCIBus = masterBus.rootPCIBus() {
            rootPCIBus.devicesMatching() { (device: PCIDevice, deviceClass: PCIDeviceClass) in
                guard device.deviceDriver == nil else { return }
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
            var driverName = ""
            if let driver = device.deviceDriver { driverName = ": [\(driver)]" }
            print("\(spaces)+--- \(device)\(driverName)")
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


    func walkDeviceTree(bus: Bus? = nil, body: (Device) -> ()) {
        for device in (bus ?? masterBus).devices {
            body(device)
            if let bus = device.deviceDriver as? Bus {
                walkDeviceTree(bus: bus, body: body)
            }
        }
    }


    func dumpPCIDevices(bus: Bus? = nil) {
        walkDeviceTree(bus: bus) { device in
            if let pciDevice = device as? PCIDevice {
                print(pciDevice)
            }
        }
    }

    func dumpPNPDevices(bus: Bus? = nil) {
        walkDeviceTree(bus: bus) { device in
            if let pnpDevice = device as? PNPDevice {
                print(pnpDevice)
            }
        }
    }
}
