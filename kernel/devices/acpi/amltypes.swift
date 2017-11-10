/*
 * amltypes.swift
 *
 * Created by Simon Evans on 05/07/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * AML Type and Opcode definitions
 *
 */


// Simple Types
typealias AMLInteger = UInt64
typealias AMLTermList = [AMLTermObj]
typealias AMLByteData = UInt8
typealias AMLByteList = [AMLByteData]
typealias AMLWordData = UInt16
typealias AMLDWordData = UInt32
typealias AMLQWordData = UInt64
typealias AMLTermArgList = [AMLTermArg]
typealias AMLPkgLength = UInt

private let AMLIntegerFalse = AMLInteger(0)
private let AMLIntegerTrue = AMLInteger(1)

protocol AMLTermObj {
    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg
}

extension AMLTermObj {
    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


protocol AMLTermArg {
    func canBeConverted(to: AMLDataRefObject) -> Bool
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg
}

extension AMLTermArg {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }
    var resultAsString: AMLString? { return nil }
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return self
    }
}


protocol AMLBuffPkgStrObj: AMLTermArg {
}

protocol AMLNamedObj: AMLTermObj {
    // FIXME: add the name in here
    mutating func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext)
}

extension AMLNamedObj {
    mutating func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("updateValue denied")
    }
}

protocol AMLDataRefObject: AMLBuffPkgStrObj, AMLNamedObj {
    //var asInteger: AMLInteger? { get }
    //var asString: String? { get }
    var isReadOnly: Bool { get }
}

extension AMLDataRefObject {
   // func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
   //    // FIXME fatalError("updateValue denied")
   // }
}


protocol AMLTarget {
    var value: AMLDataRefObject { get set }
}


protocol AMLSuperName: AMLTarget {
}


protocol AMLSimpleName: AMLSuperName {
}


protocol AMLNameSpaceModifierObj: AMLTermObj {
    //var name: AMLNameString { get }
    func execute(context: inout ACPI.AMLExecutionContext) throws
}


protocol AMLType1Opcode: AMLTermObj {
 //   func execute(context: inout ACPI.AMLExecutionContext) throws
}

extension AMLType1Opcode {
  //  func execute(context: inout ACPI.AMLExecutionContext) throws {
  //      throw AMLError.unimplemented("\(type(of: self))")
  //  }
}


protocol AMLType2Opcode: AMLTermObj, AMLTermArg {
    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg
}

extension AMLType2Opcode {
    //mutating func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
    //    throw AMLError.unimplemented("\(type(of: self))")
   // }
}


protocol AMLType6Opcode: AMLSuperName, AMLBuffPkgStrObj {
}


protocol AMLDataObject: AMLDataRefObject {
}


protocol AMLComputationalData: AMLDataObject {
}


class AMLIntegerData: AMLDataObject, AMLTermArg {
    var value: AMLInteger
    let isReadOnly = false

    init(value: AMLInteger) {
        self.value = value
    }

    func canBeConverted(to: AMLDataRefObject) -> Bool {
        if to is AMLIntegerData {
            return true
        }
        if let _to = to as? AMLNamedField {
            return _to.bitWidth <= AMLInteger.bitWidth
        }

        return false
    }

    func updateValue(to operand: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        guard let result = operand.evaluate(context: &context) as? AMLIntegerData else {
            fatalError("\(operand) does not evaluate to an integer")
        }
        value = result.value
    }
}


struct AMLNameString: AMLSimpleName, AMLBuffPkgStrObj, AMLTermArg {
    var value: AMLDataRefObject {
        get { return AMLString(_value) }
        set {}
    }

    func canBeConverted(to: AMLDataRefObject) -> Bool {
        if to is AMLFieldElement {
            return true
        }
        return false
    }

    var resultAsInteger: AMLInteger? {
        return nil
    }
    var resultAsString: AMLString? {
        return AMLString(_value)
    }
    var _value: String

    init(value: String) {
        _value = value
       // self.value = AMLString(value)
    }

    var isNameSeg: Bool { return (_value.count <= 4) }

    // Name starts with '\\'
    var isFullPath: Bool { return _value.first == AMLNameString.rootChar }

    func parent() -> AMLNameString {
        let seperator = AMLNameString.pathSeparatorChar
        var parentSegs = self._value.components(separatedBy: seperator)
        parentSegs.removeLast()
        let result = parentSegs.joined(separator: String(seperator))
        return AMLNameString(value: result)
    }


    func replaceLastSeg(with newSeg: AMLNameString) -> AMLNameString {
        let seperator = AMLNameString.pathSeparatorChar
        var parentSegs = self._value.components(separatedBy: seperator)
        //let child = newSeg._value.components(separatedBy: seperator).last()
        parentSegs.removeLast()
        parentSegs.append(newSeg._value)
        let result = parentSegs.joined(separator: String(seperator))
        return AMLNameString(value: result)
    }


    static func ==(lhs: AMLNameString, rhs: AMLNameString) -> Bool {
        return lhs._value == rhs._value
    }

    static func ==(lhs: AMLNameString, rhs: String) -> Bool {
        return lhs._value == rhs
    }

    static func ==(lhs: String, rhs: AMLNameString) -> Bool {
        return lhs == rhs._value
    }


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let scope = context.scope
        guard let (node, fullName) = context.globalObjects.getGlobalObject(currentScope: scope,
                                                                           name: self) else {
            fatalError("Cant find node: \(_value)")
        }
        guard let namedObject = node.object else {
            fatalError("Cant find namedObj: \(_value)")
        }
        if let fieldElement = namedObject as? AMLNamedField {
            var tmpContext = ACPI.AMLExecutionContext(scope: AMLNameString(value: fullName),
                                                      args: [],
                                                      globalObjects: context.globalObjects)
            return fieldElement.evaluate(context: &tmpContext)
            //fieldElement.setOpRegion(context: tmpContext)
            //return AMLIntegerData(value: fieldElement.resultAsInteger ?? 0)
        } else if let termArg = namedObject as? AMLTermArg {
            return termArg
        } else {
            fatalError("Unknown namedObject: \(namedObject)")
        }
    }
}


