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


protocol AMLTermObj {
}

protocol AMLTermArg {
    var resultAsInteger: AMLInteger? { get }
    var resultAsString: AMLString? { get }
    func canBeConverted(to: AMLDataRefObject) -> Bool
}

extension AMLTermArg {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        print("AMLTermArg.canBeConverted")
        return false
    }
    var resultAsString: AMLString? { return nil }
}


protocol AMLBuffPkgStrObj: AMLTermArg {
}

protocol AMLNamedObj: AMLTermObj {
    mutating func updateValue(to: AMLTermArg)
}

extension AMLNamedObj {
    func updateValue(to: AMLTermArg) { fatalError("updateValue denied") }
}

protocol AMLDataRefObject: AMLBuffPkgStrObj, AMLNamedObj {
    var asInteger: AMLInteger? { get }
    var asString: String? { get }
    var isReadOnly: Bool { get }


}

extension AMLDataRefObject {
    func updateValue(to: AMLTermArg) {
        print("AMLDataRefObject")
        fatalError("updateValue denied")
    }
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
}


protocol AMLType1Opcode: AMLTermObj {
    func execute(context: inout ACPI.AMLExecutionContext) throws
}

extension AMLType1Opcode {
    func execute(context: inout ACPI.AMLExecutionContext) throws {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


protocol AMLType2Opcode: AMLTermObj, AMLTermArg {
    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg
}

extension AMLType2Opcode {
    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


protocol AMLType6Opcode: AMLSuperName, AMLBuffPkgStrObj {
}


protocol AMLDataObject: AMLDataRefObject {
}


protocol AMLComputationalData: AMLDataObject {
}


struct AMLIntegerData: AMLDataObject, AMLTermArg {
    var asInteger: AMLInteger? { return value }

    var asString: String? { return String(value) }

    var value: AMLInteger
    let isReadOnly = false
    var resultAsInteger: AMLInteger? { return value }

    func canBeConverted(to: AMLDataRefObject) -> Bool {
        print("AMLIntegerData.canBeConverted")
        if to is AMLIntegerData {
            return true
        }
        return false
    }

    mutating func updateValue(to: AMLTermArg) {
        guard let v = to.resultAsInteger else {
            fatalError("\(to) cannot be converted to integer")
        }
        value = v
    }

}


struct AMLNameString: AMLSimpleName, AMLTermArg {
    var value: AMLDataRefObject
    var resultAsInteger: AMLInteger? {
        return nil
    }
    var resultAsString: AMLString? { return AMLString(_value) }
    var _value: String

    init(value: String) {
        _value = value
        self.value = AMLString(value)
    }

    var isNameSeg: Bool { return (_value.characters.count <= 4) }

    static func ==(lhs: AMLNameString, rhs: AMLNameString) -> Bool {
        return lhs._value == rhs._value
    }

    static func ==(lhs: AMLNameString, rhs: String) -> Bool {
        return lhs._value == rhs
    }

    static func ==(lhs: String, rhs: AMLNameString) -> Bool {
        return lhs == rhs._value
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
        var f = UInt8(argCount & 0x7)
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
        print("AMLArgObj.canBeConverted")
        return false
    }


    var resultAsInteger: AMLInteger? { return nil }
    let opcode: AMLOpcode      // FIXME needs better type
    var argIdx: UInt8 { return UInt8(opcode.rawValue - AMLOpcode.arg0Op.rawValue) }

    init(argOp: AMLOpcode) throws {
        switch argOp {
        case .arg0Op, .arg1Op, .arg2Op, .arg3Op, .arg4Op, .arg5Op, .arg6Op:
            opcode = argOp

        default: throw AMLError.invalidData(reason: "Invalid arg")
        }
    }
}


struct AMLLocalObj: AMLTermArg, AMLSimpleName, AMLBuffPkgStrObj, AMLTermObj {
    var value: AMLDataRefObject {
        get { fatalError("cant get arg") }
        set { fatalError("ArgObj is readonly") }
    }

    var resultAsInteger: AMLInteger? { return nil }
    let opcode: AMLOpcode      // FIXME needs better type
    var argIdx: UInt8 { return UInt8(opcode.rawValue - AMLOpcode.local0Op.rawValue) }

    init(localOp: AMLOpcode) throws {
         switch localOp {
        case .local0Op, .local1Op, .local2Op, .local3Op,
            .local4Op, .local5Op, .local6Op, .local7Op:
            opcode = localOp

         default: throw AMLError.invalidData(reason: "Invalid arg")
        }
    }
}


struct AMLDebugObj: AMLSuperName, AMLDataRefObject, AMLTarget {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }

    var isReadOnly: Bool  { return false }
    var asInteger: AMLInteger? { fatalError("Cant convert") }
    var asString: String? { fatalError("Cant convert") }
    var resultAsInteger: AMLInteger? { fatalError("Cant convert") }

    var value: AMLDataRefObject {
        get { fatalError("DebugObject cant be used as a source operand") }
        set { debugPrint(newValue) }
    }

    // empty for now
}


// AMLNamedObj


protocol AMLFieldElement {
}

protocol AMLConnectField: AMLFieldElement {
}


typealias AMLFieldList = [AMLFieldElement]

struct AMLNamedField: AMLFieldElement, AMLNamedObj {
    let name: AMLNameString
    let bitOffset: UInt
    let bitWidth: UInt

    init(name: AMLNameString, bitOffset: UInt, bitWidth: UInt) throws {
        guard name.isNameSeg else {
            throw AMLError.invalidData(reason: "\(name) is not a NameSeg")
        }
        self.name = name
        self.bitOffset = bitOffset
        self.bitWidth = bitWidth
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
    var resultAsInteger: AMLInteger? { return nil }

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


struct AMLDefIndexField {
    // IndexFieldOp PkgLength NameString NameString FieldFlags FieldList
    //let name: AMLNameString
    let dataName: AMLNameString
    let flags: AMLFieldFlags
    let fields: AMLFieldList
}


struct AMLMethod: AMLNamedObj, AMLDataRefObject {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }

    var isReadOnly: Bool { return true }
    var asInteger: AMLInteger? { return nil }
    var asString: String? { return nil }
    var resultAsInteger: AMLInteger? { return nil }

    //let name: AMLNameString
    let flags: AMLMethodFlags
    let parser: AMLParser
}



struct AMLDefMutex: AMLNamedObj {
    let name: AMLNameString
    let flags: AMLMutexFlags
}


struct AMLFieldFlags {
    let flags: AMLByteData
}

struct AMLDefBankField {
    // BankFieldOp PkgLength NameString NameString BankValue FieldFlags FieldList
    //let name: AMLNameString
    let bankValue: AMLTermArg // => Integer
    let flags: AMLFieldFlags
    let fields: AMLFieldList
}


struct AMLDefCreateBitField: AMLTermObj {
    // CreateBitFieldOp SourceBuff BitIndex NameString
    let sourceBuff: AMLTermArg
    let bitIndex: AMLTermArg
    let name: AMLNameString
}


struct AMLDefCreateByteField: AMLTermObj {
    // CreateByteFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLTermArg
    let name: AMLNameString
}

struct AMLDefCreateDWordField: AMLTermObj {
    // CreateDWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLTermArg
    let name: AMLNameString
}


struct AMLDefCreateField: AMLTermObj {
    // CreateFieldOp SourceBuff BitIndex NumBits NameString
    let sourceBuff: AMLTermArg
    let bitIndex: AMLTermArg
    let numBits: AMLTermArg
    let name: AMLNameString
}


struct AMLDefCreateQWordField: AMLTermObj {
    // CreateQWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLTermArg
    let name: AMLNameString
}


struct AMLDefCreateWordField: AMLTermObj {
    // CreateWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg
    let byteIndex: AMLTermArg
    let name: AMLNameString
}


struct AMLDefField: AMLNamedObj, AMLDataRefObject {
    var asInteger: AMLInteger? { return nil }
    var asString: String? { return nil }
    var isReadOnly: Bool { return false }
    var resultAsInteger: AMLInteger? { return nil }

    // FieldOp PkgLength NameString FieldFlags FieldList
    let name: AMLNameString
    let flags: AMLFieldFlags
    let fields: AMLFieldList
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
    var resultAsInteger: AMLInteger? { return nil }

    // OpRegionOp NameString RegionSpace RegionOffset RegionLen
    let name: AMLNameString
    let region: AMLRegionSpace
    let offset: AMLTermArg // => Integer
    let length: AMLTermArg // => Integer
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
    var name: AMLNameString { return aliasObject }
    let sourceObject: AMLNameString
    let aliasObject: AMLNameString
}


/*struct AMLDefName: AMLNameSpaceModifierObj {
    // NameOp NameString DataRefObject
    let name: AMLNameString
    let value: AMLDataRefObject
}*/


struct AMLDefScope: AMLNameSpaceModifierObj {
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
}


struct AMLDefFatal: AMLType1Opcode {
    let type: AMLByteData
    let code: AMLDWordData
    let arg: AMLTermArg // => Integer
}


typealias AMLPredicate = AMLTermArg // => Integer
struct AMLIfElseOp: AMLType1Opcode {
    // IfOp PkgLength Predicate TermList DefElse
    let predicate: AMLPredicate
    let value: AMLTermList
    let elseValue: AMLTermList?

    init(predicate: AMLPredicate, value: AMLTermList, defElse: AMLDefElse) {
        self.predicate = predicate
        self.value = value
        elseValue = defElse.value
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        print(predicate)
        guard let result = predicate.resultAsInteger else {
            fatalError("Predicate does not evaluate to an integer")
        }
        if result != 0 {
            try context.execute(termList: value)
        } else if let elseTermList = elseValue {
            try context.execute(termList: elseTermList)
        }
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

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        context.returnValue = object
        context.endOfMethod = true
    }
}


struct AMLDefSignal: AMLType1Opcode {
    // SignalOp EventObject
    let object: AMLEventObject
}


struct AMLDefSleep: AMLType1Opcode {
    // SleepOp MsecTime
    let msecTime: AMLTermArg // => Integer
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
}


// AMLType2Opcode
typealias AMLTimeout = AMLWordData
struct AMLDefAcquire: AMLType2Opcode {
    // AcquireOp MutexObject Timeout
    var resultAsInteger: AMLInteger? { return nil }
    let mutex: AMLMutexObject
    let timeout: AMLTimeout
}

typealias AMLOperand = AMLTermArg // => Integer
struct AMLDefAdd: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // AddOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget
}


struct AMLDefAnd: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // AndOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget
}


struct AMLBuffer: AMLType2Opcode, AMLComputationalData {
    var resultAsInteger: AMLInteger? { return nil }
    var asInteger: AMLInteger? { return nil }
    var asString: String? { return nil }
    var isReadOnly: Bool { return true }

