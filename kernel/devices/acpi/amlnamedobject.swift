//
//  kernel/devices/acpi/amlnamedobject.swift
//  project1
//
//  Created by Simon Evans on 25/11/2017.
//  Copyright © 2017 - 2019 Simon Evans. All rights reserved.
//
//  Named Object types


struct AMLDataRegion {
    let name: AMLNameString
    let signature: AMLString
    let oemId: AMLString
    let oemTableId: AMLString

    //TODO: something here
}


struct AMLDefDevice {

    struct DeviceStatus {
        private let bits: BitArray32
        var present: Bool { bits[0] == 1 }
        var enabled: Bool { bits[1] == 1 }
        var showInUI: Bool { bits[2] == 1 }
        var functioning: Bool { bits[3] == 1}
        var batteryPresent: Bool { bits[4] == 1 }

        init(_ value: AMLInteger) {
            bits = BitArray32(UInt32(value))
        }

        // When no _STA is present a default status of everything enabled is assumed
        static func defaultStatus() -> DeviceStatus {
            return DeviceStatus(0x1f)
        }
    }


    // DeviceOp PkgLength NameString TermList
    let value: AMLTermList
    let name: AMLNameString
//    private(set) var device: Device? = nil
/*
    var description: String {
        var result = "ACPI Device:"
        if let devname = device {
            result += " [\(devname)]"
        } else {
            result += " No driver set"
        }
        return result
    }
*/
    init(name: AMLNameString, value: AMLTermList) {
        self.name = name
        self.value = value
    }
}

// Helper functions for ACPI Device nodes
extension ACPI.ACPIObjectNode {

    func status() throws(AMLError) -> AMLDefDevice.DeviceStatus {
        guard let sta = childNode(named: "_STA") else {
            return .defaultStatus()
        }
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(sta.fullname()))
        let result = try sta.readValue(context: &context)
        return AMLDefDevice.DeviceStatus(result.integerValue!)
    }

    // Run the _INI method if it exists
    func initialise() throws(AMLError) {
        guard let iniNode = childNode(named: "_INI"),  let ini = iniNode.object.methodValue else {
            return
        }
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(iniNode.fullname()))
        try ini.execute(context: &context)
    }

    func initialiseIfPresent() throws(AMLError) -> Bool {
        let status = try self.status()
        if !status.present {
            #kprint("DEV: Ignoring", self.fullname(), "as status present:", status.present, "enabled:", status.enabled)
            return false
        }
        do {
            #kprintf("ACPI: calling %s._INI\n", self.fullname())
            try self.initialise()
        } catch {
            let str = error.description
            #kprint("ACPI: Error running _INI for", self.fullname(), str)
        }
        let newStatus = try self.status()
        #kprint("initialiseIfPresent:", newStatus.enabled)
        return newStatus.enabled
    }

    func currentResourceSettings() throws(AMLError) -> [AMLResourceSetting]? {
        return try _resourceSettings(node: "_CRS")
    }

    func possibleResourceSettings() throws(AMLError) -> [AMLResourceSetting]? {
        return try _resourceSettings(node: "_PRS")
    }

    func setResourceSettings(_ resources: [AMLResourceSetting]) throws(AMLError) {

        guard let srsNode = childNode(named: "_SRS"), let srsMethod = srsNode.object.methodValue else {
            throw AMLError.invalidMethod(reason: "No method \(fullname())._SRS")
        }

        // Get the current CRS to compare and overwrite
        guard let crsBuffer = try _resourceSettingsBuffer(node: "_CRS") else {
            throw AMLError.invalidData(reason: "Cannot set resources as no _CRS")
        }
        let srsBuffer = encodeResourceData(resources)
        guard crsBuffer.count == srsBuffer.count else {
            throw AMLError.invalidData(reason: "Setting SRS of buffer length \(srsBuffer.count), but CRS has buffer length \(crsBuffer.count)")
        }
        let crs = decodeResourceData(crsBuffer)
        guard resources.count == crs.count else {
            throw AMLError.invalidData(reason: "Setting SRS of element length \(srsBuffer.count), but CRS has element length \(crsBuffer.count)")
        }
        // TODO: Add more validation that the 2 buffers are matching in specific resource types

        let arg = AMLObject(srsBuffer)
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(srsNode.fullname()), args: [arg])
        try srsMethod.execute(context: &context)
    }

    private func _resourceSettingsBuffer(node: String) throws(AMLError) -> AMLBuffer? {
        guard let crs = childNode(named: node) else {
            return nil
        }
        let crsValue = try crs.amlObject()

        guard let buffer = crsValue.bufferValue else {
            fatalError("crsObject namedValue \(crsValue) is not a buffer")
        }
        return buffer.asAMLBuffer()
    }

    private func _resourceSettings(node: String) throws(AMLError) -> [AMLResourceSetting]? {
        guard let buffer = try _resourceSettingsBuffer(node: node) else {
            return nil
        }
        return decodeResourceData(buffer)
    }

    func hardwareId() throws(AMLError) -> String? {
        guard let hidNode = childNode(named: "_HID") else {
            return nil
        }

        let hidValue = try hidNode.amlObject()
        if hidValue.isInteger || hidValue.isString {
            return decodeHID(obj: hidValue)
        }
        if let hidMethod = hidNode.object.methodValue {
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(hidNode.fullname()))
            return decodeHID(obj: try hidMethod.readValue(context: &context))
        }
        fatalError("\(hidNode.fullname()) has invalid node for _HID: \(type(of: hidNode))")
    }


    func compatibleIds() throws(AMLError) -> [String]? {
        guard let cid = childNode(named: "_CID") else {
            return nil
        }
        let cidValue = try cid.amlObject()

        if cidValue.isInteger || cidValue.isString {
            return [decodeHID(obj: cidValue)]
        }

        // _CID could be a package containg multiple values, so take the first (for now)
        if let package = cidValue.packageValue {
            guard package.count > 0 else { return nil }
            var cids: [String] = []
            for value in package {
                if value.isInteger || value.isString {
                    cids.append(decodeHID(obj: value))
                } else {
                    fatalError("\(cid.fullname()) has invalid value for pnpname: \(value)")
                }

            }
            return cids
        } else {
            fatalError("\(cid.fullname()) has invalid value for pnpname: \(cidValue)")
        }
    }


    func uniqueId() throws(AMLError) -> AMLObject? { // Integer or String
        if let uidValue = try childNode(named: "_UID")?.amlObject(), uidValue.isInteger || uidValue.isString {
            return uidValue
        }
        return nil
    }


    func baseBusNumber() throws(AMLError) -> UInt8? {
        if let bbnValue = try childNode(named: "_BBN")?.amlObject().integerValue {
            return UInt8(truncatingIfNeeded: bbnValue)
        } else {
            return nil
        }
    }


    func addressResource() throws(AMLError) -> AMLInteger? {
        guard let adr = try childNode(named: "_ADR")?.amlObject().integerValue else {
            // Override missing _ADR for Root PCIBus
            return self.fullname() == "\\_SB.PCI0" ? AMLInteger(0) : nil
        }
        return adr
    }

    func pciRoutingTable() -> PCIRoutingTable? {
        if let prtNode = childNode(named: "_PRT") {
            return PCIRoutingTable(prtNode: prtNode)
        } else {
            return nil
        }
    }
}


