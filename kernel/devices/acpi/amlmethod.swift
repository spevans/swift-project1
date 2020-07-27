//
//  kernel/devices/acpi/amlmethod.swift
//
//  Created by Simon Evans on 12/05/2017.
//  Copyright © 2017 - 2019 Simon Evans. All rights reserved.
//
//  ACPI method invocation


extension ACPI {

    struct AMLExecutionContext {
        let scope: AMLNameString
        let args: AMLTermArgList
        var localObjects: [AMLTermArg?]
        var endOfMethod = false
        private var _returnValue: AMLTermArg? = nil

        var returnValue: AMLTermArg? {
            mutating get {
                let ret = _returnValue
                _returnValue = nil
                return ret
            }
            set {
                _returnValue = newValue
            }
        }


        init(scope: AMLNameString, args: AMLTermArgList = []) {
            self.scope = scope
            self.args = args
            self.localObjects = Array(repeatElement(nil, count: 8))
        }


        private init(scope: AMLNameString, args: AMLTermArgList, localObjects: [AMLTermArg?]) {
            self.scope = scope
            self.args = args
            self.localObjects = localObjects
        }


        func withNewScope(_ newScope: AMLNameString) -> AMLExecutionContext {
            return AMLExecutionContext(scope: newScope, args: self.args, localObjects: self.localObjects)
        }


        mutating func execute(termList: AMLTermList) throws {
            var dynamicNamedObjects: [AMLNamedObj] = []
            defer {
                for object in dynamicNamedObjects.reversed() {
                    object.parent!.removeChildNode(object.name)
                }
            }
            for termObj in termList {
                if let op = termObj as? AMLType2Opcode {
                    // FIXME, should something be done with the result or maybe it should
                    // only be returned in the context
                    _ = op.evaluate(context: &self)
                } else if let op = termObj as? AMLType1Opcode {
                    try op.execute(context: &self)
                } else if let op = termObj as? AMLNamedObj {
                    try op.createNamedObject(context: &self)
                    dynamicNamedObjects.append(op)
                } else if let op = termObj as? AMLNameSpaceModifierObj {
                    try op.execute(context: &self)
                } else if let defFields = termObj as? AMLDefField {
                    // AMLDefField isnt a named object but rather holds a list of AMLNamedObj
                    for object in defFields.fields {
                        try object.createNamedObject(context: &self)
                        dynamicNamedObjects.append(object)
                    }
                }
                else if let indexFields = termObj as? AMLDefIndexField {
                    // AMLDefIndexField isnt a named object but rather holds a list of AMLNamedObj
                    for object in indexFields.fields {
                        try object.createNamedObject(context: &self)
                        dynamicNamedObjects.append(object)
                    }
                } else {
                    fatalError("Unknown op: \(termObj) in scope \(self.scope)")
                }
                if endOfMethod {
                    return
                }
            }
        }
    }


    static func _OSI_Method(_ args: AMLTermArgList) throws -> AMLTermArg {
        guard args.count == 1 else {
            throw AMLError.invalidData(reason: "_OSI: Should only be 1 arg")
        }
        guard let arg = args[0] as? AMLString else {
            throw AMLError.invalidData(reason: "_OSI: is not a string")
        }
        if arg.value == "Darwin" {
            return AMLIntegerData(0xffffffff)
        } else {
            return AMLIntegerData(0)
        }
    }
}