//FIXME, also an AMLNAmePath, Should it even exist as a type???
struct AMLNullName: AMLTarget {
    var value: AMLDataRefObject {
        get { fatalError("cant get a nullname") }
        set { fatalError("cant set a nullname") }
    }
    // 0x00
}


// Subtypes used in structs
struct AMLMethodFlags {
    // bit 0-2: ArgCount (0-7)
    // bit 3: SerializeFlag: 0 NotSerialized 1 Serialized
    // bit 4-7: SyncLevel (0x00-0x0f)

    let flags: AMLByteData
    var argCount: Int { return Int(flags & 7) }
    var isSerialized: Bool { return flags.bit(3) }
    var syncLevel: Int { return Int(flags >> 4) }

    init(flags: AMLByteData) {
        self.flags = flags
    }

    init (argCount: Int, isSerialized: Bool, syncLevel: Int) {
        var f = UInt8(UInt8(argCount) & 0x7)
        f |= isSerialized ? 8 : 0
        f |= UInt8((syncLevel & 0xf) << 4)
        flags = f
    }
}


struct AMLMutexFlags {
    // bit 0-3: SyncLevel (0x00-0x0f)
    // bit 4-7: Reserved (must be 0)

    let flags: AMLByteData


    init() {
        self.flags = 0
    }
    init(flags: AMLByteData) throws {
        try self.init(syncLevel: flags)
    }


    init(syncLevel: UInt8) throws {
        guard syncLevel & 0x0f == syncLevel else {
            throw AMLError.invalidData(reason: "Invalid synclevel \(syncLevel)")
        }
        self.flags = syncLevel
    }
}


// AMLTermArg
struct AMLArgObj: AMLTermArg, AMLSimpleName, AMLBuffPkgStrObj, AMLTermObj {
    var value: AMLDataRefObject {
        get { fatalError("cant get arg") }
        set { fatalError("ArgObj is readonly") }
    }

    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }



    let opcode: AMLOpcode      // FIXME needs better type
    var argIdx: Int { return Int(opcode.rawValue - AMLOpcode.arg0Op.rawValue) }

    init(argOp: AMLOpcode) throws {
        switch argOp {
        case .arg0Op, .arg1Op, .arg2Op, .arg3Op, .arg4Op, .arg5Op, .arg6Op:
            opcode = argOp

        default: throw AMLError.invalidData(reason: "Invalid arg")
        }
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return context.args[argIdx]
    }
}


struct AMLLocalObj: AMLTermArg, AMLSimpleName, AMLBuffPkgStrObj, AMLTermObj {
    var value: AMLDataRefObject {
        get { fatalError("cant get arg") }
        set { fatalError("ArgObj is readonly") }
    }


    let opcode: AMLOpcode      // FIXME needs better type
    var argIdx: Int { return Int(opcode.rawValue - AMLOpcode.local0Op.rawValue) }

    init(localOp: AMLOpcode) throws {
         switch localOp {
        case .local0Op, .local1Op, .local2Op, .local3Op,
            .local4Op, .local5Op, .local6Op, .local7Op:
            opcode = localOp

         default: throw AMLError.invalidData(reason: "Invalid arg")
        }
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let v = context.localObjects[argIdx]!
        let r = v.evaluate(context: &context)
        return r
    }
}


struct AMLDebugObj: AMLSuperName, AMLDataRefObject, AMLTarget {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }

    var isReadOnly: Bool  { return false }

    var value: AMLDataRefObject {
        get { fatalError("DebugObject cant be used as a source operand") }
        set { debugPrint(newValue) }
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("DEBUG:", to)
    }
}


// AMLNamedObj
protocol AMLFieldElement {
}

protocol AMLConnectField: AMLFieldElement {
}


typealias AMLFieldList = [AMLFieldElement]

struct AMLNamedField: AMLFieldElement, AMLDataObject {
    var isReadOnly: Bool = false

    let name: AMLNameString
    let bitOffset: UInt
    let bitWidth: UInt
    let fieldRef: AMLDefFieldRef

    init(name: AMLNameString, bitOffset: UInt, bitWidth: UInt, fieldRef: AMLDefFieldRef) throws {
        guard name.isNameSeg else {
            throw AMLError.invalidData(reason: "\(name) is not a NameSeg")
        }
        self.name = name
        self.bitOffset = bitOffset
        self.bitWidth = bitWidth
        self.fieldRef = fieldRef
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        let value = operandAsInteger(operand: to, context: &context)
        setOpRegion(context: context)
        fieldRef.getRegionSpace().write(bitOffset: Int(bitOffset),
                                        width: Int(bitWidth),
                                        value: value)
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        setOpRegion(context: context)
        let value = fieldRef.getRegionSpace().read(bitOffset: Int(bitOffset),
                                              width: Int(bitWidth))
        return AMLIntegerData(value: value)
    }


    private func setOpRegion(context: ACPI.AMLExecutionContext) {
        if fieldRef.opRegion == nil {
            guard let opRegionName = fieldRef.amlDefField?.name else {
                fatalError("cant get opRegionanme")
            }
            if let (opNode, _) = context.globalObjects.getGlobalObject(currentScope: context.scope,
                                                                          name: opRegionName) {
                if let opRegion = opNode.object as? AMLDefOpRegion {
                    fieldRef.opRegion = opRegion
                    return
                }
            }
            fatalError("No valid opRegion found")
        }
    }
}


