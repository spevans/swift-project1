//
//  kernel/devices/acpi/amlnamespacemodifier.swift
//  AML name space modifier types
//
//  Created by Simon Evans on 07/08/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//


/// AMLNameSpaceModifierObj is a protocol for opcodes that add to the global
/// namespace either as globals at parse time or locally during method
/// execution.
/// This differs from the NameSpaceModifierObj listed in the ACPI documentation
/// which uses it to cover DefScope and DefAlias. These to are excluded as they
/// add to the namespace immediately as they are parsed and are not opcode, in
/// fact they dont really need to exist as types (AMLDefScope, AMLDefAlias) and
/// will probably be removed at some point.


protocol AMLNameSpaceModifierObj: AMLTermObj {
    //var name: AMLNameString { get }
    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)]
}


struct AMLDefName: AMLNameSpaceModifierObj {
    // NameOp NameString DataRefObject
    let name: AMLNameString
    let value: AMLDataRefObject

    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)] {
        let fullname = resolveNameTo(scope: context.scope, path: name)
        let object = AMLNamedValue(name: name, value: value)
        return [(fullname: fullname, object)]
    }
}


final class AMLNamedValue: AMLNamedObj {
    //let name: AMLNameString
    var value: AMLDataRefObject

    init(name: AMLNameString, value: AMLDataRefObject) {
        self.value = value
        super.init(name: name)
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        let fullPath = resolveNameTo(scope: context.scope, path: name)
        let globalObjects = system.deviceManager.acpiTables.globalObjects!
        globalObjects.add(fullPath.value, self)
    }

    override func updateValue(to newValue: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        //print("Updating value of", self.fullname(), "to:", newValue)
        if let newValue = newValue as? AMLDataObject {
            value = .dataObject(newValue)
        } else {
            fatalError("AMLDefName.updateValue, cant update to \(newValue)")
        }
    }

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        switch value {
            case .dataObject(let object): return object
            default: fatalError("AMLDefName.readValue, cant return \(value)")
        }
    }
}


struct AMLDefIndexField: AMLNameSpaceModifierObj {
    // IndexFieldOp PkgLength NameString NameString FieldFlags FieldList
    let indexName: AMLNameString
    let dataName: AMLNameString
    let flags: AMLFieldFlags
    let fields: AMLFieldList

    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)] {
        var result: [(fullname: AMLNameString, AMLNamedObj)] = []
        for (name, settings) in fields {
            let field = AMLNamedIndexField(name: name, indexField: indexName, dataField: dataName, fieldSettings: settings)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            result.append((fullname: fullname, field))
        }
        return result
    }
}


struct AMLDefField: AMLNameSpaceModifierObj {
    // FieldOp PkgLength NameString FieldFlags FieldList
    let regionName: AMLNameString
    let flags: AMLFieldFlags
    let fields: AMLFieldList

    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)] {
        var result: [(fullname: AMLNameString, AMLNamedObj)] = []
        for (name, settings) in fields {
            let field = AMLNamedField(name: name, regionName: regionName, fieldSettings: settings)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            result.append((fullname: fullname, field))
        }
        return result
    }
}


final class AMLNamedIndexField: AMLNamedObj, OpRegionSpace, CustomStringConvertible {

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


    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let value = self.read(bitOffset: Int(fieldSettings.bitOffset),
                          width: Int(fieldSettings.bitWidth),
                          flags: fieldSettings.fieldFlags)
        return AMLIntegerData(value)
    }


    func read(atIndex index: Int, flags: AMLFieldFlags) -> AMLInteger {
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(self.fullname()))
        let _indexField = getField(&indexField)
        let _datafield = getField(&dataField)

        //print("NamedIndexField read(0x\(String(index, radix: 16))) \(self.fullname()) indexField \(_indexField) dataField: \(dataField)")
        // FIXME, ensure index is correct wrt register access width
        _indexField.updateValue(to: AMLIntegerData(AMLInteger(index)), context: &context)
        let data = _datafield.readValue(context: &context).integerValue!
        return data
    }


    func write(atIndex index: Int, value: AMLInteger, flags: AMLFieldFlags) {
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(self.fullname()))
        let _indexField = getField(&indexField)
        let _datafield = getField(&dataField)

        // FIXME, ensure index is correct wrt register access width
        _indexField.updateValue(to: AMLIntegerData(AMLInteger(index)), context: &context)
        _datafield.updateValue(to: AMLIntegerData(value), context: &context)
    }
}


final class AMLNamedField: AMLNamedObj, CustomStringConvertible {

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


    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let value = getRegionSpace(context: &context).read(bitOffset: Int(fieldSettings.bitOffset),
                                                          width: Int(fieldSettings.bitWidth),
                                                          flags: fieldSettings.fieldFlags)
        //print("\(self.name): read 0x\(String(value, radix: 16)) from bitOffset: \(fieldSettings.bitOffset)")
        return AMLIntegerData(value)
    }
}


