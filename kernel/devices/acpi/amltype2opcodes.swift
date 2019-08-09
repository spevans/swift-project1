//
//  kernel/devices/acpi/amltype2ocodes.swift
//
//  Created by Simon Evans on 25/11/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  ACPI Type 2 Opcodes

protocol AMLType2Opcode: AMLTermObj, AMLTermArg {
    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg
}


private let AMLIntegerFalse = AMLInteger(0)
private let AMLIntegerTrue = AMLInteger(1)

private func AMLBoolean(_ bool: Bool) -> AMLInteger {
    return bool ? AMLIntegerTrue : AMLIntegerFalse
}


func operandAsInteger(operand: AMLOperand, context: inout ACPI.AMLExecutionContext) -> AMLInteger {
    guard let result = operand.evaluate(context: &context) as? AMLIntegerData else {
        fatalError("\(operand) does not evaluate to an integer")
    }
    return result.value
}


// AMLType2Opcode
typealias AMLTimeout = AMLWordData
struct AMLDefAcquire: AMLType2Opcode {
    // AcquireOp MutexObject Timeout

    let mutex: AMLMutexObject
    let timeout: AMLTimeout

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        // FIXME - implement
        print("Acquiring Mutex:", mutex)
        return AMLIntegerData(AMLBoolean(false))   // acquired
    }
}

typealias AMLOperand = AMLTermArg // => Integer
struct AMLDefAdd: AMLType2Opcode {

    // AddOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData(op1 + op2)
        return result
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let value = evaluate(context: &context)
        target.updateValue(to: value, context: &context)
        return value
    }
}


struct AMLDefAnd: AMLType2Opcode {

    // AndOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let result = AMLIntegerData(op1 & op2)
        target.updateValue(to: result, context: &context)
        return result
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let value = evaluate(context: &context)
        target.updateValue(to: value, context: &context)
        return value
    }
}


struct AMLBuffer: AMLBuffPkgStrObj, AMLType2Opcode, AMLComputationalData {
    var isReadOnly: Bool { return true }

    // BufferOp PkgLength BufferSize ByteList
    let size: AMLTermArg // => Integer
    let value: AMLByteList


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        guard let result = size.evaluate(context: &context) as? AMLIntegerData else {
            fatalError("\(size) does not evaluate to an integer")
        }
        return result
    }
}


typealias AMLData = AMLTermArg // => ComputationalData
struct AMLDefConcat: AMLType2Opcode {

    // ConcatOp Data Data Target
    let data1: AMLData
    let data2: AMLData
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


typealias AMLBufData = AMLTermArg // =>
struct AMLDefConcatRes: AMLType2Opcode {

    // ConcatResOp BufData BufData Target
    let data1: AMLBufData
    let data2: AMLBufData
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        guard let buf1 = data1.evaluate(context: &context) as? AMLBuffer,
            let buf2 = data2.evaluate(context: &context) as? AMLBuffer else {
                fatalError("cant evaulate to buffers")
        }
        // Fixme, iterate validating the individual entries and add an endtag
        let result = Array(buf1.value[0..<buf1.value.count-2]) + buf2.value

        let newBuffer = AMLBuffer(size: AMLIntegerData(AMLInteger(result.count)), value: result)
        target.updateValue(to: newBuffer, context: &context)
        return newBuffer
    }
}

///ObjReference := TermArg => ObjectReference | String
//ObjectReference :=  Integer
struct AMLDefCondRefOf: AMLType2Opcode {


    // CondRefOfOp SuperName Target
    let name: AMLSuperName
    var target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        guard let n = name as? AMLNameString else {
            return AMLIntegerData(0)
        }
        guard let (obj, _) = context.globalObjects.getGlobalObject(currentScope: context.scope,
                                                                   name: n) else {
                                                                    return AMLIntegerData(0)
        }
        // FIXME, do the store into the target
        //target.value = obj
        print(String(describing: obj))
        return AMLIntegerData(1)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefCopyObject: AMLType2Opcode {

    // CopyObjectOp TermArg SimpleName
    let object: AMLTermArg
    let target: AMLSimpleName


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let value = evaluate(context: &context)
        target.updateValue(to: value, context: &context)
        return value
    }
}


struct AMLDefDecrement: AMLType2Opcode {

