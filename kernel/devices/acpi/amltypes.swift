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
typealias AMLTermList = [AMLParsedItem]
typealias AMLByteData = UInt8
typealias AMLByteList = [AMLByteData]
typealias AMLBuffer = AMLByteList
typealias AMLWordData = UInt16
typealias AMLDWordData = UInt32
typealias AMLQWordData = UInt64
typealias AMLTermArgList = [AMLTermArg]
typealias AMLPkgLength = UInt
typealias AMLByteBuffer = UnsafeRawBufferPointer


struct AMLString {
    var data: AMLBuffer = [] // Holds a NULL terminated ASCII string

    init() {
        data = [0]
    }

    init(_ string: String) throws(AMLError) {
        data.reserveCapacity(string.count + 1)
        for ch in string {
            guard let byte = ch.asciiValue else {
                throw AMLError.invalidData(reason: "'\(ch)' is not an ACSII character")
            }
            data.append(byte)
        }
        data.append(0)
    }

    // FIXME, make this a memcpy between buffers
    init(asciiString: String) {
        data.reserveCapacity(asciiString.count + 1)
        for ch in asciiString {
            data.append(ch.asciiValue!)
        }
        data.append(0)
    }

    init(_ nameString: AMLNameString) {
        // AMLNameStrings are always ASCII
        data.reserveCapacity(nameString.value.count)
        for ch in nameString.value {
            data.append(ch.asciiValue!)
        }
        data.append(0)
    }

    init(buffer: AMLBuffer, maxLength: AMLInteger = AMLInteger.max) {
        data.reserveCapacity(buffer.count)
        let maxIdx = min(buffer.count, Int(maxLength))
        for idx in 0..<maxIdx {
            let byte = buffer[idx]
            if byte == 0 {
                break
            }
            data.append(byte)
        }
        data.append(0)    // Final NULL terminator
    }

    init(integer: AMLInteger, radix: AMLInteger = 10) {
        let zeros = (radix == 10) ? 20 : 16
        var result = Array<UInt8>(repeating: UInt8(ascii: "0"), count: zeros) // enought for base 16 or base 10
        result.append(0)
        let digits: StaticString = "0123456789ABCDEF"
        let digitsPtr = UnsafeRawPointer(digits.utf8Start)

        var value = integer
        var digit: AMLInteger
        // Start 1 element before the end, allowing for terminating NULL
        var charIndex = result.index(before: result.endIndex)

        repeat {
            charIndex = result.index(before: charIndex)
            digit = value % radix
            value /= radix
            let char = digitsPtr.load(fromByteOffset: Int(digit), as: UInt8.self)
            result[charIndex] = char
        } while value > 0

/*
        if (radix == 16) {
            charIndex = result.index(before: charIndex)
            result[charIndex] = UInt8(ascii: "x")
            charIndex = result.index(before: charIndex)
            result[charIndex] = UInt8(ascii: "0")
        }

        result.removeSubrange(0..<charIndex)
*/
        self.data = result
    }

    func asString() -> String {
        let count = data.count - 1
        return String(unsafeUninitializedCapacity: count, initializingUTF8With: { buffer in
            for index in 0..<count {
                buffer[index] = data[index]
            }
            return count
        })
    }

    func asAMLInteger() throws(AMLError) -> AMLInteger {
        let string = self.asString()
        if string.hasPrefix("0x"), let result = AMLInteger(string.dropFirst(2)) {
            return result
        } else if let result = AMLInteger(string) {
            return result
        }
        else {
            throw AMLError.invalidDataConversion
        }
    }

    func asAMLBuffer() -> AMLBuffer {
        AMLBuffer(data.dropLast())  // Remove NULL terminator
    }

    // FIXME: change to append(contentsOf:)
    mutating func append(other: AMLString) {
        data.removeLast() // Remove NULL terminator
        data.append(contentsOf: other.data)
    }
}


struct AMLBufferField {
    let buffer: AMLSharedBuffer
    let bitIndex: AMLInteger
    let bitLength: AMLInteger

