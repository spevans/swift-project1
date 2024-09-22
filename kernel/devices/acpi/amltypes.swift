/*
 * kernel/devices/acpi/amltypes.swift
 *
 * Created by Simon Evans on 05/07/2016.
 * Copyright © 2016 - 2019 Simon Evans. All rights reserved.
 *
 * AML Type and Opcode definitions
 */


// Simple Types
typealias AMLInteger = UInt64
typealias AMLString = String
typealias AMLTermList = [AMLTermObj]
typealias AMLByteData = UInt8
typealias AMLByteList = [AMLByteData]
typealias AMLBuffer = AMLByteList
typealias AMLWordData = UInt16
typealias AMLDWordData = UInt32
typealias AMLQWordData = UInt64
typealias AMLTermArgList = [AMLTermArg]
typealias AMLPkgLength = UInt


protocol AMLTermObj {
}


protocol AMLTermArg: CustomStringConvertible {
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg

    var integerValue: AMLInteger? { get }
    var stringValue: AMLString? { get }
    var bufferValue: AMLSharedBuffer? { get }
}


extension AMLTermArg {
    var integerValue: AMLInteger? { nil }
    var stringValue: AMLString? { nil }
    var bufferValue: AMLSharedBuffer? { nil }
    var description: String {
        if let i = integerValue {
            return "0x" + String(i, radix: 16)
        } else if let s = stringValue {
            return s
        } else if let b = bufferValue {
            return "[Buffer of  \(b.count) bytes]"
        } else {
            return "<UNKNOWN>"
        }
    }
}


protocol AMLTarget {
    //var value: AMLDataRefObject { get set }
    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext)
}



protocol AMLSuperName: AMLTarget {
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg
    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext)
}

protocol AMLType6Opcode: AMLSuperName {}

enum AMLSimpleName: AMLSuperName {
    case nameString(AMLNameString)
    case argObj(AMLArgObj)
    case localObj(AMLLocalObj)

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        switch self {
            case .nameString(let name): return name
            case .argObj(let object): return object.evaluate(context: &context)
            case .localObj(let object): return object.evaluate(context: &context)
        }
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        switch self {
            case .nameString(let name): name.updateValue(to: to, context: &context)
            case .argObj(let object): object.updateValue(to: to, context: &context)
            case .localObj(let object): object.updateValue(to: to, context: &context)
        }
    }
}


#if false
// FIXME: 'indirect enum' causes a GP fault at the moment, most likely due to a bug in
// converting the runtime to negative address space - the faulting address has the
// high bit clear. Enable this one the runtime is fixed
indirect enum AMLSuperName: AMLTarget {
    case simpleName(AMLSimpleName)
    case debugObj(AMLDebugObj)

    // Type6 Opcodes
    case defRefOf(AMLDefRefOf)
    case defDerefOf(AMLDefDerefOf)
    case defIndex(AMLDefIndex)
    case userTermObj(AMLUserTermObj)

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        switch self {
            case .simpleName(let name):
                switch name {
                    case .nameString(let name): return name
                    case .argObj(let object): return object.evaluate(context: &context)
                    case .localObj(let object): return object.evaluate(context: &context)
                }

            case .debugObj(let object): return object.evaluate(context: &context)
            case .defRefOf(let ref): return ref.evaluate(context: &context)
            case .defDerefOf(let ref): return ref.evaluate(context: &context)
            case .defIndex(let index): return index.evaluate(context: &context)
            case .userTermObj(let object): return object.evaluate(context: &context)
        }
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        switch self {
            case .simpleName(let name):
                switch name {
                    case .nameString(let name): name.updateValue(to: to, context: &context)
                    case .argObj(let object): object.updateValue(to: to, context: &context)
                    case .localObj(let object): object.updateValue(to: to, context: &context)
                }

            case .debugObj(let object): object.updateValue(to: to, context: &context)
            case .defRefOf(let ref): ref.updateValue(to: to, context: &context)
            case .defDerefOf(let ref): ref.updateValue(to: to, context: &context)
            case .defIndex(let index): index.updateValue(to: to, context: &context)
            case .userTermObj(let object): object.updateValue(to: to, context: &context)
        }
    }
}
#endif


