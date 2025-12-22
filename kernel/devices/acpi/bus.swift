//
//  kernel/devices/acpi/bus.swift
//  project1
//
//  Created by Simon Evans on 25/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//

#if ACPI
// PNP0C02 device
final class MotherBoardResource: DeviceDriver {
    private let resources: [AMLResourceSetting]


    init?(pnpDevice: PNPDevice) {
        guard let crs = pnpDevice.crs() else {
            #kprint("\(pnpDevice): No valid resources found")
            return nil
        }
        self.resources = crs
        super.init(driverName: "motherboard", device: pnpDevice)
        #kprint("\(pnpDevice): Found \(resources.count) resources")
        #kprint(pnpDevice.info())
    }

    override func initialise() -> Bool {
        true
    }
}
#endif

final class MasterBus: CustomStringConvertible {
    let description = "MasterBus"
    let device: Device

    var resources: [MotherBoardResource] = []
#if ACPI
    let acpiSystemBus: ACPI.ACPIObjectNode      // \_SB node

    init(acpiSystemBus: ACPI.ACPIObjectNode) {
        self.device = Device()
        self.acpiSystemBus = acpiSystemBus
    }
#else

    init() {
        self.device = Device()
    }
#endif
}
