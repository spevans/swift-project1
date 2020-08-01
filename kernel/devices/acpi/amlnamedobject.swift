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


    // DeviceOp PkgLength NameString ObjectList
    //let name: AMLNameString
    let value: AMLObjectList


    init(name: AMLNameString, value: AMLObjectList) {
        self.value = value
        super.init(name: name)
    }


    func status() -> AMLDefDevice.DeviceStatus {
        guard let sta = childNode(named: "_STA") else {
            return .defaultStatus()
        }
        if let obj = sta as? AMLDefName, let v = obj.value as? AMLIntegerData {
            return AMLDefDevice.DeviceStatus(v.value)
        }

        var context = ACPI.AMLExecutionContext(scope: AMLNameString(sta.fullname()))
        if let v = sta.readValue(context: &context) as? AMLIntegerData {
            return AMLDefDevice.DeviceStatus(v.value)
        }
        fatalError("Cant determine status of: \(sta))")
    }


    func currentResourceSettings() -> [AMLResourceSetting]? {
        guard let crs = childNode(named: "_CRS") else {
            return nil
        }

        let buffer: AMLBuffer?
        if let obj = crs as? AMLDefName {
            buffer = obj.value as? AMLBuffer
        } else {
            guard let crsObject = crs as? AMLMethod else {
                fatalError("CRS object is an \(type(of: crs))")
            }
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(crs.fullname()))
            buffer = crsObject.readValue(context: &context) as? AMLBuffer
        }
        if buffer != nil {
            return decodeResourceData(buffer!)
        } else {
            return nil
        }
    }


    func hardwareId() -> String? {
        guard let hid = childNode(named: "_HID") else {
            return nil
        }

        if let hidName = hid as? AMLDefName {
            return (decodeHID(obj: hidName.value) as? AMLString)?.value
        }

        if let hidMethod = hid as? AMLMethod {
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(hid.fullname()))
            if let _hid = hidMethod.readValue(context: &context) as? AMLIntegerData {
                return (decodeHID(obj: _hid) as? AMLString)?.value
            }
        }
        return nil
    }


    func pnpName() -> String? {
        guard let cid = childNode(named: "_CID") else {
            return nil
        }

        if let cidName = cid as? AMLDefName {
            return (decodeHID(obj: cidName.value) as? AMLString)?.value
        }

        if let cidMethod = cid as? AMLMethod {
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(cid.fullname()))
            if let _cid = cidMethod.readValue(context: &context) as? AMLIntegerData {
                return (decodeHID(obj: _cid) as? AMLString)?.value
            }
        }

        return nil
    }


    func addressResource() -> AMLInteger? {
        guard let adr = childNode(named: "_ADR") as? AMLDefName else {
            print("Cant find _ADR in", self.fullname())
            return nil
        }

        return adr.integerValue()
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


struct AMLDefIndexField: AMLTermObj {
    // IndexFieldOp PkgLength NameString NameString FieldFlags FieldList
    let indexName: AMLNameString
    let dataName: AMLNameString
    let flags: AMLFieldFlags
    let fields: [AMLNamedObj]

    init(indexName: AMLNameString, dataName: AMLNameString, flags: AMLFieldFlags, fields: [AMLNamedObj]) {
        self.indexName = indexName
        self.dataName = dataName
        self.flags = flags
        self.fields = fields
    }
}


final class AMLMethod: AMLNamedObj {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }

    //let name: AMLNameString
    let flags: AMLMethodFlags
    private var parser: AMLParser!
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

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        do {
            let termList = try self.termList()
            try context.execute(termList: termList)
            return context.returnValue!
        } catch {
            fatalError(String(describing: error))
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


final class AMLDefBankField: AMLNamedObj {
    // BankFieldOp PkgLength NameString NameString BankValue FieldFlags FieldList
    //let name: AMLNameString
    let bankValue: AMLTermArg // => Integer
    let flags: AMLFieldFlags
    let fields: AMLFieldList

    init(name: AMLNameString, bankValue: AMLTermArg, flags: AMLFieldFlags, fields: AMLFieldList) {
        self.bankValue = bankValue
        self.flags = flags
        self.fields = fields
        super.init(name: name)
    }


    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        print("reading from \(self)")
        return AMLIntegerData(0)
    }

    override func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("Updating \(self) to \(to)")
    }
}


final class AMLDefCreateBitField: AMLNamedObj {
    // CreateBitFieldOp SourceBuff BitIndex NameString
    let sourceBuff: AMLTermArg
    let bitIndex: AMLInteger

