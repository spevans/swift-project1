//
//  driver.swift
//  project1
//
//  Created by Simon Evans on 26/09/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//


protocol DeviceDriver: AnyObject {
    func initialiseDevice() -> Bool
}

extension DeviceDriver {
    func initialiseDevice() -> Bool  { return false }
}


protocol PNPDeviceDriver: DeviceDriver {
//    var pnpDevice: PNPDevice { get }
//    var supportedPnpIds: Set<String> { get }
    init?(pnpDevice: PNPDevice)
}


protocol PCIDeviceDriver: DeviceDriver {
//    var pciDevice: PCIDevice { get }
//    var supportedVendorIds: Set<(UInt16, UInt16)> { get }
    init?(pciDevice: PCIDevice)
}


struct PCISupportedVendorDevice: Hashable, Equatable {
    let vendor: UInt16
    let device: UInt16
}

private var pciDriversForIds: [PCISupportedVendorDevice: PCIDeviceDriver.Type] = [:
]

#if KERNEL
private var pnpDriversForIds: [String: PNPDeviceDriver.Type] = [
    "PNP0100": PIT8254.self,
    "PNP0303": KBD8042.self,
    "PNP030B": KBD8042.self,
    "PNP0B00": CMOSRTC.self,
    "PNP0C0F": PCIInterruptLinkDevice.self,
    "QEMU0002": QEMUFWCFG.self,
]
#else
private var pnpDriversForIds: [String: PNPDeviceDriver.Type] = [:]
#endif


func pciDriverById(vendor: UInt16, device: UInt16) -> PCIDeviceDriver.Type? {
    let vendorDevice = PCISupportedVendorDevice(vendor: vendor, device: device)
    return pciDriversForIds[vendorDevice]
}

func pnpDriverById(pnpName: String) -> PNPDeviceDriver.Type? {
    return pnpDriversForIds[pnpName]
}


func registerPCIDriver(driver: PCIDeviceDriver.Type, supportedIds: [PCISupportedVendorDevice]) {
    for supportedId in supportedIds {
        pciDriversForIds[supportedId] = driver
    }
}

func registerPNPDeviceDriver(driver: PNPDeviceDriver.Type) {

}
