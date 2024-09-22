//
//  kernel/devices/acpi/amltype2ocodes.swift
//
//  Created by Simon Evans on 25/11/2017.
//  Copyright © 2017 - 2019 Simon Evans. All rights reserved.
//
//  ACPI Type 2 Opcodes

protocol AMLType2Opcode: AMLTermObj, AMLTermArg {
}

extension AMLType2Opcode {
    // FIXME: This should be removed when implemented fully
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        fatalError("\(type(of: self)) is not implemented")
    }
}


private func AMLBoolean(_ bool: Bool) -> AMLDataObject {
    return bool ? AMLOnesOp() : AMLZeroOp()
}


func operandAsInteger(operand: AMLTermArg, context: inout ACPI.AMLExecutionContext) -> AMLInteger {
    guard let result = operand.evaluate(context: &context).integerValue else {
        fatalError("\(operand) does not evaluate to an integer")
    }
    return result
}


// AMLType2Opcode
struct AMLDefAcquire: AMLType2Opcode {
    // AcquireOp MutexObject Timeout
    let mutex: AMLMutexObject
    let timeout: AMLWordData

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        // FIXME - implement
        print("Acquiring Mutex")
        return AMLBoolean(false)   // acquired
    }
}


struct AMLDefAdd: AMLType2Opcode {
    // AddOp Operand Operand Target
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData(op1 &+ op2)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefAnd: AMLType2Opcode {
    // AndOp Operand Operand Target
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData(op1 & op2)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefConcat: AMLType2Opcode {
    // ConcatOp Data Data Target
    let data1: AMLTermArg // => ComputationalData
    let data2: AMLTermArg // => ComputationalData
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        fatalError("\(type(of: self))")
    }
}


struct AMLDefConcatRes: AMLType2Opcode {
    // ConcatResOp BufData BufData Target
    let data1: AMLTermArg // => Buffer
    let data2: AMLTermArg // => Buffer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        guard let buf1 = data1.evaluate(context: &context).bufferValue?.copyBuffer(),
            let buf2 = data2.evaluate(context: &context).bufferValue?.copyBuffer() else {
                fatalError("AMLDefConcatRes: cant evaulate operands as buffers")
        }
        // Fixme, iterate validating the individual entries and add an endtag
        let result = AMLBuffer(buf1[0..<buf1.count-2]) + buf2

        let newBuffer = AMLDataObject.buffer(AMLSharedBuffer(bytes: result))
        target.updateValue(to: newBuffer, context: &context)
        return newBuffer
    }
}


struct AMLDefCondRefOf: AMLType2Opcode {
    // CondRefOfOp SuperName Target
    let name: AMLSuperName
    var target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {

        guard let n = name.evaluate(context: &context).stringValue else {
            print("AMLDefCondRef \(name) does not evanulate to a string")
            return AMLIntegerData(0)
        }

        let globalObjects = system.deviceManager.acpiTables.globalObjects!
        guard let (obj, _) = globalObjects.getGlobalObject(currentScope: context.scope, name: AMLNameString(n)) else {
            return AMLIntegerData(0)
        }
        let ref = AMLNameString(obj.fullname())
        target.updateValue(to: ref, context: &context)
        return AMLIntegerData(1)
    }
}


struct AMLDefCopyObject: AMLType2Opcode {
    // CopyObjectOp TermArg SimpleName
    let object: AMLTermArg
    let target: AMLSimpleName

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        fatalError("Implement DefCopyObject")
    }
}


struct AMLDefDecrement: AMLType2Opcode {
    // DecrementOp SuperName
    let target: AMLSuperName

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        guard let value = target.evaluate(context: &context).integerValue else {
            fatalError("\target) is not an integer")
        }
        let result = AMLIntegerData(value &- 1)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefDerefOf: AMLType2Opcode, AMLType6Opcode {
    // DerefOfOp ObjReference
    let name: AMLSuperName

    // FIXME: Implement

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("AMLDefDerefOf.updateValue not implemented")
    }
}


struct AMLDefDivide: AMLType2Opcode {
    // DivideOp Dividend Divisor Remainder Quotient
    let dividend: AMLTermArg // => Integer
    let divisor: AMLTermArg // => Integer
    let remainder: AMLTarget
    let quotient: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let d1 = operandAsInteger(operand: dividend, context: &context)
        let d2 = operandAsInteger(operand: divisor, context: &context)
        guard d2 != 0 else {
            fatalError("divisor is 0")
        }
        let q = AMLIntegerData((d1 / d2))
        let r = AMLIntegerData((d1 % d2))
        quotient.updateValue(to: q, context: &context)
        remainder.updateValue(to: r, context: &context)
        return q
    }
}


