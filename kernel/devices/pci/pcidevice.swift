/*
 * kernel/devices/pci/pcidevice.swift
 *
 * Created by Simon Evans on 27/07/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * PCI Device class.
 *
 */


final class PCIDevice: Device, CustomStringConvertible {
    unowned let parentBus: Bus
    let acpiDevice: AMLDefDevice?
    let fullName: String
    var enabled = false
    let deviceFunction: PCIDeviceFunction
    var pciDeviceDriver: PCIDeviceDriver?   // FIXME: setter should be private

    var deviceDriver: DeviceDriver? { pciDeviceDriver as DeviceDriver? }
    var description: String { "PCI \(fullName) \(deviceFunction.description)" }

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpiDevice: AMLDefDevice? = nil) {
        guard deviceFunction.vendor != 0xffff else { return nil } // Invalid device
        self.parentBus = parentBus
        self.deviceFunction = deviceFunction
        self.acpiDevice = acpiDevice
        self.fullName = acpiDevice?.fullname() ?? "PCI Device"
    }


    func initialiseDevice() {
        pciDeviceDriver?.initialiseDevice()
    }
}


// Header Type 0x00, PCI General Device, excludes common fields in PCIDeviceFunction
struct PCIGeneralDevice {
    fileprivate let configSpace: PCIConfigSpace

    var bar0:               UInt32 { configSpace.readConfigDword(atByteOffset: 0x10) }
    var bar1:               UInt32 { configSpace.readConfigDword(atByteOffset: 0x14) }
    var bar2:               UInt32 { configSpace.readConfigDword(atByteOffset: 0x18) }
    var bar3:               UInt32 { configSpace.readConfigDword(atByteOffset: 0x1c) }
    var bar4:               UInt32 { configSpace.readConfigDword(atByteOffset: 0x20) }
    var bar5:               UInt32 { configSpace.readConfigDword(atByteOffset: 0x24) }
    var cardbusCISPointer:  UInt32 { configSpace.readConfigDword(atByteOffset: 0x28) }
    var subsystemID:        UInt16 { configSpace.readConfigWord(atByteOffset: 0x2e) }
    var systemID:           UInt16 { configSpace.readConfigWord(atByteOffset: 0x2e) }
    var romBaseAddress:     UInt32 { configSpace.readConfigDword(atByteOffset: 0x30) }
    var capabilitiesPtr:    UInt16 { configSpace.readConfigWord(atByteOffset: 0x34) }
    var interruptLine:      UInt8 { configSpace.readConfigByte(atByteOffset: 0x3c) }
    var interruptPin:       UInt8 { configSpace.readConfigByte(atByteOffset: 0x3d) }
    var minGrant:           UInt8 { configSpace.readConfigByte(atByteOffset: 0x3e) }
    var maxLatency:         UInt8 { configSpace.readConfigByte(atByteOffset: 0x3f) }
}

// Header Type 0x01, PCI-to-PCI Bridge, excludes common fields in PCIDeviceFunction
struct PCIBridgeDevice {
    fileprivate let configSpace: PCIConfigSpace

