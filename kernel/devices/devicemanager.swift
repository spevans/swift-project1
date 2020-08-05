//
//  kernel/devices/devicemanager.swift
//  acpi
//
//  Created by Simon Evans on 07/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//


class Device {
    unowned let parentBus: Bus?
    let fullName: String
    let acpiDevice: AMLDefDevice?

    init(parentBus: Bus? = nil, acpiDevice: AMLDefDevice? = nil) {
        self.acpiDevice = acpiDevice
        self.fullName = acpiDevice?.fullname() ?? ""
        self.parentBus = parentBus
    }
}


class UnknownDevice: Device, CustomStringConvertible {

    let pnpName: String
    var description: String { "Unknown device: \(pnpName) \(fullName)" }

    init?(parentBus: Bus, pnpName: String? = nil, acpiDevice: AMLDefDevice? = nil) {
        self.pnpName = pnpName ?? ""
        super.init(parentBus: parentBus, acpiDevice: acpiDevice)
    }
}


class MasterBus: Bus {
    let acpiSystemBus: ACPI.ACPIObjectNode

    init(acpiSystemBus: ACPI.ACPIObjectNode) {
        self.acpiSystemBus = acpiSystemBus
        super.init(parentBus: nil, acpiDevice: nil)
    }

    override func initialiseDevices() {
        for (_, value) in acpiSystemBus.childNodes {
            if let device = value as? AMLDefDevice {
                processNode(parentBus: self, device)
            }
        }
    }
}


class Bus: Device {
    private(set) var devices: [Device] = []


    func addDevice(_ device: Device) {
        devices.append(device)
    }

    func sortDevices(by body: (Device, Device) -> Bool) {
        devices.sort(by: body)
    }

    func device(parentBus: Bus, pnpName: String, acpiDevice: AMLDefDevice? = nil) -> Device? {
        return nil
    }

    func device(parentBus: Bus, address: UInt32, acpiDevice: AMLDefDevice) -> Device? {
        return nil
    }

    func unknownDevice(parentBus: Bus, pnpName: String? = nil, acpiDevice: AMLDefDevice? = nil) -> UnknownDevice? {
        return UnknownDevice(parentBus: parentBus, pnpName: pnpName, acpiDevice: acpiDevice)
    }


    func initialiseDevices() {
        guard let acpi = self.acpiDevice else { return }
        for (_, value) in acpi.childNodes {
            if let device = value as? AMLDefDevice {
                processNode(parentBus: self, device)
            }
        }
    }

    // FIXME: Rename processPNPDevices or somesuch
    func processNode(parentBus: Bus, _ node: AMLDefDevice) {

        let status = node.status()
        if !(status.present && status.enabled) {
            //print("DEV: Ignoring", node.fullname(), "as status present:", status.present, "enabled:", status.enabled)
            return
        }

        var foundDevice: Device? = nil
        let deviceId = node.hardwareId() ?? node.pnpName()

        if let pnpName = deviceId, let crs = node.currentResourceSettings() {
            let deviceManager = system.deviceManager
            let im = deviceManager.interruptManager

            switch pnpName {

                case "PNP0A00": // ISABus
                    foundDevice = ISABus(parentBus: parentBus, acpiDevice: node)

                case "PNP0A03", "PNP0A08": // PCIBus, PCI Express
                    let _address = node.addressResource()
                    if _address == nil {
                        print("Cant get addressResource for \(node.fullname())")
                    }
                    // FIXME, is it ok to default _ADR and _BBN to 0?
                    let address = _address ?? 0

                    // FIXME: _BBN should be a method 'busNumbers()' on a DefDevice
                    var busId: UInt8 = 0
                    var p: ACPI.ACPIObjectNode? = node
                    while let _node = p {
                        if let bbnNode = _node.childNode(named: "_BBN") as? AMLDefName {
                            let bbnValue = bbnNode.value.integerValue!
                            busId = UInt8(bbnValue)
                            break
                        }
                        p = _node.parent
                    }
                    let device = UInt8(address >> 16)
                    let function = UInt8(truncatingIfNeeded: address)
                    if let deviceFunction = PCIDeviceFunction(busId: busId, device: device, function: function) {
                        foundDevice = PCIBus(parentBus: self, deviceFunction: deviceFunction, acpiDevice: node)
                    }


                case "PNP0100":
                    if let timer = PIT8254(parentBus: self, interruptManager: im, pnpName: "PNP0100",
                                           resources: ISABus.Resources(crs),
                                           facp: nil) {
                        deviceManager.addDevice(timer)
                        foundDevice = timer
                }

                case "PNP0B00":
                    if let cmos = CMOSRTC(parentBus: self, interruptManager: im,
                                          pnpName: pnpName,
                                          resources: ISABus.Resources(crs),
                                          facp: deviceManager.acpiTables.facp
                        ) {
                        print(cmos)
                        deviceManager.addDevice(cmos)
                        foundDevice = cmos
                }

                case "QEMU0002":
                    foundDevice = QEMUFWCFG(parentBus: self, acpiDevice: node)


                default: // "PNP0A01", "PNP0A02", "PNP0A04", "PNP0A05", "PNP0A06":
                    foundDevice = self.unknownDevice(parentBus: parentBus, pnpName: pnpName, acpiDevice: node) ??
                        UnknownDevice(parentBus: parentBus, pnpName: pnpName, acpiDevice: node)
            }
        } else if deviceId == "PNP0A05" || deviceId == "PNP0A06" {
            // ISA Generic Contrainer device, can have sub devices
            for (_, value) in node.childNodes {
                if let device = value as? AMLDefDevice {
                    self.processNode(parentBus: self, device)
                }
            }
        } else if let address = node.addressResource() {
            if let device = self.device(parentBus: self, address: UInt32(address), acpiDevice: node) {
                foundDevice = device
            } else {
                foundDevice = UnknownDevice(parentBus: parentBus, pnpName: nil, acpiDevice: node)
            }
        }

        if let dev = foundDevice {
            parentBus.addDevice(dev)
        }

        if let bus = foundDevice as? Bus {
            bus.initialiseDevices()
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
    private(set) var interruptManager: InterruptManager
    private(set) var devices: [Device] = []
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
        masterBus = MasterBus(acpiSystemBus: sb)
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

