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


    init?(pnpDevice: PNPDevice) {
        guard let acpiDevice = pnpDevice.acpiDevice else {
            print("PCIInterruptLinkDevice: \(pnpDevice) has no ACPI information")
            return nil
        }


        guard let uid = acpiDevice.uniqueId() else {
            print("PCIInterruptLinkDevice: cant get _UID")
            return nil
        }

        guard let uidValue = uid.integerValue, uidValue <= UInt8.max else {
            print("PCI LNK: uid is not an integer: \(uid)")
            return nil
        }

        guard let crs = acpiDevice.currentResourceSettings() else {
            print("PCIInterruptLinkDevice: Cant get resources")
            return nil
        }

        let resources = ISABus.Resources(crs)
        let f = acpiDevice.fullname()
        print("PCIInterruptLinkDevice: \(f) \(resources)")

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

    // FIXME: Maybe select a better IRQ to use to balance them out better or make
    // .irq into a funtion to do lazy irq allocation
    func initialise() -> Bool {
        true
    }
}