    init(buffer: AMLSharedBuffer, bitIndex: AMLInteger, bitLength: AMLInteger) throws(AMLError) {
        guard bitIndex + bitLength <= buffer.bitCount else {
            throw AMLError.invalidData(reason: "BufferField bitIndex: \(bitIndex) + bitLength \(bitLength) > buffer size \(buffer.bitCount) bits")
        }
        self.buffer = buffer
        self.bitIndex = bitIndex
        self.bitLength = bitLength
    }

    init(buffer: AMLSharedBuffer, byteIndex: AMLInteger, bitLength: AMLInteger) throws(AMLError) {
        try self.init(buffer: buffer, bitIndex: byteIndex * 8, bitLength: bitLength)
    }

    func readValue(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        throw AMLError.unimplemented("AMLBufferField.readValue()")
/*
        // TODO: Handle the output being a string buffer or integer
        let byte = buffer.readBits(atBitIndex: Int(bitIndex), numBits: bitLength)
        return .integer(AMLInteger(byte))
 */
    }

    func updateValue(to newValue: AMLObject, context: inout ACPI.AMLExecutionContext) throws(AMLError) {
        throw AMLError.unimplemented("AMLBufferField.updateValue()")
        // TODO: Handle the input being a string, buffer or integer
/*
        switch
        let byte = AMLByteData(newValue.integerValue!)
        buffer.writeBits(atBitIndex: Int(bitIndex), value: byte)
*/
    }
}

enum AMLError: Error, CustomStringConvertible {
    //case invalidOpcode(reason: String)
    case invalidSymbol(reason: String)
    case invalidMethod(reason: String)
    case invalidData(reason: String)
    case invalidOperand(reason: String)
    case invalidIndex(index: AMLInteger, bound: AMLInteger)
    case invalidDataConversion
    case endOfStream(reason: String)
    case parseError
    case unimplementedError(reason: String)

    var description: String {
        switch self {
            case .invalidSymbol(let reason):            return "Invalid Symbol: \(reason)"
            case .invalidMethod(let reason):            return "Invalid Method: \(reason)"
            case .invalidData(let reason):              return "Invalid data: \(reason)"
            case .invalidOperand(let reason):           return "Invalid Operand: \(reason)"
            case .invalidIndex(let index, let bound):   return "Index (\(index)) out of range (\(bound))"
            case .invalidDataConversion:                return "Invalid data conversion"
            case .endOfStream(let reason):              return "Unexpected end of stream: \(reason)"
            case .parseError:                           return "Unknown parsing error"
            case .unimplementedError(let reason):       return "Unimplemented Error: \(reason)"
        }
    }

    static func invalidOpcode(value: UInt8) -> AMLError {
        let reason = "Bad opcode: " + asHex(value)
        return invalidData(reason: reason)
    }

    static func invalidOpcode(value: UInt16) -> AMLError {
        let reason = "Bad opcode: " + asHex(value)
        return invalidData(reason: reason)
    }


    static func unimplemented(_ function: String = #function, line: Int = #line) -> AMLError {
        print("line:", line, function, "is unimplemented")
        return unimplementedError(reason: function)
    }
}


/*
struct AMLObjectReference {
    private enum _Object {
        case string(AMLString) // FIXME: Probably need to make AMLString a shared class
        case buffer(AMLSharedBuffer)
        case package(AMLPackage)
        case nameString(AMLNameString)
    }

    private let object: _Object
    private let index: AMLInteger

    init(of string: AMLString, index: AMLInteger) {
        self.object = .string(string)
        self.index = index
    }

    init(of buffer: AMLSharedBuffer, index: AMLInteger) {
        self.object = .buffer(buffer)
        self.index = index
    }

    init(of package: AMLPackage, index: AMLInteger) {
        self.object = .package(package)
        self.index = index
    }

    init(_ nameString: AMLNameString) {
        self.object = .nameString(nameString)
        self.index = 0
    }

    var nameString: AMLNameString? {
        if case .nameString(let string) = object { return string } else { return nil }
    }

    // FIXME: Deal with out of bounds and the fact that a String is not byte addressable
    func readValue(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        switch object {
            case .string(let string):
                let strIndex = string.index(string.startIndex, offsetBy: Int(index))
                guard let byte = string[strIndex].asciiValue else {
                    throw AMLError.invalidData(reason: "Object reference for string does not return an ASCII value")
                }
                return AMLObject(AMLInteger(byte))
            case .buffer(let buffer):
                let byte = buffer.readByte(atByteIndex: Int(index))
                return AMLObject(AMLInteger(byte))
            case .package(let package):
                return package[Int(index)]
            case .nameString(let name):
                guard let (node, _) = context.getObject(named: name) else {
                    throw AMLError.invalidData(reason: "\(name) is not a valid Object Reference")
                }
                return node.object
        }
    }

    func updateValue(to newValue: AMLObject, context: inout ACPI.AMLExecutionContext) throws(AMLError) {
        fatalError("implement")
    }

    func sizeof() -> AMLInteger? {
        switch object {
            case .string, .buffer:
                return 1
            case .package(let package):
                let object = package[Int(index)]
                return object.sizeof()
            case .nameString(let aMLNameString):
                return nil
        }
    }
}
*/


