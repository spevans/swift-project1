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
    init?(interruptManager: InterruptManager, pnpName: String,
        resources: ISABus.Resources, facp: FACP?)
}


final class UnknownISADevice: UnknownDevice, ISADevice {
    let pnpName: String
    let resources: ISABus.Resources
    override var description: String { "ISA: Unknown device: \(pnpName) \(resources)" }

    override init?(parentBus: Bus, pnpName: String? = nil, acpiNode: AMLDefDevice? = nil) {
        self.pnpName = pnpName ?? acpiNode?.fullname() ?? "unknown"
        self.resources = ISABus.extractCRSSettings(acpiNode?.currentResourceSettings() ?? [])
        super.init(parentBus: parentBus, pnpName: pnpName, acpiNode: acpiNode)
    }

    init?(interruptManager: InterruptManager, pnpName: String,
          resources: ISABus.Resources, facp: FACP?) {
        self.pnpName = pnpName
        self.resources = resources
        super.init()
    }
}


final class ISABus: Bus {

    // Resources used by a device
    struct Resources: CustomStringConvertible {
        let ioPorts: [ClosedRange<UInt16>]
        let interrupts: [UInt8]

        var description: String {
            var s = ""
            if !ioPorts.isEmpty {
                s = "io: " + ioPorts.map {
                    $0.count == 1 ? "0x\(String($0.first!, radix: 16))"
                    : "0x\(String($0.first!, radix: 16))-0x\(String($0.last!, radix: 16))"
                }.joined(separator: ", ")
            }
            if !interrupts.isEmpty {
                let irq = "irq: " + interrupts.map { String($0) }.joined(separator: ", ")
                if !s.isEmpty { s += " " }
                s += irq
            }
            return s
        }
    }

    let rs = ReservedSpace(name: "IO Ports", start: 0, end: 0xfff)

    override func unknownDevice(parentBus: Bus, pnpName: String? = nil, acpiNode: AMLDefDevice? = nil) -> UnknownDevice? {
        return UnknownISADevice(parentBus: parentBus, pnpName: pnpName, acpiNode: acpiNode)
    }


    override func initialiseDevices() {
        print("ISA: InitialiseDevices called name:", self.fullName)

        guard let acpi = self.acpi else { return }
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
            if let device = KBD8042(interruptManager: im, pnpName: "PNP0303",
                                    resources: ISABus.extractCRSSettings(ps2keyboard), facp: nil) {
                self.addDevice(device)
                // FIXME: KBD8042 should really be some port of BusDevice that adds its
                // sub devices.
                if let keyboard = device.keyboardDevice {
                    deviceManager.addDevice(keyboard)
                }
            }
        }
    }


    static func extractCRSSettings(_ resources: [AMLResourceSetting]) -> ISABus.Resources {
        var ioports: [ClosedRange<UInt16>] = []
        var irqs: [UInt8] = []

        for resource in resources {
            if let ioPort = resource as? AMLIOPortSetting {
                ioports.append(ioPort.ioPorts())
            } else if let irq = resource as? AMLIrqSetting {
                irqs.append(contentsOf: irq.interrupts())
            } else {
                print("Ignoring resource:", resource)
            }
        }
        return ISABus.Resources(ioPorts: ioports, interrupts: irqs)
    }
}
