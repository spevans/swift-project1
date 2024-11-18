//
//  kernel/devices/acpi/amlnamedobject.swift
//  project1
//
//  Created by Simon Evans on 25/11/2017.
//  Copyright © 2017 - 2019 Simon Evans. All rights reserved.
//
//  Named Object types


// Named Objects
typealias AMLNamedObj = ACPI.ACPIObjectNode


final class AMLDefDataRegion: AMLNamedObj {
    var isReadOnly: Bool { return false }


    // DataRegionOp NameString TermArg TermArg TermArg
    //let name: AMLNameString
    let arg1: AMLTermArg
    let arg2: AMLTermArg
    let arg3: AMLTermArg

    init(name: AMLNameString, arg1: AMLTermArg, arg2: AMLTermArg, arg3: AMLTermArg) {
        self.arg1 = arg1
        self.arg2 = arg2
        self.arg3 = arg3
        super.init(name: name)
    }
}


final class AMLDefDevice: AMLNamedObj {

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
    //let name: AMLNameString
    let value: AMLTermList
    private(set) var device: Device? = nil

    override var description: String {
        var result = "ACPI Device:"
        if let devname = device {
            result += " [\(devname)]"
        } else {
            result += " No driver set"
        }
        return result
    }

    init(name: AMLNameString, value: AMLTermList) {
        self.value = value
        super.init(name: name)
    }

    func setDevice(_ device: Device) {
        if let curDevice = self.device {
            fatalError("\(fullname()) already has a device \(curDevice), cant set to \(device)")
        }
        self.device = device
    }
}

// Helper functions for ACPI Device nodes
extension AMLNamedObj {

    func currentResourceSettings() -> [AMLResourceSetting]? {
        return _resourceSettings(node: "_CRS")
    }

    func possibleResourceSettings() -> [AMLResourceSetting]? {
        return _resourceSettings(node: "_PRS")
    }


    private func _resourceSettings(node: String) -> [AMLResourceSetting]? {
        guard let crs = childNode(named: node) else {
            return nil
        }

        let buffer: AMLSharedBuffer
        if let obj = (crs as? AMLNamedValue)?.value {
            guard let _buffer = obj.bufferValue else {
                fatalError("crsObject namedValue \(self.fullname()) not a buffer")
            }
            buffer = _buffer
        } else {
            guard let crsObject = crs as? AMLMethod else {
                fatalError("CRS object is an \(type(of: crs))")
            }
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(crs.fullname()))
            let value = crsObject.readValue(context: &context)
            guard let _buffer = value.bufferValue else {
                fatalError("crsObject returned \(value) not a buffer")
            }
            buffer = _buffer
        }
        return decodeResourceData(buffer)
    }

    // _CID or _HID, used for PNP
    var deviceId: String? { hardwareId() ?? pnpName() }

    func hardwareId() -> String? {
        guard let hid = childNode(named: "_HID") else {
            return nil
        }

        if let hidName = hid as? AMLNamedValue {
            switch hidName.value {
                case .dataObject(let object): return decodeHID(obj: object)
                default: fatalError("\(hid.fullname()) has invalid value for pnpname: \(hidName.value)")
            }
        }

        if let hidMethod = hid as? AMLMethod {
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(hid.fullname()))
            return decodeHID(obj: hidMethod.readValue(context: &context))

        }
        return nil
    }


    // FIXME, maybe return an array of String if source is a package
    func pnpName() -> String? {
        guard let cid = childNode(named: "_CID") else {
            return nil
        }

        let value: AMLTermArg
        if let cidName = cid as? AMLNamedValue {
            let dataRefObject = cidName.value
            guard let object = dataRefObject.dataObject else {
                fatalError("\(cid.fullname()) has invalid value for pnpname: \(dataRefObject)")
            }
            value = object
        } else if let cidMethod = cid as? AMLMethod {
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(cid.fullname()))
            value = cidMethod.readValue(context: &context)
        } else {
            return nil
        }


        guard let object = value as? AMLDataObject else {
            fatalError("\(cid.fullname()) has invalid value for pnpname: \(value)")
        }

        // _CID could be a package containg multiple values, so take the first (for now)
        if case let .package(package) = object {
            for value in package {
                guard let data = value.dataRefObject?.dataObject else {
                    fatalError("\(cid.fullname()) has invalid value for pnpname: \(value)")
                }
                return decodeHID(obj: data)
            }
        } else {
            return decodeHID(obj: object)
        }

        return nil
    }


    func uniqueId() -> AMLDataObject? { // Integer or String
        guard let uid = childNode(named: "_UID") else { return nil }

        var value: AMLDataObject? = nil

        if let uidValue = uid as? AMLNamedValue {
            value = uidValue.value.dataObject
        }
        else if let uidMethod = uid as? AMLMethod {
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(uid.fullname()))
            value = uidMethod.readValue(context: &context) as? AMLDataObject
        }

        guard let dataObject = value else {
            fatalError("\(uid.fullname()): doesnt evaluate to a dataobject")
        }

        switch dataObject {
            case .integer, .string: return dataObject
            default: break
        }

        fatalError("\(uid.fullname()) has invalid valid for _UID: \(dataObject)")
    }


    func addressResource() -> AMLInteger? {
        guard let adr = childNode(named: "_ADR") as? AMLNamedValue else {
            print("Cant find _ADR in", self.fullname())
            // Override missing _ADR for Root PCIBus
            return self.fullname() == "\\_SB.PCI0" ? AMLInteger(0) : nil
        }

        return adr.value.integerValue
    }
}


