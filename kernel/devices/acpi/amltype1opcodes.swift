//
//  kernel/devices/acpi/amltype1opcodes.swift
//
//  Created by Simon Evans on 25/11/2017.
//  Copyright © 2017 - 2019 Simon Evans. All rights reserved.
//
//  ACPI Type 1 Opcodes

protocol AMLType1Opcode: AMLTermObj {
    func execute(context: inout ACPI.AMLExecutionContext) throws
}

extension AMLType1Opcode {
    // FIXME - this should be removed when all type1 opcodes implemented
    func execute(context: inout ACPI.AMLExecutionContext) throws {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


// AMLType1Opcode
struct AMLDefBreak: AMLType1Opcode {
    // empty
}


struct AMLDefBreakPoint: AMLType1Opcode {
    // empty
}


struct AMLDefContinue: AMLType1Opcode {
    // empty
}


struct AMLDefElse: AMLType1Opcode {
    // Nothing | <ElseOp PkgLength TermList>
    let value: AMLTermList?

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        if let termList = value {
            try context.execute(termList: termList)
        }
    }
}


struct AMLDefFatal: AMLType1Opcode {
    let type: AMLByteData
    let code: AMLDWordData
    let arg: AMLTermArg // => Integer

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        fatalError("FatalError Type: \(type) code: \(code) arg: \(arg)")
    }
}


struct AMLDefIfElse: AMLType1Opcode {
    // IfOp PkgLength Predicate TermList DefElse
    let predicate: AMLPredicate
    let value: AMLTermList
    let elseValue: AMLTermList?

    init(predicate: AMLPredicate, value: AMLTermList, defElse: AMLDefElse) {
        self.predicate = predicate
        self.value = value
        elseValue = defElse.value
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        guard let result = predicate.evaluate(context: &context) as? AMLIntegerData else {
            fatalError("Predicate does not evaluate to an integer")
        }
        if result.value != 0 {
            try context.execute(termList: value)
        } else if let elseTermList = elseValue {
            try context.execute(termList: elseTermList)
        }
    }
}


struct AMLDefLoad: AMLType1Opcode {
    // LoadOp NameString DDBHandleObject
    let name: AMLNameString
    let value: AMLDDBHandleObject
}


struct AMLDefNoop: AMLType1Opcode {
    // NoopOp

    func execute(context: inout ACPI.AMLExecutionContext) throws {
    }
}


struct AMLDefNotify: AMLType1Opcode {
    // NotifyOp NotifyObject NotifyValue
    let object: AMLSuperName // => ThermalZone | Processor | Device AMLNotifyObject
    let value: AMLTermArg // -> Integer AMLNotifyValue

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        let _value = operandAsInteger(operand: value, context: &context)
        let string = String(describing: object)
        let v = String(describing: _value)
        print("NOTIFY:", string, v)
    }
}


struct AMLDefRelease: AMLType1Opcode {
    // ReleaseOp MutexObject
    let mutex: AMLMutexObject

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        print("Releasing Mutex:", mutex)
    }
}


struct AMLDefReset: AMLType1Opcode {
    // ResetOp EventObject
    let object: AMLEventObject
}


// fixme
//typealias AMLArgObject = AMLTermArg
struct AMLDefReturn: AMLType1Opcode {
    // ReturnOp ArgObject
    let object: AMLTermArg//AMLDataRefObject // TermArg => DataRefObject

    init(object: AMLTermArg?) {
        if object == nil {
            self.object = AMLIntegerData(0)
        } else {
            self.object = object!
        }
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        context.returnValue = object.evaluate(context: &context)
        context.endOfMethod = true
    }
}


struct AMLDefSignal: AMLType1Opcode {
    // SignalOp EventObject
    let object: AMLEventObject
}


struct AMLDefSleep: AMLType1Opcode {
    // SleepOp MsecTime
    let msecTime: AMLTermArg // => Integer

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        print("SLEEP: \(msecTime) ms")
    }
}


struct AMLDefStall: AMLType1Opcode {
    // StallOp UsecTime
    let usecTime: AMLTermArg // => ByteData

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        let value = operandAsInteger(operand: usecTime, context: &context)
        print("Stalling for \(value) us)")
    }
}


struct AMLDefUnload: AMLType1Opcode {
    // UnloadOp DDBHandleObject
    let object: AMLDDBHandleObject
}


struct AMLDefWhile: AMLType1Opcode {
    // WhileOp PkgLength Predicate TermList
    let predicate: AMLPredicate
    let list: AMLTermList

    func execute(context: inout ACPI.AMLExecutionContext) throws {
        while true {
            let result = predicate.evaluate(context: &context) as! AMLIntegerData
            if result.value == 0 {
                return
            }
            try context.execute(termList: list)
            if context.endOfMethod {
                return
            }
        }
    }
}


