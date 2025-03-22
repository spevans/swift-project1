//
//  kernel/devices/acpi/amltype1opcodes.swift
//
//  Created by Simon Evans on 25/11/2017.
//  Copyright © 2017 - 2025 Simon Evans. All rights reserved.
//
//  ACPI Type 1 Opcodes


enum AMLType1Opcode {
    case amlDefBreak
    case amlDefBreakPoint
    case amlDefContinue

    // Nothing | <ElseOp PkgLength TermList>
    case amlDefElse(AMLTermList?)
    case amlDefFatal(AMLByteData, AMLDWordData, AMLTermArg)

    // IfOp PkgLength Predicate TermList DefElse
    case amlDefIfElse(AMLTermArg, AMLTermList, AMLTermList?)
    case amlDefNoop
    case amlDefNotify(AMLTarget, AMLTermArg)
    case amlDefRelease(AMLTarget)
    case amlDefReset(AMLTarget)
    case amlDefReturn(AMLTermArg)
    case amlDefSignal(AMLTarget)
    case amlDefSleep(AMLTermArg)
    case amlDefStall(AMLTermArg)
    case amlDefUnload(AMLTarget)
    case amlDefWhile(AMLTermArg, AMLTermList)

    func execute(context: inout ACPI.AMLExecutionContext) throws(AMLError) {
        switch self {
            case .amlDefBreak:
                context.breakWhile = true
                return

            case .amlDefBreakPoint:
                return

            case .amlDefContinue:
                context.continueWhile = true
                return

            case .amlDefElse(let termList):
                if let termList = termList {
                    try context.execute(termList: termList)
                }

            case .amlDefFatal(let type, let code, let arg):
                fatalError("FatalError Type: \(type) code: \(code) arg: \(arg)")

            case .amlDefIfElse(let predicate, let termList, let elseTermList):
                let result = try operandAsInteger(operand: predicate, context: &context)
                if result != 0 {
                    try context.execute(termList: termList)
                } else if let elseTermList = elseTermList {
                    try context.execute(termList: elseTermList)
                }

            case .amlDefNoop:
                return

            case .amlDefNotify(let object, let value):
                // NotifyOp NotifyObject NotifyValue
                let _value = try operandAsInteger(operand: value, context: &context)
                let string = "TODO" //object.description
                let v = String(describing: _value)
                #kprint("NOTIFY:", string, v)
                throw AMLError.unimplemented("Notify \(object) \(_value)")

            case .amlDefRelease(let mutex):
                // ReleaseOp MutexObject
                throw AMLError.unimplemented("Release \(mutex))")

            case .amlDefReset(let object):
                // ResetOp EventObject
                throw AMLError.unimplemented("Reset \(object)")

            case .amlDefReturn(let termArg):
                // ReturnOp ArgObject
                context.returnValue = try termArg.evaluate(context: &context)
                context.endOfMethod = true

            case .amlDefSignal(let object):
                // SignalOp EventObject
                throw AMLError.unimplemented("Signal \(object)")

            case .amlDefSleep(let msecTime):
                // SleepOp MsecTime
                let value = try operandAsInteger(operand: msecTime, context: &context)
                throw AMLError.unimplemented("SLEEP: \(value) ms")

            case .amlDefStall(let usecTime):
                // StallOp UsecTime
                let value = try operandAsInteger(operand: usecTime, context: &context)
                throw AMLError.unimplemented("Stalling for \(value) usec)")

            case .amlDefUnload(let target):
                // UnloadOp DDBHandleObject (AMLTarget // => Supername)
                throw AMLError.unimplemented("Unload \(target)")

            case .amlDefWhile(let predicate, let termList):
                // WhileOp PkgLength Predicate TermList
                while true {
                    context.breakWhile = false
                    context.continueWhile = false
                    let result = try predicate.evaluate(context: &context).integerValue!
                    if result == 0 {
                        return
                    }
                    try context.execute(termList: termList)
                    if context.breakWhile {
                        context.breakWhile = false
                        break
                    }
                    if context.continueWhile {
                        context.continueWhile = false
                        continue
                    }
                    if context.endOfMethod {
                        return
                    }
                }
                return
        }
    }
}