struct AMLDefBankField: AMLNameSpaceModifierObj {
    // BankFieldOp PkgLength NameString NameString BankValue FieldFlags FieldList
    //let name: AMLNameString
    let bankValue: AMLTermArg // => Integer
    let flags: AMLFieldFlags
    let fields: AMLFieldList

    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)] {
        fatalError("AMLDefBankField.createObjects not implemented")
    }
}


// Create a field of a specified bitwidth
struct AMLDefCreateBitsField: AMLNameSpaceModifierObj {
    // CreateFieldOp SourceBuff BitIndex NumBits NameString
    let sourceBuff: AMLTermArg  // => Buffer
    let bitIndex: AMLTermArg  // => Integer
    let numBits: AMLTermArg  // => Integer
    let name: AMLNameString

    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)] {
        let buffer = sourceBuff.evaluate(context: &context).bufferValue!
        let index = bitIndex.evaluate(context: &context).integerValue!
        let bitWidth = numBits.evaluate(context: &context).integerValue!
        let fullname = resolveNameTo(scope: context.scope, path: name)
        let object = AMLNamedBitsField(name: name, buffer: buffer, bitIndex: index, bitWidth: bitWidth)
        return [(fullname: fullname, object)]
    }
}


final class AMLNamedBitsField: AMLNamedObj {
    // CreateFieldOp SourceBuff BitIndex NumBits NameString
    let buffer: AMLSharedBuffer
    let bitIndex: Int
    let bitWidth: Int

    init(name: AMLNameString, buffer: AMLSharedBuffer, bitIndex: AMLInteger, bitWidth: AMLInteger) {
        precondition(bitWidth > 0)
        precondition(bitIndex + bitWidth <= buffer.count * 8)
        self.buffer = buffer
        self.bitIndex = Int(bitIndex)
        self.bitWidth = Int(bitWidth)
        super.init(name: name)
    }

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let bits = buffer.readBits(atBitIndex: bitIndex, numBits: bitWidth)
        return AMLDataObject.buffer(bits)
    }

    override func updateValue(to newValue: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        guard let dataObject = newValue.evaluate(context: &context) as? AMLDataObject else{
            fatalError("AMLNamedBitsField: \(newValue) didnt evaluate to a AMLDataObject, \(context)")
        }
        switch dataObject {
            case .buffer(let value): buffer.writeBits(atBitIndex: bitIndex, numBits: bitWidth, value: value)
            case .integer(let value): buffer.writeBits(atBitIndex: bitIndex, numBits: bitWidth, value: ByteArray8(value))
            //case .string(let value): buffer.writeBits(atBitIndex: bitIndex, numBits: bitWidth, value: value.utf8)
            default: fatalError("AMLNamedBitsField: Cant updated from a value of type \(dataObject)")
        }
    }
}


struct AMLDefCreateBitField: AMLNameSpaceModifierObj {
    // CreateBitFieldOp SourceBuff BitIndex NameString
    let sourceBuff: AMLTermArg  // => Buffer
    let bitIndex: AMLTermArg  // => Integer
    let name: AMLNameString

    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)] {
        let buffer = sourceBuff.evaluate(context: &context).bufferValue!
        let index = bitIndex.evaluate(context: &context).integerValue!
        let fullname = resolveNameTo(scope: context.scope, path: name)
        let object = AMLNamedBitField(name: name, buffer: buffer, bitIndex: index)
        return [(fullname: fullname, object)]
    }
}


final class AMLNamedBitField: AMLNamedObj {
    // CreateBitFieldOp SourceBuff BitIndex NameString
    var buffer: AMLSharedBuffer
    let bitIndex: Int

    init(name: AMLNameString, buffer: AMLSharedBuffer, bitIndex: AMLInteger) {
        self.buffer = buffer
        self.bitIndex = Int(bitIndex)
        super.init(name: name)
    }

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let bit = buffer.readBit(atBitIndex: bitIndex)
        return AMLIntegerData(bit)
    }

    override func updateValue(to newValue: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        let bit = newValue.evaluate(context: &context).integerValue!
        buffer.writeBit(atBitIndex: bitIndex, value: bit)
    }
}


struct AMLDefCreateByteField: AMLNameSpaceModifierObj {
    // CreateByteFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg  // => Buffer
    let byteIndex: AMLTermArg  // => Integer
    let name: AMLNameString

    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)] {
        let buffer = sourceBuff.evaluate(context: &context).bufferValue!
        let index = byteIndex.evaluate(context: &context).integerValue!
        let fullname = resolveNameTo(scope: context.scope, path: name)
        let object = AMLNamedByteField(name: name, buffer: buffer, byteIndex: index)
        return [(fullname: fullname, object)]
    }
}