typealias AMLObjectType = AMLByteData
struct AMLDefExternal {
    // ExternalOp NameString ObjectType ArgumentCount
    // let name: AMLNameString

    let type: AMLObjectType
    let argCount: AMLByteData // (0 - 7)

    init(name: AMLNameString, type: AMLObjectType, argCount: AMLByteData) throws(AMLError) {
        guard argCount <= 7 else {
            let reason = "argCount must be 0-7, not \(argCount)"
            throw AMLError.invalidData(reason: reason)
        }

        self.type = type
        self.argCount = argCount
    //    super.init(name: name)
    }
}




struct AMLDefMutex {
    let name: AMLNameString
    let flags: AMLMutexFlags

    init(name: AMLNameString, flags: AMLMutexFlags) {
        self.name = name
        self.flags = flags
    }

    // FIXME: Implement correct locking
    func acquire(timeout: AMLWordData) -> Bool {
        if ACPIDebug {
            #kprintf("acpi: Acquiring mutex '%s'\n", name.value)
        }
        return false  //Acquired
    }

    func release() {
        if ACPIDebug {
            #kprintf("acpi: Releasing mutex '%s'\n", name.value)
        }
    }
}


enum AMLRegionSpace: AMLByteData, CustomStringConvertible {
    case systemMemory = 0x00
    case systemIO = 0x01
    case pciConfig = 0x02
    case embeddedControl = 0x03
    case smbus = 0x04
    case systemCMOS = 0x05
    case pciBarTarget = 0x06
    case ipmi = 0x07
    case generalPurposeIO = 0x08
    case genericSerialBus = 0x09
    case oemDefined = 0x80 // .. 0xff fixme

    var description: String {
        return switch self {
            case .systemMemory: "System Memory"
            case .systemIO: "System IO"
            case .pciConfig: "PCI Config"
            case .embeddedControl: "EmbeddedControl"
            case .smbus: "SMBus"
            case .systemCMOS: "System CMOS"
            case .pciBarTarget: "PCI Bar Target"
            case .ipmi: "IPMI"
            case .generalPurposeIO: "GPIO"
            case .genericSerialBus: "GPSerialBus"
            default: "OEMDefined"
        }
    }
}


struct AMLDefProcessor {
    // ProcessorOp PkgLength NameString ProcID PblkAddr PblkLen ObjectList
    let procId: AMLByteData
    let pblkAddr: AMLDWordData
    let pblkLen: AMLByteData
    let objects: AMLTermList

    init(name: AMLNameString, procId: AMLByteData, pblkAddr: AMLDWordData, pblkLen: AMLByteData, objects: AMLTermList) {
        self.procId = procId
        self.pblkAddr = pblkAddr
        self.pblkLen = pblkLen
        self.objects = objects
    }
}

struct AMLDefPowerResource {
    // PowerResOp PkgLength NameString SystemLevel ResourceOrder TermList
    let name: AMLNameString
    let systemLevel: AMLByteData
    let resourceOrder: AMLWordData
    let termList: AMLTermList
}