struct AMLDefFindSetLeftBit: AMLType2Opcode {
    // FindSetLeftBitOp Operand Target
    let operand: AMLTermArg // => Integer
    let target: AMLTarget

    func execute(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let value = (op == 0) ? AMLInteger(0) : AMLInteger(op.leadingZeroBitCount + 1)
        let result = AMLIntegerData(value)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefFindSetRightBit: AMLType2Opcode {
    // FindSetRightBitOp Operand Target
    let operand: AMLTermArg // => Integer
    let target: AMLTarget

    func execute(context: inout ACPI.AMLExecutionContext)  -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let value = (op == 0) ? AMLInteger(0) : AMLInteger(op.trailingZeroBitCount + 1)
        let result = AMLIntegerData(value)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefFromBCD: AMLType2Opcode {
    // FromBCDOp BCDValue Target
    let value: AMLTermArg // => Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let bcdValue = operandAsInteger(operand: value, context: &context)
        var tmpBcdValue = bcdValue
        var newValue: AMLInteger = 0
        var idx: AMLInteger = 1

        while tmpBcdValue != 0 {
            let bcd = tmpBcdValue & 0xf
            guard bcd < 10 else { fatalError("BCD value \(String(bcdValue, radix: 16)) contains nonBCD \(bcd)") }
            newValue += AMLInteger(idx * bcd)
            idx *= 10
            tmpBcdValue >>= 4
        }
        let result = AMLIntegerData(newValue)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefIncrement: AMLType2Opcode {
    // IncrementOp SuperName
    let target: AMLSuperName

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        guard let value = target.evaluate(context: &context).integerValue else {
            fatalError("\target) is not an integer")
        }
        let result = AMLIntegerData(value &+ 1)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefIndex: AMLType2Opcode, AMLType6Opcode {
    // IndexOp BuffPkgStrObj IndexValue Target
    let operand1: AMLTermArg // => Buffer, Package or String
    let operand2: AMLTermArg // => Integer
    let target: AMLTarget

    // FIXME: Implement
    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        guard let object = operand1.evaluate(context: &context) as? AMLDataObject else {
            fatalError("\(operand1) does not evaluate to an AMLDataObject")
        }

        let index = operandAsInteger(operand: operand2, context: &context)

        switch object {
            case .buffer(let buffer):   precondition(index < buffer.count)
            case .package(let package): precondition(index < package.count)
            case .string(let string):   precondition(index < string.count)

            default:
            fatalError("ACPI: Index passed an integer as the source")
        }
        fatalError("Implement Index (Index Reference to Member objecr")
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        guard let object = operand1.evaluate(context: &context) as? AMLDataObject else {
            fatalError("\(operand1) does not evaluate to an AMLDataObject")
        }
        let index = operandAsInteger(operand: operand2, context: &context)

        switch object {
            case .buffer(let buffer):
                fatalError("buffer [index=\(index)] \(buffer)")

            case .package(let package):
                guard let element = AMLPackageElement(termarg: to) else {
                    fatalError("\(to) cant be stored as a package element")
                }
                package[Int(index)] = element

            case .string(let string):
                fatalError("string [index=\(index)] \(string)")

            default:
            fatalError("ACPI: DefIndex attempt to update \(object) with index: \(index)")
        }
    }
}


struct AMLDefLAnd: AMLType2Opcode {
    // LandOp Operand Operand
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        return AMLBoolean(op1 != 0 && op2 != 0)
    }
}


struct AMLDefLEqual: AMLType2Opcode {
    // LequalOp Operand Operand
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        return AMLBoolean(op1 == op2)
    }
}


struct AMLDefLGreater: AMLType2Opcode {
    // LgreaterOp Operand Operand
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        return AMLBoolean(op1 < op2)
    }
}


struct AMLDefLGreaterEqual: AMLType2Opcode {
    // LgreaterEqualOp Operand Operand
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        return AMLBoolean(op1 >= op2)
    }
}


struct AMLDefLLess: AMLType2Opcode {
    // LlessOp Operand Operand
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        return AMLBoolean(op1 < op2)
    }
}


struct AMLDefLLessEqual: AMLType2Opcode {
    // LlessEqualOp Operand Operand
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        return AMLBoolean(op1 <= op2)
    }
}


struct AMLDefLNot: AMLType2Opcode {
    // LnotOp Operand
    let operand: AMLTermArg // => Integer

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        return AMLBoolean(op == 0)
    }
}


