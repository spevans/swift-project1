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
    private let acpiDeviceConfig: ACPIDeviceConfig
    let pnpName: String
    let isPCIHost: Bool

    override var description: String { pnpName }
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
        self.acpiDeviceConfig = acpiDeviceConfig
        self.pnpName = pnpName
        self.isPCIHost = acpiDeviceConfig.isPCIHost
        super.init(device: device, busDeviceName: "acpi-" + pnpName)
    }

    func acpiName() -> String {
        self.acpiDeviceConfig.node.fullname()
    }

    func acpiNode() -> ACPI.ACPIObjectNode {
        self.acpiDeviceConfig.node
    }

    var uid: AMLObject? {
        self.acpiDeviceConfig.uid
    }

    func crs() -> [AMLResourceSetting]? {
        try? self.acpiDeviceConfig.node.currentResourceSettings()
    }

    func prs() -> [AMLResourceSetting]? {
        try? self.acpiDeviceConfig.node.possibleResourceSettings()
    }

    func setResourceSettings(_ settings: [AMLResourceSetting]) throws(AMLError) {
        try self.acpiDeviceConfig.node.setResourceSettings(settings)
    }

    func prt() -> PCIRoutingTable? {
        self.acpiDeviceConfig.node.pciRoutingTable()
    }

    func getResources() -> ISABus.Resources? {
        if self.resources == nil, let crs = self.crs() {
            self.resources = ISABus.Resources(crs)
        }
        return self.resources
    }

    #if false
    func initialise() -> Bool {
        device.initialised = true
        self.resources = getResources()
        device.enabled = true
        return true
    }
    #endif

    func matchesId(_ pnpId: String) -> Bool {
        return self.acpiDeviceConfig.matches(hidOrCid: pnpId)
    }

    override func info() -> String {
        var result = "isPCIHost: \(isPCIHost)"
        if let resources = self.crs() {
            for resource in resources {
                result += "\n\t\(resource.description)"
            }
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
            case "PNP0C02":
                return MotherBoardResource(pnpDevice: pnpDevice)
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
