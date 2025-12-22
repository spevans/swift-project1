//
//  kernel/devices/devicemanager.swift
//  acpi
//
//  Created by Simon Evans on 07/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//



private(set) var interruptManager = InterruptManager()

final class DeviceManager {
    let acpiTables: ACPI

    private(set) var masterBus: MasterBus

    var keyboard: Keyboard?
    var mouse: Mouse?
    var timer: Timer?
    var rtc: CMOSRTC?
    private(set)var usb: USB?


    init(acpiTables: ACPI) {
        acpiTables.parseAMLTables()
        guard let (sb, _) = ACPI.globalObjects.getGlobalObject(currentScope: AMLNameString("\\"),
                                                                     name: AMLNameString("_SB")) else {
            fatalError("No \\_SB system bus node")
        }
        self.acpiTables = acpiTables
        interruptManager.setup(with: acpiTables)
        withUnsafePointer(to: &interruptManager) {
            set_interrupt_manager($0)
        }
        masterBus = MasterBus(acpiSystemBus: sb)
    }



    // Setup devices required for other device setup. This includes timers which are used to
    // implement sleep() etc, used by more complex devices eg USB Host Controllers when initialising.
    // Currently this setups all of the pnp ISA devices but this should be restricted to timers.
    func initialiseEarlyDevices() {
        #kprint("initialiseEarlyDevices start, device manager has \(masterBus.device.devices.count) devices")

        interruptManager.enableGpicMode()
        initPNPDevice(withName: "PNP0C0F")  // PCI Interrupt Link Devices
         // Look for a PIT timer and add to device tree if found
        // Look for an HPET timer
        if initPNPDevice(withName: "PNP0103") || initPNPDevice(withName: "PNP0C01") {
            #kprint("Found an HPET")
        } else {
            if initPNPDevice(withName: "PNP0100") {
                #kprint("Found a PIT")
            }
        }
        guard setupPeriodicTimer() else {
            koops("Cannot find a HPET or PIT to use for periodic clock")
        }
    }

    @discardableResult
    private func initPNPDevice(withName pnpName: String) -> Bool {
        var found = false
        walkDeviceTree(bus: masterBus.device) { device in
            if _initPnpDevice(device: device, isPCIHost: false, matchingId: pnpName) {
                found = true
            }
            return true
        }
        return found
    }


    private func _initPnpDevice(device: Device, isPCIHost: Bool = false, matchingId: String? = nil) -> Bool {
        guard device.deviceDriver == nil else {
            return false
        }

        guard let pnpDevice = device as? PNPDevice else {
            return false
        }

        guard isPCIHost == pnpDevice.isPCIHost else { return false }
        if let matchingId = matchingId, !pnpDevice.matchesId(matchingId) { return false }
        guard let driver = PNPDevice.initPnpDevice(pnpDevice) else { return false }
        guard driver.initialise() else {
            #kprint("\(driver) initialisation failed")
            return false
        }
        return true
    }

    private func initPnpDevices() {
        #kprint("Initing other PNP devices")
        walkDeviceTree(bus: masterBus.device) { device in
            _ = _initPnpDevice(device: device, isPCIHost: false)
            return true
        }
        #kprint("Initialising PCI hosts")
        walkDeviceTree(bus: masterBus.device) { device in
            if _initPnpDevice(device: device, isPCIHost: true) {
                #kprint("Found PCI Host:", device)
                setPCIHostBus(device)
                return false
            }
            return true
        }
    }


    // Setup the rest of the devices.
    func initialiseDevices() {
        #kprint("MasterBus.initialiseDevices")
        // Now load device drivers for any known devices, ISA/PNP first
        initPnpDevices()

        if let rootPCIBus = pciHostBus {
            #kprint("Initialising USB")
            usb = USB()
            usb?.initialiseDevices(rootPCIBus: rootPCIBus)
            #kprint("USB initialised, looking at rest of devices")

            rootPCIBus.devicesMatching() { (device: PCIDevice, deviceClass: PCIDeviceClass) in
                guard !device.initialised else {
                    // TODO: initialise PCI devices
                    return
                }
            }
            return
        } else {
            #kprint("Error: Cant Find ROOT PCI Bus")
        }
    }


    func setIrqHandler(_ handler: InterruptHandler, forInterrupt: IRQSetting) {
        interruptManager.setIrqHandler(handler, forInterrupt: forInterrupt)
    }

    func enableIRQs(){
        interruptManager.enableIRQs()
    }


    private func dumpBus(_ bus: Device, depth: Int) {
        let spaces = String(repeating: " ", count: depth * 6)
        for device in bus.devices {
            let driverName = if let driver = device.deviceDriver {
                #sprintf(" driver: %s instance: %s",
                         driver.driverName, driver.instanceName)
            } else {
                ""
            }
            #kprintf("%s+---- %s busdev: %s%s\n", spaces, device.deviceName,
                     device.busDeviceName, driverName)
            if device.isBus {
                dumpBus(device, depth: depth + 1)
            }
        }
    }


    func dumpDeviceTree() {
        #kprint(masterBus.device.deviceName, masterBus.description)
        dumpBus(masterBus.device, depth: 0)
    }

    func walkDeviceTree(bus: Device, body: (Device) -> Bool) {

        for device in bus.devices {
            if !body(device) {
                return
            }
            if device.isBus {
                walkDeviceTree(bus: device, body: body)
            }
        }
    }


    func dumpPCIDevices() {
        guard let rootPCIBus = pciHostBus else {
            #kprint("No PCI bus found")
            return
        }
        var devices: [PCIDevice] = []
        walkDeviceTree(bus: rootPCIBus.busDevice) { device in
            if let d = device as? PCIDevice {
                devices.append(d)
            }
            return true
        }
        for device in devices.sorted(by: { $0.deviceFunction < $1.deviceFunction }) {
            #kprintf("%s => %s [%s]\n", device.deviceName, device.description,
                     device.deviceDriver?.description ?? "")
        }
    }

    func dumpPNPDevices() {
        walkDeviceTree(bus: masterBus.device) { device in
            if let d = device as? PNPDevice {
                #kprintf("%s => %s [%s]\n", d.deviceName, d.description,
                         d.deviceDriver?.description ?? "")
            }
            return true
        }
    }

    func dumpUSBDevices() {
        walkDeviceTree(bus: masterBus.device) { device in
            if let d = device as? USBDevice {
                #kprintf("%s => %s [%s]\n", d.deviceName, d.description,
                         d.deviceDriver?.description ?? "")
            }
            return true
        }
    }

    func getDeviceByName(_ devname: String) -> Device? {
        var found: Device?
        walkDeviceTree(bus: masterBus.device) { device in
            if device.deviceName == devname {
                found = device
                return false    // stop searching
            }
            return true
        }
        return found
    }
}