struct AMLDefLNotEqual: AMLType2Opcode {
    // LnotEqualOp Operand Operand
    let operand1: AMLTermArg
    let operand2: AMLTermArg

    // FIXME: Implement
}


struct AMLDefLoadTable: AMLType2Opcode {
    // LoadTableOp TermArg TermArg TermArg TermArg TermArg TermArg
    let arg1: AMLTermArg
    let arg2: AMLTermArg
    let arg3: AMLTermArg
    let arg4: AMLTermArg
    let arg5: AMLTermArg
    let arg6: AMLTermArg


    // FIXME: Implement
}


struct AMLDefLOr: AMLType2Opcode {
    // LorOp Operand Operand
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        return AMLBoolean(op1 != 0 || op2 != 0)
    }
}


struct AMLDefMatch: AMLType2Opcode {
    enum AMLMatchOpcode: AMLByteData {
        case mtr = 0
        case meq = 1
        case mle = 2
        case mlt = 3
        case mge = 4
        case mgt = 5
    }

    // MatchOp SearchPkg MatchOpcode Operand MatchOpcode Operand StartIndex
    let package: AMLTermArg // => Package
    let matchOpcode1: AMLMatchOpcode
    let operand1: AMLTermArg // => Integer
    let matchOpcode2: AMLMatchOpcode
    let operand2: AMLTermArg // => Integer
    let startIndex: AMLTermArg // => Integer


    // FIXME: Implement
}


struct AMLDefMid: AMLType2Opcode {
    // MidOp MidObj TermArg TermArg Target
    let obj: AMLTermArg // => Buffer | String
    let arg1: AMLTermArg
    let arg2: AMLTermArg
    let target: AMLTarget


    // FIXME: Implement
}


