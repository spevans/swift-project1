//
//  kernel/devices/acpi/amlnamespacemodifier.swift
//  AML name space modifier types
//
//  Created by Simon Evans on 07/08/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//


/// AMLNameSpaceModifierj is a protocol for opcodes that add to the global
/// namespace either as globals at parse time or locally during method
/// execution.
/// This differs from the NameSpaceModifierObj listed in the ACPI documentation
/// which uses it to cover DefScope and DefAlias. These to are excluded as they
/// add to the namespace immediately as they are parsed and are not opcode, in
/// fact they dont really need to exist as types (AMLDefScope, AMLDefAlias) and
/// will probably be removed at some point.


enum AMLNameSpaceModifier {
    case defScope(AMLDefScope)
    case creator(AMLNameString, (_ context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)])

    init(name: AMLNameString, closure: @escaping (_ context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)]) {
        self = .creator(name, closure)
    }
/*
    func createObjects(context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] {
        switch self {
            case .creator(_, let closure): return try closure(&context)
            default: fatalError("Undefined")
        }
    }
 */
}


struct AMLDefScope {
    // ScopeOp PkgLength NameString TermList
    let scope: AMLNameString
    let termList: AMLTermList

    init(scope: AMLNameString, termList: AMLTermList) {
        self.scope = scope
        self.termList = termList
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        throw AMLError.unimplemented("AMLDefScope")
    }
}

struct AMLDefIndexField {
    // IndexFieldOp PkgLength NameString NameString FieldFlags FieldList
    let indexName: AMLNameString
    let dataName: AMLNameString
    let flags: AMLFieldFlags
    let fields: AMLFieldList
}


struct AMLNamedField {

    enum RegionReference {
        case regionSpace(OpRegionSpace)
        case opRegion(AMLDefOpRegion)
        case name(AMLNameString)
        case indexDataField(AMLNameString, AMLNameString)
    }

    let name: AMLNameString
    let region: RegionReference
    let fieldSettings: AMLFieldSettings
    var isReadOnly: Bool { false }


    var description: String {
        return "\(self.name): bitOffset: \(fieldSettings.bitOffset) bitWidth: \(fieldSettings.bitWidth)"
            + " fieldFlags: \(fieldSettings.fieldFlags)"
    }

    init(name: AMLNameString, regionName: AMLNameString, fieldSettings: AMLFieldSettings) {
        self.name = name
        self.region = .name(regionName)
        self.fieldSettings = fieldSettings
    }

    init(name: AMLNameString, opRegion: AMLDefOpRegion, fieldSettings: AMLFieldSettings) {
        self.name = name
        self.region = .opRegion(opRegion)
        self.fieldSettings = fieldSettings
    }

    init(name: AMLNameString, indexField: AMLNameString, dataField: AMLNameString, fieldSettings: AMLFieldSettings) {
        self.name = name
        self.region = .indexDataField(indexField, dataField)
        self.fieldSettings = fieldSettings
    }

    func getRegionSpace(context: inout ACPI.AMLExecutionContext) throws -> OpRegionSpace {
        let space: OpRegionSpace

        switch region {
            case let .regionSpace(opRegionSpace):
                space = opRegionSpace

            case let .opRegion(opRegion):
                space = try opRegion.getRegionSpace(context: &context)
                // region = .regionSpace(space)

            case let .name(regionName):
                guard let (opNode, _) = context.getObject(named: regionName),
                      let opRegion = opNode.object.operationRegionValue else {
                    fatalError("Cant find \(regionName) in \(context.scope)")
                }
                space = try opRegion.getRegionSpace(context: &context)

            case .indexDataField(let index, let data):
                fatalError("implement IndexData Field \(index)/\(data)")
        }
        return space
    }


    func updateValue(to value: AMLObject, context: inout ACPI.AMLExecutionContext) throws {
        let region = try getRegionSpace(context: &context)
        let accessWidth = fieldSettings.fieldFlags.fieldAccessType.accessWidth
        var iterator = try AMLByteIterator(value, bitWidth: Int(fieldSettings.bitWidth), accessWidth: accessWidth)

        //print("\(self.name): writing 0x\(String(value, radix: 16)) to bitOffset: \(fieldSettings.bitOffset)")
        var bitOffset = Int(fieldSettings.bitOffset)
        while let value = iterator.next() {
            region.write(bitOffset: bitOffset, width: accessWidth * 8, value: value, flags: fieldSettings.fieldFlags)
            bitOffset += accessWidth
        }
    }


    func readValue(context: inout ACPI.AMLExecutionContext) throws -> AMLObject {
        let value = try getRegionSpace(context: &context).read(bitOffset: Int(fieldSettings.bitOffset),
                                                               width: Int(fieldSettings.bitWidth),
                                                               flags: fieldSettings.fieldFlags)
        //print("\(self.name): read 0x\(String(value, radix: 16)) from bitOffset: \(fieldSettings.bitOffset)")
        return AMLObject(value)
    }
}


struct AMLDefBankField {
    // BankFieldOp PkgLength NameString NameString BankValue FieldFlags FieldList
    //let name: AMLNameString
    let bankValue: AMLTermArg // => Integer
    let flags: AMLFieldFlags
    let fields: AMLFieldList
}
