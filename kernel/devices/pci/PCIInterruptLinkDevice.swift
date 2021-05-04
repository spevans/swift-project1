//
//  kernel/devices/PCIInterruptLinkDevice.swift
//  project1
//
//  Created by Simon Evans on 03/05/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//
//  PCI Link Devices (LNKA..LNKD) used for PCI interrupts (INT #A .. INT #D)
//

final class PCIInterruptLinkDevice: PNPDeviceDriver, CustomStringConvertible {
    let irq: IRQSetting  // The IRQ signaled by this device
    var description: String { "PCI Link Device: [IRQ: \(irq)]" }


    init?(pnpDevice: ISADevice) {
        let resources = pnpDevice.resources

        let f = pnpDevice.acpiDevice?.fullname() ?? "[no name]"
        print("PCIInterruptLinkDevice: \(f) \(resources)")


        guard let uid = pnpDevice.acpiDevice?.uniqueId() else {
            print("PCI LNK: cant get _UID")
            return nil
        }

        guard let uidValue = uid.integerValue, uidValue <= UInt8.max else {
            print("PCI LNK: uid is not an integer: \(uid)")
            return nil
        }

        if let prs = pnpDevice.acpiDevice?.possibleResourceSettings() {
            print("PCI LNK \(f): _PRS:", prs)
        }

        if let cirq = resources.interrupts.first {
            irq = cirq
            print("Using IRQ \(cirq)")
        } else {
            print(f, "has no configured irq")
            return nil
        }

        print("PCI INT Link \(f) [_UID=\(uidValue)]: resources:", resources)
    }
}