    init(sourceBuff: AMLTermArg, bitIndex: AMLInteger, name: AMLNameString) {
        self.sourceBuff = sourceBuff
        self.bitIndex = bitIndex
        super.init(name: name)
    }

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        //let buffer = sourceBuff.evaluate(context: &context) as! AMLBuffer
        //print(type(of: self), "reading from \(buffer), bitIndex:", bitIndex)
        return AMLIntegerData(0)
    }

    override func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        //print(type(of: self), "Updating \(sourceBuff)[\(bitIndex)] to \(to)")
    }
}


final class AMLDefCreateByteField: AMLNamedObj {
    // CreateByteFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger
    //  let name: AMLNameString

    init(sourceBuff: AMLTermArg, byteIndex: AMLInteger, name: AMLNameString) {
        self.sourceBuff = sourceBuff
        self.byteIndex = byteIndex
        super.init(name: name)
    }


    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let buffer = sourceBuff.evaluate(context: &context) as! AMLBuffer
        return AMLIntegerData(AMLInteger(buffer.read(atIndex: byteIndex)))
    }

    override func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        //print(self.name.value, "updateValue, context:", context)
        var buffer = sourceBuff.evaluate(context: &context) as! AMLBuffer
        let byte = (to.evaluate(context: &context) as! AMLIntegerData).value
        buffer.write(atIndex: byteIndex, value: AMLByteData(byte))
    }
}


final class AMLDefCreateDWordField: AMLNamedObj {
    // CreateDWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger
    // let name: AMLNameString

    init(sourceBuff: AMLTermArg, byteIndex: AMLInteger, name: AMLNameString) {
        self.sourceBuff = sourceBuff
        self.byteIndex = byteIndex
        super.init(name: name)
    }

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        //let buffer = sourceBuff.evaluate(context: &context)
        //print(type(of: self), "reading from \(buffer), byteIndex:", byteIndex)
        return AMLIntegerData(0)
    }

    override func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        //print(type(of: self), "Updating \(sourceBuff)[\(byteIndex)] to \(to)")
    }
}


final class AMLDefCreateField: AMLNamedObj {
    // CreateFieldOp SourceBuff BitIndex NumBits NameString
    let sourceBuff: AMLTermArg
    let bitIndex: AMLInteger
    let numBits: AMLInteger

    init(sourceBuff: AMLTermArg, bitIndex: AMLInteger, numBits: AMLInteger, name: AMLNameString) {
        precondition(numBits > 0)
        self.sourceBuff = sourceBuff
        self.bitIndex = bitIndex
        self.numBits = numBits
        super.init(name: name)
    }


    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        //let buffer = sourceBuff.evaluate(context: &context)
        //print(type(of: self), "reading from \(buffer), byteIndex:", bitIndex)
        return AMLIntegerData(0)
    }

    override func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        //print(type(of: self), "Updating \(sourceBuff)[\(bitIndex)] to \(to)")
    }
}


final class AMLDefCreateQWordField: AMLNamedObj {
    // CreateQWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger

    init(sourceBuff: AMLTermArg, byteIndex: AMLInteger, name: AMLNameString) {
        self.sourceBuff = sourceBuff
        self.byteIndex = byteIndex
        super.init(name: name)
    }


    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        //let buffer = sourceBuff.evaluate(context: &context)
        //print(type(of: self), "reading from \(buffer), byteIndex:", byteIndex)
        return AMLIntegerData(0)
    }

    override func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        //print(type(of: self), "Updating \(sourceBuff)[\(byteIndex)] to \(to)")
    }
}


final class AMLDefCreateWordField: AMLNamedObj {
    // CreateWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger

    init(sourceBuff: AMLTermArg, byteIndex: AMLInteger, name: AMLNameString) {
        self.sourceBuff = sourceBuff
        self.byteIndex = byteIndex
        super.init(name: name)
    }


    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        //let buffer = sourceBuff.evaluate(context: &context)
        //print(type(of: self), "reading from \(buffer), byteIndex:", byteIndex)
        return AMLIntegerData(0)
    }

    override func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        //print(type(of: self), "Updating \(sourceBuff)[\(byteIndex)] to \(to)")
    }
}


struct AMLDefField: AMLTermObj {
    // FieldOp PkgLength NameString FieldFlags FieldList
    let regionName: AMLNameString
    let flags: AMLFieldFlags
    let fields: [AMLNamedObj]

    init(regionName: AMLNameString, flags: AMLFieldFlags, fields: [AMLNamedObj]) {
        self.regionName = regionName
        self.flags = flags
        self.fields = fields
    }
}


protocol OpRegionSpace {
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

        let elementBits = elementBitWidth(flags: flags)
        precondition((bitOffset + width) <= (length * elementBits))

