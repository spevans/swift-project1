//
//  AMLNamedObject.swift
//  project1
//
//  Created by Simon Evans on 25/11/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//


protocol AMLNamedObj: AMLBuffPkgStrObj, AMLTermObj, AMLObject {
    // FIXME: add the name in here
    var name: AMLNameString { get }
    func createNamedObject(context: inout ACPI.AMLExecutionContext) throws
    func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg
    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext)
}

extension AMLNamedObj {
    func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        fatalError("readValue for \(self) not implementd")
    }
    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("updateValue denied")
    }

    func createNamedObject(context: inout ACPI.AMLExecutionContext) throws {
        let fullPath = resolveNameTo(scope: context.scope, path: name)
        context.globalObjects.add(fullPath._value, self)
    }
}


// Named Objects

typealias AMLObjectList = AMLTermList // FIXME: ObjectList should be more specific


struct AMLDefDataRegion: AMLNamedObj {
    var isReadOnly: Bool { return false }


    // DataRegionOp NameString TermArg TermArg TermArg
    let name: AMLNameString
    let arg1: AMLTermArg
    let arg2: AMLTermArg
    let arg3: AMLTermArg
}


struct AMLDefDevice: AMLNamedObj {
    // DeviceOp PkgLength NameString ObjectList
    let name: AMLNameString
    let value: AMLObjectList
}


typealias AMLObjectType = AMLByteData
struct AMLDefExternal: AMLNamedObj {
    // ExternalOp NameString ObjectType ArgumentCount
    let name: AMLNameString
    let type: AMLObjectType
    let argCount: AMLByteData // (0 - 7)

    init(name: AMLNameString, type: AMLObjectType, argCount: AMLByteData) throws {
        guard argCount <= 7 else {
            let reason = "argCount must be 0-7, not \(argCount)"
            throw AMLError.invalidData(reason: reason)
        }
        self.name = name
        self.type = type
        self.argCount = argCount
    }
}


struct AMLDefIndexField: AMLNamedObj {
    // IndexFieldOp PkgLength NameString NameString FieldFlags FieldList
    let name: AMLNameString
    let dataName: AMLNameString
    let flags: AMLFieldFlags
    let fields: AMLFieldList
}


final class AMLMethod: AMLNamedObj {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }

    //var isReadOnly: Bool { return true }
    //var asInteger: AMLInteger? { return nil }
    //var asString: String? { return nil }


    let name: AMLNameString
    let flags: AMLMethodFlags
    private var parser: AMLParser!
    private var _termList: AMLTermList?


    init(name: AMLNameString, flags: AMLMethodFlags, parser: AMLParser?) {
        self.name = name
        self.flags = flags
        self.parser = parser
    }

    func termList() throws -> AMLTermList {
        if _termList == nil {
            _termList = try parser.parseTermList()
            parser = nil
        }
        return _termList!
    }
}



struct AMLDefMutex: AMLNamedObj {
    let name: AMLNameString
    let flags: AMLMutexFlags
}

enum AMLFieldAccessType: AMLByteData {
    case AnyAcc     = 0
    case ByteAcc    = 1
    case WordAcc    = 2
    case DWordAcc   = 3
    case QWordAcc   = 4
    case BufferAcc  = 5 //

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

struct AMLFieldFlags {
    // let value: AMLByteData
    let fieldAccessType: AMLFieldAccessType
    var lockRule: AMLLockRule
    var updateRule: AMLUpdateRule


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

struct AMLDefBankField: AMLNamedObj {
    // BankFieldOp PkgLength NameString NameString BankValue FieldFlags FieldList
    let name: AMLNameString
    let bankValue: AMLTermArg // => Integer
    let flags: AMLFieldFlags
    let fields: AMLFieldList

    func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        print("reading from \(self)")
        return AMLIntegerData(value: 0)
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("Updating \(self) to \(to)")
    }
}


struct AMLDefCreateBitField: AMLNamedObj {
    // CreateBitFieldOp SourceBuff BitIndex NameString
    let sourceBuff: AMLTermArg
    let bitIndex: AMLInteger
    let name: AMLNameString