    // BufferOp PkgLength BufferSize ByteList
    let size: AMLTermArg // => Integer
    let value: AMLByteList
}


typealias AMLData = AMLTermArg // => ComputationalData
struct AMLDefConcat: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ConcatOp Data Data Target
    let data1: AMLData
    let data2: AMLData
    let target: AMLTarget
}


typealias AMLBufData = AMLTermArg // =>
struct AMLDefConcatRes: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ConcatResOp BufData BufData Target
    let data1: AMLBufData
    let data2: AMLBufData
    let target: AMLTarget
}

///ObjReference := TermArg => ObjectReference | String
//ObjectReference :=  Integer
struct AMLDefCondRefOf: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }

    // CondRefOfOp SuperName Target
    let name: AMLSuperName
    let target: AMLTarget
}


struct AMLDefCopyObject: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // CopyObjectOp TermArg SimpleName
    let object: AMLTermArg
    let target: AMLSimpleName
}


struct AMLDefDecrement: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // DecrementOp SuperName
    let target: AMLSuperName
}


struct AMLDefDerefOf: AMLType2Opcode, AMLType6Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    var value: AMLDataRefObject {
        get {fatalError("cant get") }
        set {}
    }

    // DerefOfOp ObjReference
    let name: AMLSuperName
}


typealias AMLDividend = AMLTermArg // => Integer
typealias AMLDivisor = AMLTermArg // => Integer
struct AMLDefDivide: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // DivideOp Dividend Divisor Remainder Quotient
    let dividend: AMLDividend
    let divisor: AMLDivisor
    var remainder: AMLTarget
    var quotient: AMLTarget

    mutating func execute() -> AMLIntegerData {
        if let d1 = dividend.resultAsInteger, let d2 = divisor.resultAsInteger {
            guard d2 != 0 else {
                fatalError("divisor is 0")
            }
            remainder.value = AMLIntegerData(value: (d1 % d2))
            let q = d1 / d2
            quotient.value = AMLIntegerData(value: q)
            return AMLIntegerData(value: q)
        }
        fatalError("divide: arguments are not both integer")
    }
}