    var bar0:               UInt32 { configSpace.readConfigDword(atByteOffset: 0x10) }
    var bar1:               UInt32 { configSpace.readConfigDword(atByteOffset: 0x14) }
    var primaryBusId:       UInt8  { configSpace.readConfigByte(atByteOffset: 0x18) }   // The bus this device is on
    var secondaryBusId:     UInt8  { configSpace.readConfigByte(atByteOffset: 0x19) }   // If a bridge, the busId of the non device side.
    var subordinateBusId:   UInt8  { configSpace.readConfigByte(atByteOffset: 0x1a) }
    var secondayLatencyTimer: UInt8 { configSpace.readConfigByte(atByteOffset: 0x19) }
    var ioBase:             UInt8  { configSpace.readConfigByte(atByteOffset: 0x1c) }
    var ioLimit:            UInt8  { configSpace.readConfigByte(atByteOffset: 0x1d) }
    var secondaryStatus:    UInt16 { configSpace.readConfigWord(atByteOffset: 0x1e) }
    var memoryBase:         UInt16 { configSpace.readConfigWord(atByteOffset: 0x20) }
    var memoryLimit:        UInt16 { configSpace.readConfigWord(atByteOffset: 0x22) }
    var prefetechMemBase:   UInt16 { configSpace.readConfigWord(atByteOffset: 0x24) }
    var prefetechMemLimit:  UInt16 { configSpace.readConfigWord(atByteOffset: 0x26) }
    var prefetchBaseUpper32: UInt32 { configSpace.readConfigDword(atByteOffset: 0x28) }
    var prefetchLimitUpper32: UInt32 { configSpace.readConfigDword(atByteOffset: 0x2c) }
    var ioBaseUpper16:      UInt16 { configSpace.readConfigWord(atByteOffset: 0x30) }
    var ioLimitUpper16:     UInt16 { configSpace.readConfigWord(atByteOffset: 0x32) }
    var capabilitiesPtr:    UInt16 { configSpace.readConfigWord(atByteOffset: 0x34) }
    var romBaseAddress:     UInt32 { configSpace.readConfigDword(atByteOffset: 0x38) }
    var interruptLine:      UInt8 { configSpace.readConfigByte(atByteOffset: 0x3c) }
    var interruptPin:       UInt8 { configSpace.readConfigByte(atByteOffset: 0x3d) }
    var bridgeControl:      UInt16 { configSpace.readConfigWord(atByteOffset: 0x3e) }
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
    var progInterface:  UInt8  { configSpace.readConfigByte(atByteOffset: 0x9) }
    var headerType:     UInt8  { configSpace.readConfigByte(atByteOffset: 0xe) & 0x7f }
    var hasSubFunction: Bool   { configSpace.readConfigByte(atByteOffset: 0xe) & 0x80 == 0x80 }

    var deviceClass:    PCIDeviceClass? { PCIDeviceClass(classCode: classCode, subClassCode: subClassCode, progInterface: progInterface) }
    var acpiADR:        UInt32 { UInt32(withWords: UInt16(configSpace.function), UInt16(device)) }
    var isValidDevice:  Bool   { vendor != 0xffff }
    var capabilitiesPtr:    UInt16 { configSpace.readConfigWord(atByteOffset: 0x34) }
    var interruptLine:      UInt8 { configSpace.readConfigByte(atByteOffset: 0x3c) }
    var interruptPin:       UInt8 { configSpace.readConfigByte(atByteOffset: 0x3d) }

    var generalDevice: PCIGeneralDevice? { headerType == 0x00 ? PCIGeneralDevice(configSpace: configSpace) : nil }
    var bridgeDevice: PCIBridgeDevice?   { headerType == 0x01 ? PCIBridgeDevice(configSpace: configSpace)  : nil }


    var description: String {
        let fmt: StaticString =  "%2.2X:%2.2X/%u: %4.4X:%4.4X [%2.2X%2.2X] HT: %2.2X %@ [IRQ: %u/%u]"
        return String.sprintf(fmt, busId, device, function, vendor, deviceId,
                              classCode, subClassCode, headerType, configSpace.pciConfigAccess, interruptLine, interruptPin)
    }


    init?(bus: PCIBus, device: UInt8, function: UInt8) {
        precondition(device < 32)
        precondition(function < 8)

        self.busId = bus.busId
        self.configSpace =  bus.pciConfigSpace.configSpaceFor(device: device, function: function)
        if (vendor == 0xFFFF) {
            return nil
        }
    }


    init?(busId: UInt8, device: UInt8, function: UInt8) {
        precondition(device < 32)
        precondition(function < 8)

        self.busId = busId
        self.configSpace = PCIConfigSpace(busId: busId, device: device, function: function)

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
