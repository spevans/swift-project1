/*
 * kernel/devices/pci/PCIDeviceFunction.swift
 *
 * Created by Simon Evans on 18/05/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * PCI Device Function access
 *
 */


final class PCIDeviceFunction: CustomStringConvertible {
    private let configSpace: PCIConfigSpace
    private let busId: UInt8
    let device:     UInt8
    let function:   UInt8

    var slot:           UInt8  { device }
    var deviceFunction: UInt8  { device << 3 | function }
    var vendor:         UInt16 { readConfigWord(atByteOffset: 0x0) }
    var deviceId:       UInt16 { readConfigWord(atByteOffset: 0x2) }
    var command:        PCICommand {
        get { PCICommand(rawValue: readConfigWord(atByteOffset: 0x04)) }
        set { writeConfigWord(atByteOffset: 0x04, value: newValue.rawValue) }
    }
    var status:         PCIStatus { PCIStatus(rawValue: readConfigWord(atByteOffset: 0x06)) }
    var classCode:      UInt8  { readConfigByte(atByteOffset: 0xb) }
    var subClassCode:   UInt8  { readConfigByte(atByteOffset: 0xa) }
    var progInterface:  UInt8  { readConfigByte(atByteOffset: 0x9) }
    var revisionId:     UInt8  { readConfigByte(atByteOffset: 0x8) }
    var headerType:     UInt8  { readConfigByte(atByteOffset: 0xe) & 0x7f }
    var hasSubFunction: Bool   { readConfigByte(atByteOffset: 0xe) & 0x80 == 0x80 }

    var deviceClass:    PCIDeviceClass? { PCIDeviceClass(classCode: classCode, subClassCode: subClassCode, progInterface: progInterface) }
    var acpiADR:        UInt32 { UInt32(withWords: UInt16(function), UInt16(device)) }
    var isValidDevice:  Bool   { vendor != 0xffff }
    var capabilitiesPtr:    UInt8 { readConfigByte(atByteOffset: 0x34) }
    var interruptLine:      UInt8 {
        get { readConfigByte(atByteOffset: 0x3c) }
        set { writeConfigByte(atByteOffset: 0x3c, value: newValue) }
    }
    var interruptPin:       PCIInterruptPin? { PCIInterruptPin(pin: readConfigByte(atByteOffset: 0x3d)) }

    var generalDevice: PCIGeneralDevice? { headerType == 0x00 ? PCIGeneralDevice(deviceFunction: self) : nil }
    var bridgeDevice: PCIBridgeDevice?   { headerType == 0x01 ? PCIBridgeDevice(deviceFunction: self)  : nil }


    var description: String {
        let fmt: StaticString =  "%2.2X:%2.2X/%u: %4.4X:%4.4X [%2.2X%2.2X] HT: %2.2X %s [IRQ: %u/%s]"
        let int = interruptPin?.description ?? "none"
        return #sprintf(fmt, busId, device, function, vendor, deviceId,
                              classCode, subClassCode, headerType, configSpace.description, interruptLine, int)
    }


    var hasValidVendor: Bool { vendor != 0xFFFF }

    init(busId: UInt8, device: UInt8, function: UInt8) {
        precondition(device < 32)
        precondition(function < 8)

        let configSpace = PCIConfigSpace(busId: busId, device: device, function: function)
        self.configSpace = configSpace
        self.busId = busId
        self.device = device
        self.function = function
    }

    init(busId: UInt8, device: UInt8, function: UInt8, configSpace: PCIConfigSpace) {
        self.busId = busId
        self.device = device
        self.function = function
        self.configSpace = configSpace
    }

    deinit {
        configSpace.release()
    }

    var configSpaceSize: Int { configSpace.size }

    func readConfigByte(atByteOffset offset: UInt) -> UInt8 {
        configSpace.readConfigByte(device: device, function: function, offset: offset)
    }

    func readConfigWord(atByteOffset offset: UInt) -> UInt16 {
        configSpace.readConfigWord(device: device, function: function, offset: offset)
    }

    func readConfigDword(atByteOffset offset: UInt) -> UInt32 {
        configSpace.readConfigDword(device: device, function: function, offset: offset)
    }

    func writeConfigByte(atByteOffset offset: UInt, value: UInt8) {
        configSpace.writeConfigByte(device: device, function: function, offset: offset, value: value)
    }

    func writeConfigWord(atByteOffset offset: UInt, value: UInt16) {
        configSpace.writeConfigWord(device: device, function: function, offset: offset, value: value)
    }

    func writeConfigDword(atByteOffset offset: UInt, value: UInt32) {
        configSpace.writeConfigDword(device: device, function: function, offset: offset, value: value)
    }
}