    func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let buffer = sourceBuff.evaluate(context: &context)
        print("reading from \(buffer), bitIndex:", bitIndex)
        return AMLIntegerData(value: 0)
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("Updating \(sourceBuff)[\(bitIndex)] to \(to)")
    }
}


struct AMLDefCreateByteField: AMLNamedObj {
    // CreateByteFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger
    let name: AMLNameString

    func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let buffer = sourceBuff.evaluate(context: &context)
        print("reading from \(buffer), byteIndex:", byteIndex)
        return AMLIntegerData(value: 0)
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("Updating \(sourceBuff)[\(byteIndex)] to \(to)")
    }
}

struct AMLDefCreateDWordField: AMLNamedObj {
    // CreateDWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger
    let name: AMLNameString

    func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let buffer = sourceBuff.evaluate(context: &context)
        print("reading from \(buffer), byteIndex:", byteIndex)
        return AMLIntegerData(value: 0)
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("Updating \(sourceBuff)[\(byteIndex)] to \(to)")
    }
}


struct AMLDefCreateField: AMLNamedObj {
    // CreateFieldOp SourceBuff BitIndex NumBits NameString
    let sourceBuff: AMLTermArg
    let bitIndex: AMLInteger
    let numBits: AMLInteger
    let name: AMLNameString

    func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let buffer = sourceBuff.evaluate(context: &context)
        print("reading from \(buffer), byteIndex:", bitIndex)
        return AMLIntegerData(value: 0)
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("Updating \(sourceBuff)[\(bitIndex)] to \(to)")
    }
}


struct AMLDefCreateQWordField: AMLNamedObj {
    // CreateQWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger
    let name: AMLNameString

    func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let buffer = sourceBuff.evaluate(context: &context)
        print("reading from \(buffer), byteIndex:", byteIndex)
        return AMLIntegerData(value: 0)
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("Updating \(sourceBuff)[\(byteIndex)] to \(to)")
    }
}


struct AMLDefCreateWordField: AMLNamedObj {
    // CreateWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger
    let name: AMLNameString

    func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let buffer = sourceBuff.evaluate(context: &context)
        print("reading from \(buffer), byteIndex:", byteIndex)
        return AMLIntegerData(value: 0)
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("Updating \(sourceBuff)[\(byteIndex)] to \(to)")
    }
}


struct AMLDefField: AMLNamedObj {
    // FieldOp PkgLength NameString FieldFlags FieldList
    let name: AMLNameString
    let flags: AMLFieldFlags
    let fields: AMLFieldList
}


protocol OpRegionSpace {
    init (offset: AMLInteger, length: AMLInteger, flags: AMLFieldFlags)
    func read(bitOffset: Int, width: Int) -> AMLInteger
    func write(bitOffset: Int, width: Int, value: AMLInteger)
}


final class EmbeddedControlRegionSpace: OpRegionSpace, CustomStringConvertible {
    private var array: Array<UInt8>
    private let flags: AMLFieldFlags

    var description: String {
        return "EmbeddedControlRegionSpace"
    }

    init (offset: AMLInteger, length: AMLInteger, flags: AMLFieldFlags) {
        self.flags = flags
        array = Array(repeating: 0, count: Int(length))
    }

    func read(bitOffset: Int, width: Int) -> AMLInteger {
        return 0
    }

    func write(bitOffset: Int, width: Int, value: AMLInteger) {

    }
}


final class SystemMemorySpace<T: UnsignedInteger & FixedWidthInteger>: OpRegionSpace, CustomStringConvertible {
    private var array: Array<T>
    private let flags: AMLFieldFlags

    var description: String {
        var str = "SystemMemory:"
        str.append(String(describing: T.self))
        str.append(": ")
        for v in array {
            str.append("[\(String(v, radix: 16))]")
        }
        return str
    }

    init(offset: AMLInteger, length: AMLInteger, flags: AMLFieldFlags) {
        precondition(length > 0)
        let count = (Int(length) + MemoryLayout<T>.size - 1) / MemoryLayout<T>.size
        self.flags = flags
        array = Array(repeating: 0, count: count)
    }