struct AMLReservedField: AMLFieldElement {
    let pkglen: AMLPkgLength
}


struct AMLAccessType {
    let value: AMLByteData
}


struct AMLAccessField: AMLFieldElement {
    let type: AMLAccessType
    let attrib: AMLByteData
}


enum AMLExtendedAccessAttrib: AMLByteData {
    case attribBytes = 0x0B
    case attribRawBytes = 0x0E
    case attribRawProcess = 0x0F
}


struct AMLExtendedAccessField: AMLFieldElement {
    let type: AMLAccessType
    let attrib: AMLExtendedAccessAttrib
    let length: AMLIntegerData
}

// Named Objects

typealias AMLObjectList = AMLTermList // FIXME: ObjectList should be more specific


struct AMLDefDataRegion: AMLDataRefObject, AMLNamedObj {
    var asInteger: AMLInteger? { return nil }
    var asString: String? { return nil }
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
    //let name: AMLNameString
    let type: AMLObjectType
    let argCount: AMLByteData // (0 - 7)

    init(name: AMLNameString, type: AMLObjectType, argCount: AMLByteData) throws {
        guard argCount <= 7 else {
            let reason = "argCount must be 0-7, not \(argCount)"
            throw AMLError.invalidData(reason: reason)
        }
        //self.name = name
        self.type = type
        self.argCount = argCount
    }
}


struct AMLDefIndexField: AMLNamedObj {
    // IndexFieldOp PkgLength NameString NameString FieldFlags FieldList
    //let name: AMLNameString
    let dataName: AMLNameString
    let flags: AMLFieldFlags
    let fields: AMLFieldList
}


final class AMLMethod: AMLNamedObj, AMLDataRefObject {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }

    var isReadOnly: Bool { return true }
    var asInteger: AMLInteger? { return nil }
    var asString: String? { return nil }


    //let name: AMLNameString
    let flags: AMLMethodFlags
    private var parser: AMLParser!
    private var _termList: AMLTermList?


    init(flags: AMLMethodFlags, parser: AMLParser?) {
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
    //let name: AMLNameString
    let bankValue: AMLTermArg // => Integer
    let flags: AMLFieldFlags
    let fields: AMLFieldList
}


struct AMLDefCreateBitField: AMLNamedObj {
    // CreateBitFieldOp SourceBuff BitIndex NameString
    let sourceBuff: AMLTermArg
    let bitIndex: AMLInteger
    let name: AMLNameString
}


struct AMLDefCreateByteField: AMLNamedObj {
    // CreateByteFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger
    let name: AMLNameString
}

struct AMLDefCreateDWordField: AMLNamedObj {
    // CreateDWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger
    let name: AMLNameString

    init(sourceBuff: AMLTermArg, byteIndex: AMLInteger, name: AMLNameString) {
        self.sourceBuff = sourceBuff
        self.byteIndex = byteIndex
        self.name = name
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let fullPath = resolveNameTo(scope: context.scope, path: name)
        context.globalObjects.add(fullPath._value, self)
        return AMLIntegerData(value: 0)
    }
}


struct AMLDefCreateField: AMLNamedObj {
    // CreateFieldOp SourceBuff BitIndex NumBits NameString
    let sourceBuff: AMLTermArg
    let bitIndex: AMLInteger
    let numBits: AMLInteger
    let name: AMLNameString
}


struct AMLDefCreateQWordField: AMLNamedObj {
    // CreateQWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger
    let name: AMLNameString
}


struct AMLDefCreateWordField: AMLNamedObj {
    // CreateWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLInteger
    let name: AMLNameString
}


struct AMLDefField: AMLNamedObj, AMLDataRefObject {
    var asInteger: AMLInteger? { return nil }
    var asString: String? { return nil }
    var isReadOnly: Bool { return false }


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


    func getRegionSpace() -> OpRegionSpace {
        if let rs = regionSpace {
            return rs
        }
        guard let field = amlDefField, let region = opRegion else {
            fatalError("field/region not defined")
        }

        let offset = region.offset.value
        let length = region.length.value
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


struct AMLDefOpRegion: AMLNamedObj, AMLDataRefObject {
    var asInteger: AMLInteger? { return nil }
    var asString: String? { return nil }
    var isReadOnly: Bool { return false }


    // OpRegionOp NameString RegionSpace RegionOffset RegionLen
    let name: AMLNameString
    let region: AMLRegionSpace
    let offset: AMLIntegerData // => Integer
    let length: AMLIntegerData // => Integer


    init(name: AMLNameString, region: AMLRegionSpace, offset: AMLIntegerData, length: AMLIntegerData) {
        self.name = name
        self.region = region
        self.offset = offset
        self.length = length
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let o = operandAsInteger(operand: offset, context: &context)
        let l = operandAsInteger(operand: length, context: &context)
        fatalError("do somthing with \(o) and \(l)")
    }
}


struct AMLDefProcessor: AMLNamedObj {
    // ProcessorOp PkgLength NameString ProcID PblkAddr PblkLen ObjectList
//    let name: AMLNameString
    let procId: AMLByteData
    let pblkAddr: AMLDWordData
    let pblkLen: AMLByteData
    let objects: AMLObjectList
}


// AMLNameSpaceModifierObj
struct AMLDefAlias: AMLNameSpaceModifierObj {
    func execute(context: inout ACPI.AMLExecutionContext) throws {

    }

    var name: AMLNameString { return aliasObject }
    let sourceObject: AMLNameString
    let aliasObject: AMLNameString
}


struct AMLDefScope: AMLNameSpaceModifierObj {
    func execute(context: inout ACPI.AMLExecutionContext) throws {
        throw AMLError.unimplemented("\(type(of: self))")

    }

    // ScopeOp PkgLength NameString TermList
    let name: AMLNameString
    let value: AMLTermList
}


// AMLType1Opcode
struct AMLDefBreak: AMLType1Opcode {
    // empty
}


struct AMLDefBreakPoint: AMLType1Opcode {
    // empty
}


struct AMLDefContinue: AMLType1Opcode {
    // empty
}


struct AMLDefElse: AMLType1Opcode {
    // Nothing | <ElseOp PkgLength TermList>
    let value: AMLTermList?

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        if let termList = value {
            try context.execute(termList: termList)
        }
        return AMLIntegerData(value: 0)
    }
}


struct AMLDefFatal: AMLType1Opcode {
    let type: AMLByteData
    let code: AMLDWordData
    let arg: AMLTermArg // => Integer
}


typealias AMLPredicate = AMLTermArg // => Integer

struct AMLDefIfElse: AMLType1Opcode {
    // IfOp PkgLength Predicate TermList DefElse
    let predicate: AMLPredicate
    let value: AMLTermList
    let elseValue: AMLTermList?

