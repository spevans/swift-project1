//
//  kernel/devices/ISABus.swift
//
//
//  Created by Simon Evans on 06/12/2017.
//  Copyright © 2017 - 2018 Simon Evans. All rights reserved.
//

// There is only one ISA (EISA) bus and it owns all of the I/O address space
// which is defined as ports 0 - 0xffff accessed via the IN & OUT instructions.

final class ISABus: DeviceDriver {
   // private var isaDevices: [PNPDevice] = []

    var resources: [MotherBoardResource] = []
    let rs = ReservedSpace(name: "IO Ports", start: 0, end: 0xfff)
    override var description: String { "ISABus: \(device.fullName)" }


    init?(pciDevice: PCIDevice) {
        let device = pciDevice.device
        #kprint("Initialising ISABus on PCI:", device.fullName)
        super.init(device: device)
        self.device.setDriver(self)
    }

    init?(pnpDevice: PNPDevice) {
        let device = pnpDevice.device
        #kprint("Initialising ISABus on PNP:", device.fullName)
        super.init(device: device)
        self.device.setDriver(self)
    }

    override func initialise() -> Bool {
        guard device.initialise() else { return false }
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
                switch resource {
                case let .ioPortSetting(ioPort): ioPorts.append(ioPort.ioPorts())
                    case let .irqSetting(irq): interrupts.append(contentsOf: irq.interrupts())
                case let .extendedIrqSetting(irq): interrupts.append(contentsOf: irq.interrupts())
                case let .dmaSetting(dma): dmaChannels.append(contentsOf: dma.channels())
                case let .fixedMemoryRangeDescriptor(fixedRange): guard fixedRange.rangeLength > 0 else {
                        #kprint("Ignoring AMLFixedMemoryRangeDescriptor with base: 0x\(String(fixedRange.baseAddress, radix: 16)) length of 0 ")
                        continue
                    }
                    let range = fixedRange.baseAddress..<(fixedRange.baseAddress + (fixedRange.rangeLength - 1))
                    fixedMemoryRanges.append((range, fixedRange.writeable))
                case let .dwordAddressSpaceDescriptor(spaceDescriptor):
                    // FIXME
                    #kprint("Ignoring:", spaceDescriptor)
                default: fatalError("Cant convert \(resource) to an ISABus.Resource")
                }
            }

            self.ioPorts = ioPorts
            self.interrupts = interrupts
            self.dmaChannels = dmaChannels
            self.fixedMemoryRanges = fixedMemoryRanges
        }
    }
}