final class AMLTermArg: CustomStringConvertible {
    private enum _Data {
        case value(AMLObject)
        case opcode(AMLType2Opcode)
        case nameString(AMLNameString)
        case argObj(AMLArgObj)
        case localObj(AMLLocalObj)
    }

    private let data: _Data


    init(_ obj: AMLObject) {
        self.data = .value(obj)
    }

    init(_ value: AMLInteger) {
        self.data = .value(AMLObject(value))
    }

    init(_ value: Bool) {
        let i = value ? AMLInteger.max : AMLInteger.zero
        self.data = .value(AMLObject(i))
    }

    init(_ value: AMLString) {
        self.data = .value(AMLObject(value))
    }

    init(_ value: AMLBuffer) {
        self.data = .value(AMLObject(value))
    }

    init(_ opcode: AMLType2Opcode) {
        self.data = .opcode(opcode)
    }

    init(_ value: AMLNameString) {
        self.data = .nameString(value)
    }

    init(_ value: AMLArgObj) {
        self.data = .argObj(value)
    }

    init(_ value: AMLLocalObj) {
        self.data = .localObj(value)
    }

    init(_ value: AMLPackage) {
        self.data = .value(AMLObject(value))
    }

    var description: String {
        switch self.data {
            case let .value(value): return value.description
            case let .localObj(object): return "Local\(object.argIdx)"
            case let .argObj(object): return "Arg\(object.argIdx)"
            case .opcode(_): return "opcode"
            case let .nameString(string): return "\"\(string.value)\""
        }
    }

    var amlObject: AMLObject? {
        if case .value(let object) = self.data { return object} else { return nil }
    }

    func dataRefObject(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        let value = try self.evaluate(context: &context)
        guard value.isDataRefObject else {
            throw AMLError.invalidData(reason: "Termarg does not evaluate to a dataRefObject")
        }
        return value
    }

    var integerValue: AMLInteger? {
        return self.amlObject?.integerValue
    }

    var bufferValue: AMLBuffer? {
        return self.amlObject?.bufferValue
    }

    var stringValue: AMLString? {
        return self.amlObject?.stringValue
    }

    var nameString: AMLNameString? {
        if case .nameString(let value) = self.data { return value }
        return nil
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        switch self.data {
            case let .value(value): return value
            case let .opcode(opcode): return try opcode.evaluate(context: &context)
            case let .nameString(value):
                return try value.evaluate(context: &context)
            case let .argObj(object):
                return try object.evaluate(context: &context)

            case let .localObj(object):
                return try object.evaluate(context: &context)
        }
    }
}


enum AMLTarget {