final class AMLNamedByteField: AMLNamedObj {
    var buffer: AMLSharedBuffer
    let byteIndex: Int

    init(name: AMLNameString, buffer: AMLSharedBuffer, byteIndex: AMLInteger) {
        self.buffer = buffer
        self.byteIndex = Int(byteIndex)
        super.init(name: name)
    }

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let byte = buffer.readByte(atByteIndex: byteIndex)
        return AMLIntegerData(AMLInteger(byte))
    }

    override func updateValue(to newValue: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        let byte = AMLByteData(newValue.evaluate(context: &context).integerValue!)
        buffer.writeByte(atByteIndex: byteIndex, value: byte)
    }
}


struct AMLDefCreateWordField: AMLNameSpaceModifierObj {
    // CreateWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg  // => Buffer
    let byteIndex: AMLTermArg  // => Integer
    let name: AMLNameString

    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)] {
        let buffer = sourceBuff.evaluate(context: &context).bufferValue!
        let index = byteIndex.evaluate(context: &context).integerValue!
        let fullname = resolveNameTo(scope: context.scope, path: name)
        let object = AMLNamedWordField(name: name, buffer: buffer, byteIndex: index)
        return [(fullname: fullname, object)]
    }
}


final class AMLNamedWordField: AMLNamedObj {
    var buffer: AMLSharedBuffer
    let byteIndex: Int

    init(name: AMLNameString, buffer: AMLSharedBuffer, byteIndex: AMLInteger) {
        self.buffer = buffer
        self.byteIndex = Int(byteIndex)
        super.init(name: name)
    }


    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let word = buffer.readWord(atByteIndex: byteIndex)
        return AMLIntegerData(AMLInteger(word))
    }

    override func updateValue(to newValue: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        let word = AMLWordData(newValue.evaluate(context: &context).integerValue!)
        buffer.writeWord(atByteIndex: byteIndex, value: word)
    }
}


struct AMLDefCreateDWordField: AMLNameSpaceModifierObj {
    // CreateDWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg  // => Buffer
    let byteIndex: AMLTermArg  // => Integer
    let name: AMLNameString

    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)] {
        let buffer = sourceBuff.evaluate(context: &context).bufferValue!
        let index = byteIndex.evaluate(context: &context).integerValue!
        let fullname = resolveNameTo(scope: context.scope, path: name)
        let object = AMLNamedDWordField(name: name, buffer: buffer, byteIndex: index)
        return [(fullname: fullname, object)]
    }
}


final class AMLNamedDWordField: AMLNamedObj {
    var buffer: AMLSharedBuffer
    let byteIndex: Int

    var value: AMLInteger {
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(fullname()))
        return readValue(context: &context).integerValue!
    }

    init(name: AMLNameString, buffer: AMLSharedBuffer, byteIndex: AMLInteger) {
        self.buffer = buffer
        self.byteIndex = Int(byteIndex)
        super.init(name: name)
    }

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let dword = buffer.readDWord(atByteIndex: byteIndex)
        return AMLIntegerData(AMLInteger(dword))
    }

    override func updateValue(to newValue: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        let dword = AMLDWordData(newValue.evaluate(context: &context).integerValue!)
        buffer.writeDWord(atByteIndex: byteIndex, value: dword)
    }
}


struct AMLDefCreateQWordField: AMLNameSpaceModifierObj {
    // CreateQWordFieldOp SourceBuff ByteIndex NameString
    let sourceBuff: AMLTermArg  // => Buffer
    let byteIndex: AMLTermArg  // => Integer
    let name: AMLNameString

    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(fullname: AMLNameString, AMLNamedObj)] {
        let buffer = sourceBuff.evaluate(context: &context).bufferValue!
        let index = byteIndex.evaluate(context: &context).integerValue!
        let fullname = resolveNameTo(scope: context.scope, path: name)
        let object = AMLNamedQWordField(name: name, buffer: buffer, byteIndex: index)
        return [(fullname: fullname, object)]
    }
}


final class AMLNamedQWordField: AMLNamedObj {
    var buffer: AMLSharedBuffer
    let byteIndex: Int

    init(name: AMLNameString, buffer: AMLSharedBuffer, byteIndex: AMLInteger) {
        self.buffer = buffer
        self.byteIndex = Int(byteIndex)
        super.init(name: name)
    }

    override func readValue(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let qword = buffer.readQWord(atByteIndex: byteIndex)
        return AMLIntegerData(AMLInteger(qword))
    }

    override func updateValue(to newValue: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        let qword = AMLQWordData(newValue.evaluate(context: &context).integerValue!)
        buffer.writeQWord(atByteIndex: byteIndex, value: qword)
    }
}