    init(predicate: AMLPredicate, value: AMLTermList, defElse: AMLDefElse) {
        self.predicate = predicate
        self.value = value
        elseValue = defElse.value
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        guard let result = predicate.evaluate(context: &context) as? AMLIntegerData else {
            fatalError("Predicate does not evaluate to an integer")
        }
        if result.value != 0 {
            try context.execute(termList: value)
        } else if let elseTermList = elseValue {
            try context.execute(termList: elseTermList)
        }
        return AMLIntegerData(value: 0)
    }
}


typealias AMLDDBHandleObject = AMLSuperName
struct AMLDefLoad: AMLType1Opcode {
    // LoadOp NameString DDBHandleObject
    let name: AMLNameString
    let value: AMLDDBHandleObject
}


struct AMLDefNoop: AMLType1Opcode {
    // NoopOp
}


struct AMLDefNotify: AMLType1Opcode {
    // NotifyOp NotifyObject NotifyValue
    let object: AMLSuperName // => ThermalZone | Processor | Device AMLNotifyObject
    let value: AMLTermArg // -> Integer AMLNotifyValue

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let _value = operandAsInteger(operand: value, context: &context)
        let string = String(describing: object.value.resultAsString)
        let v = String(describing: _value)
        print("NOTIFY:", string, v)
        return AMLIntegerData(value: 0)
    }
}


typealias AMLMutexObject = AMLSuperName
struct AMLDefRelease: AMLType1Opcode {
    // ReleaseOp MutexObject
    let object: AMLMutexObject
}


typealias AMLEventObject = AMLSuperName
struct AMLEvent {
    // EventOp NameString
    let name: AMLNameString
}


struct AMLDefReset: AMLType1Opcode {
    // ResetOp EventObject
    let object: AMLEventObject
}

// fixme
//typealias AMLArgObject = AMLTermArg
struct AMLDefReturn: AMLType1Opcode {
    // ReturnOp ArgObject
    let object: AMLTermArg//AMLDataRefObject // TermArg => DataRefObject

    init(object: AMLTermArg?) {
        if object == nil {
            self.object = AMLIntegerData(value: 0)
        } else {
            self.object = object!
        }
    }
    
    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        context.returnValue = object //.evaluate(context: &context)
        context.endOfMethod = true
        return object
    }
}


struct AMLDefSignal: AMLType1Opcode {
    // SignalOp EventObject
    let object: AMLEventObject
}


struct AMLDefSleep: AMLType1Opcode {
    // SleepOp MsecTime
    let msecTime: AMLTermArg // => Integer

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        print("SLEEP: \(msecTime) ms")
        return AMLIntegerData(value: 0)
    }
}


struct AMLDefStall: AMLType1Opcode {
    // StallOp UsecTime
    let usecTime: AMLTermArg // => ByteData
}


struct AMLDefUnload: AMLType1Opcode {
    // UnloadOp DDBHandleObject
    let object: AMLDDBHandleObject
}


struct AMLDefWhile: AMLType1Opcode {
    // WhileOp PkgLength Predicate TermList
    let predicate: AMLPredicate
    let list: AMLTermList

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        while true {
            let result = predicate.evaluate(context: &context) as! AMLIntegerData
            if result.value == 0 {
                return AMLIntegerData(value: 0)
            }
            try context.execute(termList: list)
            if context.endOfMethod {
                return AMLIntegerData(value: 0)
            }
        }
    }
}


// AMLType2Opcode
typealias AMLTimeout = AMLWordData
struct AMLDefAcquire: AMLType2Opcode {
    // AcquireOp MutexObject Timeout

    let mutex: AMLMutexObject
    let timeout: AMLTimeout

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}

typealias AMLOperand = AMLTermArg // => Integer
struct AMLDefAdd: AMLType2Opcode {

    // AddOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData(value: op1 + op2)
        return result
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


private func operandAsInteger(operand: AMLOperand, context: inout ACPI.AMLExecutionContext) -> AMLInteger {
    guard let result = operand.evaluate(context: &context) as? AMLIntegerData else {
        fatalError("\(operand) does not evaluate to an integer")
    }
    return result.value
}

struct AMLDefAnd: AMLType2Opcode {

    // AndOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData(value: op1 & op2)
        return result
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
    }
}


struct AMLBuffer: AMLBuffPkgStrObj, AMLType2Opcode, AMLComputationalData {

    var asInteger: AMLInteger? { return nil }
    var asString: String? { return nil }
    var isReadOnly: Bool { return true }