typealias AMLObjectType = AMLByteData
final class AMLDefExternal: AMLNamedObj {
    // ExternalOp NameString ObjectType ArgumentCount
    // let name: AMLNameString

    let type: AMLObjectType
    let argCount: AMLByteData // (0 - 7)

    init(name: AMLNameString, type: AMLObjectType, argCount: AMLByteData) throws {
        guard argCount <= 7 else {
            let reason = "argCount must be 0-7, not \(argCount)"
            throw AMLError.invalidData(reason: reason)
        }

        self.type = type
        self.argCount = argCount
        super.init(name: name)
    }
}


final class AMLMethod: AMLNamedObj {
    //let name: AMLNameString
    let flags: AMLMethodFlags
    var parser: AMLParser!
    private var _termList: AMLTermList?


    init(name: AMLNameString, flags: AMLMethodFlags, parser: AMLParser?) {
        self.flags = flags
        self.parser = parser
        super.init(name: name)
    }

    func termList() throws -> AMLTermList {
        if _termList == nil {
            _termList = try parser.parseTermList()
            parser = nil
        }
        return _termList!
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        let termList = try self.termList()
        try context.execute(termList: termList)
    }

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        do {
            try execute(context: &context)
            return context.returnValue!
        } catch {
            if let error = error as? AMLError {
                fatalError("ACPI AML parsing error: \(error.description)")
            } else {
                fatalError("Unknown ACPI AML error")
            }
        }
    }
}



final class AMLDefMutex: AMLNamedObj {
    //let name: AMLNameString
    let flags: AMLMutexFlags

    init(name: AMLNameString, flags: AMLMutexFlags) {
        self.flags = flags
        super.init(name: name)
    }
}

enum AMLFieldAccessType: AMLByteData, CustomStringConvertible {
    case AnyAcc     = 0
    case ByteAcc    = 1
    case WordAcc    = 2
    case DWordAcc   = 3
    case QWordAcc   = 4
    case BufferAcc  = 5 //

    var description: String {
        switch self {
            case .AnyAcc: return "AnyWidth"
            case .ByteAcc: return "Byte"
            case .WordAcc: return "Word"
            case .DWordAcc: return "DWord"
            case .QWordAcc: return "QWord"
            case .BufferAcc: return "Buffer"
        }
    }


    init?(_ value: AMLByteData) {
        let type = value & 0xf
        self.init(rawValue: type)
    }
}

enum AMLLockRule {
    case NoLock
    case Lock

    init(_ value: AMLByteData) {
        if (value & 0x10) == 0x00 {
            self = .NoLock
        } else {
            self = .Lock
        }
    }
}

enum AMLUpdateRule: AMLByteData {
    case Preserve     = 0
    case WriteAsOnes  = 1
    case WriteAsZeros = 2

    init?(_ value: AMLByteData) {
        self.init(rawValue: BitArray8(value)[5...6])
    }
}

struct AMLFieldFlags: CustomStringConvertible {
    // let value: AMLByteData
    let fieldAccessType: AMLFieldAccessType
    let lockRule: AMLLockRule
    let updateRule: AMLUpdateRule

    var description: String {
        return "\(fieldAccessType), \(lockRule), \(updateRule)"
    }

    init(fieldAccessType: AMLFieldAccessType, lockRule: AMLLockRule, updateRule: AMLUpdateRule) {
        self.fieldAccessType = fieldAccessType
        self.lockRule = lockRule
        self.updateRule = updateRule
    }

    init(flags value: AMLByteData) {
        guard let _fieldAccessType = AMLFieldAccessType(value) else {
            fatalError("Invalid AMLFieldAccessType")
        }
        fieldAccessType = _fieldAccessType
        guard let _updateRule = AMLUpdateRule(value) else {
            fatalError("Invalid AMLUpdateRule")
        }
        updateRule = _updateRule
        lockRule = AMLLockRule(value)
    }
}




