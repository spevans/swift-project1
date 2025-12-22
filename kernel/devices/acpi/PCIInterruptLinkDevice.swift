//
//  kernel/devices/PCIInterruptLinkDevice.swift
//  project1
//
//  Created by Simon Evans on 03/05/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//
//  PCI Link Devices (LNKA..LNKD) used for PCI interrupts (INT #A .. INT #D)
//

final class PCIInterruptLinkDevice: DeviceDriver {
    let pnpDevice: PNPDevice
    private(set) var irq: IRQSetting?  // The IRQ signaled by this device

    override func info() -> String {
        let irqStr = irq?.description ?? "none"
        return "PCI Link Device: [IRQ: \(irqStr)]"
    }


    init?(pnpDevice: PNPDevice) {
        guard let uid = pnpDevice.uid else {
            #kprint("PCIInterruptLinkDevice: cant get _UID")
            return nil
        }

        guard let uidValue = uid.integerValue, uidValue <= UInt8.max else {
            #kprint("PCI LNK: uid is not an integer: \(uid)")
            return nil
        }

        self.pnpDevice = pnpDevice
        super.init(driverName: "pci-int-link", device: pnpDevice.device)
        self.setInstanceName(to: "pciint\(uidValue)")
    }

    // FIXME: Maybe select a better IRQ to use to balance them out better or make
    // .irq into a function to do lazy irq allocation
    override func initialise() -> Bool {
        guard var crs = self.pnpDevice.crs() else {
            #kprint("PCIInterruptLinkDevice: Cant get resources")
            return false
        }
        let f = self.pnpDevice.acpiName()
        let resources = ISABus.Resources(crs)

        if let cirq = resources.interrupts.first {
            if cirq.irq == 0 {  // Ignore IRQ0
                #kprintf("%s: Need to set an IRQ\n", f)
                guard let (resource, interrupt) = possibleInterrupts() else {
                    #kprintf("%s: Cannot set interrupt\n", f)
                    return false
                }
                crs[0] = resource
                do {
                    try pnpDevice.setResourceSettings(crs)
                } catch {
                    #kprintf("%s: Cannot set _SRS: %s\n", f, error.description)
                    return false
                }
                irq = interrupt
            } else {
                irq = cirq
            }
        } else {
            #kprintf("%s: has no configured irq\n", f)
            return false
        }
        return true
    }

    private func possibleInterrupts() -> (AMLResourceSetting, IRQSetting)? {
        let f = self.pnpDevice.acpiName()
        guard let prs = pnpDevice.prs() else {
            #kprintf("%s: No _PRS, cant get irqs\n", f)
            return nil
        }
        for resource in prs {
            switch resource {
                case .irqSetting(let setting):
                    guard let interrupt = setting.interrupts().first else { return nil }
                    return (resource, interrupt)
                case .extendedIrqSetting(let setting):
                    guard let interrupt = setting.interrupts().first else { return nil }
                    return (resource, interrupt)
                default: continue
            }
        }
        return nil
    }
}
