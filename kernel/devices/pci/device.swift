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
    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpiDevice: AMLDefDevice?)

    var deviceFunction: PCIDeviceFunction { get }
}


struct PCIDeviceFunction: CustomStringConvertible {

    private let busId: UInt8
    private let configSpace: PCIConfigSpace

    var device:         UInt8  { configSpace.device }
    var function:       UInt8  { configSpace.function }
    var deviceFunction: UInt8  { device << 3 | function }
    var vendor:         UInt16 { configSpace.readConfigWord(atByteOffset: 0x0) }
    var deviceId:       UInt16 { configSpace.readConfigWord(atByteOffset: 0x2) }
    var classCode:      UInt8  { configSpace.readConfigByte(atByteOffset: 0xb) }
    var subClassCode:   UInt8  { configSpace.readConfigByte(atByteOffset: 0xa) }
    var headerType:     UInt8  { configSpace.readConfigByte(atByteOffset: 0xe) }
    var primaryBusId:   UInt8  { configSpace.readConfigByte(atByteOffset: 0x18) }   // The bus this device is on
    var secondaryBusId: UInt8  { configSpace.readConfigByte(atByteOffset: 0x19) }   // If a bridge, the busID of the non device side.

    var hasSubFunction: Bool   { (headerType & 0x80) == 0x80 }
    var isBus:          Bool   { (headerType & 0x01) == 0x01 }
    var acpiADR:        UInt32 { UInt32(withWords: UInt16(configSpace.function), UInt16(device)) }
    var isValidDevice:  Bool   { vendor != 0xffff }


    var description: String {
        let fmt: StaticString =  "%2.2X:%2.2X/%u: %4.4X:%4.4X [%2.2X%2.2X] HT: %2.2X %@"
        return String.sprintf(fmt, busId, device, function, vendor, deviceId,
                              classCode, subClassCode, headerType, configSpace.pciConfigAccess)
    }


    init?(bus: PCIBus, device: UInt8, function: UInt8) {
        precondition(device < 32)
        precondition(function < 8)

        self.busId = bus.busID
        self.configSpace =  bus.pciConfigSpace.configSpaceFor(device: device, function: function)
        if (vendor == 0xFFFF) {
            return nil
        }
    }


    init?(busId: UInt8, device: UInt8, function: UInt8) {
        precondition(device < 32)
        precondition(function < 8)

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

    override var description: String {
        return "PCI: Unknown device: \(fullName) \(deviceFunction.description)"
    }

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpiDevice: AMLDefDevice? = nil) {
        self.deviceFunction = deviceFunction
        super.init(parentBus: parentBus, acpiDevice: acpiDevice)
    }

    override init?(parentBus: Bus, pnpName: String?, acpiDevice: AMLDefDevice? = nil) {
        guard let acpiDevice = acpiDevice else {
            print("UnknownPCIDevice, acpiDevice is nil for \(pnpName ?? "nil")")
            return nil
        }
        guard let address = acpiDevice.addressResource() else {
            print("UnknownPCIDevice, no _ADR for \(acpiDevice.fullname())")
            return nil
        }

        let device = UInt8(address >> 16)
        let function = UInt8(truncatingIfNeeded: address)
        guard let deviceFunction = PCIDeviceFunction(busId: (parentBus as! PCIBus).busID, device: device, function: function) else {
            print("UnknownPCIDevice, no valid PCIDeviceFunction for address \(String(address, radix: 16))")
            return nil
        }
        self.deviceFunction = deviceFunction
        super.init(parentBus: parentBus, pnpName: pnpName, acpiDevice: acpiDevice)
    }
}
