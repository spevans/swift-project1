//
//  kernel/devices/isa.swift
//
//
//  Created by Simon Evans on 06/12/2017.
//  Copyright © 2017 - 2018 Simon Evans. All rights reserved.
//

// There is only one ISA (EISA) bus and it owns all of the I/O address space
// which is defined as ports 0 - 0xffff accessed via the IN & OUT instructions.


final class ISADevice: Device, PNPDevice, CustomStringConvertible {
    unowned let parentBus: Bus
    let acpiDevice: AMLDefDevice?
    let fullName: String
    var enabled = false

    let pnpName: String
    let resources: ISABus.Resources
    var pnpDeviceDriver: PNPDeviceDriver?   // FIXME: setter should be private
    var deviceDriver: DeviceDriver? { pnpDeviceDriver as DeviceDriver? }

    var description: String { "ISA: \(pnpName) \(fullName) \(resources)" }

    init(parentBus: Bus, pnpName: String, acpiDevice: AMLDefDevice? = nil, resources: ISABus.Resources? = nil) {
        self.acpiDevice = acpiDevice
        self.parentBus = parentBus
        self.pnpName = pnpName

        if let acpi = acpiDevice {
            if let resources = resources {
                self.resources = resources
            } else {
                if let crs = acpi.currentResourceSettings() {
                    self.resources = ISABus.Resources(crs)
                } else {
                    self.resources = ISABus.Resources([])
                }
            }
            self.fullName = acpi.fullname()
        } else {
            self.resources = (resources == nil) ? ISABus.Resources([]) : resources!
            self.fullName = pnpName
        }
    }

    func initialiseDevice() {
    }
}


final class ISABus: PCIDeviceDriver, Bus, CustomStringConvertible {
    private unowned let pciDevice: PCIDevice
    private var isaDevices: [ISADevice] = []

    var resources: [MotherBoardResource] = []
    var devices: [Device] { isaDevices.map { $0 as Device }}

    let rs = ReservedSpace(name: "IO Ports", start: 0, end: 0xfff)
    var description: String { "ISABus: \(pciDevice.acpiDevice?.fullname() ?? "")" }


    init?(pciDevice: PCIDevice) {
        self.pciDevice = pciDevice
        print("Initialising ISABus, acpi:", pciDevice.acpiDevice?.fullname() ?? "unknown")
    }

    func device(acpiDevice: AMLDefDevice, pnpName: String? = nil) -> Device? {
        guard let pnpName = pnpName else { return nil }
        return ISADevice(parentBus: self, pnpName: pnpName, acpiDevice: acpiDevice)
    }

    func addDevice(_ device: Device) {
        guard let isaDevice = device as? ISADevice else {
            fatalError("\(self): trying to add device of type \(device) to ISABus")
        }
        isaDevices.append(isaDevice)
    }

    func initialiseDevice() {
        initialiseDevices(acpiDevice: pciDevice.acpiDevice)
    }

    func initialiseDevices(acpiDevice: AMLDefDevice?) {
        guard let acpi = acpiDevice else {
            print("ISABus: initialiseDevices: No ACPI node")
            return
        }

        // PS2 is split over 2 devices (keyboard, mouse) so need to gather these
        // up beforehand.
        var ps2keyboard: [AMLResourceSetting] = []
        var ps2mouse: [AMLResourceSetting] = []

        for (_, node) in acpi.childNodes {
            guard let child = node as? AMLDefDevice else {
                continue
            }

            if let deviceId = child.pnpName() ?? child.hardwareId(),
                let crs = child.currentResourceSettings() {
                switch deviceId {
                    case "PNP0303", "PNP030B":
                        ps2keyboard = crs
                        continue

                    case "PNP0F03", "PNP0F13":
                        ps2mouse = crs
                        continue

                    default:
                        break
                }
            }
            ACPI.processNode(parentBus: self, child)
        }

        if !ps2keyboard.isEmpty {
            ps2keyboard.append(contentsOf: ps2mouse)
            // FIXME: KBD8042 should really be some sort of BusDevice that adds its
            // sub devices.
            let resources = ISABus.Resources(ps2keyboard)
            let device = ISADevice(parentBus: self, pnpName: "PNP0303", acpiDevice: acpiDevice, resources: resources)
            if let driverType = pnpDriverById(pnpName: "PNP0303"), let driver = driverType.init(pnpDevice: device) {
                device.pnpDeviceDriver = driver
                self.addDevice(device)
                if let keyboard = (driver as? KBD8042)?.keyboardDevice {
                    system.deviceManager.addDevice(keyboard)
                }
            }
        }
        isaDevices.sort { $0.fullName < $1.fullName }
    }
}