    // LittleEndian read
    func read(bitOffset: Int, width: Int) -> AMLInteger {
        precondition(bitOffset >= 0)
        precondition(width >= 1)
        precondition((bitOffset + width) <= (array.count * 8 * MemoryLayout<T>.size))

        let elementBits = 8 * MemoryLayout<T>.size
        var _width = width
        var index = bitOffset / elementBits
        var startBit = bitOffset % elementBits

        var result: AMLInteger = 0
        var elementShift = 0
        var bitShift = elementShift - startBit
        repeat {
            let endBit = min(elementBits - 1, _width + startBit - 1)
            let bitCount = (endBit + 1 - startBit)
            let valueMask = AMLInteger(createMask(startBit, endBit))
            result |= readElement(index: index, bitShift: bitShift, valueMask: valueMask)

            startBit = 0
            elementShift += elementBits
            bitShift += elementBits
            _width -= bitCount
            index += 1
            assert(_width >= 0)
        } while _width > 0

        return result
    }


    private func readElement(index: Int, bitShift: Int, valueMask: AMLInteger) -> AMLInteger {
        var v = AMLInteger(array[index])

        var mask = valueMask
        if bitShift < 0 {
            v >>= abs(bitShift)
            mask >>= abs(bitShift)
        } else if bitShift > 0{
            v <<= bitShift
            mask <<= bitShift
        }

        return v & mask
    }


    // LittleEndian write
    func write(bitOffset: Int, width: Int, value: AMLInteger) {
        precondition(bitOffset >= 0)
        precondition(width >= 1)
        precondition((bitOffset + width) <= (array.count * 8 * MemoryLayout<T>.size))

        if value > (1 << width) {
            let max = (1 << width) - 1
            fatalError("Value [\(value)] cant fit in \(width) bits [max = \(max)]")
        }
        let elementBits = 8 * MemoryLayout<T>.size

        var _width = width
        var elementValue = value
        var index = bitOffset / elementBits
        var startBit = bitOffset % elementBits

        repeat {
            let endBit = min(elementBits - 1, _width + startBit - 1)
            let elementMask = createMask(startBit, endBit)
            let bitCount = (endBit + 1 - startBit)
            let valueMask: AMLInteger = bitCount == AMLInteger.bitWidth ? AMLInteger.max : (1 << bitCount) - 1

            writeElement(index: index, mask: elementMask, value: T(truncatingIfNeeded: elementValue & valueMask) << startBit)
            elementValue = elementValue >> bitCount
            startBit = 0
            _width -= bitCount
            index += 1
            assert(_width >= 0)
        } while _width > 0

        #if TEST
            // testing check
            let readBack = read(bitOffset: bitOffset, width: width)
            if readBack != value {
                fatalError("read after write failed [value=\(value) readBack=\(readBack)]")
            }
        #endif
    }


    private func writeElement(index: Int, mask: T, value: T) {
        if mask == T.max {
            array[index] = value
            return
        }

        switch flags.updateRule {
        case .Preserve:
            let curValue = array[index] & ~mask
            array[index] = curValue | value

        case .WriteAsOnes:
            array[index] = value | ~mask

        case .WriteAsZeros:
            array[index] = value
        }
    }

    private func createMask(_ startBit: Int, _ endBit: Int) -> T {
        let endMask: T = (endBit + 1 == T.bitWidth) ? T.max : T((1 << (T(endBit) + 1)) - 1)
        let startMask: T = ~((1 << T(startBit)) - 1)
        return startMask & endMask
    }
}


class AMLDefFieldRef {
    var amlDefField: AMLDefField? = nil
    var opRegion: AMLDefOpRegion? = nil
    var regionSpace: OpRegionSpace? = nil

    init() {
    }