    typealias Evaluator = (inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject
    typealias Updater = (AMLObject, inout ACPI.AMLExecutionContext) throws(AMLError) -> Void

    case nameString(AMLNameString)              // Simplename, Supername
    case argObj(AMLArgObj)                      // Simplename, Supername
    case localObj(AMLLocalObj)                  // Simplename, Supernam,e
    case debugObj(AMLDebugObj)                  // Supername
//    case objectReference(AMLObjectReference)    // Supername
    case type6opcode(Evaluator, Updater)        // ReferenceTypeOpcode:  DefRefOf | DefDerefOf | DefIndex | UserTermObj
    case nullName

    var isSimpleName: Bool {
        switch self {
            case .nameString, .argObj, .localObj: return true
            default: return false
        }
    }

    func getObject(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        switch self {
 //           case .objectReference(let objectReference): return AMLObject(objectReference)
            case .type6opcode(let evaluator, _): return try evaluator(&context)
            case .nameString(let name): return try name.getObject(context: &context)
            case .argObj(let object): return try object.evaluate(context: &context)
            case .localObj(let object): return try object.evaluate(context: &context)
            case .debugObj(let object): return object.evaluate(context: &context)
            case .nullName: return AMLObject(0)
        }
    }

    func updateValue(to newValue: AMLObject, context: inout ACPI.AMLExecutionContext) throws(AMLError) {
        switch self {
//            case .objectReference(let objectReference): fatalError("updateValue with \(objectReference)")
            case .type6opcode(_, let updater): try updater(newValue, &context)
            case .nameString(let name): try name.updateValue(to: newValue, context: &context)
            case .argObj(let object): object.updateValue(to: newValue, context: &context)
            case .localObj(let object): object.updateValue(to: newValue, context: &context)
            case .debugObj(let object): object.updateValue(to: newValue, context: &context)
            case .nullName: return
        }
    }
}

extension AMLBuffer {
    init(integer: AMLInteger) {
        let byteCount = MemoryLayout<AMLInteger>.size
        self = Array<UInt8>(unsafeUninitializedCapacity: byteCount) {
            (data: inout UnsafeMutableBufferPointer<UInt8>, initializedCount: inout Int) in
            initializedCount = 0
            var integer = integer
            repeat {
                data[initializedCount] = UInt8(truncatingIfNeeded: integer)
                initializedCount += 1
                integer >>= 8
            } while integer > 0
        }
    }

    func asAMLInteger() throws(AMLError) -> AMLInteger {
        if count == 0 {
            throw AMLError.invalidDataConversion
        }
        let maxIdx = Swift.min(7, count - 1)
        var result: AMLInteger = 0
        for idx in 0...maxIdx {
            let byte = AMLInteger(self[idx]) << (idx * 8)
            result |= byte
        }
        return result
    }

    func asAMLString(maxLength: AMLInteger = AMLInteger.max) -> AMLString {
        return AMLString(buffer: self, maxLength: maxLength)
    }
}


struct AMLByteIterator: IteratorProtocol {
    enum _Value {
        case integer(AMLInteger)
        case buffer(AMLBuffer)
    }

    typealias Element = AMLInteger
    private var _value: _Value
    private let accessWidth: Int    // 1,2,4
    private var bitWidth: Int
    private let lastIndex: Int
    private var nextIndex = 0

    init(_ object: AMLObject, bitWidth: Int, accessWidth: Int) throws(AMLError) {
        if let integer = object.integerValue {
            self._value = .integer(integer)
            self.lastIndex = min(integer.bitWidth, (bitWidth + 7) / 8)
        } else {
            let buffer = try object.asBuffer()
            self._value = .buffer(buffer)
            self.lastIndex = min(buffer.endIndex, (bitWidth + 7) / 8)
        }
        self.bitWidth = bitWidth
        self.accessWidth = accessWidth
    }

    mutating func next() -> Element? {
        if nextIndex >= lastIndex {
            return nil
        }

        var result: Element = 0
        var shift = 0
        for _ in 0..<accessWidth {
            if nextIndex < lastIndex {
                let mask = bitWidth < 8 ? Element((1 << (bitWidth & 7)) - 1) : 0xff

                let byte: UInt8
                switch _value {
                    case .integer(var integer):
                        byte = UInt8(truncatingIfNeeded: integer)
                        integer >>= 8
                        _value = .integer(integer)

                    case .buffer(let buffer):
                        byte = buffer[nextIndex]
                }

                result |= (Element(byte) & mask) << shift
                nextIndex += 1
                bitWidth &-= 8
                shift &+= 8
            }
        }
        return result
    }
}

// This is used by buffer fields which need to share the same underlying buffer
// FIXME: Could an AMLObject(AMLBuffer) be used instead?
final class AMLSharedBuffer: RandomAccessCollection {
    typealias Index = Int
    typealias Element = UInt8

    private var buffer: AMLBuffer

    var count: Int { buffer.count }
    var bitCount: Int { buffer.count * 8 }
    var startIndex: Index { buffer.startIndex }
    var endIndex: Index { buffer.endIndex }