struct AMLDefFindSetLeftBit: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // FindSetLeftBitOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
}


struct AMLDefFindSetRightBit: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // FindSetRightBitOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
}


typealias AMLBCDValue = AMLTermArg //=> Integer
struct AMLDefFromBCD: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // FromBCDOp BCDValue Target
    let value: AMLBCDValue
    let target: AMLTarget
}


struct AMLDefIncrement: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // IncrementOp SuperName
    let target: AMLSuperName
}



struct AMLDefIndex: AMLType2Opcode, AMLType6Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    var value: AMLDataRefObject {
        get {fatalError("Cant get") }
        set {}
    }

    // IndexOp BuffPkgStrObj IndexValue Target
    let object: AMLBuffPkgStrObj // => Buffer, Package or String
    let index: AMLTermArg // => Integer
    let target: AMLTarget
}


struct AMLDefLAnd: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // LandOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand
}


struct AMLDefLEqual: AMLType2Opcode {
    var resultAsInteger: AMLInteger? {
        if let op1 = operand1.resultAsInteger,
            let op2 = operand2.resultAsInteger {
            return (op1 == op2) ? 1 : 0
        }
        return nil // FIXME: Throw?
    }

    // LequalOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand
}


struct AMLDefLGreater: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // LgreaterOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand
}


