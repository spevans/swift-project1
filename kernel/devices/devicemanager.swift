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
    let description: String

    init(parentBus: Bus, pnpName: String? = nil, acpiNode: ACPIGlobalObjects.ACPIObjectNode? = nil,
         acpiFullName: String? = nil) {
        description = "Unknown Device: \(pnpName ?? "") \(acpiFullName ?? "")"
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


    func initialiseDevices() {
        let name = "\\_SB"
        processNode(parentBus: self, acpi, name)
        acpi.childNodes.forEach {
            let child = $0
            let fullName = (name == "\\") ? name + child.name :
                name + String(AMLNameString.pathSeparatorChar) + child.name
            processNode(parentBus: self, child, fullName)
        }
    }

    // FIXME: Rename processPNPDevices or somesuch
    func processNode(parentBus: Bus, _ node: ACPIGlobalObjects.ACPIObjectNode, _ name: String) {
        let fullName = name
        guard let device = node.object as? AMLDefDevice else {
            return
        }

        var foundDevice: Device? = nil
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(fullName),
                                               args: [],
                                               globalObjects: system.deviceManager.acpiTables.globalObjects)
        if let pnpName = device.pnpName(context: &context) {
            switch pnpName {
            case "PNP0A00": // ISABus
                print("Found ISA Bus:", fullName)
                foundDevice = ISABus(parentBus: parentBus, acpi: node, fullName: fullName)

            case "PNP0A03": // PCIBus
                print("Found PCI Bus:", fullName)
                foundDevice = PCI.createBus(parentBus: parentBus, acpi: node, fullName: fullName, busID: 0)

            default: // "PNP0A01", "PNP0A02", "PNP0A04", "PNP0A05", "PNP0A06":
                foundDevice = UnknownDevice(parentBus: self, pnpName: pnpName,
                                             acpiNode: node, acpiFullName: fullName)
            }
        } else if let address = device.addressResource(context: &context) {
            let name = "_ADR: 0x\(String(address, radix: 16))"
            foundDevice = UnknownDevice(parentBus: self, pnpName: name, acpiNode: node, acpiFullName: fullName)
        }
        if let dev = foundDevice {
            parentBus.addDevice(dev)
            if let bus = dev as? Bus {
                bus.initialiseDevices()
            }
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
        masterBus.initialiseDevices()

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