    // DecrementOp SuperName
    let target: AMLSuperName

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        guard let result = target.evaluate(context: &context) as? AMLIntegerData else {
            fatalError("\target) is not an integer")
        }
        return AMLIntegerData(result.value &- 1)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let value = evaluate(context: &context)
        target.updateValue(to: value, context: &context)
        return value
    }
}


struct AMLDefDerefOf: AMLType2Opcode, AMLType6Opcode {
    // DerefOfOp ObjReference
    let name: AMLSuperName


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("Cant update \(self) to \(to)")
    }
}


typealias AMLDividend = AMLTermArg // => Integer
typealias AMLDivisor = AMLTermArg // => Integer
struct AMLDefDivide: AMLType2Opcode {

    // DivideOp Dividend Divisor Remainder Quotient
    let dividend: AMLDividend
    let divisor: AMLDivisor
    let remainder: AMLTarget
    let quotient: AMLTarget


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let d1 = operandAsInteger(operand: dividend, context: &context)
        let d2 = operandAsInteger(operand: divisor, context: &context)
        guard d2 != 0 else {
            fatalError("divisor is 0")
        }
        let q = AMLIntegerData((d1 / d2))
        return q
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
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
    let operand: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefFindSetRightBit: AMLType2Opcode {

    // FindSetRightBitOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


typealias AMLBCDValue = AMLTermArg //=> Integer
struct AMLDefFromBCD: AMLType2Opcode {

    // FromBCDOp BCDValue Target
    let value: AMLBCDValue
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefIncrement: AMLType2Opcode {

    // IncrementOp SuperName
    let target: AMLSuperName


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        guard let result = target.evaluate(context: &context) as? AMLIntegerData else {
            fatalError("\target) is not an integer")
        }
        return AMLIntegerData(result.value &+ 1)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let value = evaluate(context: &context)
        target.updateValue(to: value, context: &context)
        return value
    }
}


struct AMLDefIndex: AMLType2Opcode, AMLType6Opcode {

    // IndexOp BuffPkgStrObj IndexValue Target
    let object: AMLBuffPkgStrObj // => Buffer, Package or String
    let index: AMLTermArg // => Integer
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("Cant update \(self) to \(to)")
    }
}


struct AMLDefLAnd: AMLType2Opcode {
    // LandOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 != 0 && op2 != 0)
        return AMLIntegerData(value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
    }
}


struct AMLDefLEqual: AMLType2Opcode {
    // LequalOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 == op2)
        return AMLIntegerData(value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
    }
}


struct AMLDefLGreater: AMLType2Opcode {
    // LgreaterOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 < op2)
        return AMLIntegerData(value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
    }
}


struct AMLDefLGreaterEqual: AMLType2Opcode {
    // LgreaterEqualOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 >= op2)
        return AMLIntegerData(value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
    }
}


struct AMLDefLLess: AMLType2Opcode {
    // LlessOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 < op2)
        return AMLIntegerData(value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
    }
}


struct AMLDefLLessEqual: AMLType2Opcode {
    // LlessEqualOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 <= op2)
        return AMLIntegerData(value)
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
    }
}


struct AMLDefLNot: AMLType2Opcode {
    // LnotOp Operand
    let operand: AMLOperand

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let value = AMLBoolean(op == 0)
        return AMLIntegerData(value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
    }
}


struct AMLDefLNotEqual: AMLType2Opcode {