// Header Type 0x00, PCI General Device, excludes common fields in PCIDeviceFunction
struct PCIGeneralDevice: CustomStringConvertible {
    let description = "GeneralDevice"
    fileprivate let deviceFunction: PCIDeviceFunction

    var bar0:               UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x10) }
    var bar1:               UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x14) }
    var bar2:               UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x18) }
    var bar3:               UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x1c) }
    var bar4:               UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x20) }
    var bar5:               UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x24) }
    var cardbusCISPointer:  UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x28) }
    var subsystemID:        UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x2e) }
    var systemID:           UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x2e) }
    var romBaseAddress:     UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x30) }
    var capabilitiesPtr:    UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x34) }
    var interruptLine:      UInt8 { deviceFunction.readConfigByte(atByteOffset: 0x3c) }
    var interruptPin:       PCIInterruptPin? { PCIInterruptPin(pin: deviceFunction.readConfigByte(atByteOffset: 0x3d)) }
    var minGrant:           UInt8 { deviceFunction.readConfigByte(atByteOffset: 0x3e) }
    var maxLatency:         UInt8 { deviceFunction.readConfigByte(atByteOffset: 0x3f) }
}

// Header Type 0x01, PCI-to-PCI Bridge, excludes common fields in PCIDeviceFunction
struct PCIBridgeDevice: CustomStringConvertible {
    let description = "BridgeDevice"
    fileprivate let deviceFunction: PCIDeviceFunction

    var bar0:               UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x10) }
    var bar1:               UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x14) }
    var primaryBusId:       UInt8  { deviceFunction.readConfigByte(atByteOffset: 0x18) }   // The bus this device is on
    var secondaryBusId:     UInt8  { deviceFunction.readConfigByte(atByteOffset: 0x19) }   // If a bridge, the busId of the non device side.
    var subordinateBusId:   UInt8  { deviceFunction.readConfigByte(atByteOffset: 0x1a) }
    var secondayLatencyTimer: UInt8 { deviceFunction.readConfigByte(atByteOffset: 0x19) }
    var ioBase:             UInt8  { deviceFunction.readConfigByte(atByteOffset: 0x1c) }
    var ioLimit:            UInt8  { deviceFunction.readConfigByte(atByteOffset: 0x1d) }
    var secondaryStatus:    UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x1e) }
    var memoryBase:         UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x20) }
    var memoryLimit:        UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x22) }
    var prefetechMemBase:   UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x24) }
    var prefetechMemLimit:  UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x26) }
    var prefetchBaseUpper32: UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x28) }
    var prefetchLimitUpper32: UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x2c) }
    var ioBaseUpper16:      UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x30) }
    var ioLimitUpper16:     UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x32) }
    var capabilitiesPtr:    UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x34) }
    var romBaseAddress:     UInt32 { deviceFunction.readConfigDword(atByteOffset: 0x38) }
    var interruptLine:      UInt8 { deviceFunction.readConfigByte(atByteOffset: 0x3c) }
    var interruptPin:       PCIInterruptPin? { PCIInterruptPin(pin: deviceFunction.readConfigByte(atByteOffset: 0x3d)) }
    var bridgeControl:      UInt16 { deviceFunction.readConfigWord(atByteOffset: 0x3e) }
}