final class AMLSharedBuffer: RandomAccessCollection {
    typealias Index = Int
    typealias Element = UInt8

    private var buffer: [UInt8]

    var count: Int { buffer.count }
    var startIndex: Index { buffer.startIndex }
    var endIndex: Index { buffer.endIndex }

    init(bytes: AMLBuffer) {
        buffer = bytes
    }

    func copy() -> Self {
        return Self(bytes: buffer)
    }

    func copyBuffer() -> AMLBuffer {
        let copy = buffer
        return copy
    }

    func index(after i: Index) -> Index {
        precondition(i >= 0)
        precondition(i < endIndex)
        return i + 1
    }

    subscript(position: Index) -> Element {
        get { buffer[position] }
        set { buffer[position] = newValue }
    }


    // Bit
    func readBit(atBitIndex bitIndex: Int) -> AMLInteger {
        let byteIndex = Int(bitIndex / 8)
        let bit = bitIndex % 8
        let result = ((buffer[byteIndex] >> bit) & 1)
        return AMLInteger(result)
    }

    func writeBit(atBitIndex bitIndex: Int, value: AMLInteger) {
        let byteIndex = Int(bitIndex / 8)
        let bit = bitIndex % 8
        let mask = AMLByteData(1 << bit)

        switch value {
            case 0: buffer[byteIndex] &= ~mask
            case 1: buffer[byteIndex] |= mask
            default: fatalError("AMLSharedBuffer.writeBit: Attempting to set value to \(value) not 0 or 1")
        }
    }

    // Byte
    func readByte(atByteIndex index: Int) -> AMLByteData {
        return buffer[index]
    }

    func writeByte(atByteIndex index: Int, value: AMLByteData) {
        buffer[index] = value
    }

    // Word
    func readWord(atByteIndex byteIndex: Int) -> AMLWordData {
        let value = (AMLWordData(buffer[byteIndex + 1]) << 8) | (AMLWordData(buffer[byteIndex + 0]))
        return value
    }

    func writeWord(atByteIndex byteIndex: Int, value: AMLWordData) {
        buffer[Int(byteIndex + 0)] = AMLByteData(truncatingIfNeeded: value)
        buffer[Int(byteIndex + 1)] = AMLByteData(truncatingIfNeeded: value >> 8)
    }

    // DWord
    func readDWord(atByteIndex byteIndex: Int) -> AMLDWordData {
        let value = (AMLDWordData(buffer[Int(byteIndex + 3)]) << 24)
            | (AMLDWordData(buffer[Int(byteIndex + 2)]) << 16)
            | (AMLDWordData(buffer[Int(byteIndex + 1)]) << 8)
            | (AMLDWordData(buffer[Int(byteIndex + 0)]))
        return value
    }

    func writeDWord(atByteIndex byteIndex: Int, value: AMLDWordData) {
        buffer[Int(byteIndex + 0)] = AMLByteData(truncatingIfNeeded: value)
        buffer[Int(byteIndex + 1)] = AMLByteData(truncatingIfNeeded: value >> 8)
        buffer[Int(byteIndex + 2)] = AMLByteData(truncatingIfNeeded: value >> 16)
        buffer[Int(byteIndex + 3)] = AMLByteData(truncatingIfNeeded: value >> 24)
    }

    // QWord
    func readQWord(atByteIndex byteIndex: Int) -> AMLQWordData {
        var value = (AMLQWordData(buffer[byteIndex + 7]) << 56)
        value |= (AMLQWordData(buffer[byteIndex + 6]) << 48)
        value |= (AMLQWordData(buffer[byteIndex + 5]) << 40)
        value |= (AMLQWordData(buffer[byteIndex + 4]) << 32)
        value |= (AMLQWordData(buffer[byteIndex + 3]) << 24)
        value |= (AMLQWordData(buffer[byteIndex + 2]) << 16)
        value |= (AMLQWordData(buffer[byteIndex + 1]) << 8)
        value |= (AMLQWordData(buffer[byteIndex + 0]))
        return value
    }

