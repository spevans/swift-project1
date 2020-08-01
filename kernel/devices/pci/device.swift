/*
 * kernel/devices/pci/device.swift
 *
 * Created by Simon Evans on 27/07/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * PCI Device class.
 *
 */


protocol PCIDevice {
    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpi: AMLDefDevice?)

    var deviceFunction: PCIDeviceFunction { get }
}


struct PCIDeviceFunction: CustomStringConvertible {

    private let busId: UInt8
    private let configSpace: PCIConfigSpace

    var device:         UInt8  { configSpace.device }
    var function:       UInt8  { configSpace.function }
    var vendor:         UInt16 { configSpace.readConfigWord(atByteOffset: 0x0) }
    var deviceId:       UInt16 { configSpace.readConfigWord(atByteOffset: 0x2) }
    var classCode:      UInt8  { configSpace.readConfigByte(atByteOffset: 0xb) }
    var subClassCode:   UInt8  { configSpace.readConfigByte(atByteOffset: 0xa) }
    var headerType:     UInt8  { configSpace.readConfigByte(atByteOffset: 0xe) }
    var hasSubFunction: Bool   { (headerType & 0x80) == 0x80 }
    var acpiADR:        UInt32 { UInt32(withWords: UInt16(configSpace.function), UInt16(device)) }
    var isValidDevice:  Bool   { vendor != 0xffff }


    var primaryBusNumber: UInt8 { configSpace.readConfigByte(atByteOffset: 0x18) }
    var secondaryBusNumber: UInt8 { configSpace.readConfigByte(atByteOffset: 0x19) }


    var description: String {
        let fmt: StaticString =  "%2.2X:%2.2X/%u: %4.4X:%4.4X [%2.2X%2.2X] HT: %2.2X %@"
        return String.sprintf(fmt, busId, device, function, vendor, deviceId,
                              classCode, subClassCode, headerType, configSpace.pciConfigAccess)
    }


    init?(bus: PCIBus, device: UInt8, function: UInt8) {
        self.busId = bus.busID
        self.configSpace =  bus.pciConfigSpace.configSpaceFor(device: device, function: function)
        if (vendor == 0xFFFF) {
            return nil
        }
    }


    init?(busId: UInt8, device: UInt8, function: UInt8) {
        self.busId = busId
        self.configSpace = PCIConfigSpace(busID: busId, device: device, function: function)

        if (vendor == 0xFFFF) {
            return nil
        }
    }


    func subFunctions() -> [PCIDeviceFunction]? {
        guard hasSubFunction else { return nil }

        var functions: [PCIDeviceFunction] = []
        for fidx: UInt8 in 1..<8 {
            if let dev = PCIDeviceFunction(busId: busId, device: device, function: fidx) {
                functions.append(dev)
            }
        }

        return functions.count > 0 ? functions : nil
    }
}


final class UnknownPCIDevice: UnknownDevice, PCIDevice {
    let deviceFunction: PCIDeviceFunction
    let acpiName: String?

    override var description: String {
        var desc = "PCI: Unknown device: " + deviceFunction.description
        if let name = acpiName {
            desc.append(": ")
            desc.append(name)
        }
        return desc
    }

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction) {
        self.deviceFunction = deviceFunction
        acpiName = nil
        super.init()
    }

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpi: AMLDefDevice? = nil) {
        self.deviceFunction = deviceFunction
        acpiName = acpi?.fullname()
        super.init()
    }

    override init?(parentBus: Bus, pnpName: String?, acpiNode: AMLDefDevice? = nil) {
        guard let acpiNode = acpiNode else {
            print("UnknownPCIDevice, acpiNode is nil for \(pnpName ?? "nil")")
            return nil
        }
        guard let address = acpiNode.addressResource() else {
            print("UnknownPCIDevice, no _ADR for \(acpiNode.fullname())")
            return nil
        }

        let device = UInt8(address >> 16)
        let function = UInt8(truncatingIfNeeded: address)
        guard let deviceFunction = PCIDeviceFunction(busId: (parentBus as! PCIBus).busID, device: device, function: function) else {
            print("UnknownPCIDevice, no valid PCIDeviceFunction for address \(String(address, radix: 16))")
            return nil
        }
        self.deviceFunction = deviceFunction
        acpiName = acpiNode.fullname()
        super.init()
    }
}
