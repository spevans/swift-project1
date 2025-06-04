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


    init?(pnpDevice: PNPDevice) {
        guard let crs = pnpDevice.device.acpiDeviceConfig?.crs else {
            #kprint("\(pnpDevice.device): No valid resources found")
            return nil
        }
        self.resources = crs
        super.init(driverName: "motherboard", pnpDevice: pnpDevice)
    }

    override func info() -> String {
        var result = "Resources:"
        for resource in resources {
            result += "\n\t" + resource.description
        }
        return result
    }
}


final class MasterBus: CustomStringConvertible {
    let description = "MasterBus"
    let device: Device

    var resources: [MotherBoardResource] = []
    let acpiSystemBus: ACPI.ACPIObjectNode      // \_SB node


    init(acpiSystemBus: ACPI.ACPIObjectNode) {
        self.device = Device(parent: nil)
        device.deviceName = "MasterBus"
        self.acpiSystemBus = acpiSystemBus
    }
}
