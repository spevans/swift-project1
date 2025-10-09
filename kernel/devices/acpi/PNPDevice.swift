//
//  kernel/devices/PNPDevice.swift
//  project1
//
//  Created by Simon Evans on 07/06/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//
//  Device representing hardware identified by a _HID or _CID ACPI name,
//  non-PCI, usually ISA or ACPI devices.

final class PNPDevice: BusDevice {
    private(set) var resources: ISABus.Resources?
    let pnpName: String
    let isPCIHost: Bool

    override var description: String {"PNP Device \(pnpName)" }
    override var className: String { "PNPDevice" }

    init?(device: Device, acpiDeviceConfig: ACPIDeviceConfig) {
        guard device.busDevice == nil else {
            #kprint("Device \(device) already has a busDevice")
            return nil
        }
        guard let pnpName = acpiDeviceConfig.hid else {
            #kprintf("%s has no ACPI DeviceConfig or _HID for %s\n", device.deviceName,
                     acpiDeviceConfig.node.fullname())
            return nil
        }
        self.pnpName = pnpName
        self.isPCIHost = acpiDeviceConfig.isPCIHost
        super.init(device: device, busDeviceName: "acpi-" + pnpName)
    }


    func getResources() -> ISABus.Resources? {
        if resources == nil {
            if let crs = device.acpiDeviceConfig?.crs() {
                resources = ISABus.Resources(crs)
            }
        }
        return resources
    }


    func initialise() -> Bool {
        device.initialised = true
        resources = getResources()
        device.enabled = true
        return true
    }

    func matchesId(_ pnpId: String) -> Bool {
        if let config = device.acpiDeviceConfig {
            return config.matches(hidOrCid: pnpId)
        } else {
            return false
        }
    }

    override func info() -> String {
        var result = "PNPDevice: \(pnpName)\n\tisPCIHost: \(isPCIHost)"
        if let resources = self.resources {
            result += "\n\tResources: \(resources)"
        }
        return result
    }

    #if !TEST
    static func initPnpDevice(_ pnpDevice: PNPDevice) -> DeviceDriver? {
        guard pnpDevice.device.deviceDriver == nil else { return nil }
        switch pnpDevice.pnpName {
            case "PNP0100": return PIT8254(pnpDevice: pnpDevice)
            case "PNP0303": return KBD8042(pnpDevice: pnpDevice)
            case "PNP030B": return KBD8042(pnpDevice: pnpDevice)
            case "PNP0B00": return CMOSRTC(pnpDevice: pnpDevice)
            case "PNP0C0F": return PCIInterruptLinkDevice(pnpDevice: pnpDevice)
            case "QEMU0002": return QEMUFWCFG(pnpDevice: pnpDevice)
            case "PNP0A03", // PCI Host bridge
                "PNP0A08": // PCIBus, PCI Express
                return PCIBus(pnpDevice: pnpDevice)
            case "PNP0103", // HPET System Timer
                "PNP0C01":  // System Board
                return HPET(pnpDevice: pnpDevice)
            default:
                return nil
        }
    }
    #endif
}


class PNPDeviceDriver: DeviceDriver {
    init?(driverName: String, pnpDevice: PNPDevice) {
        super.init(driverName: driverName, device: pnpDevice.device)
    }
}