    func writeQWord(atByteIndex byteIndex: Int, value: AMLQWordData) {
        buffer[Int(byteIndex + 0)] = AMLByteData(truncatingIfNeeded: value)
        buffer[Int(byteIndex + 1)] = AMLByteData(truncatingIfNeeded: value >> 8)
        buffer[Int(byteIndex + 2)] = AMLByteData(truncatingIfNeeded: value >> 16)
        buffer[Int(byteIndex + 3)] = AMLByteData(truncatingIfNeeded: value >> 24)
        buffer[Int(byteIndex + 4)] = AMLByteData(truncatingIfNeeded: value >> 32)
        buffer[Int(byteIndex + 5)] = AMLByteData(truncatingIfNeeded: value >> 40)
        buffer[Int(byteIndex + 6)] = AMLByteData(truncatingIfNeeded: value >> 48)
        buffer[Int(byteIndex + 7)] = AMLByteData(truncatingIfNeeded: value >> 56)
    }

    // Bits
    func readBits(atBitIndex bitIndex: Int, numBits: Int) -> AMLSharedBuffer {
        var result: AMLBuffer = []
        result.reserveCapacity((numBits + 7) / 8)

        if bitIndex.isMultiple(of: 8) && numBits.isMultiple(of: 8) {
            let start = bitIndex / 8
            let count = numBits / 8
            for i in 0..<count {
                result[i] = buffer[start + i]
            }
            return AMLSharedBuffer(bytes: result)
        } else {
            fatalError("AMLSharedBuffer.readBits() need to implement for index: \(bitIndex) numBits: \(numBits)")
        }
    }

    func writeBits<C: RandomAccessCollection>(atBitIndex bitIndex: Int, numBits: Int, value: C) where C.Element == UInt8, C.Index == Int {
        print("WriteBits bitIndex: \(bitIndex) numBits: \(numBits) buffer.count \(buffer.count) value.count: \(value.count)")
        if bitIndex.isMultiple(of: 8) && numBits.isMultiple(of: 8) {
            let start = bitIndex / 8
            let count = numBits / 8
            for i in 0..<count {
                buffer[start + i] = value[i]
            }
        } else {
            fatalError("AMLSharedBuffer.readBits() need to implement for index: \(bitIndex) numBits: \(numBits)")
        }
    }
}


enum AMLComputationalData {
    case buffer(AMLSharedBuffer)
    case integer(AMLInteger)
    case string(AMLString)
}

enum AMLDataObject: AMLTermArg, CustomStringConvertible {

    case package(AMLPackage)
    case buffer(AMLSharedBuffer)
    case integer(AMLInteger)
    case string(AMLString)

    var description: String {
        switch self {
        case .package: return "Package"
        case .buffer: return "Buffer"
        case let .integer(value): return "Integer: '\(value)'"
        case let .string(value): return "String: '\(value)'"
        }
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return self
    }

    func copy() -> Self {
        // Return a copy of the object, used by AMLPackage to copy objects that are being stored.
        switch self {
            case .package(let value): return AMLDataObject.package(value.copy())
            case .buffer(let value):  return AMLDataObject.buffer(value.copy())
            default: return self    // These are value types, implicitly copied
        }
    }

    var integerValue: AMLInteger? {
        switch self {
            case .integer(let value): return value
            default: return nil
        }
    }

    var stringValue: AMLString? {
        switch self {
            case .string(let value): return value
            default: return nil
        }
    }

    var bufferValue: AMLSharedBuffer? {
        switch self {
            case .buffer(let value): return value
            default: return nil
        }
    }

    var packageValue: AMLPackage? {
        switch self {
            case .package(let value): return value
            default: return nil
        }
    }

    var computationalData: AMLComputationalData? {
        switch self {
            case .buffer(let value):  return .buffer(value)
            case .integer(let value): return .integer(value)
            case .string(let value):  return .string(value)
            default: return nil
        }
    }
}


