//
//  kernel/devices/isa.swift
//
//
//  Created by Simon Evans on 06/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

// There is only one ISA (EISA) bus and it owns all of the I/O address space
// which is defined as ports 0 - 0xffff accessed via the IN & OUT instructions.


class ISABus: Device {

    // Resources used by a device
    struct Resources {
        let ioPorts: [UInt16]
        let interrupts: [UInt8]
    }

    let acpi: ACPI
    var devices: [ISADevice]
    let rs = ReservedSpace(name: "IO Ports", start: 0, end: 0xfff)

    init(acpi: ACPI) {
        self.acpi = acpi
        devices = []
    }


    func initialiseBusDevices(deviceManager: DeviceManager) {
        let im = deviceManager.interruptManager
        // PS2 is split over 2 devices (keyboard, mouse) so need to gather these
        // up beforehard.
        var ps2keyboard: [AMLResourceSetting] = []
        var ps2mouse: [AMLResourceSetting] = []

        acpi.globalObjects.pnpDevices() { (fullname, pnpName, crs) in
            print("Configuring \(pnpName)")
            switch pnpName {
            case "PNP0303": ps2keyboard = crs
            case "PNP0F13": ps2mouse = crs
            default: print("Ignoring PNP device:", pnpName)
            }
        }

        if !ps2keyboard.isEmpty {
            ps2keyboard.append(contentsOf: ps2mouse)
            if let device = KBD8042(interruptManager: im, pnpName: "PNP0303",
                                    resource: extractCRSSettings(ps2keyboard)) {
                print("PNP: KBD init")
                devices.append(device)
                deviceManager.addDevice(device)
                // FIXME: KBD8042 should really be some port of BusDevice that adds its
                // sub devices.
                if let keyboard = device.keyboardDevice as? Device {
                    deviceManager.addDevice(keyboard)
                }
            }
        }
        if let timer = PIT8254(interruptManager: im, pnpName: "PNP0100",
                            resource: ISABus.Resources(ioPorts: [0x40, 0x42], interrupts: [0])) {
                devices.append(timer)
                deviceManager.addDevice(timer)
        }
    }

    private func extractCRSSettings(_ resources: [AMLResourceSetting]) -> ISABus.Resources {
        var ioports: [UInt16] = []
        var irqs: [UInt8] = []
        for resource in resources {
            if let ioPort = resource as? AMLIOPortSetting {
                ioports.append(contentsOf: ioPort.ioPorts())
            } else if let irq = resource as? AMLIrqSetting {
                irqs.append(contentsOf: irq.interrupts())
            } else {
                print("Ignoreing resource:", resource)
            }
        }
        return ISABus.Resources(ioPorts: ioports, interrupts: irqs)
    }
}


protocol ISADevice {

    init?(interruptManager: InterruptManager, pnpName: String, resource: ISABus.Resources)
}