extension ISABus {
    // Resources used by a device
    struct Resources: CustomStringConvertible {
        let ioPorts: [ClosedRange<UInt16>]
        let interrupts: [UInt8]
        let dmaChannels: [UInt8]
        let fixedMemoryRanges: [(Range<UInt32>, Bool)]


        var description: String {
            var s = ""
            if !ioPorts.isEmpty {
                s = "io: " + ioPorts.map {
                    $0.count == 1 ? "0x\(String($0.lowerBound, radix: 16))"
                        : "0x\(String($0.lowerBound, radix: 16))-0x\(String($0.upperBound, radix: 16))"
                }.joined(separator: ", ")
            }
            if !interrupts.isEmpty {
                let irq = "irq: " + interrupts.map { String($0) }.joined(separator: ", ")
                if !s.isEmpty { s += " " }
                s += irq
            }
            if !dmaChannels.isEmpty {
                let dma = "dma: " + dmaChannels.map { String($0) }.joined(separator: ", ")
                if !s.isEmpty { s += " " }
                s += dma
            }
            if !fixedMemoryRanges.isEmpty {
                let ranges = "memory: " + fixedMemoryRanges.map {
                    "0x\(String($0.0.lowerBound, radix: 16)) - 0x\(String($0.0.upperBound, radix: 16)) \($0.1 ? "RO" : "RW")"
                }.joined(separator: ", " )
                if !s.isEmpty { s += " " }
                s += ranges
            }
            return s
        }

        init(_ resources: [AMLResourceSetting]) {
            var ioPorts: [ClosedRange<UInt16>] = []
            var interrupts: [UInt8] = []
            var dmaChannels: [UInt8] = []
            var fixedMemoryRanges: [(Range<UInt32>, Bool)] = []

            for resource in resources {
                if let ioPort = resource as? AMLIOPortSetting {
                    ioPorts.append(ioPort.ioPorts())
                } else if let irq = resource as? AMLIrqSetting {
                    interrupts.append(contentsOf: irq.interrupts())
                } else if let irq = resource as? AMLIrqExtendedDescriptor {
                    interrupts.append(contentsOf: irq.interrupts)
                } else if let dma = resource as? AMLDmaSetting {
                    dmaChannels.append(contentsOf: dma.channels())
                } else if let fixedRange = resource as? AMLFixedMemoryRangeDescriptor {
                    guard fixedRange.rangeLength > 0 else {
                        print("Ignoring AMLFixedMemoryRangeDescriptor with base: 0x\(String(fixedRange.baseAddress, radix: 16)) length of 0 ")
                        continue
                    }
                    let range = fixedRange.baseAddress..<(fixedRange.baseAddress + (fixedRange.rangeLength - 1))
                    fixedMemoryRanges.append((range, fixedRange.writeable))
                } else if let spaceDescriptor = resource as? AMLDWordAddressSpaceDescriptor {
                    // FIXME
                    print("Ignoring:", spaceDescriptor)
                } else {
                    fatalError("Cant convert \(resource) to an ISABus.Resource")
                }
            }

            self.ioPorts = ioPorts
            self.interrupts = interrupts
            self.dmaChannels = dmaChannels
            self.fixedMemoryRanges = fixedMemoryRanges
        }
    }
}
