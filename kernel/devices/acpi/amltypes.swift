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
    func canBeConverted(to: AMLDataRefObject) -> Bool
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg
}


extension AMLTermArg {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }
}


protocol AMLObject {
    var name: AMLNameString { get }
}

typealias AMLObjectList = [AMLObject] // FIXME: ObjectList should be more specific


protocol AMLBuffPkgStrObj: AMLTermArg {
}


protocol AMLDataRefObject: AMLBuffPkgStrObj {
    var isReadOnly: Bool { get }
    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext)
}

extension AMLDataRefObject {
    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        if isReadOnly {
            fatalError("updateValue denied")
        } else {
            fatalError("Missing updateValue function for \(self)")
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

extension AMLSuperName {
    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("\(self) can not be written to")
    }
}

protocol AMLNameSpaceModifierObj: AMLTermObj, AMLObject {
    //var name: AMLNameString { get }
    func execute(context: inout ACPI.AMLExecutionContext) throws
}

protocol AMLSimpleName: AMLSuperName {}
protocol AMLType6Opcode: AMLSuperName, AMLBuffPkgStrObj {}
protocol AMLDataObject: AMLDataRefObject {}
protocol AMLComputationalData: AMLDataObject {}
protocol AMLConstObj: AMLComputationalData {
    var value: AMLIntegerData { get }
}

extension AMLConstObj {
    var isReadOnly: Bool { return true }
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return value
    }
}

typealias AMLFieldList = [(AMLNameString, AMLFieldSettings)]
typealias AMLPredicate = AMLTermArg // => Integer
typealias AMLDDBHandleObject = AMLSuperName
typealias AMLMutexObject = AMLSuperName
typealias AMLEventObject = AMLSuperName
typealias AMLObjectReference = AMLInteger


class AMLIntegerData: AMLDataObject, AMLTermArg, AMLTermObj {
    private(set) var value: AMLInteger
    let isReadOnly = false

    init(_ value: AMLInteger) {
        self.value = value
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return self
    }