        if value > (1 << width) {
            let max = (1 << width) - 1
            fatalError("Value [\(value)] cant fit in \(width) bits [max = \(max)]")
        }

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

struct EmbeddedControlRegionSpace: OpRegionSpace, CustomStringConvertible {
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
    private var data: UnsafeMutableRawPointer
    let offset: UInt
    let length: Int

    var description: String {
        return "SystemMemory: offset: 0x\(String(offset, radix: 16)), length: \(length)"
    }


    init(offset: AMLInteger, length: AMLInteger) {
        precondition(length > 0)
        self.offset = UInt(offset)
        self.length = Int(length)
#if TEST
        data = UnsafeMutableRawPointer.allocate(byteCount: self.length, alignment: 8)
#else
        data = PhysAddress(self.offset).rawPointer
#endif
    }


    func read(atIndex index: Int, flags: AMLFieldFlags) -> AMLInteger {
        switch flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                return AMLInteger(data.load(fromByteOffset: index, as: UInt8.self))

            case .WordAcc:
                return AMLInteger(data.load(fromByteOffset: index * 2, as: UInt16.self))

            case .DWordAcc:
                return AMLInteger(data.load(fromByteOffset: index * 4, as: UInt32.self))

            case .QWordAcc:
                return AMLInteger(data.load(fromByteOffset: index * 8, as: UInt64.self))

            case .BufferAcc: fatalError("Buffer access used in a SystemRegion for reading")
        }
    }

    func write(atIndex index: Int, value: AMLInteger, flags: AMLFieldFlags) {
        switch flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                data.storeBytes(of: UInt8(truncatingIfNeeded: value), toByteOffset: index, as: UInt8.self)

            case .WordAcc:
                data.storeBytes(of: UInt16(truncatingIfNeeded: value), toByteOffset: index * 2, as: UInt16.self)

            case .DWordAcc:
                data.storeBytes(of: UInt32(truncatingIfNeeded: value), toByteOffset: index * 4, as: UInt32.self)

            case .QWordAcc:
                data.storeBytes(of: UInt64(truncatingIfNeeded: value), toByteOffset: index * 8, as: UInt64.self)

            case .BufferAcc: fatalError("Buffer access used in a SystemRegion for reading")
        }
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


final class AMLDefOpRegion: AMLNamedObj, CustomStringConvertible {
    // OpRegionOp NameString RegionSpace RegionOffset RegionLen
    let regionSpaceType: AMLRegionSpace
    let offset: AMLTermArg // => Integer
    let length: AMLTermArg // => Integer
    private var regionSpace: OpRegionSpace?


    var description: String {
        let _offset: String
        if let o = offset as? AMLIntegerData {
            _offset = "0x" + String(o.value, radix: 16)
        } else {
            _offset = String(describing: offset)
        }

        let _length: String
        if let l = length as? AMLIntegerData {
            _length = l.value.description
        } else {
            _length = String(describing: length)
        }

        let rs = regionSpace != nil ? String(describing: regionSpace!) : "nil"
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

        let regionOffset = (offset.evaluate(context: &context) as! AMLIntegerData).value
        let regionLength = (length.evaluate(context: &context) as! AMLIntegerData).value

        switch regionSpaceType {

            case .systemMemory:
                regionSpace = SystemMemorySpace(offset: regionOffset, length: regionLength)

            case .systemIO:
                regionSpace = SystemIO(port: regionOffset, length: regionLength)

            case .pciConfig:
                guard let dev = self.parent as? AMLDefDevice else {
                    fatalError("\(parent!.fullname()) is not am AMLDefDevice")
                }

                guard let adr = dev.addressResource() else {
                    fatalError("Cant get addressResource for \(dev.fullname())")
                }

                var busId: UInt8 = 0
                var p: ACPI.ACPIObjectNode? = dev
                while let node = p {
                    if let bbnNode = node.childNode(named: "_BBN") as? AMLDefName, let bbnValue = bbnNode.integerValue() {
                        busId = UInt8(bbnValue)
                        break
                    }
                    p = node.parent
                }

                let device = UInt8(adr >> 16)
                let function = UInt8(truncatingIfNeeded: adr)
                let configSpace = PCIConfigSpace(busID: busId, device: device, function: function)
                regionSpace = PCIConfigRegionSpace(config: configSpace, offset: regionOffset, length: regionLength)

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
    let objects: AMLObjectList

    init(name: AMLNameString, procId: AMLByteData, pblkAddr: AMLDWordData, pblkLen: AMLByteData, objects: AMLObjectList) {
        self.procId = procId
        self.pblkAddr = pblkAddr
        self.pblkLen = pblkLen
        self.objects = objects
        super.init(name: name)
    }
}