    func getRegionSpace(context: inout ACPI.AMLExecutionContext) -> OpRegionSpace {
        if let rs = regionSpace {
            return rs
        }
        guard let field = amlDefField, let region = opRegion else {
            fatalError("field/region not defined")
        }

        let offset = (region.offset.evaluate(context: &context) as! AMLIntegerData).value
        let length = (region.length.evaluate(context: &context) as! AMLIntegerData).value

        switch region.region {

        case .systemMemory:
            switch field.flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                regionSpace = SystemMemorySpace<UInt8>(offset: offset, length: length, flags: field.flags)

            case .WordAcc:
                regionSpace = SystemMemorySpace<UInt16>(offset: offset, length: length, flags: field.flags)

            case .DWordAcc:
                regionSpace = SystemMemorySpace<UInt32>(offset: offset, length: length, flags: field.flags)

            case .QWordAcc:
                regionSpace = SystemMemorySpace<UInt64>(offset: offset, length: length, flags: field.flags)

            case .BufferAcc:
                fatalError("Buffer ACC not supported")
            }

        case .systemIO:
            switch field.flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                regionSpace = SystemMemorySpace<UInt8>(offset: offset, length: length, flags: field.flags)

            case .WordAcc:
                regionSpace = SystemMemorySpace<UInt16>(offset: offset, length: length, flags: field.flags)

            case .DWordAcc:
                regionSpace = SystemMemorySpace<UInt32>(offset: offset, length: length, flags: field.flags)

            case .QWordAcc:
                regionSpace = SystemMemorySpace<UInt64>(offset: offset, length: length, flags: field.flags)

            case .BufferAcc:
                fatalError("SystemIO Buffer ACC not supported")
            }

        case .pciConfig:
            switch field.flags.fieldAccessType {
            case .AnyAcc, .ByteAcc:
                regionSpace = SystemMemorySpace<UInt8>(offset: offset, length: length, flags: field.flags)

            case .WordAcc:
                regionSpace = SystemMemorySpace<UInt16>(offset: offset, length: length, flags: field.flags)

            case .DWordAcc:
                regionSpace = SystemMemorySpace<UInt32>(offset: offset, length: length, flags: field.flags)

            case .QWordAcc:
                regionSpace = SystemMemorySpace<UInt64>(offset: offset, length: length, flags: field.flags)

            case .BufferAcc:
                fatalError("PCI config Buffer ACC not supported")
            }

        case .embeddedControl:
            switch field.flags.fieldAccessType {
            case .ByteAcc:
                //regionSpace = EmbeddedControlRegionSpace(offset: region.offset, length: region.length, flags: field.flags)
                // FIXME - should be embedded control
                regionSpace = SystemMemorySpace<UInt8>(offset: offset, length: length, flags: field.flags)

            default:
                fatalError("EmbeddedControl Region Space does not support access of type \(field.flags.fieldAccessType)")
            }

        case .smbus:
            fatalError("\(region) region not implemented")
        case .systemCMOS:
            fatalError("\(region) region not implemented")
        case .pciBarTarget:
            fatalError("\(region) region not implemented")
        case .ipmi:
            fatalError("\(region) region not implemented")
        case .generalPurposeIO:
            fatalError("\(region) region not implemented")
        case .genericSerialBus:
            fatalError("\(region) region not implemented")
        case .oemDefined:
            fatalError("\(region) region not implemented")
        }
        return regionSpace!
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


struct AMLDefOpRegion: AMLNamedObj {
    // OpRegionOp NameString RegionSpace RegionOffset RegionLen
    let name: AMLNameString
    let region: AMLRegionSpace
    let offset: AMLTermArg // => Integer
    let length: AMLTermArg // => Integer


  /*  init(name: AMLNameString, region: AMLRegionSpace, offset: AMLIntegerData, length: AMLIntegerData) {
        self.name = name
        self.region = region
        self.offset = offset
        self.length = length
    }*/

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let o = operandAsInteger(operand: offset, context: &context)
        let l = operandAsInteger(operand: length, context: &context)
        fatalError("do somthing with \(o) and \(l)")
    }
}


struct AMLDefProcessor: AMLNamedObj {
    // ProcessorOp PkgLength NameString ProcID PblkAddr PblkLen ObjectList
    let name: AMLNameString
    let procId: AMLByteData
    let pblkAddr: AMLDWordData
    let pblkLen: AMLByteData
    let objects: AMLObjectList
}