enum AMLDataRefObject {
    case dataObject(AMLDataObject)
    case objectReference(AMLInteger)
    case ddbHandle(AMLInteger)

    init?(_ value: Any) {
        if let refObject = value as? Self {
            self = refObject
        } else if let object = value as? AMLDataObject {
            self = .dataObject(object)
        } else {
            return nil
        }
    }

    init(_ value: Self) {
        self = value
    }

    init(integer: AMLInteger) {
        self = .dataObject(.integer(integer))
    }

    init(string: AMLString) {
        self = .dataObject(.string(string))
    }

    func copy() -> Self {
        switch self {
            case .dataObject(let value): return .dataObject(value.copy())
            default: return self
        }
    }

    var dataObject: AMLDataObject? {
        switch self {
            case .dataObject(let value): return value
            default: return nil
        }
    }

    var integerValue: AMLInteger? {
        switch self {
            case .dataObject(.integer(let value)): return value
            default: return nil
        }
    }

    var stringValue: AMLString? {
        switch self {
            case .dataObject(.string(let value)): return value
            default: return nil
        }
    }

    var bufferValue: AMLSharedBuffer? {
        switch self {
            case .dataObject(.buffer(let value)): return value
            default: return nil
        }
    }
}


enum AMLPackageElement {
    case uninitialised  // FIXME, might need to be used in other places
    case dataRefObject(AMLDataRefObject)
    case nameString(AMLNameString)

    init(object: AMLDataRefObject) {
        self = .dataRefObject(object)
    }

    init(string: AMLNameString) {
        self = .nameString(string)
    }

    init?(termarg: AMLTermArg) {
        if let dro = termarg as? AMLDataObject {
            self = .dataRefObject(.dataObject(dro))
        }
        else if let ns = termarg as? AMLNameString {
            self = .nameString(ns)
        }
        else {
            return nil
        }
    }

    func copy() -> Self {
        switch self {
            case .dataRefObject(let value): return .dataRefObject(value.copy())
            default: return self
        }
    }

    var dataRefObject: AMLDataRefObject? {
        switch self {
            case .dataRefObject(let object): return object
            default: return nil
        }
    }

    var nameString: AMLNameString? {
        switch self {
            case .nameString(let name): return name
            default: return nil
        }
    }
}


typealias AMLFieldList = [(AMLNameString, AMLFieldSettings)]
typealias AMLDDBHandleObject = AMLSuperName
typealias AMLMutexObject = AMLSuperName
typealias AMLEventObject = AMLSuperName
typealias AMLObjectReference = AMLInteger
typealias AMLDefVarPackage = AMLDataRefObject


protocol AMLIndexableObject: AnyObject, Sequence {
    associatedtype Element
    associatedtype Index
    var count: Int { get }
    subscript(position: Self.Index) -> Self.Element { get set }
}


final class AMLPackage: AMLIndexableObject {
    typealias Index = Int
    typealias Element = AMLPackageElement
    typealias Iterator = IndexingIterator<Array<Element>>

    private var elements: [AMLPackageElement]
    var count: Int { self.elements.count }

    init(numElements: Int, elements: [AMLPackageElement]) {
        guard numElements >= elements.count else {
            fatalError("AMLPackage: numElements: \(numElements), elements.count: \(elements.count)")
        }
        self.elements = elements

        // numElements may be greater then elements.count in which case fill the
        // other elements with AMLPackageElement.uninitialised
        if numElements > elements.count {
            self.elements.reserveCapacity(numElements)
            for _ in (elements.count)..<numElements {
                self.elements.append(.uninitialised)
            }
        }
        precondition(numElements == self.elements.count)
    }

    private init(elements: [AMLPackageElement]) {
        self.elements = elements
    }

    func copy() -> Self {
        return Self(elements: elements)
    }

    func makeIterator() -> IndexingIterator<Array<Element>> {
        return self.elements.makeIterator()
    }


    subscript(position: Index) -> Element {
        get { self.elements[position] }
        set { self.elements[position] = newValue.copy() }
    }
}


func AMLIntegerData(_ value: AMLInteger) -> AMLDataObject { .integer(value) }