struct AMLDefMod: AMLType2Opcode {
    // ModOp Dividend Divisor Target
    let dividend: AMLTermArg // => Integer
    let divisor: AMLTermArg // => Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let d1 = operandAsInteger(operand: dividend, context: &context)
        let d2 = operandAsInteger(operand: divisor, context: &context)
        guard d2 != 0 else {
            fatalError("divisor is 0")
        }
        let result = AMLIntegerData(d1 % d2)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefMultiply: AMLType2Opcode {
    // MultiplyOp Operand Operand Target
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData(op1 &* op2)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefNAnd: AMLType2Opcode {
    // NandOp Operand Operand Target
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData( ~(op1 & op2))
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefNOr: AMLType2Opcode {
    // NorOp Operand Operand Target
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData( ~(op1 | op2))
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefNot: AMLType2Opcode {
    // NotOp Operand Target
    let operand: AMLTermArg // => Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let result = AMLIntegerData(~op)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefObjectType: AMLType2Opcode {

    // ObjectTypeOp <SimpleName | DebugObj | DefRefOf | DefDerefOf | DefIndex>
    let object: AMLSuperName


    // FIXME: Implement
}


struct AMLDefOr: AMLType2Opcode {
    // OrOp Operand Operand Target
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData(op1 | op2)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefRefOf: AMLType2Opcode, AMLType6Opcode {
    // RefOfOp SuperName
    let name: AMLSuperName

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        fatalError("AMLDefRefOf.evaluate not implemented")
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("AMLDefRefOf.updateValue not implenented")
    }
}


struct AMLDefShiftLeft: AMLType2Opcode {
    // ShiftLeftOp Operand ShiftCount Target
    let operand: AMLTermArg // => Integer
    let count: AMLTermArg //=> Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let shiftCount = operandAsInteger(operand: count, context: &context)
        let result = AMLIntegerData(op << shiftCount)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefShiftRight: AMLType2Opcode {
    // ShiftRightOp Operand ShiftCount Target
    let operand: AMLTermArg // => Integer
    let count: AMLTermArg //=> Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let shiftCount = operandAsInteger(operand: count, context: &context)
        let result = AMLIntegerData(op >> shiftCount)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefSizeOf: AMLType2Opcode {
    // SizeOfOp SuperName
    let name: AMLSuperName

    // FIXME: Implement
}


struct AMLDefStore: AMLType2Opcode {
    // StoreOp TermArg SuperName
    let arg: AMLTermArg
    let name: AMLSuperName

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        var source = arg

        // FIXME: Is this required or can it just be replaced with the evaluate?
        if let args2 = arg as? AMLArgObj {
            guard args2.argIdx < context.args.count else {
                fatalError("Tried to access arg \(args2.argIdx) but only have \(context.args.count) args")
            }
            source = context.args[Int(args2.argIdx)]
        }

        let value = source.evaluate(context: &context)
        name.updateValue(to: value, context: &context)
        return value
    }
}


struct AMLDefSubtract: AMLType2Opcode {
    // SubtractOp Operand Operand Target
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData(op1 &- op2)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefTimer: AMLType2Opcode {

    // TimerOp

    // FIXME: Implement
}


struct AMLDefToBCD: AMLType2Opcode {
    // ToBCDOp Operand Target
    let operand: AMLTermArg // => Integer
    let target: AMLTarget
    var description: String { return "ToBCD(\(operand), \(target)" }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        var value = operandAsInteger(operand: operand, context: &context)
        var bcdValue = AMLInteger(0)
        var idx = 0

        while value != 0 {
            let x = value % 10
            bcdValue |= (x << idx)
            idx += 4
            value /= 10
        }

        let result = AMLIntegerData(bcdValue)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefToBuffer: AMLType2Opcode {

    // ToBufferOp Operand Target
    let operand: AMLTermArg // => Integer
    let target: AMLTarget
    var description: String { return "ToBuffer(\(operand), \(target)" }

    // FIXME: Implement
}


struct AMLDefToDecimalString: AMLType2Opcode {

    // ToDecimalStringOp Operand Target
    let operand: AMLTermArg // => Integer
    let target: AMLTarget

    // FIXME: Implement
}


struct AMLDefToHexString: AMLType2Opcode {

    // ToHexStringOp Operand Target
    let operand: AMLTermArg // => Integer
    let target: AMLTarget


    // FIXME: Implement
}


struct AMLDefToInteger: AMLType2Opcode {
    // ToIntegerOp Operand Target
    let operand: AMLTermArg // => Integer
    let target: AMLTarget


    // FIXME: Implement
}


struct AMLDefToString: AMLType2Opcode {
    // ToStringOp TermArg LengthArg Target
    let arg: AMLTermArg
    let length: AMLTermArg // => Integer
    let target: AMLTarget


    // FIXME: Implement
}


struct AMLDefWait: AMLType2Opcode {
    // WaitOp EventObject Operand
    let object: AMLEventObject
    let operand: AMLTermArg // => Integer


    // FIXME: Implement
}


struct AMLDefXor: AMLType2Opcode {
    // XorOp Operand Operand Target
    let operand1: AMLTermArg // => Integer
    let operand2: AMLTermArg // => Integer
    var target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData(op1 ^ op2)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLMethodInvocation: AMLType2Opcode {
    // NameString TermArgList
    let method: AMLNameString
    let args: AMLTermArgList

    init(method: AMLNameString, args: AMLTermArgList) throws {
        guard args.count < 8 else {
            throw AMLError.invalidData(reason: "More than 7 args")
        }
        self.method = method
        self.args = args
    }

    init(method: AMLNameString, _ args: AMLTermArg...) throws {
        try self.init(method: method, args: args)
    }


    fileprivate func _invokeMethod(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg? {

        let name = self.method.value
        if name == "\\_OSI" || name == "_OSI" {
            return try ACPI._OSI_Method(args)
        }

        guard let globalObjects = system.deviceManager.acpiTables.globalObjects,
            let (obj, fullPath) = globalObjects.getGlobalObject(currentScope: context.scope,
                                                                name: method) else {
                throw AMLError.invalidMethod(reason: "Cant find method: \(name)")
        }
        guard let method = obj as? AMLMethod else {
            throw AMLError.invalidMethod(reason: "\(name) [\(obj.description))] is not an AMLMethod")
        }
        let termList = try method.termList()
        let newArgs = args.map { $0.evaluate(context: &context) }
        var newContext = ACPI.AMLExecutionContext(scope: AMLNameString(fullPath),
                                                  args: newArgs)
        try newContext.execute(termList: termList)
        return newContext.returnValue
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        do {
            if let result = try _invokeMethod(context: &context) {
                context.returnValue = result
                return result
            } else {
                return AMLIntegerData(0)
            }
        } catch {
            fatalError("Cant run method: \(self): \(error)")
        }
    }
}

extension ACPI {

    @discardableResult
    static func invoke(method: String, _ args: AMLTermArg...) throws -> AMLTermArg? {
        let mi = try AMLMethodInvocation(method: AMLNameString(method), args: args)
        var context = ACPI.AMLExecutionContext(scope: mi.method)

        if let result = try mi._invokeMethod(context: &context) {
            context.returnValue = result
            return result
        } else {
            return nil
        }
    }
}
