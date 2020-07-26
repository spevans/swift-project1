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
    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction)
    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpi: AMLDefDevice)

    var deviceFunction: PCIDeviceFunction { get }
}


struct PCIDeviceFunction: CustomStringConvertible {

    private let bus: PCIBus
    private let configSpace: PCIConfigSpace

    var device:         UInt8  { configSpace.device }
    var function:       UInt8  { configSpace.function }
    var vendor:         UInt16 { configSpace.readConfigWord(atOffset: 0) }
    var deviceId:       UInt16 { configSpace.readConfigWord(atOffset: 1) }
    var classCode:      UInt8  { configSpace.readConfigByte(atOffset: 0xB) }
    var subClassCode:   UInt8  { configSpace.readConfigByte(atOffset: 0xa) }
    var headerType:     UInt8  { configSpace.readConfigByte(atOffset: 0xe) }
    var hasSubFunction: Bool   { (headerType & 0x80) == 0x80 }
    var acpiADR:        UInt32 { UInt32(withWords: UInt16(configSpace.function), UInt16(device)) }
    var isValidDevice:  Bool   { vendor != 0xffff }

    var description: String {
        let fmt: StaticString =  "%2.2X:%2.2X/%u: %4.4X:%4.4X [%2.2X%2.2X] HT: %2.2X %@"
        return String.sprintf(fmt, bus.busID, device, function, vendor, deviceId,
                              classCode, subClassCode, headerType, configSpace.pciConfigAccess)
    }


    init?(bus: PCIBus, device: UInt8, function: UInt8) {
        self.bus = bus
        self.configSpace =  bus.pciConfigSpace.configSpaceFor(device: device, function: function)
        if (vendor == 0xFFFF) {
            return nil
        }
    }

    init?(bus: PCIBus, address: UInt32) {
        self.bus = bus
        self.configSpace = PCIConfigSpace(busID: bus.busID, address: address)

        if (vendor == 0xFFFF) {
            return nil
        }
    }

    func subFunctions() -> [PCIDeviceFunction]? {
        guard hasSubFunction else { return nil }

        var functions: [PCIDeviceFunction] = []
        for fidx: UInt8 in 1..<8 {
            if let dev = PCIDeviceFunction(bus: bus, device: device, function: fidx) {
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

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpi: AMLDefDevice) {
        self.deviceFunction = deviceFunction
        acpiName = acpi.fullname()
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
        guard let deviceFunction = PCIDeviceFunction(bus: parentBus as! PCIBus, address: UInt32(address)) else {
            print("UnknownPCIDevice, no valid PCIDeviceFunction for address \(String(address, radix: 16))")
            return nil
        }
        self.deviceFunction = deviceFunction
        acpiName = acpiNode.fullname()
        super.init()
    }
}