struct AMLDefLGreaterEqual: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // LgreaterEqualOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand
}


struct AMLDefLLess: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // LlessOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand
}


struct AMLDefLLessEqual: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // LlessEqualOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand
}


struct AMLDefLNot: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // LnotOp Operand
    let operand: AMLOperand
}


struct AMLDefLNotEqual: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // LnotEqualOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand
}


struct AMLDefLoadTable: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // LoadTableOp TermArg TermArg TermArg TermArg TermArg TermArg
    let arg1: AMLTermArg
    let arg2: AMLTermArg
    let arg3: AMLTermArg
    let arg4: AMLTermArg
    let arg5: AMLTermArg
    let arg6: AMLTermArg
}


struct AMLDefLOr: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // LorOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand
}


struct AMLDefMatch: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
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
}


struct AMLDefMid: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // MidOp MidObj TermArg TermArg Target
    let obj: AMLTermArg // => Buffer | String
    let arg1: AMLTermArg
    let arg2: AMLTermArg
    let target: AMLTarget
}


struct AMLDefMod: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ModOp Dividend Divisor Target
    let dividend: AMLDividend
    let divisor: AMLDivisor
    let target: AMLTarget
}


struct AMLDefMultiply: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // MultiplyOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget
}


struct AMLDefNAnd: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // NandOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget
}


struct AMLDefNOr: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // NorOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget
}


struct AMLDefNot: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // NotOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
}


struct AMLDefObjectType: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ObjectTypeOp <SimpleName | DebugObj | DefRefOf | DefDerefOf | DefIndex>
    let object: AMLSuperName
}


struct AMLDefOr: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // OrOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget
}


typealias AMLPackageElement = AMLDataRefObject
typealias AMLPackageElementList = [AMLPackageElement]
struct AMLDefPackage: AMLType2Opcode, AMLDataObject, AMLTermArg {
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
}


/*struct AMLDefVarPackage: AMLType2Opcode, AMLDataObject {
    // VarPackageOp PkgLength VarNumElements PackageElementList
    let pkgLength: AMLPkgLength
    let varNumElements: AMLTermArg // => Integer
    let elements: AMLPackageElementList
    var value: AMLPackageElementList { return elements }
}*/
//func AMLDefVarPAckage(element)
typealias AMLDefVarPackage = AMLDataRefObject


struct AMLDefRefOf: AMLType2Opcode, AMLType6Opcode {

    var resultAsInteger: AMLInteger? { return nil }
    var value: AMLDataRefObject {
        get {fatalError("cant get") }
        set {}
    }

    // RefOfOp SuperName
    let name: AMLSuperName
}


typealias AMLShiftCount = AMLTermArg // => Integer
struct AMLDefShiftLeft: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ShiftLeftOp Operand ShiftCount Target
    let operand: AMLOperand
    let count: AMLShiftCount
    let target: AMLTarget
}


struct AMLDefShiftRight: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ShiftRightOp Operand ShiftCount Target
    let operand: AMLOperand
    let count: AMLShiftCount
    let target: AMLTarget
}


struct AMLDefSizeOf: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // SizeOfOp SuperName
    let name: AMLSuperName
}


