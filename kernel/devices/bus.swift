//
//  bus.swift
//  project1
//
//  Created by Simon Evans on 25/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//

// PNP0C02 device
final class MotherBoardResource: PNPDeviceDriver {
    private let resources: [AMLResourceSetting]

    override var description: String { "\(device.fullName): \(resources)" }


    override init?(pnpDevice: PNPDevice) {
        guard let crs = pnpDevice.device.acpiDeviceConfig?.crs else {
            #kprint("\(pnpDevice.device.fullName) No valid resources found")
            return nil
        }
        self.resources = crs
        super.init(pnpDevice: pnpDevice)
    }
}


final class MasterBus: CustomStringConvertible {
    private var pciHostBus: PCIBus?     // PCI Host Bus
    let description = "MasterBus"
    let device: Device

    var resources: [MotherBoardResource] = []
    let acpiSystemBus: ACPI.ACPIObjectNode      // \_SB node


    init(acpiSystemBus: ACPI.ACPIObjectNode) {
        self.device = Device(parent: nil, fullName: "MasterBus")
        self.acpiSystemBus = acpiSystemBus
    }

    func rootPCIBus() -> PCIBus? {
        if pciHostBus == nil {
            #kprint("Looking for rootPCIBus")
            system.deviceManager.walkDeviceTree(bus: self.device) { device in
                #kprint("Looking at", device.fullName, unsafeBitCast(device, to: UInt.self).hex())
                if let driver = device.deviceDriver as? PCIBus, driver.isHostBus {
                    #kprint("Found match on device", device.fullName)
                    self.pciHostBus = driver
                    return false
                } else {
                    return true
                }
            }
        }
        return pciHostBus
    }
}