struct PCICommand: CustomStringConvertible {
    private var bits: BitArray16
    fileprivate var rawValue: UInt16 { bits.rawValue }

    fileprivate init(rawValue: UInt16) {
        bits = BitArray16(rawValue)
    }

    var ioSpace: Bool {
        get { bits[0] == 1 }
        set { bits[0] = newValue ? 1 : 0 }
    }

    var memorySpace: Bool {
        get { bits[1] == 1 }
        set { bits[1] = newValue ? 1 : 0 }
    }

    var busMaster: Bool {
        get { bits[2] == 1 }
        set { bits[2] = newValue ? 1 : 0 }
    }

    var specialCycles: Bool {
        get { bits[3] == 1 }
        set { bits[3] = newValue ? 1 : 0 }
    }

    var memoryWriteInvalidate: Bool {
        get { bits[4] == 1 }
        set { bits[4] = newValue ? 1 : 0 }
    }

    var vgaPaletteSnoop: Bool {
        get { bits[5] == 1 }
        set { bits[5] = newValue ? 1 : 0 }
    }

    var parityErrorResponse: Bool {
        get { bits[6] == 1 }
        set { bits[6] = newValue ? 1 : 0 }
    }

    var serrEnable: Bool {
        get { bits[8] == 1 }
        set { bits[8] = newValue ? 1 : 0 }
    }

    var fastBackToBack: Bool {
        get { bits[9] == 1 }
        set { bits[9] = newValue ? 1 : 0 }
    }

    var interruptDisable: Bool {
        get { bits[10] == 1 }
        set { bits[10] = newValue ? 1 : 0 }
    }

    var description: String {
        var result = ""
        if ioSpace { result += "ioSpace " }
        if memorySpace { result += "memorySpace " }
        if busMaster { result += "busMaster " }
        if specialCycles { result += "specialCycles " }
        if memoryWriteInvalidate { result += "memoryWriteInvalidate " }
        if vgaPaletteSnoop { result += "vgaPaletteSnoop " }
        if parityErrorResponse { result += "parityErrorResponse " }
        if serrEnable { result += "serrEnable " }
        if fastBackToBack { result += "fastBackToBack " }
        if interruptDisable { result += "interruptDisable" }
        return result
    }
}


struct PCIStatus: CustomStringConvertible {
    private let bits: BitArray16
    fileprivate var rawValue: UInt16 { bits.rawValue }

    fileprivate init(rawValue: UInt16) {
        bits = BitArray16(rawValue)
    }

    var interrupt: Bool { bits[3] == 1 }
    var hasCapabilities: Bool { bits[4] == 1 }
    var is66MhzCapable: Bool { bits[5] == 1 }
    var isFastBackToBackCapable: Bool { bits[7] == 1 }
    var msterDataParityError: Bool { bits[8] == 1 }
    var devselTiming: Int { Int(bits[9...10]) }
    var signaledTargetAbort: Bool { bits[11] == 1 }
    var receivedTargetAbort: Bool { bits[12] == 1 }
    var receivedMasterAbort: Bool { bits[13] == 1 }
    var signaledSystemError: Bool { bits[14] == 1 }
    var detectedParityError: Bool { bits[15] == 1 }

    var description: String {
        var result = ""
        if interrupt { result += "interrupt " }
        if hasCapabilities { result += "hasCapabilities " }
        if is66MhzCapable { result += "is66MhzCapable " }
        if isFastBackToBackCapable { result += "isFastBackToBackCapable " }
        if msterDataParityError { result += "msterDataParityError " }
        result += "devselTiming \(devselTiming) "
        if signaledTargetAbort { result += "signaledTargetAbort " }
        if receivedTargetAbort { result += "receivedTargetAbort " }
        if receivedMasterAbort { result += "receivedMasterAbort " }
        if signaledSystemError { result += "signaledSystemError " }
        if detectedParityError { result += "detectedParityError" }
        return result
    }
}
