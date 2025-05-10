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
        guard let crs = childNode(named: node), let crsValue = try? crs.amlObject() else {
            return nil
        }

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
            #kprint("Cant find _ADR in", self.fullname())
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
}


enum AMLRegionSpace: AMLByteData {
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
}

enum OpRegionSpace: CustomStringConvertible {
    case systemMemory(SystemMemorySpace)
    case systemIO(SystemIO)
    case pciConfig(PCIConfigRegionSpace)
    case embeddedControl(EmbeddedControlRegionSpace)
    case smbus
    case systemCMOS
    case pciBarTarget
    case ipmi
    case generalPurposeIO
    case genericSerialBus
    case oemDefined(UInt8)

    var regionType: UInt8 {
        switch self {
        case .systemMemory(_): return 0x00
        case .systemIO(_): return 0x01
        case .pciConfig(_): return 0x02
        case .embeddedControl(_): return 0x03
        case .smbus: return 0x04
        case .systemCMOS: return 0x05
        case .pciBarTarget: return 0x06
        case .ipmi: return 0x07
        case .generalPurposeIO: return 0x08
        case .genericSerialBus: return 0x09
        case let .oemDefined(region): return region // .. 0xff fixme
        }
    }

    var description: String {
        switch self {
        case let .systemMemory(region): return region.description
        case let .systemIO(region): return region.description
        case let .pciConfig(region): return region.description
        case let .embeddedControl(region): return region.description
        case .smbus: return "SMBus"
        case .systemCMOS: return "SystemCMOS"
        case .pciBarTarget: return "PCIBarTarget"
        case .ipmi: return "IPMI"
        case .generalPurposeIO: return "GPIO"
        case .genericSerialBus: return "GPSB"
        case .oemDefined: return "OEMDefined"
        }
    }


    var length: Int {
        switch self {
        case let .systemMemory(region): return region.length
        case let .systemIO(region): return region.length
        case let .pciConfig(region): return region.length
        case let .embeddedControl(region): return region.length
        case .smbus: return 0
        case .systemCMOS: return 0
        case .pciBarTarget: return 0
        case .ipmi: return 0
        case .generalPurposeIO: return 0
        case .genericSerialBus: return 0
        case .oemDefined: return 0
        }
    }


    func read(atIndex index: Int, flags: AMLFieldFlags) -> AMLInteger {
        switch self {
        case let .systemMemory(region): return region.read(atIndex: index, flags: flags)
        case let .systemIO(region): return region.read(atIndex: index, flags: flags)
        case let .pciConfig(region): return region.read(atIndex: index, flags: flags)
        case let .embeddedControl(region): return region.read(atIndex: index, flags: flags)
        case .smbus: fatalError("OpRegionSpace.read() not implemented for smbus")
        case .systemCMOS: fatalError("OpRegionSpace.read() not implemented for systemCMOS")
        case .pciBarTarget: fatalError("OpRegionSpace.read() not implemented for pciBarTarget")
        case .ipmi: fatalError("OpRegionSpace.read() not implemented for ipmp")
        case .generalPurposeIO: fatalError("OpRegionSpace.read() not implemented for generalPurposeIO")
        case .genericSerialBus: fatalError("OpRegionSpace.read() not implemented for genericSerialBus")
        case .oemDefined: fatalError("OpRegionSpace.read() not implemented for oemDefined")
        }
    }