    func canBeConverted(to: AMLDataRefObject) -> Bool {
        if to is AMLIntegerData {
            return true
        }
        if let _to = to as? AMLNamedField {
            return _to.fieldSettings.bitWidth <= AMLInteger.bitWidth
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


struct AMLNameString: AMLSimpleName, AMLBuffPkgStrObj, AMLTermArg, Hashable {

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

    func canBeConverted(to: AMLDataRefObject) -> Bool {
        if to is AMLNamedField {
            return true
        }
        return false
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
            return fieldElement.evaluate(context: &tmpContext)
        } else if let namedObj = namedObject as? AMLDefName {
                return namedObj.value
        } else {
            return namedObject.readValue(context: &context)
        }
    }


    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("Updating value of \(self) to \(to)")
        // Update Value
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
struct AMLArgObj: AMLTermArg, AMLSimpleName, AMLBuffPkgStrObj, AMLTermObj {
    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("\(self) is readOnly")
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


struct AMLDebugObj: AMLSuperName, AMLDataRefObject, AMLTarget {
    var isReadOnly: Bool  { return false }

    func canBeConveArted(to: AMLDataRefObject) -> Bool {
        return false
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return self
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        print("DEBUG:", to)
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


final class AMLNamedField: AMLNamedObj, AMLDataObject, CustomStringConvertible {

    enum RegionReference {
        case regionSpace(OpRegionSpace)
        case opRegion(AMLDefOpRegion)
        case name(AMLNameString)
    }

    var region: RegionReference
    let fieldSettings: AMLFieldSettings
    var isReadOnly: Bool { false }


    var description: String {
        return "\(self.name): bitOffset: \(fieldSettings.bitOffset) bitWidth: \(fieldSettings.bitWidth)"
            + " fieldFlags: \(fieldSettings.fieldFlags)"
    }

    init(name: AMLNameString, regionName: AMLNameString, fieldSettings: AMLFieldSettings) {
        self.region = .name(regionName)
        self.fieldSettings = fieldSettings
        super.init(name: name)
    }

    init(name: AMLNameString, opRegion: AMLDefOpRegion, fieldSettings: AMLFieldSettings) {
        self.region = .opRegion(opRegion)
        self.fieldSettings = fieldSettings
        super.init(name: name)
    }


    private func getRegionSpace(context: inout ACPI.AMLExecutionContext) -> OpRegionSpace {
        let space: OpRegionSpace

        switch region {
            case let .regionSpace(opRegionSpace):
                space = opRegionSpace

            case let .opRegion(opRegion):
                space = opRegion.getRegionSpace(context: &context)
                region = .regionSpace(space)

            case let .name(regionName):
                guard let globalObjects = system.deviceManager.acpiTables.globalObjects else {
                    fatalError("cant get opRegionanme for \(self.fullname()) in scope for \(context.scope)")
                }
                guard let (opNode, _) = globalObjects.getGlobalObject(currentScope: context.scope, name: regionName),
                    let opRegion = opNode as? AMLDefOpRegion else {
                        fatalError("Cant find \(regionName) in \(context.scope)")
                }
                space = opRegion.getRegionSpace(context: &context)
                region = .regionSpace(space)
        }
        //print("region space:", region)
        return space
    }


    override func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        let value = operandAsInteger(operand: to, context: &context)

        //print("\(self.name): writing 0x\(String(value, radix: 16)) to bitOffset: \(fieldSettings.bitOffset)")
        getRegionSpace(context: &context).write(bitOffset: Int(fieldSettings.bitOffset),
                                               width: Int(fieldSettings.bitWidth),
                                               value: value,
                                               flags: fieldSettings.fieldFlags)
    }


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let value = getRegionSpace(context: &context).read(bitOffset: Int(fieldSettings.bitOffset),
                                                          width: Int(fieldSettings.bitWidth),
                                                          flags: fieldSettings.fieldFlags)
        //print("\(self.name): read 0x\(String(value, radix: 16)) from bitOffset: \(fieldSettings.bitOffset)")
        return AMLIntegerData(value)
    }


    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return evaluate(context: &context)
    }
}


final class AMLNamedIndexField: AMLNamedObj, AMLDataObject, OpRegionSpace, CustomStringConvertible {

    enum FieldReference {
        case namedField(AMLNamedField)
        case name(AMLNameString)
    }

    private var indexField: FieldReference
    private var dataField: FieldReference
    let fieldSettings: AMLFieldSettings
    var isReadOnly: Bool { false }
    var length: Int { Int(( fieldSettings.bitOffset + fieldSettings.bitWidth + 7) / 8) }

    var description: String {
        return "idx: \(indexField) data: \(dataField) \(self.name): bitOffset: \(fieldSettings.bitOffset)"
            + " fieldFlags: \(fieldSettings.fieldFlags)"
    }


    init(name: AMLNameString, indexField: AMLNameString, dataField: AMLNameString, fieldSettings: AMLFieldSettings) {
        self.indexField = .name(indexField)
        self.dataField = .name(dataField)
        self.fieldSettings = fieldSettings
        super.init(name: name)
    }


    private func getField(_ field: inout FieldReference) -> AMLNamedField {
        let namedField: AMLNamedField
        switch field {
            case let .namedField(obj):
                namedField = obj

            case let .name(fieldName):
                let scope = self.parent?.fullname() ?? "\\"
                guard
                    let globalObjects = system.deviceManager.acpiTables.globalObjects,
                    let (node, _) = globalObjects.getGlobalObject(currentScope: AMLNameString(scope), name: fieldName) else {
                    fatalError("cant get field \(fieldName) for IndexField \(self.fullname())")
                }
                guard let obj = node as? AMLNamedField else {
                    fatalError("\(node.fullname()) is not an AMLNamedField")
                }
                field = .namedField(obj)
                namedField = obj
        }
        return namedField
    }

    override func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        let value = operandAsInteger(operand: to, context: &context)
        self.write(bitOffset: Int(fieldSettings.bitOffset),
                   width: Int(fieldSettings.bitWidth),
                   value: value,
                   flags: fieldSettings.fieldFlags)
    }


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let value = self.read(bitOffset: Int(fieldSettings.bitOffset),
                          width: Int(fieldSettings.bitWidth),
                          flags: fieldSettings.fieldFlags)
        return AMLIntegerData(value)
    }


    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return evaluate(context: &context)
    }


