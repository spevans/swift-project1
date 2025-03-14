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
    private(set) var masterBus: MasterBus

    var keyboard: Keyboard?
    var timer: Timer?
    var rtc: CMOSRTC?


    init(acpiTables: ACPI) {
        acpiTables.parseAMLTables()
        guard let (sb, _) = ACPI.globalObjects.getGlobalObject(currentScope: AMLNameString("\\"),
                                                                     name: AMLNameString("_SB")) else {
            fatalError("No \\_SB system bus node")
        }
        self.acpiTables = acpiTables
        interruptManager = InterruptManager(acpiTables: acpiTables)
        set_interrupt_manager(&interruptManager)
        masterBus = MasterBus(acpiSystemBus: sb)
    }



    // Setup devices required for other device setup. This includes timers which are used to
    // implement sleep() etc, used by more complex devices eg USB Host Controllers when initialising.
    // Currently this setups all of the pnp ISA devices but this should be restricted to timers.
    func initialiseEarlyDevices() {
        print("initialiseEarlyDevices start, device manager has \(masterBus.device.devices.count) devices")

        interruptManager.enableGpicMode()
        initPNPDevice(withName: "PNP0C0F")  // PCI Interrupt Link Devices
         // Look for a PIT timer and add to device tree if found
        if !initPNPDevice(withName: "PNP0103") {
            initPNPDevice(withName: "PNP0C01") // Look for an HPET timer
        }
        initPNPDevice(withName: "PNP0100")
        guard setupPeriodicTimer() else {
            koops("Cant find a timer to use for periodic clock")
        }
    }

    @discardableResult
    private func initPNPDevice(withName pnpName: String) -> Bool {
        var found = false
        walkDeviceTree() { device in
            if _initPnpDevice(device: device, isPCIHost: false, matchingId: pnpName) {
                found = true
            }
            return true
        }
        return found
    }

    private func pnpDevices(pnpName: String, body: (Device) -> ()) {
        walkDeviceTree() { device in
            if let config = device.acpiDeviceConfig, config.matches(hidOrCid: pnpName) {
                print("** found pnp device", config)
                body(device)
            }
            return true
        }
    }


    private func _initPnpDevice(device: Device, isPCIHost: Bool = false, matchingId: String? = nil) -> Bool {
        guard device.deviceDriver == nil else {
            return false
        }

        guard let pnpDevice = device.busDevice as? PNPDevice else {
            return false
        }

        guard isPCIHost == pnpDevice.isPCIHost else { return false }
        if let matchingId = matchingId, !pnpDevice.matchesId(matchingId) { return false }
        guard let driver = PNPDevice.initPnpDevice(pnpDevice) else { return false }
        device.setDriver(driver)
        guard driver.initialise() else {
            print("\(driver) initialisation failed")
            return false
        }
        return true
    }

    private func initPnpDevices() {
        print("Initing other PNP devices")
        walkDeviceTree() { device in
            _ = _initPnpDevice(device: device, isPCIHost: false)
            return true
        }
        print("Initialising PCI hosts")
        walkDeviceTree() { device in
            if _initPnpDevice(device: device, isPCIHost: true) {
                print("Found PCI Host:", device)
                return false
            }
            return true
        }
    }


    // Setup the rest of the devices.
    func initialiseDevices() {
        print("MasterBus.initialiseDevices")
        // Now load device drivers for any known devices, ISA/PNP first
        initPnpDevices()

        print("Initialising USB")
        usbBus = USB()
        usbBus.initialiseDevices()
        print("USB initialised, looking at rest of devices")

        if let rootPCIBus = masterBus.rootPCIBus() {
            rootPCIBus.devicesMatching() { (device: PCIDevice, deviceClass: PCIDeviceClass) in
                guard !device.device.initialised else { return }
            }
        } else {
            print("Error: Cant Find ROOT PCI Bus")
        }

        tty.scrollTimingTest()
        dumpDeviceTree()
    }

    private func dumpBus(_ bus: Device, depth: Int) {
        let spaces = String(repeating: " ", count: depth * 6)
        for device in bus.devices {
            var driverName = ""
            if let driver = device.deviceDriver { driverName = ": [\(driver.description)]" }
            print("\(spaces)+--- \(device)\(driverName) [init: \(device.initialised) enab: \(device.enabled)]")
            if device.isBus {
                dumpBus(device, depth: depth + 1)
            }
        }
    }


    func dumpDeviceTree() {
        print(masterBus)
        dumpBus(masterBus.device, depth: 0)
    }

    func walkDeviceTree(bus: Device? = nil, body: (Device) -> Bool) {
        for device in (bus ?? masterBus.device).devices {
            if !body(device) {
                return
            }
            if device.isBus {
                walkDeviceTree(bus: device, body: body)
            }
        }
    }


    func dumpPCIDevices(bus: Device? = nil) {
        walkDeviceTree(bus: bus) { device in
            if let d = device.busDevice as? PCIDevice {
                print(d)
            }
            return true
        }
    }

    func dumpPNPDevices(bus: Device? = nil) {
        walkDeviceTree(bus: bus) { device in
            if let d =  device.busDevice as? PNPDevice {
                print(d)
            }
            return true
        }
    }
}
