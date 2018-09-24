//
//  kernel/devices/isa.swift
//
//
//  Created by Simon Evans on 06/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

// There is only one ISA (EISA) bus and it owns all of the I/O address space
// which is defined as ports 0 - 0xffff accessed via the IN & OUT instructions.


protocol ISADevice {
    init?(interruptManager: InterruptManager, pnpName: String,
        resources: ISABus.Resources, facp: FACP?)
}


final class UnknownISADevice: Device, ISADevice, CustomStringConvertible {
    let description: String

    init?(interruptManager: InterruptManager, pnpName: String,
        resources: ISABus.Resources, facp: FACP?) {
        description = "ISA: Unknown device: \(pnpName) \(resources)"
    }
}


final class ISABus: Bus {

    // Resources used by a device
    struct Resources {
        let ioPorts: [UInt16]
        let interrupts: [UInt8]
    }

    let rs = ReservedSpace(name: "IO Ports", start: 0, end: 0xfff)


    override func initialiseDevices() {
        let deviceManager = system.deviceManager
        let im = deviceManager.interruptManager
        // PS2 is split over 2 devices (keyboard, mouse) so need to gather these
        // up beforehard.
        var ps2keyboard: [AMLResourceSetting] = []
        var ps2mouse: [AMLResourceSetting] = []

        print("ISA Bus:", fullName)
        for node in acpi.childNodes {
            if let dev = node.object as? AMLDefDevice {

                let fullNodeName = fullName + String(AMLNameString.pathSeparatorChar) + node.name
                var context = ACPI.AMLExecutionContext(scope: AMLNameString(fullNodeName),
                                                       args: [],
                                                       globalObjects: deviceManager.acpiTables.globalObjects)
                if let pnpName = dev.pnpName(context: &context),
                    let crs = dev.currentResourceSettings(context: &context) {

                    //print("Configuring \(pnpName)")
                    switch pnpName {
                    case "PNP0303": ps2keyboard = crs
                    case "PNP0F13": ps2mouse = crs
                    case "PNP0B00":
                        if let cmos = CMOSRTC(interruptManager: im,
                            pnpName: pnpName,
                            resources: extractCRSSettings(crs),
                            facp: deviceManager.acpiTables.facp
                        ) {
                            print(cmos)
                            addDevice(cmos)
                            deviceManager.addDevice(cmos)
                            let date = cmos.readTime()
                            print("Current datetime:", date)
                        }

                    default:
                        let resources = extractCRSSettings(crs)
                        if let dev = UnknownISADevice(interruptManager: im,
                            pnpName: pnpName, resources: resources, facp: nil) {
                            addDevice(dev)
                        }
                    }
                }
            }
        }
        if !ps2keyboard.isEmpty {
            ps2keyboard.append(contentsOf: ps2mouse)
            if let device = KBD8042(interruptManager: im, pnpName: "PNP0303",
                resources: extractCRSSettings(ps2keyboard), facp: nil) {
                addDevice(device)
                deviceManager.addDevice(device)
                // FIXME: KBD8042 should really be some port of BusDevice that adds its
                // sub devices.
                if let keyboard = device.keyboardDevice as? Device {
                    deviceManager.addDevice(keyboard)
                }
            }
        }

        if let timer = PIT8254(interruptManager: im, pnpName: "PNP0100",
            resources: ISABus.Resources(ioPorts: [0x40, 0x42], interrupts: [0]),
            facp: nil) {
            addDevice(timer)
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
                print("Ignoring resource:", resource)
            }
        }
        return ISABus.Resources(ioPorts: ioports, interrupts: irqs)
    }
}