    // BufferOp PkgLength BufferSize ByteList
    let size: AMLTermArg // => Integer
    let value: AMLByteList


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


typealias AMLData = AMLTermArg // => ComputationalData
struct AMLDefConcat: AMLType2Opcode {

    // ConcatOp Data Data Target
    let data1: AMLData
    let data2: AMLData
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


typealias AMLBufData = AMLTermArg // =>
struct AMLDefConcatRes: AMLType2Opcode {

    // ConcatResOp BufData BufData Target
    let data1: AMLBufData
    let data2: AMLBufData
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}

///ObjReference := TermArg => ObjectReference | String
//ObjectReference :=  Integer
struct AMLDefCondRefOf: AMLType2Opcode {


    // CondRefOfOp SuperName Target
    let name: AMLSuperName
    var target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        guard let n = name as? AMLNameString else {
            return AMLIntegerData(value: 0)
        }
        guard let (obj, _) = context.globalObjects.getGlobalObject(currentScope: context.scope,
                                                                   name: n) else {
            return AMLIntegerData(value: 0)
        }
        // FIXME, do the store into the target
        //target.value = obj
        print(String(describing: obj))
        return AMLIntegerData(value: 1)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefCopyObject: AMLType2Opcode {

    // CopyObjectOp TermArg SimpleName
    let object: AMLTermArg
    let target: AMLSimpleName


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefDecrement: AMLType2Opcode {

    // DecrementOp SuperName
    let target: AMLSuperName


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefDerefOf: AMLType2Opcode, AMLType6Opcode {

    var value: AMLDataRefObject {
        get {fatalError("cant get") }
        set {}
    }

    // DerefOfOp ObjReference
    let name: AMLSuperName


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


typealias AMLDividend = AMLTermArg // => Integer
typealias AMLDivisor = AMLTermArg // => Integer
struct AMLDefDivide: AMLType2Opcode {


    // DivideOp Dividend Divisor Remainder Quotient
    let dividend: AMLDividend
    let divisor: AMLDivisor
    var remainder: AMLTarget
    var quotient: AMLTarget


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let d1 = operandAsInteger(operand: dividend, context: &context)
        let d2 = operandAsInteger(operand: divisor, context: &context)
        guard d2 != 0 else {
            fatalError("divisor is 0")
        }
        //remainder.value = AMLIntegerData(value: (d1 % d2))
        let q = d1 / d2
        //quotient.value = AMLIntegerData(value: q)
        return AMLIntegerData(value: q)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefFindSetLeftBit: AMLType2Opcode {

    // FindSetLeftBitOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefFindSetRightBit: AMLType2Opcode {

    // FindSetRightBitOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


typealias AMLBCDValue = AMLTermArg //=> Integer
struct AMLDefFromBCD: AMLType2Opcode {

    // FromBCDOp BCDValue Target
    let value: AMLBCDValue
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefIncrement: AMLType2Opcode {

    // IncrementOp SuperName
    let target: AMLSuperName


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefIndex: AMLType2Opcode, AMLType6Opcode {

    var value: AMLDataRefObject {
        get {fatalError("Cant get") }
        set {}
    }

    // IndexOp BuffPkgStrObj IndexValue Target
    let object: AMLBuffPkgStrObj // => Buffer, Package or String
    let index: AMLTermArg // => Integer
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLAnd: AMLType2Opcode {
    // LandOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 != 0 && op2 != 0)
        return AMLIntegerData(value: value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLEqual: AMLType2Opcode {
    // LequalOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 == op2)
        return AMLIntegerData(value: value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLGreater: AMLType2Opcode {
    // LgreaterOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 < op2)
        return AMLIntegerData(value: value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}

private func AMLBoolean(_ bool: Bool) -> AMLInteger {
    return bool ? AMLIntegerTrue : AMLIntegerFalse
}

struct AMLDefLGreaterEqual: AMLType2Opcode {
    // LgreaterEqualOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 >= op2)
        return AMLIntegerData(value: value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLLess: AMLType2Opcode {
    // LlessOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 < op2)
        return AMLIntegerData(value: value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLLessEqual: AMLType2Opcode {
    // LlessEqualOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 <= op2)
        return AMLIntegerData(value: value)
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLNot: AMLType2Opcode {
    // LnotOp Operand
    let operand: AMLOperand

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let value = AMLBoolean(op == 0)
        return AMLIntegerData(value: value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLNotEqual: AMLType2Opcode {

    // LnotEqualOp Operand Operand
    let operand1: AMLTermArg
    let operand2: AMLTermArg


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLoadTable: AMLType2Opcode {

    // LoadTableOp TermArg TermArg TermArg TermArg TermArg TermArg
    let arg1: AMLTermArg
    let arg2: AMLTermArg
    let arg3: AMLTermArg
    let arg4: AMLTermArg
    let arg5: AMLTermArg
    let arg6: AMLTermArg


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLOr: AMLType2Opcode {
    // LorOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 != 0 || op2 != 0)
        return AMLIntegerData(value: value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefMatch: AMLType2Opcode {

    enum AMLMatchOpcode: AMLByteData {
    case mtr = 0
    case meq = 1
    case mle = 2
    case mlt = 3
    case mge = 4
    case mgt = 5
    }

    // MatchOp SearchPkg MatchOpcode Operand MatchOpcode Operand StartIndex
    let package: AMLTermArg // => Package
    let matchOpcode1: AMLMatchOpcode
    let operand1: AMLOperand
    let matchOpcode2: AMLMatchOpcode
    let operand2: AMLOperand
    let startIndex: AMLTermArg // => Integer


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefMid: AMLType2Opcode {

    // MidOp MidObj TermArg TermArg Target
    let obj: AMLTermArg // => Buffer | String
    let arg1: AMLTermArg
    let arg2: AMLTermArg
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefMod: AMLType2Opcode {

    // ModOp Dividend Divisor Target
    let dividend: AMLDividend
    let divisor: AMLDivisor
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefMultiply: AMLType2Opcode {

    // MultiplyOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefNAnd: AMLType2Opcode {

    // NandOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefNOr: AMLType2Opcode {

    // NorOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefNot: AMLType2Opcode {
    // NotOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        return AMLIntegerData(value: ~op)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefObjectType: AMLType2Opcode {

    // ObjectTypeOp <SimpleName | DebugObj | DefRefOf | DefDerefOf | DefIndex>
    let object: AMLSuperName


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefOr: AMLType2Opcode {
    // OrOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        return AMLIntegerData(value: op1 | op2)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
    }

}


typealias AMLPackageElement = AMLDataRefObject
typealias AMLPackageElementList = [AMLPackageElement]
struct AMLDefPackage: AMLBuffPkgStrObj, AMLType2Opcode, AMLDataObject, AMLTermArg {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }

    var isReadOnly: Bool { return false }

    var asString: String? { fatalError("package to string") }

    // PackageOp PkgLength NumElements PackageElementList
    //let pkgLength: AMLPkgLength
    let numElements: AMLByteData
    let elements: AMLPackageElementList

    var value: AMLPackageElementList { return elements }
    let asInteger: AMLInteger? = nil
    let resultAsInteger: AMLInteger? = nil


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


typealias AMLDefVarPackage = AMLDataRefObject


struct AMLDefRefOf: AMLType2Opcode, AMLType6Opcode {


    var value: AMLDataRefObject {
        get {fatalError("cant get") }
        set {}
    }

    // RefOfOp SuperName
    let name: AMLSuperName


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


typealias AMLShiftCount = AMLTermArg //=> Integer
struct AMLDefShiftLeft: AMLType2Opcode {
    // ShiftLeftOp Operand ShiftCount Target
    let operand: AMLOperand
    let count: AMLShiftCount
    let target: AMLTarget


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let shiftCount = operandAsInteger(operand: count, context: &context)
        let value = op << shiftCount
        return AMLIntegerData(value: value)
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let result = evaluate(context: &context)
        //target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefShiftRight: AMLType2Opcode {
    // ShiftRightOp Operand ShiftCount Target
    let operand: AMLOperand
    let count: AMLShiftCount
    let target: AMLTarget


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let shiftCount = operandAsInteger(operand: count, context: &context)
        let value = op >> shiftCount
        return AMLIntegerData(value: value)
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let result = evaluate(context: &context)
        //target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefSizeOf: AMLType2Opcode {

    // SizeOfOp SuperName
    let name: AMLSuperName


    func execute(context: inout ACPI.AMLExecutionContext) throws  -> AMLTermArg{
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefStore: AMLType2Opcode {

    // StoreOp TermArg SuperName
    let arg: AMLTermArg
    let name: AMLSuperName

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        var source = arg
        if let args2 = arg as? AMLArgObj {
            guard args2.argIdx < context.args.count else {
                fatalError("Tried to access arg \(args2.argIdx) but only have \(context.args.count) args")
            }
            source = context.args[Int(args2.argIdx)]
        }
        let v = source.evaluate(context: &context)

        if var obj = name as? AMLDataRefObject {
            //obj.updateValue(to: source, context: &context)
            //return source
            obj.updateValue(to: v, context: &context)
            return v
        }

        if let localObj = name as? AMLLocalObj {
            context.localObjects[localObj.argIdx] = v
            return v

        }
        guard let sname = name as? AMLNameString else {
            throw AMLError.invalidData(reason: "\(name) is not a string")
        }
        guard let (dest, fullPath) = context.globalObjects.getGlobalObject(currentScope: context.scope,
                                                                    name: sname) else {
            fatalError("Cant find \(sname)")
        }
       // guard let target = dest.object as? AMLDataRefObject else {
       //     fatalError("dest not an AMLDataRefObject")
       // }

        // FIXME: Shouldnt be here
        //guard var namedObject = dest.object else {
        //    fatalError("Cant find namedObj: \(sname)")
        //}
      //  guard source.canBeConverted(to: target) else {
      //      fatalError("\(source) can not be converted to \(target)")
      //  }
        var tmpContext = ACPI.AMLExecutionContext(scope: AMLNameString(value: fullPath),
                                                  args: context.args,
                                                  globalObjects: context.globalObjects)
        dest.object!.updateValue(to: source, context: &tmpContext)

        return v
    }
}


struct AMLDefSubtract: AMLType2Opcode {

    // SubtractOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefTimer: AMLType2Opcode {

    // TimerOp
    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToBCD: AMLType2Opcode {

    // ToBCDOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
    var description: String { return "ToBCD(\(operand), \(target)" }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToBuffer: AMLType2Opcode {

    // ToBufferOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
    var description: String { return "ToBuffer(\(operand), \(target)" }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToDecimalString: AMLType2Opcode {

    // ToDecimalStringOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToHexString: AMLType2Opcode {

    // ToHexStringOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToInteger: AMLType2Opcode {

    // ToIntegerOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToString: AMLType2Opcode {

    // ToStringOp TermArg LengthArg Target
    let arg: AMLTermArg
    let length: AMLTermArg // => Integer
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefWait: AMLType2Opcode {

    // WaitOp EventObject Operand
    let object: AMLEventObject
    let operand: AMLOperand


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefXor: AMLType2Opcode {
    // XorOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    var target: AMLTarget


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = op1 ^ op2
        return AMLIntegerData(value: value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws  -> AMLTermArg{
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLMethodInvocation: AMLType2Opcode {


    // NameString TermArgList
    let method: AMLNameString
    let args: AMLTermArgList

    init(method: AMLNameString, args: AMLTermArgList) throws {
        guard args.count < 8 else {
            throw AMLError.invalidData(reason: "More than 7 args")
        }
        self.method = method
        self.args = args
    }

    init(method: AMLNameString, _ args: AMLTermArg...) throws {
        try self.init(method: method, args: args)
    }

    private func _OSI_Method(_ args: AMLTermArgList) throws -> AMLTermArg {
        guard args.count == 1 else {
            throw AMLError.invalidData(reason: "_OSI: Should only be 1 arg")
        }
        guard let arg = args[0] as? AMLString else {
            throw AMLError.invalidData(reason: "_OSI: is not a string")
        }
        if arg.value == "Darwin" {
            return AMLIntegerData(value: 0xffffffff)
        } else {
            return AMLIntegerData(value: 0)
        }
    }


    private func _invokeMethod(invocation: AMLMethodInvocation,
                               context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg? {

        let name = invocation.method._value
        if name == "\\_OSI" || name == "_OSI" {
            return try _OSI_Method(invocation.args)
        }

        //let scope = invocation.method
        guard let (obj, fullPath) = context.globalObjects.getGlobalObject(currentScope: context.scope,
                                                              name: invocation.method) else {
            throw AMLError.invalidMethod(reason: "Cant find method: \(name)")
        }
        guard let method = obj.object as? AMLMethod else {
            throw AMLError.invalidMethod(reason: "\(name) [\(String(describing:obj.object))] is not an AMLMethod")
        }
        let termList = try method.termList()
        var newContext = ACPI.AMLExecutionContext(scope: AMLNameString(value: fullPath),
                                                  args: invocation.args,
                                                  globalObjects: context.globalObjects)
//            context.withNewScope(AMLNameString(value: fullPath))   //invocation.method)
        try newContext.execute(termList: termList)
        context.returnValue = newContext.returnValue
        return context.returnValue
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let returnValue = try _invokeMethod(invocation: self, context: &context)

        context.returnValue = returnValue
        guard let retval = returnValue else {
            return AMLIntegerData(value: 0)
        }
        return retval
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        do {
            if let result = try _invokeMethod(invocation: self, context: &context) {
                return result
            }
        } catch {
            fatalError("cant evaluate: \(self): \(error)")
        }
        fatalError("Failed to evaluate \(self)")
    }
}


// AMLType6Opcode
struct AMLUserTermObj: AMLType6Opcode {

    var value: AMLDataRefObject {
        get { fatalError("Cant Get") }
        set {}
    }
}


func AMLByteConst(_ v: AMLByteData) -> AMLIntegerData {
    return AMLIntegerData(value: AMLInteger(v))
}

func AMLWordConst(_ v: AMLWordData) -> AMLIntegerData {
    return AMLIntegerData(value: AMLInteger(v))
}

func AMLDWordConst(_ v: AMLDWordData) -> AMLIntegerData {
    return AMLIntegerData(value: AMLInteger(v))
}

func AMLQWordConst(_ v: AMLQWordData) -> AMLIntegerData {
    return AMLIntegerData(value: AMLInteger(v))
}


struct AMLString: AMLDataRefObject {

    var asString: String? { return self.value }
    var isReadOnly: Bool { return false }
    var resultAsString: AMLString? { return self }

    var value: String

    init(_ v: String) {
        value = v
    }
}


protocol AMLConstObj: AMLComputationalData {
}

extension AMLConstObj {
    var isReadOnly: Bool { return true }
}


struct AMLZeroOp: AMLConstObj {
    // ZeroOp
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return true
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return AMLIntegerData(value: 0)
    }
}

struct AMLOneOp: AMLConstObj {
    // OneOp
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return true
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return AMLIntegerData(value: 1)
    }
}

struct AMLOnesOp: AMLConstObj {
    // OnesOp
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return true
    }
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return AMLIntegerData(value: 0xff)
    }
}


struct AMLRevisionOp: AMLConstObj {
    // RevisionOp - AML interpreter supports revision 2
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return AMLIntegerData(value: 2)
    }
}


// AMLDataObject
struct AMLDDBHandle: AMLDataRefObject {
    var asString: String? { return String(value) }
    let isReadOnly = true

    let value: AMLInteger
}


typealias AMLObjectReference = AMLInteger



// opcode or character
protocol AMLSymbol {
}

// ASCII 'A'-'Z' 0x41 - 0x5A

enum AMLChar {
case nullChar, leadNameChar, digitChar, rootChar, parentPrefixChar, dualNamePrefix, multiNamePrefix
}

struct AMLCharSymbol: AMLSymbol, Equatable {
    let value: UInt8
    let charType: AMLChar

    init?(byte: UInt8) {
        switch byte {
        case 0x00:
            charType = .nullChar

            // A-Z
        case 0x41...0x5A:
            charType = .leadNameChar

            // 0-9
        case 0x30...0x39:
            charType = .digitChar

            // '_'
        case 0x5F:
            charType = .leadNameChar

            // '\'
        case 0x5C:
            charType = .rootChar

            // '^'
        case 0x5E:
            charType = .parentPrefixChar

        case 0x2E:
            charType = .dualNamePrefix

        case 0x2F:
            charType = .multiNamePrefix

        default:
            return nil
        }
        value = byte
    }

    // '_' is trailing padding
    static let paddingChar = Character(UnicodeScalar(0x5F))

    var character: Character { return Character(UnicodeScalar(value)) }
    var isPaddingChar: Bool { return character == AMLCharSymbol.paddingChar }

    var numericValueInclHex: Int? {
        if charType == .digitChar {
            return Int(value) - 0x30
        } else if value >= 0x41 && value <= 46 { // 'A' - 'F'
            return Int(value) - 0x41 + 10
        } else {
            return nil
        }
    }

    var numericValue: Int? {
        if let value = numericValueInclHex, value < 10 {
            return value
        }
        return nil
    }
}


func ==(lhs: AMLCharSymbol, rhs: AMLCharSymbol) -> Bool {
    return lhs.character == rhs.character
}



enum AMLOpcode: UInt16, AMLSymbol {
    case zeroOp             = 0x00
    case oneOp              = 0x01
    case aliasOp            = 0x06
    case nameOp             = 0x08
    case bytePrefix         = 0x0a
    case wordPrefix         = 0x0b
    case dwordPrefix        = 0x0c
    case stringPrefix       = 0x0d
    case qwordPrefix        = 0x0e     /* acpi 2.0 */
    case scopeOp            = 0x10
    case bufferOp           = 0x11
    case packageOp          = 0x12
    case varPackageOp       = 0x13     /* acpi 2.0 */
    case methodOp           = 0x14
    case externalOp         = 0x15
    case extendedOpPrefix   = 0x5b

    // Extended 2byte opcodes
    case mutexOp            = 0x5b01
    case eventOp            = 0x5b02
    case condRefOfOp        = 0x5b12
    case createFieldOp      = 0x5b13
    case loadTableOp        = 0x5b1f
    case loadOp             = 0x5b20
    case stallOp            = 0x5b21
    case sleepOp            = 0x5b22
    case acquireOp          = 0x5b23
    case signalOp           = 0x5b24
    case waitOp             = 0x5b25
    case resetOp            = 0x5b26
    case releaseOp          = 0x5b27
    case fromBCDOp          = 0x5b28
    case toBCDOp            = 0x5b29
    case unloadOp           = 0x5b2a
    case revisionOp         = 0x5b30
    case debugOp            = 0x5b31
    case fatalOp            = 0x5b32
    case timerOp            = 0x5b33
    case opRegionOp         = 0x5b80
    case fieldOp            = 0x5b81
    case deviceOp           = 0x5b82
    case processorOp        = 0x5b83
    case powerResOp         = 0x5b84
    case thermalZoneOp      = 0x5b85
    case indexFieldOp       = 0x5b86
    case bankFieldOp        = 0x5b87
    case dataRegionOp       = 0x5b88

    case local0Op           = 0x60
    case local1Op           = 0x61
    case local2Op           = 0x62
    case local3Op           = 0x63
    case local4Op           = 0x64
    case local5Op           = 0x65
    case local6Op           = 0x66
    case local7Op           = 0x67
    case arg0Op             = 0x68
    case arg1Op             = 0x69
    case arg2Op             = 0x6a
    case arg3Op             = 0x6b
    case arg4Op             = 0x6c
    case arg5Op             = 0x6d
    case arg6Op             = 0x6e
    case storeOp            = 0x70
    case refOfOp            = 0x71
    case addOp              = 0x72
    case concatOp           = 0x73
    case subtractOp         = 0x74
    case incrementOp        = 0x75
    case decrementOp        = 0x76
    case multiplyOp         = 0x77
    case divideOp           = 0x78
    case shiftLeftOp        = 0x79
    case shiftRightOp       = 0x7a
    case andOp              = 0x7b
    case nandOp             = 0x7c
    case orOp               = 0x7d
    case norOp              = 0x7e
    case xorOp              = 0x7f
    case notOp              = 0x80
    case findSetLeftBitOp   = 0x81
    case findSetRightBitOp  = 0x82
    case derefOfOp          = 0x83
    case concatResOp        = 0x84     /* acpi 2.0 */
    case modOp              = 0x85     /* acpi 2.0 */
    case notifyOp           = 0x86
    case sizeOfOp           = 0x87
    case indexOp            = 0x88
    case matchOp            = 0x89
    case createDWordFieldOp = 0x8a
    case createWordFieldOp  = 0x8b
    case createByteFieldOp  = 0x8c
    case createBitFieldOp   = 0x8d
    case objectTypeOp       = 0x8e
    case createQWordFieldOp = 0x8f     /* acpi 2.0 */
    case lAndOp             = 0x90
    case lOrOp              = 0x91
    case lNotOp             = 0x92
    case lNotEqualOp        = 0x9293    // combinational
    case lLessEqualOp       = 0x9294    // combinational
    case lGreaterEqualOp    = 0x9295    // combinational

    case lEqualOp           = 0x93
    case lGreaterOp         = 0x94
    case lLessOp            = 0x95
    case toBufferOp         = 0x96     /* acpi 2.0 */
    case toDecimalStringOp  = 0x97     /* acpi 2.0 */
    case toHexStringOp      = 0x98     /* acpi 2.0 */
    case toIntegerOp        = 0x99     /* acpi 2.0 */
    case toStringOp         = 0x9c     /* acpi 2.0 */
    case copyObjectOp       = 0x9d     /* acpi 2.0 */
    case midOp              = 0x9e     /* acpi 2.0 */
    case continueOp         = 0x9f     /* acpi 2.0 */
    case ifOp               = 0xa0
    case elseOp             = 0xa1
    case whileOp            = 0xa2
    case noopOp             = 0xa3
    case returnOp           = 0xa4
    case breakOp            = 0xa5
    case breakPointOp       = 0xcc
    case onesOp             = 0xff


    init?(byte: UInt8) {
        self.init(rawValue: UInt16(byte))
    }


    var isTwoByteOpcode: Bool {
        return self.rawValue == AMLOpcode.extendedOpPrefix.rawValue
    }
}