    // LnotEqualOp Operand Operand
    let operand1: AMLTermArg
    let operand2: AMLTermArg


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLoadTable: AMLType2Opcode {

    // LoadTableOp TermArg TermArg TermArg TermArg TermArg TermArg
    let arg1: AMLTermArg
    let arg2: AMLTermArg
    let arg3: AMLTermArg
    let arg4: AMLTermArg
    let arg5: AMLTermArg
    let arg6: AMLTermArg


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefLOr: AMLType2Opcode {
    // LorOp Operand Operand
    let operand1: AMLOperand
    let operand2: AMLOperand

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = AMLBoolean(op1 != 0 || op2 != 0)
        return AMLIntegerData(value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
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
    let operand1: AMLOperand
    let matchOpcode2: AMLMatchOpcode
    let operand2: AMLOperand
    let startIndex: AMLTermArg // => Integer


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefMid: AMLType2Opcode {

    // MidOp MidObj TermArg TermArg Target
    let obj: AMLTermArg // => Buffer | String
    let arg1: AMLTermArg
    let arg2: AMLTermArg
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefMod: AMLType2Opcode {

    // ModOp Dividend Divisor Target
    let dividend: AMLDividend
    let divisor: AMLDivisor
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefMultiply: AMLType2Opcode {

    // MultiplyOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefNAnd: AMLType2Opcode {

    // NandOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefNOr: AMLType2Opcode {

    // NorOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefNot: AMLType2Opcode {
    // NotOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        return AMLIntegerData(~op)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefObjectType: AMLType2Opcode {

    // ObjectTypeOp <SimpleName | DebugObj | DefRefOf | DefDerefOf | DefIndex>
    let object: AMLSuperName


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefOr: AMLType2Opcode {
    // OrOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        return AMLIntegerData(op1 | op2)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        return evaluate(context: &context)
    }

}


typealias AMLPackageElement = AMLDataRefObject
typealias AMLPackageElementList = [AMLPackageElement]
struct AMLDefPackage: AMLBuffPkgStrObj, AMLType2Opcode, AMLDataObject, AMLTermArg {
    func canBeConverted(to: AMLDataRefObject) -> Bool {
        return false
    }

    var isReadOnly: Bool { return false }

    // PackageOp PkgLength NumElements PackageElementList
    //let pkgLength: AMLPkgLength
    let numElements: AMLByteData
    let elements: AMLPackageElementList

    var value: AMLPackageElementList { return elements }
    let asInteger: AMLInteger? = nil
    let resultAsInteger: AMLInteger? = nil


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


typealias AMLDefVarPackage = AMLDataRefObject


struct AMLDefRefOf: AMLType2Opcode, AMLType6Opcode {
    // RefOfOp SuperName
    let name: AMLSuperName


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) {
        fatalError("cant update \(self) to \(to)")
    }
}


typealias AMLShiftCount = AMLTermArg //=> Integer
struct AMLDefShiftLeft: AMLType2Opcode {
    // ShiftLeftOp Operand ShiftCount Target
    let operand: AMLOperand
    let count: AMLShiftCount
    let target: AMLTarget


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let shiftCount = operandAsInteger(operand: count, context: &context)
        let value = op << shiftCount
        return AMLIntegerData(value)
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let result = evaluate(context: &context)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefShiftRight: AMLType2Opcode {
    // ShiftRightOp Operand ShiftCount Target
    let operand: AMLOperand
    let count: AMLShiftCount
    let target: AMLTarget


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op = operandAsInteger(operand: operand, context: &context)
        let shiftCount = operandAsInteger(operand: count, context: &context)
        let value = op >> shiftCount
        return AMLIntegerData(value)
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let result = evaluate(context: &context)
        target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefSizeOf: AMLType2Opcode {

    // SizeOfOp SuperName
    let name: AMLSuperName


    func execute(context: inout ACPI.AMLExecutionContext) throws  -> AMLTermArg{
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefStore: AMLType2Opcode {

    // StoreOp TermArg SuperName
    let arg: AMLTermArg
    let name: AMLSuperName

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        var source = arg
        if let args2 = arg as? AMLArgObj {
            guard args2.argIdx < context.args.count else {
                fatalError("Tried to access arg \(args2.argIdx) but only have \(context.args.count) args")
            }
            source = context.args[Int(args2.argIdx)]
        }
        let v = source.evaluate(context: &context)

        if let obj = name as? AMLDataRefObject {
            //obj.updateValue(to: source, context: &context)
            //return source
            obj.updateValue(to: v, context: &context)
            return v
        }

        if let localObj = name as? AMLLocalObj {
            context.localObjects[localObj.argIdx] = v
            return v

        }
        guard let sname = name as? AMLNameString else {
            throw AMLError.invalidData(reason: "\(name) is not a string")
        }
        guard let (dest, fullPath) = context.globalObjects.getGlobalObject(currentScope: context.scope,
                                                                           name: sname) else {
                                                                            fatalError("Cant find \(sname)")
        }
        // guard let target = dest.object as? AMLDataRefObject else {
        //     fatalError("dest not an AMLDataRefObject")
        // }

        // FIXME: Shouldnt be here
        //guard var namedObject = dest.object else {
        //    fatalError("Cant find namedObj: \(sname)")
        //}
        //  guard source.canBeConverted(to: target) else {
        //      fatalError("\(source) can not be converted to \(target)")
        //  }
        let resolvedScope = AMLNameString(fullPath).removeLastSeg()
        var tmpContext = ACPI.AMLExecutionContext(scope: resolvedScope,
                                                  args: context.args,
                                                  globalObjects: context.globalObjects)

        if let no = dest.object as? AMLNamedObj {
            no.updateValue(to: source, context: &tmpContext)
        }
        else if let no = dest.object as? AMLDataRefObject {
            no.updateValue(to: source, context: &tmpContext)
        } else if let no = dest.object as? AMLDefName {
            no.value.updateValue(to: source, context: &tmpContext)
        } else {
            fatalError("Cant store \(source) into \(String(describing: dest.object))")
        }

        return v
    }
}


struct AMLDefSubtract: AMLType2Opcode {

    // SubtractOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    let target: AMLTarget


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = op1 &- op2
        return AMLIntegerData(value)
    }

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let result = evaluate(context: &context)
        //target.updateValue(to: result, context: &context)
        return result
    }
}


struct AMLDefTimer: AMLType2Opcode {

    // TimerOp
    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToBCD: AMLType2Opcode {

    // ToBCDOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
    var description: String { return "ToBCD(\(operand), \(target)" }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToBuffer: AMLType2Opcode {

    // ToBufferOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget
    var description: String { return "ToBuffer(\(operand), \(target)" }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToDecimalString: AMLType2Opcode {

    // ToDecimalStringOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget

    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToHexString: AMLType2Opcode {

    // ToHexStringOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToInteger: AMLType2Opcode {

    // ToIntegerOp Operand Target
    let operand: AMLOperand
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefToString: AMLType2Opcode {

    // ToStringOp TermArg LengthArg Target
    let arg: AMLTermArg
    let length: AMLTermArg // => Integer
    let target: AMLTarget


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefWait: AMLType2Opcode {
    // WaitOp EventObject Operand
    let object: AMLEventObject
    let operand: AMLOperand


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        throw AMLError.unimplemented("\(type(of: self))")
    }
}


struct AMLDefXor: AMLType2Opcode {
    // XorOp Operand Operand Target
    let operand1: AMLOperand
    let operand2: AMLOperand
    var target: AMLTarget


    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        let op1 = operandAsInteger(operand: operand1, context: &context)
        let op2 = operandAsInteger(operand: operand2, context: &context)
        let value = op1 ^ op2
        return AMLIntegerData(value)
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws  -> AMLTermArg{
        throw AMLError.unimplemented("\(type(of: self))")
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


    private func _invokeMethod(invocation: AMLMethodInvocation,
                               context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg? {

        let name = invocation.method.value
        if name == "\\_OSI" || name == "_OSI" {
            return try ACPI._OSI_Method(invocation.args)
        }

        guard let (obj, fullPath) = context.globalObjects.getGlobalObject(currentScope: context.scope,
                                                                          name: invocation.method) else {
            throw AMLError.invalidMethod(reason: "Cant find method: \(name)")
        }
        guard let method = obj.object as? AMLMethod else {
            throw AMLError.invalidMethod(reason: "\(name) [\(String(describing:obj.object))] is not an AMLMethod")
        }
        let termList = try method.termList()
        let newArgs = invocation.args.map { $0.evaluate(context: &context) }
        var newContext = ACPI.AMLExecutionContext(scope: AMLNameString(fullPath),
                                                  args: newArgs,
                                                  globalObjects: context.globalObjects)
        try newContext.execute(termList: termList)
        context.returnValue = newContext.returnValue
        return context.returnValue
    }


    func execute(context: inout ACPI.AMLExecutionContext) throws -> AMLTermArg {
        let returnValue = try _invokeMethod(invocation: self, context: &context)

        context.returnValue = returnValue
        guard let retval = returnValue else {
            return AMLIntegerData(0)
        }
        return retval
    }

    func evaluate(context: inout ACPI.AMLExecutionContext) -> AMLTermArg {
        do {
            if let result = try _invokeMethod(invocation: self, context: &context) {
                return result
            }
        } catch {
            fatalError("cant evaluate: \(self): \(error)")
        }
        fatalError("Failed to evaluate \(self)")
    }
}