    func write(atIndex index: Int, value: AMLInteger, flags: AMLFieldFlags) {
        #kprintf("OpRegionSpace.write(index: %d value: %X type: %s)\n", index, value, self.description)
        switch self {
        case let .systemMemory(region): return region.write(atIndex: index, value: value, flags: flags)
        case let .systemIO(region): return region.write(atIndex: index, value: value, flags: flags)
        case let .pciConfig(region): return region.write(atIndex: index, value: value, flags: flags)
        case let .embeddedControl(region): return region.write(atIndex: index, value: value, flags: flags)
        case .smbus: fatalError("OpRegionSpace.read() not implemented for smbus")
        case .systemCMOS: fatalError("OpRegionSpace.read() not implemented for systemCMOS")
        case .pciBarTarget: fatalError("OpRegionSpace.read() not implemented for pciBarTarget")
        case .ipmi: fatalError("OpRegionSpace.read() not implemented for ipmp")
        case .generalPurposeIO: fatalError("OpRegionSpace.read() not implemented for generalPurposeIO")
        case .genericSerialBus: fatalError("OpRegionSpace.read() not implemented for genericSerialBus")
        case .oemDefined: fatalError("OpRegionSpace.read() not implemented for oemDefined")
        }
    }

    private func elementBitWidth(flags: AMLFieldFlags) -> Int  {
        switch flags.fieldAccessType {
            case .AnyAcc, .ByteAcc: return 8
            case .WordAcc: return 16
            case .DWordAcc: return 32
            case .QWordAcc: return 64
            case .BufferAcc: return 0
        }
    }

    // LittleEndian read
    func read(bitOffset: Int, width: Int, flags: AMLFieldFlags) -> AMLInteger {
        precondition(bitOffset >= 0)
        precondition(width >= 1)

        let elementBits = elementBitWidth(flags: flags)
        precondition((bitOffset + width) <= (length * elementBits))

        var _width = width
        var index = bitOffset / elementBits
        var startBit = bitOffset % elementBits

        var result: AMLInteger = 0
        var elementShift = 0
        var bitShift = elementShift - startBit
        repeat {
            let endBit = min(elementBits - 1, _width + startBit - 1)
            let bitCount = (endBit + 1 - startBit)
            let valueMask = createMask(startBit, endBit) << bitShift

            let value = read(atIndex: index, flags: flags) << bitShift
            result |= (value & valueMask)

            startBit = 0
            elementShift += elementBits
            bitShift += elementBits
            _width -= bitCount
            index += 1
            assert(_width >= 0)
        } while _width > 0

        return result
    }

    // LittleEndian write
    func write(bitOffset: Int, width: Int, value: AMLInteger, flags: AMLFieldFlags) {
        precondition(bitOffset >= 0)
        precondition(width >= 1)
       // precondition(width <= AMLInteger.bitWidth)

        let elementBits = elementBitWidth(flags: flags)
        precondition((bitOffset + width) <= (length * elementBits))

        // Truncate the value to fit in the destination
        let mask = (width == AMLInteger.bitWidth) ? AMLInteger.max : AMLInteger((1 << width) - 1)
        let value = value & mask

        var _width = width
        var elementValue = value
        var index = bitOffset / elementBits
        var startBit = bitOffset % elementBits

        repeat {
            let endBit = min(elementBits - 1, _width + startBit - 1)
            let elementMask = createMask(startBit, endBit)
            let bitCount = (endBit + 1 - startBit)
            let valueMask: AMLInteger = bitCount == AMLInteger.bitWidth ? AMLInteger.max : (1 << bitCount) - 1

            let value = (elementValue & valueMask) << startBit
            let valueToWrite: AMLInteger

            if elementMask == AMLInteger.max {
                valueToWrite = value
            } else {
                switch flags.updateRule {
                    case .Preserve:
                        let curValue = read(atIndex: index, flags: flags) & ~elementMask
                        valueToWrite = curValue | value

                    case .WriteAsOnes:
                        valueToWrite = value | ~elementMask

                    case .WriteAsZeros:
                        valueToWrite = value
                }
            }
            write(atIndex: index, value: valueToWrite, flags: flags)

            elementValue = elementValue >> bitCount
            startBit = 0
            _width -= bitCount
            index += 1
            assert(_width >= 0)
        } while _width > 0

        #if TEST
        // testing check
        let readBack = read(bitOffset: bitOffset, width: width, flags: flags)
        if readBack != value {
            fatalError("read after write failed [value=\(value) readBack=\(readBack)]")
        }
        #endif
    }