struct AMLDefStore: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // StoreOp TermArg SuperName
    let arg: AMLTermArg
    let name: AMLSuperName

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        guard let sname = name as? AMLNameString else {
            throw AMLError.invalidData(reason: "\(name) is not a string")
        }
        guard let dest = try context.globalObjects.getGlobalObject(currentScope: context.scope,
                                                                   name: sname) else {
                                                                    fatalError("Cant find \(sname)")
        }
        guard let target = dest.object as? AMLDataRefObject else {
            fatalError("dest not an AMLDataRefObject")
        }

        var source = arg
        if let args2 = arg as? AMLArgObj {
            guard args2.argIdx < context.args.count else {
                fatalError("Tried to access arg \(args2.argIdx) but only have \(context.args.count) args")
            }
            source = context.args[Int(args2.argIdx)]
        }
        guard source.canBeConverted(to: target) else {
            fatalError("\(source) can not be converted to \(target)")
        }
        dest.object?.updateValue(to: source)
        print(dest)
        return source
    }
}


struct AMLDefSubtract: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // SubtractOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget
}


struct AMLDefTimer: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // TimerOp
}


struct AMLDefToBCD: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ToBCDOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
    var description: String { return "ToBCD(\(operand), \(target)" }
}


struct AMLDefToBuffer: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ToBufferOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
    var description: String { return "ToBuffer(\(operand), \(target)" }
}


struct AMLDefToDecimalString: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ToDecimalStringOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
}


struct AMLDefToHexString: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ToHexStringOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
}


struct AMLDefToInteger: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ToIntegerOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
}


struct AMLDefToString: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // ToStringOp TermArg LengthArg Target
    let arg: AMLTermArg
    let length: AMLTermArg // => Integer
    let target: AMLTarget
}


struct AMLDefWait: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }
    // WaitOp EventObject Operand
    let object: AMLEventObject
    let operand: AMLOperand
}


struct AMLDefXor: AMLType2Opcode {

    var resultAsInteger: AMLInteger? { return nil }

    // XorOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    var target: AMLTarget

    mutating func execute() -> AMLIntegerData {
        if let o1 = operand1.resultAsInteger, let o2 = operand2.resultAsInteger {
            let result = AMLIntegerData(value: o1 ^ o2)
            target.value = result
            return result
        }
        fatalError("Xor: operand1 and operand2 are not both integers")
    }
}


struct AMLMethodInvocation: AMLType2Opcode {
    var resultAsInteger: AMLInteger? { return nil }

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
        guard let arg = args[0].resultAsString else {
            throw AMLError.invalidData(reason: "_OSI: is not a string")
        }
        if arg.value == "Windows" {
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
        guard let obj = context.globalObjects.get(name) else {
            throw AMLError.invalidMethod(reason: "Cant find method: \(name)")
        }
        guard let method = obj.object as? AMLMethod else {
            throw AMLError.invalidMethod(reason: "Cant find method: \(name)")
        }
        let termList = try method.parser.parseTermList()
        print(termList)
        //var context = ACPI.AMLExecutionContext(scope: scope,
        //                                  args: invocation.args,
        //                                  globalObjects: globalObjects)

        try context.execute(termList: termList)
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
}


// AMLType6Opcode
struct AMLUserTermObj: AMLType6Opcode {
    var resultAsInteger: AMLInteger? { return nil }
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
    var resultAsInteger: AMLInteger? { return nil }

    var asInteger: AMLInteger? { return nil }
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
    var asInteger: AMLInteger? { return self.resultAsInteger }
    var asString: String? { return String(self.resultAsInteger!) }
    var isReadOnly: Bool { return true }
}


struct AMLZeroOp: AMLConstObj {
    // ZeroOp
    var resultAsInteger: AMLInteger? { return 0 }
}

struct AMLOneOp: AMLConstObj {
    // OneOp
    var resultAsInteger: AMLInteger? { return 1 }
}

struct AMLOnesOp: AMLConstObj {
    // OnesOp
    var resultAsInteger: AMLInteger? { return 0xff }
}


struct AMLRevisionOp: AMLConstObj {
    // RevisionOp - AML interpreter supports revision 2
    var resultAsInteger: AMLInteger? { return 2 }
}


// AMLDataObject
struct AMLDDBHandle: AMLDataRefObject {
    var asInteger: AMLInteger? { return value }
    var asString: String? { return String(value) }
    let isReadOnly = true
    var resultAsInteger: AMLInteger? { return value }

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
