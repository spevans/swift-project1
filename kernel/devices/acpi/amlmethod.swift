//
//  kernel/devices/acpi/amlmethod.swift
//  acpi
//
//  Created by Simon Evans on 12/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

extension ACPI {

    struct AMLExecutionContext {
        let scope: AMLNameString
        let args: AMLTermArgList
        let globalObjects: ACPIGlobalObjects
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


        init(scope: AMLNameString, args: AMLTermArgList,
             globalObjects: ACPIGlobalObjects) {
            self.scope = scope
            self.args = args
            self.globalObjects = globalObjects
        }


        mutating func execute(termList: AMLTermList) throws {
            for termObj in termList {
                print("Executing:", termObj)
                if let op = termObj as? AMLType2Opcode {
                    _ = try op.execute(context: &self)
                } else if let op = termObj as? AMLType1Opcode {
                    try op.execute(context: &self)
                } else {
                    fatalError("Unknown op: \(type(of: termObj))")
                }
                if endOfMethod {
                    endOfMethod = false
                    return
                }
            }
        }
    }


    func invokeMethod(name: String, _ args: Any...) throws -> AMLTermArg? {
        var methodArgs: AMLTermArgList = []
        for arg in args {
            if let arg = arg as? String {
                methodArgs.append(AMLNameString(value: arg))
            } else if let arg = arg as? AMLInteger {
                methodArgs.append(AMLIntegerData(value: AMLInteger(arg)))
            } else {
                throw AMLError.invalidData(reason: "Bad data: \(arg)")
            }
        }
        let m = try AMLMethodInvocation(method: AMLNameString(value: name),
                                        args: methodArgs)
        return try invokeMethod(invocation: m)
    }


    func invokeMethod(invocation: AMLMethodInvocation) throws -> AMLTermArg? {

        let name = invocation.method._value
        if name == "\\_OSI" || name == "_OSI" {
            return try _OSI_Method(invocation.args)
        }

        let scope = invocation.method
        guard let obj = globalObjects.get(name) else {
            throw AMLError.invalidMethod(reason: "Cant find method: \(name)")
        }
        guard let method = obj.object as? AMLMethod else {
            throw AMLError.invalidMethod(reason: "Cant find method: \(name)")
        }
        let termList = try method.parser.parseTermList()
        print(termList)
        var context = AMLExecutionContext(scope: scope,
                                          args: invocation.args,
                                          globalObjects: globalObjects)

        try context.execute(termList: termList)
        return context.returnValue
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
}