    private func createMask(_ startBit: Int, _ endBit: Int) -> AMLInteger {
        let bits = endBit - startBit + 1
        guard bits < AMLInteger.bitWidth else { return AMLInteger.max }
        let mask: AMLInteger = (1 << AMLInteger(bits)) - 1
        return mask << AMLInteger(startBit)
    }
}

struct EmbeddedControlRegionSpace: CustomStringConvertible {
    let flags: AMLFieldFlags
    let offset: AMLInteger
    let length: Int

    var description: String {
        return "EmbeddedControlRegionSpace"
    }

    init(offset: AMLInteger, length: AMLInteger) {
        self.offset = offset
        self.length = Int(length)
        fatalError("EmbeddedControlRegionSpace not implemented")
    }

    func read(bitOffset: Int, width: Int, flags: AMLFieldFlags) -> AMLInteger {
        fatalError("EmbeddedControlRegionSpace.read not implemented")
    }

    func write(bitOffset: Int, width: Int, value: AMLInteger, flags: AMLFieldFlags) {
        fatalError("EmbeddedControlRegionSpace.wite not implemented")
    }

    func read(atIndex: Int, flags: AMLFieldFlags) -> AMLInteger {
        fatalError("EmbeddedControlRegionSpace.read not implemented")
    }

    func write(atIndex: Int, value: AMLInteger, flags: AMLFieldFlags) {
        fatalError("EmbeddedControlRegionSpace.wite not implemented")
    }
}


struct SystemMemorySpace: CustomStringConvertible {
    let offset: UInt
    let length: Int
    private let mmioRegion: MMIORegion  // FIXME: Should probably just be an UnsafeRawPointer

    var description: String {
        return "SystemMemory: offset: 0x\(String(offset, radix: 16)), length: \(length)"
    }


    init(offset: AMLInteger, length: AMLInteger) {
        precondition(length > 0)
        self.offset = UInt(offset)
        self.length = Int(length)
        let region = PhysRegion(start: PhysAddress(UInt(offset)), size: UInt(length))
        mmioRegion = mapIORegion(region: region)
    }


    func read(atIndex index: Int, flags: AMLFieldFlags) -> AMLInteger {
        switch flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                return AMLInteger(mmioRegion.read(fromByteOffset: index) as UInt8)

            case .WordAcc:
                return AMLInteger(mmioRegion.read(fromByteOffset: index * 2) as UInt16)

            case .DWordAcc:
                return AMLInteger(mmioRegion.read(fromByteOffset: index * 4) as UInt32)

            case .QWordAcc:
                return AMLInteger(mmioRegion.read(fromByteOffset: index * 8) as UInt64)

            case .BufferAcc: fatalError("Buffer access used in a SystemRegion for reading")
        }
    }

    func write(atIndex index: Int, value: AMLInteger, flags: AMLFieldFlags) {
        let newIndex: Int
        switch flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                mmioRegion.write(value: UInt8(truncatingIfNeeded: value), toByteOffset: index)
                newIndex = index

            case .WordAcc:
                mmioRegion.write(value: UInt16(truncatingIfNeeded: value), toByteOffset: index * 2)
                newIndex = index * 2

            case .DWordAcc:
                mmioRegion.write(value: UInt32(truncatingIfNeeded: value), toByteOffset: index * 4)
                newIndex = index * 4

            case .QWordAcc:
                mmioRegion.write(value: UInt64(truncatingIfNeeded: value), toByteOffset: index * 8)
                newIndex = index * 8

            case .BufferAcc: fatalError("Buffer access used in a SystemRegion for writing")
        }
        let address = offset + UInt(newIndex)
        #kprintf("ACPI: SystemMemorySpace.write: %#x index: %d value: %x newIndex: %d length: %d\n",
                 address, index, value, newIndex, length)
    }
}


struct SystemIO: CustomStringConvertible {
    let port: UInt16
    let length: Int