protocol OpRegionSpace: CustomStringConvertible {
    var length: Int { get }

    func read(bitOffset: Int, width: Int, flags: AMLFieldFlags) -> AMLInteger
    func write(bitOffset: Int, width: Int, value: AMLInteger, flags: AMLFieldFlags)
    func read(atIndex: Int, flags: AMLFieldFlags) -> AMLInteger
    func write(atIndex: Int, value: AMLInteger, flags: AMLFieldFlags)
}


extension OpRegionSpace {

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
        precondition(width <= AMLInteger.bitWidth)

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

struct EmbeddedControlRegionSpace: OpRegionSpace {
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


struct SystemMemorySpace: OpRegionSpace, CustomStringConvertible {
    let offset: UInt
    let length: Int
    private var mmioRegion: MMIORegion

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

            case .BufferAcc: fatalError("Buffer access used in a SystemRegion for reading")
        }
        let address = offset + UInt(newIndex)
        print("SystemMemorySpace.write 0x\(String(address, radix: 16)) index: \(index) value: \(value) newIndex \(newIndex) len: \(length)")
    }
}


struct SystemIO: OpRegionSpace, CustomStringConvertible {
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


private struct PCIConfigRegionSpace: OpRegionSpace, CustomStringConvertible {
    let config: PCIDeviceFunction
    let offset: UInt
    let length: Int

    var description: String {
        return "PCIConfigSpace: offset: 0x\(String(offset, radix: 16)), length: \(length)"
    }

    init(config: PCIDeviceFunction, offset: AMLInteger, length: AMLInteger) {
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
        //print("PCIConfigRegionSpace.write offset: \(offset) index: 0x\(String(index, radix: 16)) value: 0x\(String(value, radix: 16)) accesstype: \(flags.fieldAccessType)")
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


final class AMLDefOpRegion: AMLNamedObj {
    // OpRegionOp NameString RegionSpace RegionOffset RegionLen
    let regionSpaceType: AMLRegionSpace
    let offset: AMLTermArg // => Integer
    let length: AMLTermArg // => Integer
    private var regionSpace: OpRegionSpace?


    override var description: String {
        let _offset = offset.description
        let _length = length.description
        let rs = regionSpace?.description ?? "nil"
        return "regionType: \(regionSpaceType)\noffset: \(_offset)\nlength: \(_length)\nregionSpace: \(rs)"
    }


    // FIXME .regionSpace can be initialised here if offset and length are both AMLIntegerData
    init(name: AMLNameString, region: AMLRegionSpace, offset: AMLTermArg, length: AMLTermArg) {
        self.regionSpaceType = region
        self.offset = offset
        self.length = length
        super.init(name: name)
    }


    func getRegionSpace(context: inout ACPI.AMLExecutionContext) -> OpRegionSpace {
        if let rs = regionSpace {
            return rs
        }

        let regionOffset = offset.evaluate(context: &context).integerValue!
        let regionLength = length.evaluate(context: &context).integerValue!

        switch regionSpaceType {

            case .systemMemory:
                regionSpace = SystemMemorySpace(offset: regionOffset, length: regionLength)

            case .systemIO:
                regionSpace = SystemIO(port: regionOffset, length: regionLength)

            case .pciConfig:
                var node: AMLNamedObj? = self
                var configSpace: PCIDeviceFunction?
                while let n2 = node {
                    if let device = (n2 as? AMLDefDevice)?.device {
                        if let pciDevice = device as? PCIDevice {
                            configSpace = pciDevice.deviceFunction
                            break
                        } else if let pciHostBus = device as? PCIHostBus {
                            guard let pciBusDevice = pciHostBus.pciBus?.pciDevice else {
                                fatalError("\(self.fullname()) does not have a PCI Device")
                            }
                            configSpace = pciBusDevice.deviceFunction
                            break
                        } else {
                            fatalError("\(device): is not PCI but a \(type(of: device))")
                        }
                    }
                    node = node?.parent
                }

                if let configSpace = configSpace {
                    print("\(self.fullname()): Using \(configSpace) for PCI_Region")
                    regionSpace = PCIConfigRegionSpace(config: configSpace, offset: regionOffset, length: regionLength)
                } else {
                    fatalError("ACPI: Cant determine PCI_Region for \(self)")
                }

            case .embeddedControl:
                regionSpace = EmbeddedControlRegionSpace(offset: regionOffset, length: regionLength)

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


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let o = operandAsInteger(operand: offset, context: &context)
        let l = operandAsInteger(operand: length, context: &context)
        fatalError("do somthing with \(o) and \(l)")
    }
}


final class AMLDefProcessor: AMLNamedObj {
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
        super.init(name: name)
    }
}