struct AMLNameString: AMLTermArg, Hashable {

    let value: String
    var isNameSeg: Bool { return (value.count <= 4) }
    // Name starts with '\\'
    var isFullPath: Bool { return value.first == AMLNameString.rootChar }


    init(_ value: String) {
        self.value = value
    }


    init(buffer: ArraySlice<AMLByteData>) {
        precondition(buffer.count == 4)
        var name = ""
        for ch in buffer {
            name.append(String(UnicodeScalar(ch)))
        }
        value = name
    }


    var stringValue: AMLString? {
        AMLString(value)
    }

    // The last segment. If only one segment, removes the root '\\'
    var shortName: AMLNameString {
        if value == String(AMLNameString.rootChar) {
            return self
        }

        let segs = value.components(separatedBy: AMLNameString.pathSeparatorChar)
        if segs.count > 1 {
            return AMLNameString(segs.last!)
        } else {
            if value.first == AMLNameString.rootChar {
                var name = value
                name.remove(at: value.startIndex)
                return AMLNameString(name)
            }
        }
        return AMLNameString(value)
    }

    func parent() -> AMLNameString {
        let seperator = AMLNameString.pathSeparatorChar
        var parentSegs = value.components(separatedBy: seperator)
        parentSegs.removeLast()
        let result = parentSegs.joined(separator: String(seperator))
        return AMLNameString(result)
    }


    func replaceLastSeg(with newSeg: AMLNameString?) -> AMLNameString {
        let seperator = AMLNameString.pathSeparatorChar
        var parentSegs = value.components(separatedBy: seperator)
        //let child = newSeg._value.components(separatedBy: seperator).last()
        parentSegs.removeLast()
        if let segment = newSeg {
            parentSegs.append(segment.value)
        }
        if parentSegs.count == 0 {
            return AMLNameString("\\")
        }
        let result = parentSegs.joined(separator: String(seperator))
        return AMLNameString(result)
    }


    func removeLastSeg() -> AMLNameString {
        return replaceLastSeg(with: nil)
    }


    static func ==(lhs: AMLNameString, rhs: AMLNameString) -> Bool {
        return lhs.value == rhs.value
    }

    static func ==(lhs: AMLNameString, rhs: String) -> Bool {
        return lhs.value == rhs
    }

    static func ==(lhs: String, rhs: AMLNameString) -> Bool {
        return lhs == rhs.value
    }


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let scope = context.scope
        guard let globalObjects = system.deviceManager.acpiTables.globalObjects,
            let (node, fullPath) = globalObjects.getGlobalObject(currentScope: scope,
                                                                           name: self) else {
            fatalError("Cant find node: \(value)")
        }

        let namedObject = node
        if let fieldElement = namedObject as? AMLNamedField {
            let resolvedScope = AMLNameString(fullPath).removeLastSeg()
            var tmpContext = context.withNewScope(resolvedScope)
            return fieldElement.readValue(context: &tmpContext)
        } else {
            return namedObject.readValue(context: &context)
        }
    }


    func updateValue(to newValue: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        //print("AMLNameString Updating value of \(self) to", newValue)

        let scope = context.scope
        guard let globalObjects = system.deviceManager.acpiTables.globalObjects,
            let (node, fullPath) = globalObjects.getGlobalObject(currentScope: scope, name: self) else {
            fatalError("Cant find node: \(value)")
        }

        // Create a new scope with the context 1 level above the resolved path. This is because the object
        // being updated may have a different path to the current context so any getGlobalObject calls
        // need to be against the new path
        let resolvedScope = AMLNameString(fullPath).removeLastSeg()
        var tmpContext = context.withNewScope(resolvedScope)
        //print("AMLNameString:", node.fullname(), newValue, "context.scope:", context.scope, "tmpContext.scope:", tmpContext.scope)
        node.updateValue(to: newValue, context: &tmpContext)
    }
}


