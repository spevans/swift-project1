//
//  kernel/devices/PCIInterruptLinkDevice.swift
//  project1
//
//  Created by Simon Evans on 03/05/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//
//  PCI Link Devices (LNKA..LNKD) used for PCI interrupts (INT #A .. INT #D)
//

final class PCIInterruptLinkDevice: PNPDeviceDriver {
    let irq: IRQSetting  // The IRQ signaled by this device
    override var description: String { "PCI Link Device: [IRQ: \(irq)]" }


    override init?(pnpDevice: PNPDevice) {
        guard let uid = pnpDevice.device.acpiDeviceConfig?.uid else {
            #kprint("PCIInterruptLinkDevice: cant get _UID")
            return nil
        }

        guard let uidValue = uid.integerValue, uidValue <= UInt8.max else {
            #kprint("PCI LNK: uid is not an integer: \(uid)")
            return nil
        }

        guard let acpiConfig = pnpDevice.device.acpiDeviceConfig else {
            #kprint("\(pnpDevice.pnpName) has no ACPIDeviceConfig")
            return nil
        }
        guard let crs = acpiConfig.crs else {
            #kprint("PCIInterruptLinkDevice: Cant get resources")
            return nil
        }

        let resources = ISABus.Resources(crs)
        let f = acpiConfig.node.fullname()
        #kprint("PCIInterruptLinkDevice: \(f) \(resources)")

        if let prs = acpiConfig.prs {
            let s: String = prs.map { $0.description }.joined(separator: ", ")
            #kprint("PCI LNK ", f, ": _PRS:", s)
        }

        if let cirq = resources.interrupts.first {
            irq = cirq
            #kprint("Using IRQ \(cirq)")
        } else {
            #kprint(f, "has no configured irq")
            return nil
        }
        super.init(pnpDevice: pnpDevice)
        #kprint("PCI INT Link \(f) [_UID=\(uidValue)]: resources:", resources)
    }

    // FIXME: Maybe select a better IRQ to use to balance them out better or make
    // .irq into a funtion to do lazy irq allocation
    override func initialise() -> Bool {
        true
    }
}
