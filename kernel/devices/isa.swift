//
//  kernel/devices/isa.swift
//
//
//  Created by Simon Evans on 06/12/2017.
//  Copyright © 2017 - 2018 Simon Evans. All rights reserved.
//

// There is only one ISA (EISA) bus and it owns all of the I/O address space
// which is defined as ports 0 - 0xffff accessed via the IN & OUT instructions.


protocol ISADevice {
    init?(parentBus: Bus, interruptManager: InterruptManager, pnpName: String, resources: ISABus.Resources, facp: FACP?)
}


final class UnknownISADevice: UnknownDevice, ISADevice {
    let resources: ISABus.Resources
    override var description: String { "ISA: Unknown device: \(pnpName) \(acpiDevice?.fullname() ?? "") \(resources)" }

    override init?(parentBus: Bus, pnpName: String? = nil, acpiDevice: AMLDefDevice? = nil) {
        self.resources = ISABus.Resources(acpiDevice?.currentResourceSettings() ?? [])
        super.init(parentBus: parentBus, pnpName: pnpName, acpiDevice: acpiDevice)
    }

    init?(parentBus: Bus, interruptManager: InterruptManager, pnpName: String, resources: ISABus.Resources, facp: FACP?) {
        self.resources = resources
        super.init(parentBus: parentBus, pnpName: pnpName, acpiDevice: nil)
    }
}


final class ISABus: Bus, CustomStringConvertible {

    let rs = ReservedSpace(name: "IO Ports", start: 0, end: 0xfff)
    var description: String { "ISABus: \(acpiDevice?.fullname() ?? "")" }


    init(parentBus: Bus, acpiDevice: AMLDefDevice? = nil) {
        print("Initialising ISABus, acpi:", acpiDevice?.fullname() ?? "nil")
          super.init(parentBus: parentBus, acpiDevice: acpiDevice)
    }


    override func unknownDevice(parentBus: Bus, pnpName: String? = nil, acpiDevice: AMLDefDevice? = nil) -> UnknownDevice? {
        return UnknownISADevice(parentBus: parentBus, pnpName: pnpName, acpiDevice: acpiDevice)
    }


    override func initialiseDevices() {
        print("ISA: InitialiseDevices called name:", self.fullName)

        guard let acpi = self.acpiDevice else { return }
        // PS2 is split over 2 devices (keyboard, mouse) so need to gather these
        // up beforehard.
        var ps2keyboard: [AMLResourceSetting] = []
        var ps2mouse: [AMLResourceSetting] = []

        acpi.childNodes.filter { $1 is AMLDefDevice }.forEach { (key, value) in
            let child = value as! AMLDefDevice

            if let deviceId = child.pnpName() ?? child.hardwareId(),
                let crs = child.currentResourceSettings() {
                switch deviceId {
                    case "PNP0303", "PNP030B":
                        ps2keyboard = crs
                        return

                    case "PNP0F03", "PNP0F13":
                        ps2mouse = crs
                        return

                    default:
                        break
                }
            }
            processNode(parentBus: self, child)
        }

        if !ps2keyboard.isEmpty {
            let deviceManager = system.deviceManager
            let im = deviceManager.interruptManager

            ps2keyboard.append(contentsOf: ps2mouse)
            if let device = KBD8042(parentBus: self, interruptManager: im, pnpName: "PNP0303",
                                    resources: ISABus.Resources(ps2keyboard), facp: nil) {
                self.addDevice(device)
                // FIXME: KBD8042 should really be some sort of BusDevice that adds its
                // sub devices.
                if let keyboard = device.keyboardDevice {
                    deviceManager.addDevice(keyboard)
                }
            }
        }
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
                    let range = fixedRange.baseAddress..<(fixedRange.baseAddress + fixedRange.rangeLength)
                    fixedMemoryRanges.append((range, fixedRange.writeable))
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
