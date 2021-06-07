//
//  kernel/devices/ISABus.swift
//
//
//  Created by Simon Evans on 06/12/2017.
//  Copyright © 2017 - 2018 Simon Evans. All rights reserved.
//

// There is only one ISA (EISA) bus and it owns all of the I/O address space
// which is defined as ports 0 - 0xffff accessed via the IN & OUT instructions.

final class ISABus: PCIDeviceDriver, Bus, CustomStringConvertible {
    private unowned let pciDevice: PCIDevice
    private var isaDevices: [PNPDevice] = []

    var resources: [MotherBoardResource] = []
    var devices: [Device] { isaDevices.map { $0 as Device }}

    let rs = ReservedSpace(name: "IO Ports", start: 0, end: 0xfff)
    var description: String { "ISABus: \(pciDevice.acpiDevice?.fullname() ?? "")" }


    init?(pciDevice: PCIDevice) {
        self.pciDevice = pciDevice
        print("Initialising ISABus, acpi:", pciDevice.acpiDevice?.fullname() ?? "unknown")
    }

    func device(acpiDevice: AMLDefDevice) -> Device? {
        guard let pnpName = acpiDevice.deviceId else { return nil }
        return PNPDevice(parentBus: self, acpiDevice: acpiDevice, pnpName: pnpName)
    }

    func addDevice(_ device: Device) {
        guard let isaDevice = device as? PNPDevice else {
            fatalError("\(self): trying to add device of type \(device) to ISABus")
        }
        isaDevices.append(isaDevice)
    }

    func initialise() -> Bool {
        guard pciDevice.initialise() else { return false }
        isaDevices.sort { $0.fullName < $1.fullName }
        return true
    }
}


extension ISABus {
    // Resources used by a device
    struct Resources: CustomStringConvertible {
        let ioPorts: [ClosedRange<UInt16>]
        let interrupts: [IRQSetting]
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
                let irq = "irq: " + interrupts.map { String($0.irq) }.joined(separator: ", ")
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
            var interrupts: [IRQSetting] = []
            var dmaChannels: [UInt8] = []
            var fixedMemoryRanges: [(Range<UInt32>, Bool)] = []

            for resource in resources {
                if let ioPort = resource as? AMLIOPortSetting {
                    ioPorts.append(ioPort.ioPorts())
                } else if let irq = resource as? AMLIrqSetting {
                    interrupts.append(contentsOf: irq.interrupts())
                } else if let irq = resource as? AMLIrqExtendedDescriptor {
                    interrupts.append(contentsOf: irq.interrupts())
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
