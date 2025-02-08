//
//  kernel/devices/acpi/amlmethod.swift
//
//  Created by Simon Evans on 12/05/2017.
//  Copyright © 2017 - 2025 Simon Evans. All rights reserved.
//
//  ACPI method invocation


struct AMLMethodInvocation {
    // NameString TermArgList
    let method: AMLNameString
    let args: AMLTermArgList

    init(method: AMLNameString, args: AMLTermArgList) throws {
        guard args.count < 7 else {
            throw AMLError.invalidData(reason: "More than 7 args")
        }
        self.method = method
        self.args = args
    }

    init(method: AMLNameString, _ args: AMLTermArg...) throws {
        try self.init(method: method, args: args)
    }


    fileprivate func _invokeMethod(context: inout ACPI.AMLExecutionContext) throws -> AMLObject? {

        let name = self.method.value

        guard let (obj, fullPath) = context.getObject(named: method) else {
                throw AMLError.invalidMethod(reason: "Cant find method: \(name)")
        }
        guard let method = obj.object.methodValue else {
            throw AMLError.invalidMethod(reason: "\(name) [\(obj.description))] is not an AMLMethod")
        }
        guard method.flags.argCount == args.count else {
            throw AMLError.invalidData(reason: "Method \(fullPath) requires \(method.flags.argCount) arguments but \(args.count) were passed")
        }
        var newArgs: [AMLObject] = []
        newArgs.reserveCapacity(args.count)
        for arg in args {
            newArgs.append(try arg.evaluate(context: &context))
        }
        var newContext = ACPI.AMLExecutionContext(scope: AMLNameString(fullPath),
                                                  args: newArgs)
        try method.execute(context: &newContext)
        return newContext.returnValue
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) throws -> AMLObject {
        if let result = try _invokeMethod(context: &context) {
            context.returnValue = result
            return result
        } else {
            return AMLObject(0)
        }
    }
}

typealias AMLMethodInternalHandler = (inout ACPI.AMLExecutionContext) throws -> AMLObject?
final class AMLMethod {
    //let name: AMLNameString
    let name: AMLNameString
    let flags: AMLMethodFlags
    // FIXME: Cant termList be created at top-level parse?
    private var _parser: AMLParser?
    private var _termList: AMLTermList?
    private var handler: AMLMethodInternalHandler?


    init(name: AMLNameString, flags: AMLMethodFlags, parser: AMLParser?) {
        self.name = name
        self.flags = flags
        self._parser = parser
    }

    init(name: AMLNameString, flags: AMLMethodFlags, handler: AMLMethodInternalHandler?) {
        self.name = name
        self.flags = flags
        self.handler = handler
    }

    private func termList() throws -> AMLTermList {
        if _termList == nil, let parser = _parser {
            _termList = try parser.parseTermList()
            _parser = nil
        }
        return _termList!
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        if let handler = handler {
            context.returnValue = try handler(&context)
            return
        } else {
            let termList = try self.termList()
            try context.execute(termList: termList)
        }
    }

    func readValue(context: inout ACPI.AMLExecutionContext) throws -> AMLObject {
        do {
            try execute(context: &context)
            // reset the context
            context.endOfMethod = false
            context.localObjects = Array(repeatElement(AMLObject(), count: 8))
            return context.returnValue!
        }
    }
}


extension ACPI {
    @discardableResult
    static func invoke(method: String, _ args: AMLTermArg...) throws -> AMLObject? {
        let mi = try AMLMethodInvocation(method: AMLNameString(method), args: args)
        var context = ACPI.AMLExecutionContext(scope: mi.method)

        if let result = try mi._invokeMethod(context: &context) {
            context.returnValue = result
            return result
        } else {
            return nil
        }
    }

    struct AMLExecutionContext {
        private(set) var scope: AMLNameString
        private let isTopLevel: Bool
        var args: [AMLObject]
        var localObjects: [AMLObject]
        var endOfMethod = false
        var breakWhile = false
        var continueWhile = false
        private var _returnValue: AMLObject? = nil
        // Used for localally scoped named objects
       // private var localObjectNodes: ACPI.ACPIObjectNode?

        var returnValue: AMLObject? {
            mutating get {
                let ret = _returnValue
                _returnValue = nil
                return ret
            }
            set {
                _returnValue = newValue
            }
        }


        init(scope: AMLNameString, args: [AMLObject] = [], isTopLevel: Bool = false) {
            self.scope = scope
            self.args = args
            self.localObjects = Array(repeatElement(AMLObject(), count: 8))
         //   localObjectNodes = isTopLevel ? nil : ACPIObjectNode(name: AMLNameString("\\"), object: AMLObject())
            self.isTopLevel = isTopLevel
        }


        private init(scope: AMLNameString, args: [AMLObject], localObjects: [AMLObject]) { //}, localObjectNodes: ACPIObjectNode?) {
            self.scope = scope
            self.args = args
            self.localObjects = localObjects
            self.isTopLevel = false
         //   self.localObjectNodes = localObjectNodes
        }


        func withNewScope(_ newScope: AMLNameString) -> AMLExecutionContext {
            return AMLExecutionContext(scope: newScope,
                                       args: self.args,
                                       localObjects: self.localObjects)
                                   //    localObjectNodes: self.localObjectNodes)
        }

        // FIXME: is this needed now?
        func getObject(named name: AMLNameString) -> (ACPI.ACPIObjectNode, String)? {
            return ACPI.globalObjects.getGlobalObject(currentScope: scope, name: name)
        }

        mutating func execute(termList: AMLTermList) throws {
            var dynamicNamedObjects: [ACPIObjectNode] = []
            defer {
                for object in dynamicNamedObjects.reversed() {
                    object.parent!.removeChildNode(object.name)
                }
            }

            for termObj in termList {
                if continueWhile || breakWhile { return }
                switch termObj {
                    case let .type2opcode(op):
                        // FIXME, should something be done with the result or maybe it should
                        // only be returned in the context
                        _ = try op.evaluate(context: &self)
                        
                    case let .type1opcode(op):
                        try op.execute(context: &self)
                        
                    case let .namespaceModifier(op):
                        switch op {
                            case .defScope(let newScope):
                                let currentScope = scope
                                scope = newScope.scope
                                defer { scope = currentScope }
                                try execute(termList: newScope.termList)

                            case .creator(_, let closure):
                                let objects = try closure(&self)
                                let objectNodes = ACPI.globalObjects //localObjectNodes ?? ACPI.globalObjects
                                for (fullname, node, objTermList) in objects {
                                    // let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: object)
                                    if objectNodes.add(fullname.value, node), let objTermList = objTermList {
                                        if !isTopLevel {
                                            dynamicNamedObjects.append(node)
                                        }
                                        let currentScope = scope
                                        scope = fullname
                                        defer { scope = currentScope }
                                        try execute(termList: objTermList)
                                    }
                                }
                        }
                        
                    default:
                        fatalError("Unknown op: \(termObj) in scope \(self.scope)")
                }
                if endOfMethod {
                    return
                }
            }
        }
    }


    static func _OSI_Method(_ context: inout ACPI.AMLExecutionContext) throws -> AMLObject {
        guard context.args.count == 1 else {
            throw AMLError.invalidData(reason: "_OSI: Should only be 1 arg")
        }
        guard let arg = context.args[0].stringValue else {
            throw AMLError.invalidData(reason: "_OSI: is not a string")
        }
        if arg.asString() == "Darwin" {
            return AMLObject(0xffffffff)
        } else {
            return AMLObject(0)
        }
    }
}
