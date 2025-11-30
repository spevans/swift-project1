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
    case creator(AMLNameString, (_ context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)])

    init(name: AMLNameString, closure: @escaping (_ context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)]) {
        self = .creator(name, closure)
    }
/*
    func createObjects(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] {
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

    func execute(context: inout ACPI.AMLExecutionContext) throws(AMLError) {
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

    enum _RegionSpace {
        case opRegion(AMLDefOpRegion)
        case indexDataField(ACPI.ACPIObjectNode, ACPI.ACPIObjectNode)
    }

    private let name: AMLNameString
    private let region: _RegionSpace
    private let fieldSettings: AMLFieldSettings


    var description: String {
        return "\(self.name): bitOffset: \(fieldSettings.bitOffset) bitWidth: \(fieldSettings.bitWidth)"
            + " fieldFlags: \(fieldSettings.fieldFlags)"
    }

    init(name: AMLNameString, opRegion: AMLDefOpRegion, fieldSettings: AMLFieldSettings) {
        self.name = name
        self.region = .opRegion(opRegion)
        self.fieldSettings = fieldSettings
    }

    init(name: AMLNameString, indexField: ACPI.ACPIObjectNode, dataField: ACPI.ACPIObjectNode, fieldSettings: AMLFieldSettings) {
        self.name = name
        self.region = .indexDataField(indexField, dataField)
        self.fieldSettings = fieldSettings
    }

    @inline(never)
    func updateValue(to value: AMLObject, context: inout ACPI.AMLExecutionContext) throws(AMLError) {
        if ACPIDebug {
            #kprintf("acpi: Updating %s to %s\n", self.name.value, value.description)
        }


        switch self.region {
            case .opRegion(let opRegion):
                try opRegion.write(value: value, fieldSettings: self.fieldSettings,
                                   context: &context)

            case .indexDataField(let index, let data):
                if ACPIDebug {
                    #kprintf("acpi: IndexField(index: %s/%s data: %s/%s)\n",
                             index.name.value, index.object.description,
                             data.name.value, data.object.description)
                }
                guard let indexPort = index.object.fieldUnitValue,
                      let dataPort = data.object.fieldUnitValue else {
                    fatalError("\(index) or \(data) are not named fields")
                }
                if ACPIDebug {
                    #kprintf("acpi: updating index/data %s/%s\n",
                             indexPort.description, dataPort.description)
                }
                let bitOffset = Int(fieldSettings.bitOffset)
                let port = AMLObject(AMLInteger(bitOffset / 8))
                try indexPort.updateValue(to: port, context: &context)
                try dataPort.updateValue(to: AMLObject(value), context: &context)
        }
//        if ACPIDebug {
//            #kprintf("acpi: Updated %s\n", name.description)
//        }
    }


    @inline(never)
    func readValue(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {

        switch self.region {
            case .opRegion(let opRegion):
                let value = try opRegion.read(fieldSettings: self.fieldSettings,
                                              context: &context)
                if ACPIDebug {
                    let bitWidth = fieldSettings.bitWidth
                    let bitOffset = fieldSettings.bitOffset
                    #kprintf("acpi: %s.readValue(0x%x/%u) => %s\n",
                             name.value, bitOffset, bitWidth, value.description)
                }
                return value

            case .indexDataField(let index, let data):
                guard let indexPort = index.object.fieldUnitValue,
                      let dataPort = data.object.fieldUnitValue else {
                    fatalError("\(index) or \(data) are not named fields")
                }
                let bitOffset = fieldSettings.bitOffset

                let port = AMLObject(AMLInteger(bitOffset / 8))
                try indexPort.updateValue(to: port, context: &context)
                let value = try dataPort.readValue(context: &context)
                if ACPIDebug {
                    let bitWidth = fieldSettings.bitWidth

                    #kprintf("acpi: %s.readValue(port: 0x%x/%u) => 0x%x\n",
                             name.value, bitOffset, bitWidth, value.description)
                }
                return value
        }
    }
}


struct AMLDefBankField {
    // BankFieldOp PkgLength NameString NameString BankValue FieldFlags FieldList
    //let name: AMLNameString
    let bankValue: AMLTermArg // => Integer
    let flags: AMLFieldFlags
    let fields: AMLFieldList
}