struct AMLNullName: AMLTarget {
    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        // Ignore Updates to nullname
    }
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

    init(argCount: Int, isSerialized: Bool, syncLevel: Int) {
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
struct AMLArgObj: AMLTermArg, AMLTermObj {
    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("\(self) is readOnly")
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


struct AMLLocalObj: AMLTermArg,  AMLTermObj {
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
        if (argIdx < 0 || argIdx >= context.localObjects.count) {
            fatalError("\(argIdx) out of bounds, count = \(context.localObjects.count)")
        }
        guard let v = context.localObjects[argIdx] else {
            fatalError("AMLLocalObj: Cant get localObject for argIndex \(argIdx), context: \(context)")
        }
        let r = v.evaluate(context: &context)
        return r
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        //print("AMLLocalObj updating \(self.argIdx) to: \(to) context = \(context)")
        context.localObjects[argIdx] = to
    }
}


struct AMLDebugObj: AMLTarget, AMLType6Opcode {

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        fatalError("ACPI: Read from Debug Object")
    }

    func updateValue(to newValue: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("DEBUG:", newValue)
    }
}


// FIXME, use accessField, extendedAccessField correctly
struct AMLFieldSettings {
    let bitOffset: UInt
    let bitWidth: UInt
    let fieldFlags: AMLFieldFlags
    let accessField: AMLAccessField
    let extendedAccessField: AMLExtendedAccessField?
}




struct AMLAccessType {
    let value: AMLByteData
}

enum AMLExtendedAccessAttrib: AMLByteData {
    case attribBytes = 0x0B
    case attribRawBytes = 0x0E
    case attribRawProcess = 0x0F
}


// Field Elements
struct AMLReservedField {
    let pkglen: AMLPkgLength
}


struct AMLAccessField {
    let type: AMLAccessType
    let attrib: AMLByteData
}


struct AMLExtendedAccessField {
    let type: AMLAccessType
    let attrib: AMLExtendedAccessAttrib
    let length: AMLInteger
}



struct AMLDefAlias: AMLTermObj {
    var name: AMLNameString { return aliasObject }
    let sourceObject: AMLNameString
    let aliasObject: AMLNameString

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefScope: AMLTermObj {
    // ScopeOp PkgLength NameString TermList
    let name: AMLNameString
    let value: AMLTermList

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLEvent {
    // EventOp NameString
    let name: AMLNameString
}


// AMLType6Opcode
struct AMLUserTermObj: AMLType6Opcode {
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        fatalError("Implement UserTerm")

    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("Implement UserTerm")
    }
}


func AMLByteConst(_ v: AMLByteData) -> AMLDataObject {
    return AMLIntegerData(AMLInteger(v))
}

func AMLWordConst(_ v: AMLWordData) -> AMLDataObject {
    return AMLIntegerData(AMLInteger(v))
}


func AMLDWordConst(_ v: AMLDWordData) -> AMLDataObject {
    return AMLIntegerData(AMLInteger(v))
}


func AMLQWordConst(_ v: AMLQWordData) -> AMLDataObject {
    return AMLIntegerData(AMLInteger(v))
}


func AMLZeroOp() -> AMLDataObject {
    return AMLIntegerData(0)
}


func AMLOneOp() -> AMLDataObject {
    // OneOp
    return AMLIntegerData(1)
}


func AMLOnesOp() -> AMLDataObject {
    // OnesOp
    // FIXME, this value being 64bit is assuming the DSDT version is >= 2
    return AMLIntegerData(UInt64.max)
}


func AMLRevisionOp() -> AMLDataObject {
    // RevisionOp - AML interpreter supports revision 2

    return AMLIntegerData(2)
}


// AMLDataObject

func AMLDDBHandle(value: AMLInteger) -> AMLDataRefObject {
    return .ddbHandle(value)
}


// opcode or character
protocol AMLSymbol: CustomStringConvertible {
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

    var description: String {
        "AMLCharSym(\(String(value, radix: 16)))"
    }

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


    var description: String {
        "Opcode: " + String(rawValue, radix: 16);
    }

    var isTwoByteOpcode: Bool {
        return self.rawValue == AMLOpcode.extendedOpPrefix.rawValue
    }
}
