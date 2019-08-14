//
//  kernel/devices/acpi/amlmethod.swift
//
//  Created by Simon Evans on 12/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  ACPI method invocation


extension ACPI {

    struct AMLExecutionContext {
        let scope: AMLNameString
        let args: AMLTermArgList
        var localObjects: [AMLTermArg?] = Array(repeatElement(nil, count: 8))
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


        init(scope: AMLNameString, args: AMLTermArgList  = []) {
            self.scope = scope
            self.args = args
        }

        func withNewScope(_ newScope: AMLNameString) -> AMLExecutionContext {
            return AMLExecutionContext(scope: newScope)
        }

        mutating func execute(termList: AMLTermList) throws {
            for termObj in termList {
                if let op = termObj as? AMLType2Opcode {
                    // FIXME, should something be done with the result or maybe it should
                    // only be returned in the context
                    _ = try op.execute(context: &self)
                } else if let op = termObj as? AMLType1Opcode {
                    try op.execute(context: &self)
                } else if let op = termObj as? AMLNamedObj {
                    try op.createNamedObject(context: &self)
                } else if let op = termObj as? AMLNameSpaceModifierObj {
                    try op.execute(context: &self)
                } else {
                    fatalError("Unknown op: \(type(of: termObj))")
                }
                if endOfMethod {
                    return
                }
            }
        }
    }


    func invokeMethod(name: String, _ args: Any...) throws -> AMLTermArg? {
        var methodArgs: AMLTermArgList = []
        for arg in args {
            if let arg = arg as? String {
                methodArgs.append(AMLString(arg))
            } else if let arg = arg as? AMLInteger {
                methodArgs.append(AMLIntegerData(AMLInteger(arg)))
            } else {
                throw AMLError.invalidData(reason: "Bad data: \(arg)")
            }
        }
        let mi = try AMLMethodInvocation(method: AMLNameString(name),
                                         args: methodArgs)
        var context = AMLExecutionContext(scope: mi.method)

        return try mi.execute(context: &context)
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
