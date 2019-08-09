//
//  kernel/devices/devicemanager.swift
//  acpi
//
//  Created by Simon Evans on 07/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//


class Device {
}


class UnknownDevice: Device, CustomStringConvertible {
    let _description: String
    var description: String { _description }

    override init() {
        _description = "Unknown Device:"
    }

    init?(parentBus: Bus, pnpName: String? = nil, acpiNode: ACPIGlobalObjects.ACPIObjectNode? = nil,
         acpiFullName: String? = nil) {
        _description = "Unknown Device: \(pnpName ?? "") \(acpiFullName ?? "")"
    }
}


class Bus: Device {
    private(set) var devices: [Device] = []
    let parentBus: Bus?
    let fullName: String
    let acpi: ACPIGlobalObjects.ACPIObjectNode


    init(parentBus: Bus, acpi: ACPIGlobalObjects.ACPIObjectNode, fullName: String) {
        self.acpi = acpi
        self.fullName = fullName
        self.parentBus = parentBus
    }

    init(acpi: ACPIGlobalObjects.ACPIObjectNode, fullName: String) {
        self.acpi = acpi
        self.fullName = fullName
        self.parentBus = nil
    }

    func addDevice(_ device: Device) {
        print("\(self): Adding", device)
        devices.append(device)
    }

    func device(parentBus: Bus, pnpName: String, acpiNode: ACPIGlobalObjects.ACPIObjectNode? = nil, acpiFullName: String? = nil) -> Device? {
        print("DevinceManager.device1")
        return nil
    }

    func device(parentBus: Bus, address: UInt32, acpiNode: ACPIGlobalObjects.ACPIObjectNode, acpiFullName: String) -> Device? {
        print("DevinceManager.device2")
            return nil
    }

    func unknownDevice(parentBus: Bus, pnpName: String? = nil, acpiNode: ACPIGlobalObjects.ACPIObjectNode? = nil, acpiFullName: String? = nil) -> UnknownDevice? {
        return UnknownDevice(parentBus: parentBus, pnpName: pnpName, acpiNode: acpiNode, acpiFullName: acpiFullName)
    }


    func initialiseDevices(name: String) {
        acpi.childNodes.forEach {
            let child = $0
            let fullName = (name == "\\") ? name + child.name :
                name + String(AMLNameString.pathSeparatorChar) + child.name
            processNode(parentBus: self, child, fullName)
        }
    }

    // FIXME: Rename processPNPDevices or somesuch
    func processNode(parentBus: Bus, _ node: ACPIGlobalObjects.ACPIObjectNode, _ name: String) {
        guard let device = node.object as? AMLDefDevice else {
            return
        }

        let fullName = name
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(fullName),
                                               args: [],
                                               globalObjects: system.deviceManager.acpiTables.globalObjects)

        let status = device.status(context: &context)
        if !(status.present && status.enabled) {
            return
        }

        var foundDevice: Device? = nil
        let deviceId = device.hardwareId(context: &context) ?? device.pnpName(context: &context)

        if let pnpName = deviceId, let crs = device.currentResourceSettings(context: &context) {
            let deviceManager = system.deviceManager
            let im = deviceManager.interruptManager

            switch pnpName {

                case "PNP0A00": // ISABus
                    foundDevice = ISABus(parentBus: parentBus, acpi: node, fullName: fullName)

                case "PNP0A03", "PNP0A08": // PCIBus, PCI Express
                    foundDevice = PCIBus.createBus(parentBus: parentBus, acpi: node, fullName: fullName, busID: 0)

                case "PNP0100":
                    if let timer = PIT8254(interruptManager: im, pnpName: "PNP0100",
                                           resources: ISABus.extractCRSSettings(crs),
                                           facp: nil) {
                        deviceManager.addDevice(timer)
                        foundDevice = timer
                }

                case "PNP0B00":
                    if let cmos = CMOSRTC(interruptManager: im,
                                          pnpName: pnpName,
                                          resources: ISABus.extractCRSSettings(crs),
                                          facp: deviceManager.acpiTables.facp
                        ) {
                        print(cmos)
                        deviceManager.addDevice(cmos)
                        foundDevice = cmos
                }

                default: // "PNP0A01", "PNP0A02", "PNP0A04", "PNP0A05", "PNP0A06":
                    foundDevice = self.unknownDevice(parentBus: parentBus, pnpName: pnpName, acpiNode: node, acpiFullName: fullName) ??
                        UnknownDevice(parentBus: parentBus, pnpName: pnpName, acpiNode: node, acpiFullName: fullName)
            }
        } else if let address = device.addressResource(context: &context) {
            if let device = self.device(parentBus: self, address: UInt32(address), acpiNode: node, acpiFullName: fullName) {
                foundDevice = device
            } else {
                foundDevice = UnknownDevice(parentBus: parentBus, pnpName: nil, acpiNode: node, acpiFullName: fullName)
            }
        }

        if let bus = foundDevice as? Bus {
            bus.initialiseDevices(name: name)
        }

        if let dev = foundDevice {
            parentBus.addDevice(dev)
        }
    }
}


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
    let acpiTables: ACPI
    let systemBusRoot: ACPIGlobalObjects.ACPIObjectNode
    private(set) var interruptManager: InterruptManager
    private(set) var devices: [Device] = []
    private(set) var masterBus: Bus


    init(acpiTables: ACPI) {
        acpiTables.parseAMLTables()
        guard let (sb, sbFullName) = acpiTables.globalObjects.getGlobalObject(currentScope: AMLNameString("\\"),
                                                                        name: AMLNameString("_SB")) else {
            fatalError("No \\_SB system bus node")
        }
        self.systemBusRoot = sb
        self.acpiTables = acpiTables
        interruptManager = InterruptManager(acpiTables: acpiTables)
        set_interrupt_manager(&interruptManager)
        masterBus = Bus(acpi: sb, fullName: sbFullName)
    }


    func initialiseDevices() {
        masterBus.initialiseDevices(name: "\\_SB")

        // Set the timer interrupt for 20Hz
        if let timer = timer {
            _ = timer.enablePeriodicInterrupt(hz: 20, timerCallback)
            print(timer)
        }
        TTY.sharedInstance.scrollTimingTest()
        dumpDeviceTree()
    }

    func addDevice(_ device: Device) {
        devices.append(device)
    }


    private func dumpBus(_ bus: Bus, depth: Int) {
        let spaces = String(repeating: " ", count: depth * 6)
        for device in bus.devices {
            print("\(spaces)+--- \(device)")
            if let bus = device as? Bus {
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