    var description: String {
        return "SystemMemory: port: 0x\(String(port, radix: 16)), length: \(length)"
    }


    init(port: AMLInteger, length: AMLInteger) {
        precondition(length > 0)
        precondition(port + length <= UInt16.max)
        self.port = UInt16(port)
        self.length = Int(length)
    }


    func read(atIndex index: Int, flags: AMLFieldFlags) -> AMLInteger {
        var offset = UInt16(index)
        let result: AMLInteger

        switch flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                result = AMLInteger(inb(port + offset))

            case .WordAcc:
                offset *= 2
                result = AMLInteger(inw(port + offset))

            case .DWordAcc:
                offset *= 4
                result = AMLInteger(inl(port + offset))

            default:
                fatalError("\(flags.fieldAccessType) access not allowed in a SystemIO region")
        }
        //print("Read \(flags.fieldAccessType) from port 0x\(String(port + offset, radix: 16)) -> 0x\(String(result, radix: 16))")
        return result
    }


    func write(atIndex index: Int, value: AMLInteger, flags: AMLFieldFlags) {
        var offset = UInt16(index)

        switch flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                outb(port + offset, UInt8(truncatingIfNeeded: value))

            case .WordAcc:
                offset *= 2
                outw(port + offset, UInt16(truncatingIfNeeded: value))

            case .DWordAcc:
                offset *= 4
                outl(port + offset, UInt32(truncatingIfNeeded: value))

            default:
                fatalError("\(flags.fieldAccessType) access not allowed in a SystemIO region")
        }
        //print("Wrote \(flags.fieldAccessType) 0x\(String(value, radix: 16)) to port 0x\(String(port + offset, radix: 16))")
    }
}


struct PCIConfigRegionSpace: CustomStringConvertible {
    let config: PCIConfigSpace
    let offset: UInt
    let length: Int

    var description: String {
        return "PCIConfigSpace: offset: 0x\(String(offset, radix: 16)), length: \(length)"
    }

    init(config: PCIConfigSpace, offset: AMLInteger, length: AMLInteger) {
        precondition(length > 0)
        precondition(offset + length <= 256)

        self.config = config
        self.offset = UInt(offset)
        self.length = Int(length)
    }


    func read(atIndex index: Int, flags: AMLFieldFlags) -> AMLInteger {
        //print("PCIConfigRegionSpace.read offset: \(offset) index: 0x\(String(index, radix: 16)) accesstype: \(flags.fieldAccessType)")
        switch flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                return AMLInteger(config.readConfigByte(atByteOffset: offset + UInt(index)))

            case .WordAcc:
                return AMLInteger(config.readConfigWord(atByteOffset: offset + UInt(index * 2)))

            case .DWordAcc:
                return AMLInteger(config.readConfigDword(atByteOffset: offset + UInt(index * 4)))

            default:
                fatalError("\(flags.fieldAccessType) access not allowed in a PCIConfig region")
        }
    }


    func write(atIndex index: Int, value: AMLInteger, flags: AMLFieldFlags) {
        #kprint("PCIConfigRegionSpace.write offset: \(offset) index: 0x\(String(index, radix: 16)) value: 0x\(String(value, radix: 16)) accesstype: \(flags.fieldAccessType)")
        switch flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                config.writeConfigByte(atByteOffset: offset + UInt(index), value: UInt8(truncatingIfNeeded: value))

            case .WordAcc:
                config.writeConfigWord(atByteOffset: offset + UInt(index * 2), value: UInt16(truncatingIfNeeded: value))

            case .DWordAcc:
                config.writeConfigDword(atByteOffset: offset + UInt(index * 4), value: UInt32(truncatingIfNeeded: value))

            default:
                fatalError("\(flags.fieldAccessType) access not allowed in a PCIConfig region")

        }
    }
}


final class AMLDefOpRegion {
    // OpRegionOp NameString RegionSpace RegionOffset RegionLen
    let fullname: AMLNameString
    let regionSpaceType: AMLRegionSpace
    let offset: AMLTermArg // => Integer
    let length: AMLTermArg // => Integer
    private var regionSpace: OpRegionSpace?