    init(_ bytes: AMLBuffer) {
        buffer = bytes
    }

    func update(to newValue: AMLBuffer) {
        // Update the current buffer with the new value. Truncate the new buffer if it is too long, zero out extra bytes in the
        // current one if it is shorter
        if newValue.count > buffer.count {
            buffer = AMLBuffer(newValue[0..<buffer.count])
        } else {
            buffer = newValue + AMLBuffer(repeating: 0, count: buffer.count - newValue.count)
        }
    }

    func append(_ other: AMLSharedBuffer) {
        buffer.append(contentsOf: other.buffer)
    }

    func update(to newValue: AMLSharedBuffer) {
        update(to: newValue.buffer)
    }

    func asAMLBuffer() -> AMLBuffer {
        return buffer
    }

//    func copy() -> Self {
//        return Self(buffer)
//    }

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
            return AMLSharedBuffer(result)
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



typealias AMLFieldList = [(AMLNameString, AMLFieldSettings)]
typealias AMLPackageElement = AMLObject

final class AMLPackage: Sequence {
    typealias Index = Int
    typealias Element = AMLPackageElement
    typealias Iterator = IndexingIterator<Array<Element>>

    private(set) var elements: [AMLPackageElement]
    var count: Int { self.elements.count }

    init(numElements: Int, elements: [AMLPackageElement]) {
        guard numElements >= elements.count else {
            fatalError("AMLPackage: numElements: \(numElements), elements.count: \(elements.count)")
        }
        self.elements = elements

        // numElements may be greater then elements.count in which case fill the
        // other elements with AMLPackageElement.uninitialised
        let uninitialisedCount = numElements - elements.count
        if uninitialisedCount > 0 {
            self.elements.reserveCapacity(numElements)
            for _ in 0..<uninitialisedCount {
                self.elements.append(AMLObject())
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
        set { self.elements[position] = newValue }
    }
}


struct AMLNameString: Hashable, CustomStringConvertible {
    static let rootChar = Character(UnicodeScalar("\\"))
    static let parentPrefixChar = Character(UnicodeScalar("^"))
    static let pathSeparatorChar = Character(UnicodeScalar("."))

    let value: String
    var isNameSeg: Bool { return (value.count <= 4) }
    // Name starts with '\\'
    var isFullPath: Bool { return value.first == AMLNameString.rootChar }

    var description: String { return value }

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
        AMLString(self)
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
    #if false
    func parent() -> AMLNameString {
        let seperator = AMLNameString.pathSeparatorChar
        var parentSegs = value.components(separatedBy: seperator)
        parentSegs.removeLast()
        let result = parentSegs.joined(separator: String(seperator))
        return AMLNameString(result)
    }
    #endif


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


    func getObject(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        guard let (node, _) = context.getObject(named: self) else {
            throw AMLError.invalidSymbol(reason: value)
        }

        return node.object
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        guard let (node, fullPath) = context.getObject(named: self) else {
            fatalError("Cant find node: \(value)")
        }

        let namedObject = node
        if let fieldElement = node.object.fieldUnitValue {
            let resolvedScope = AMLNameString(fullPath).removeLastSeg()
            var tmpContext = context.withNewScope(resolvedScope)
            return try fieldElement.readValue(context: &tmpContext)
        } else {
            return try namedObject.readValue(context: &context)
        }
    }


    func updateValue(to newValue: AMLObject, context: inout ACPI.AMLExecutionContext) throws(AMLError) {
        //print("AMLNameString Updating value of \(self) to", newValue)

        guard let (node, fullPath) = context.getObject(named: self) else {
            fatalError("Cant find node: \(value)")
        }

        // Create a new scope with the context 1 level above the resolved path. This is because the object
        // being updated may have a different path to the current context so any getGlobalObject calls
        // need to be against the new path
        let resolvedScope = AMLNameString(fullPath).removeLastSeg()
        var tmpContext = context.withNewScope(resolvedScope)
        //print("AMLNameString:", node.fullname(), newValue, "context.scope:", context.scope, "tmpContext.scope:", tmpContext.scope)
        try node.updateValue(to: newValue, context: &tmpContext)
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

    init(flags: AMLByteData) throws(AMLError) {
        try self.init(syncLevel: flags)
    }

    init(syncLevel: UInt8) throws(AMLError) {
        guard syncLevel & 0x0f == syncLevel else {
            throw AMLError.invalidData(reason: "Invalid synclevel \(syncLevel)")
        }
        self.flags = syncLevel
    }
}


// AMLTermArg
struct AMLArgObj {
    let opcode: AMLOpcode      // FIXME needs better type
    var argIdx: Int { return Int(opcode.rawValue - AMLOpcode.arg0Op.rawValue) }


    init(argOp: AMLOpcode) throws(AMLError) {
        switch argOp {
        case .arg0Op, .arg1Op, .arg2Op, .arg3Op, .arg4Op, .arg5Op, .arg6Op:
            opcode = argOp

        default: throw AMLError.invalidData(reason: "Invalid arg")
        }
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        guard argIdx < context.args.count else {
            throw AMLError.invalidData(reason: "Arg\(argIdx) is not valid")
        }
        let arg = context.args[argIdx]
        if arg.isUninitialised {
            throw AMLError.invalidData(reason: "Arg\(argIdx) is not yet initialised")
        }
        return arg.isObjectReference ? try arg.dereference() : arg
    }

    func updateValue(to newValue: AMLObject, context: inout ACPI.AMLExecutionContext) {
        context.args[argIdx] = newValue
    }
}


struct AMLLocalObj {
    let opcode: AMLOpcode      // FIXME needs better type
    var argIdx: Int { return Int(opcode.rawValue - AMLOpcode.local0Op.rawValue) }

    init(localOp: AMLOpcode) throws(AMLError) {
         switch localOp {
        case .local0Op, .local1Op, .local2Op, .local3Op,
            .local4Op, .local5Op, .local6Op, .local7Op:
            opcode = localOp

         default: throw AMLError.invalidData(reason: "Invalid arg")
        }
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        let termArg = context.localObjects[argIdx]
        if termArg.isUninitialised {
            throw AMLError.invalidData(reason: "Local\(argIdx) is not yet initialised")
        }
        return termArg
    }

    func updateValue(to newValue: AMLObject, context: inout ACPI.AMLExecutionContext) {
        //print("AMLLocalObj updating \(self.argIdx) to: \(to) context = \(context)")
        context.localObjects[argIdx] = newValue
    }
}


struct AMLDebugObj {

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLObject {
        fatalError("ACPI: Read from Debug Object")
    }

    func updateValue(to newValue: AMLObject, context: inout ACPI.AMLExecutionContext) {
        print("ACPI: DEBUG:", newValue.stringValue?.asString() ?? "<unknown>")
    }
}


// Field Elements
struct AMLReservedField {
    let pkglen: AMLPkgLength
}


struct AMLEvent {
    // EventOp NameString
    let name: AMLNameString
}

struct AMLThermalZone {
    let name: AMLNameString
    let termList: AMLTermList
}


func AMLByteConst(_ v: AMLByteData) -> AMLObject {
    return AMLObject(AMLInteger(v))
}

func AMLWordConst(_ v: AMLWordData) -> AMLObject {
    return AMLObject(AMLInteger(v))
}


func AMLDWordConst(_ v: AMLDWordData) -> AMLObject {
    return AMLObject(AMLInteger(v))
}


func AMLQWordConst(_ v: AMLQWordData) -> AMLObject {
    return AMLObject(AMLInteger(v))
}


func AMLZeroOp() -> AMLObject {
    return AMLObject(AMLInteger.zero)
}


func AMLOneOp() -> AMLObject {
    // OneOp
    return AMLObject(1)
}


func AMLOnesOp() -> AMLObject {
    // OnesOp
    // FIXME, this value being 64bit is assuming the DSDT version is >= 2
    return AMLObject(AMLInteger.max)
}


func AMLRevisionOp() -> AMLObject {
    // RevisionOp - AML interpreter supports revision 2

    return AMLObject(2)
}


// ASCII 'A'-'Z' 0x41 - 0x5A

enum AMLChar {
    case nullChar, leadNameChar, digitChar, rootChar, parentPrefixChar, dualNamePrefix, multiNamePrefix
}

struct AMLCharSymbol: CustomStringConvertible, Equatable {
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


enum AMLOpcode: UInt16, CustomStringConvertible {
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