    func read(atIndex index: Int, flags: AMLFieldFlags) -> AMLInteger {
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(self.fullname()))
        let _indexField = getField(&indexField)
        let _datafield = getField(&dataField)
        print(_indexField)
        print(_datafield)

        //print("NamedIndexField read(0x\(String(index, radix: 16))) \(self.fullname()) indexField \(_indexField) dataField: \(dataField)")
        // FIXME, ensure index is correct wrt register access width
        _indexField.updateValue(to: AMLIntegerData(AMLInteger(index)), context: &context)
        let data = _datafield.readValue(context: &context) as! AMLIntegerData
        return data.value
    }


    func write(atIndex index: Int, value: AMLInteger, flags: AMLFieldFlags) {
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(self.fullname()))
        let _indexField = getField(&indexField)
        let _datafield = getField(&dataField)
        print(_indexField)
        print(_datafield)

        // FIXME, ensure index is correct wrt register access width
        print("NamedIndexField write\(index),\(value) \(self.fullname()) indexField \(_indexField) dataField: \(dataField)")
        _indexField.updateValue(to: AMLIntegerData(AMLInteger(index)), context: &context)
        _datafield.updateValue(to: AMLIntegerData(value), context: &context)
    }
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


// AMLNameSpaceModifierObj
struct AMLDefAlias: AMLNameSpaceModifierObj {
    func execute(context: inout ACPI.AMLExecutionContext) throws {

    }

    var name: AMLNameString { return aliasObject }
    let sourceObject: AMLNameString
    let aliasObject: AMLNameString
}


final class AMLDefName: AMLNamedObj, AMLNameSpaceModifierObj {
    //let name: AMLNameString
    let value: AMLDataRefObject

    init(name: AMLNameString, value: AMLDataRefObject) {
        self.value = value
        super.init(name: name)
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        let fullPath = resolveNameTo(scope: context.scope, path: name)
        let globalObjects = system.deviceManager.acpiTables.globalObjects!
        globalObjects.add(fullPath.value, self)
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return value
    }

    override func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        value.updateValue(to: to, context: &context)
    }

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        evaluate(context: &context)
    }
}


final class AMLDefScope: AMLNamedObj, AMLNameSpaceModifierObj {
    // ScopeOp PkgLength NameString TermList

    //let name: AMLNameString
    let value: AMLTermList

    init(name: AMLNameString, value: AMLTermList) {
        self.value = value
        super.init(name: name)
    }

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


func AMLByteConst(_ v: AMLByteData) -> AMLIntegerData {
    return AMLIntegerData(AMLInteger(v))
}

func AMLWordConst(_ v: AMLWordData) -> AMLIntegerData {
    return AMLIntegerData(AMLInteger(v))
}


func AMLDWordConst(_ v: AMLDWordData) -> AMLIntegerData {
    return AMLIntegerData(AMLInteger(v))
}


func AMLQWordConst(_ v: AMLQWordData) -> AMLIntegerData {
    return AMLIntegerData(AMLInteger(v))
}


struct AMLString: AMLDataRefObject, AMLTermObj {
    var isReadOnly: Bool { return false }
    private(set) var value: String

    init(_ v: String) {
        value = v
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return self
    }
}


struct AMLZeroOp: AMLConstObj {
    // ZeroOp
    var value: AMLIntegerData { AMLIntegerData(0) }

    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return true
    }
}


struct AMLOneOp: AMLConstObj {
    // OneOp
    var value: AMLIntegerData { AMLIntegerData(1) }

    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return true
    }
}


struct AMLOnesOp: AMLConstObj {
    // OnesOp
    var value: AMLIntegerData { AMLIntegerData(0xff) }

    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return true
    }
}


struct AMLRevisionOp: AMLConstObj {
    // RevisionOp - AML interpreter supports revision 2

    var value: AMLIntegerData { AMLIntegerData(2) }
}


// AMLDataObject
struct AMLDDBHandle: AMLDataRefObject {
    let isReadOnly = true
    let value: AMLInteger

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        return self
    }
}


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