    var description: String {
        let _offset = offset.description
        let _length = length.description
       // let rs = regionSpace?.description ?? "nil"
        return "regionType: \(regionSpaceType)\noffset: \(_offset)\nlength: \(_length)\nregionSpace: "
    }


    // FIXME .regionSpace can be initialised here if offset and length are both AMLIntegerData
    init(fullname: AMLNameString, region: AMLRegionSpace, offset: AMLTermArg, length: AMLTermArg) {
//        var context =
        self.fullname = fullname
        self.regionSpaceType = region
        self.offset = offset
        self.length = length
    }

    private func findPciRoot(for node: ACPI.ACPIObjectNode) throws(AMLError) -> ACPI.ACPIObjectNode {
        let rootIDs = ["PNP0A03", "PNP0308"]
        var parent: ACPI.ACPIObjectNode? = node
        while let p = parent {
            if let hid = try p.hardwareId(), rootIDs.contains(hid) {
                return p
            }
            if let cids = try p.compatibleIds() {
                for cid in cids {
                    if rootIDs.contains(cid) {
                        return p
                    }
                }
            }
            parent = p.parent
        }
        throw AMLError.error(reason: "Cannot find Root PCI containing \(node.fullname())")
    }


    func getRegionSpace(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> OpRegionSpace {
        if let rs = regionSpace {
            return rs
        }

        let regionOffset = try offset.evaluate(context: &context).integerValue!
        let regionLength = try length.evaluate(context: &context).integerValue!

        switch regionSpaceType {
            case .systemMemory:
                regionSpace = .systemMemory(SystemMemorySpace(offset: regionOffset, length: regionLength))

            case .systemIO:
                regionSpace = .systemIO(SystemIO(port: regionOffset, length: regionLength))

            case .pciConfig:
                guard let (_node, fullname) = context.getObject(named: self.fullname) else {
                    fatalError("Cant find node: \(self.fullname)")
                }

                let root = try findPciRoot(for: _node)
                guard let bbn = try root.baseBusNumber() else {
                    throw AMLError.error(reason: "\(root) has no _BBN")
                }
                // Find the PCI address for the device
                var node: ACPI.ACPIObjectNode? = _node
                var address: UInt64? = nil

                // Find the enclosing device for this node and then find its _ADR
                while let n = node {
                    if n.object.isDevice {
                        address = try n.addressResource()
                        break
                    }
                    node = n.parent
                }
                guard node != nil else {
                    throw AMLError.error(reason: "Cannot find containing device for \(_node.fullname())")
                }

                if let address = address  {
                    let configSpace = PCIConfigSpace(busId: UInt8(bbn),
                                                     device: UInt8(truncatingIfNeeded: address >> 16),
                                                     function: UInt8(truncatingIfNeeded: address))
                    #kprintf("ACPI: %s: Using %s for PCI_Region\n",  fullname, configSpace.description)
                    regionSpace = .pciConfig(PCIConfigRegionSpace(config: configSpace, offset: regionOffset, length: regionLength))
                } else {
                    fatalError("ACPI: Cant determine PCI_Region for \(self)")
                }

            case .embeddedControl:
                    regionSpace = .embeddedControl(EmbeddedControlRegionSpace(offset: regionOffset, length: regionLength))

            case .smbus: fallthrough
            case .systemCMOS: fallthrough
            case .pciBarTarget: fallthrough
            case .ipmi: fallthrough
            case .generalPurposeIO: fallthrough
            case .genericSerialBus: fallthrough
            case .oemDefined:
                fatalError("\(regionSpaceType) region not implemented")
        }
        return regionSpace!
    }


    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLTermArg {
        let o = try operandAsInteger(operand: offset, context: &context)
        let l = try operandAsInteger(operand: length, context: &context)
        fatalError("do somthing with \(o) and \(l)")
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
