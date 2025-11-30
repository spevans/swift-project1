//
//  kernel/devices/acpi/amltype2ocodes.swift
//
//  Created by Simon Evans on 25/11/2017.
//  Copyright © 2017 - 2025 Simon Evans. All rights reserved.
//
//  ACPI Type 2 Opcodes


private func AMLBoolean(_ bool: Bool) -> AMLObject {
    return bool ? AMLObject(AMLInteger.max) : AMLObject(AMLInteger.zero)
}

func operandAsInteger(operand: AMLTermArg,
                      context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLInteger {
    let o = try operand.evaluate(context: &context)
    return try o.asInteger()
}

func operandAsString(operand: AMLTermArg,
                      context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLString {
    let o = try operand.evaluate(context: &context)
    guard let result = o.stringValue else {
        throw AMLError.invalidOperand(reason: "\(operand) does not evaluate to a string")
    }
    return result
}

func operandAsBuffer(operand: AMLTermArg,
                      context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLBuffer {
    let o = try operand.evaluate(context: &context)
    guard let result = o.bufferValue else {
        throw AMLError.invalidOperand(reason: "\(operand) does not evaluate to a buffer")
    }
    return result.asAMLBuffer()
}

func operandAsSharedBuffer(operand: AMLTermArg,
                      context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLSharedBuffer {
    let o = try operand.evaluate(context: &context)
    guard let result = o.bufferValue else {
        throw AMLError.invalidOperand(reason: "\(operand) does not evaluate to a buffer")
    }
    return result
}

enum AMLType2Opcode {
    // AcquireOp MutexObject Timeout
    case amlDefAcquire(AMLTarget, AMLWordData)
    
    // AddOp Operand Operand Target
    case amlDefAdd(AMLTermArg, AMLTermArg, AMLTarget)
    
    // AndOp Operand Operand Target
    case amlDefAnd(AMLTermArg, AMLTermArg, AMLTarget)
    
    // BufferOp PkgLength BufferSize ByteList
    case amlDefBuffer(AMLDefBuffer)
    // ConcatOp Data Data Target
    case amlDefConcat(AMLTermArg, AMLTermArg, AMLTarget)
    // ConcatResOp BufData BufData Target
    case amlDefConcatRes(AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefCondRefOf(AMLTarget, AMLTarget)
    // CopyObjectOp TermArg SimpleName
    
    case amlDefCopyObject(AMLTermArg, AMLTarget)
    // DecrementOp SuperName
    case amlDefDecrement(AMLTarget)
    case amlDefDerefOf(AMLDefDerefOf)
    case amlDefDivide(AMLTermArg, AMLTermArg, AMLTarget, AMLTarget)
    case amlDefFindSetLeftBit(AMLTermArg, AMLTarget)
    case amlDefFindSetRightBit(AMLTermArg, AMLTarget)
    // FromBCDOp BCDValue Target
    case amlDefFromBCD(AMLTermArg, AMLTarget)
    case amlDefIncrement(AMLTarget)
    case amlDefIndex(AMLDefIndex)
    case amlDefLAnd(AMLTermArg, AMLTermArg)
    case amlDefLEqual(AMLTermArg, AMLTermArg)
    case amlDefLGreater(AMLTermArg, AMLTermArg)
    case amlDefLGreaterEqual(AMLTermArg, AMLTermArg)
    case amlDefLLess(AMLTermArg, AMLTermArg)
    case amlDefLLessEqual(AMLTermArg, AMLTermArg)
    case amlDefLNot(AMLTermArg)
    case amlDefLNotEqual(AMLTermArg, AMLTermArg)    
    case amlDefLoad(AMLNameString, AMLTarget)
    case amlDefLoadTable(AMLTermArg, AMLTermArg, AMLTermArg, AMLTermArg, AMLTermArg, AMLTermArg)
    case amlDefLOr(AMLTermArg, AMLTermArg)
    case amlDefMatch(AMLTermArg, AMLByteData, AMLTermArg, AMLByteData, AMLTermArg, AMLTermArg)
    case amlDefMid(AMLTermArg, AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefMod(AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefMultiply(AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefNAnd(AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefNOr(AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefNot(AMLTermArg, AMLTarget)
    case amlDefObjectType(AMLTarget)
    case amlDefOr(AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefPackage(AMLDefPackage)
    case amlDefRefOf(AMLDefRefOf)
    case amlDefShiftLeft(AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefShiftRight(AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefSizeOf(AMLTarget)
    case amlDefStore(AMLTermArg, AMLTarget)
    case amlDefSubtract(AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefTimer
    // ToBCDOp Operand Target
    case amlDefToBCD(AMLTermArg, AMLTarget)
    case amlDefToBuffer(AMLTermArg, AMLTarget)
    // ToDecimalStringOp Operand Target
    case amlDefToDecimalString(AMLTermArg, AMLTarget)
    // ToHexStringOp Operand Target
    case amlDefToHexString(AMLTermArg, AMLTarget)
    case amlDefToInteger(AMLTermArg, AMLTarget)
    case amlDefToString(AMLTermArg, AMLTermArg, AMLTarget)
    case amlDefWait(AMLTarget, AMLTermArg)
    case amlDefXor(AMLTermArg, AMLTermArg, AMLTarget)
    case amlMethodInvocation(AMLMethodInvocation)
    
    
    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        switch self {
            case .amlDefAcquire(_, _):
                // FIXME - implement
                #kprint("Acquiring Mutex")
                return AMLBoolean(false)   // NOT acquired
                
            case .amlDefAdd(let operand1, let operand2, let target):
                let op1 = try operandAsInteger(operand: operand1, context: &context)
                let op2 = try operandAsInteger(operand: operand2, context: &context)
                let result = AMLObject(op1 &+ op2)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefAnd(let operand1, let operand2, let target):
                let op1 = try operandAsInteger(operand: operand1, context: &context)
                let op2 = try operandAsInteger(operand: operand2, context: &context)
                let result = AMLObject(op1 & op2)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefBuffer(let data):
                return try data.evaluate(context: &context)
                
            case .amlDefConcat(let operand1, let operand2, let target):
                return try concat(operand1, operand2, target, &context)
                
            case .amlDefConcatRes(let operand1, let operand2, let target):
                return try concatResource(operand1, operand2, target, &context)
                
            case .amlDefCondRefOf(let name, let target):
                guard let object = try? name.getObject(context: &context), object.externalObject == nil else {
                    return AMLObject(0)
                }
                let reference = AMLObject(object)
                try target.updateValue(to: reference, context: &context)
                return AMLObject(1)
                
            case .amlDefCopyObject(let object, let target):
                let value = try object.dataRefObject(context: &context)
                if try target.getObject(context: &context).isDataRefObject {
                    try target.updateValue(to: value, context: &context)
                } else {
                    throw AMLError.invalidData(reason: "CopyObject: Target is not a DataRefObject")
                }
                return AMLObject(AMLInteger(0))
                
            case .amlDefDecrement(let target):
                let operand = try target.getObject(context: &context)
                let object = operand.isObjectReference ? try operand.dereference() : operand
                guard let value = object.integerValue else {
                    throw AMLError.invalidOperand(reason: "\(target) is not an integer")
                }
                let result = AMLObject(value &- 1)
                if operand.isObjectReference {
                    try operand.updateReferencedValue(to: result)
                } else {
                    try target.updateValue(to: result, context: &context)
                }
                return result
                
            case .amlDefDerefOf(let data):
                return try data.evaluate(context: &context)
                
            case .amlDefDivide(let operand1, let operand2, let quotient, let remainder):
                let dividend = try operandAsInteger(operand: operand1, context: &context)
                let divisor = try operandAsInteger(operand: operand2, context: &context)
                guard divisor != 0 else {
                    throw AMLError.invalidOperand(reason: "Divisor is zero")
                }
                let q = AMLObject(dividend / divisor)
                let r = AMLObject(dividend % divisor)
                try quotient.updateValue(to: q, context: &context)
                try remainder.updateValue(to: r, context: &context)
                return q
                
            case .amlDefFindSetLeftBit(let operand, let target):
                let op = try operandAsInteger(operand: operand, context: &context)
                let value = (op == 0) ? AMLInteger(0) : AMLInteger(op.leadingZeroBitCount + 1)
                let result = AMLObject(value)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefFindSetRightBit(let operand, let target):
                let op = try operandAsInteger(operand: operand, context: &context)
                let value = (op == 0) ? AMLInteger(0) : AMLInteger(op.trailingZeroBitCount + 1)
                let result = AMLObject(value)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefFromBCD(let operand, let target):
                // Operand => Integer
                let bcdValue = try operandAsInteger(operand: operand, context: &context)
                var tmpBcdValue = bcdValue
                var newValue: AMLInteger = 0
                var idx: AMLInteger = 1
                
                while tmpBcdValue != 0 {
                    let bcd = tmpBcdValue & 0xf
                    guard bcd < 10 else {
                        throw AMLError.invalidData(reason: "BCD value \(String(bcdValue, radix: 16)) contains nonBCD \(bcd)")
                    }
                    newValue += AMLInteger(idx * bcd)
                    idx *= 10
                    tmpBcdValue >>= 4
                }
                let result = AMLObject(newValue)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefIncrement(let target):
                let operand = try target.getObject(context: &context)
                let object = operand.isObjectReference ? try operand.dereference() : operand
                guard let value = object.integerValue else {
                    throw AMLError.invalidOperand(reason: "\(target) is not an integer")
                }
                let result = AMLObject(value &+ 1)
                if operand.isObjectReference {
                    try operand.updateReferencedValue(to: result)
                } else {
                    try target.updateValue(to: result, context: &context)
                }
                return result
                
            case .amlDefIndex(let data):
                return try data.evaluate(context: &context)
                
            case .amlDefLAnd(let operand1, let operand2):
                let op1 = try operandAsInteger(operand: operand1, context: &context)
                let op2 = try operandAsInteger(operand: operand2, context: &context)
                return AMLBoolean(op1 != 0 && op2 != 0)
                
            case .amlDefLEqual(let operand1, let operand2):
                let compare = try logicalCompare(context: &context, operand1: operand1, operand2: operand2)
                return AMLBoolean(compare.isEqual)
                
            case .amlDefLGreater(let operand1, let operand2):
                let compare = try logicalCompare(context: &context, operand1: operand1, operand2: operand2)
                return AMLBoolean(compare.isGreaterThan)
                
            case .amlDefLGreaterEqual(let operand1, let operand2):
                let compare = try logicalCompare(context: &context, operand1: operand1, operand2: operand2)
                return AMLBoolean(compare.isGreaterThanOrEqual)
                
            case .amlDefLLess(let operand1, let operand2):
                let compare = try logicalCompare(context: &context, operand1: operand1, operand2: operand2)
                return AMLBoolean(compare.isLessThan)
                
            case .amlDefLLessEqual(let operand1, let operand2):
                let compare = try logicalCompare(context: &context, operand1: operand1, operand2: operand2)
                return AMLBoolean(compare.isLessThanOrEqual)
                
            case .amlDefLNot(let operand):
                let op = try operandAsInteger(operand: operand, context: &context)
                return AMLBoolean(op == 0)
                
            case .amlDefLNotEqual(let operand1, let operand2):
                let compare = try logicalCompare(context: &context, operand1: operand1, operand2: operand2)
                return AMLBoolean(compare.isNotEqual)

                // FIXME Implement
            case .amlDefLoad(let name, let target):
                // LoadOp NameString DDBHandleObject
                guard let (source, _) = context.getObject(named: name) else {
                    throw AMLError.invalidSymbol(reason: name.value)
                }
                let result = AMLObject(AMLInteger.zero)
                try target.updateValue(to: result, context: &context)
                throw AMLError.unimplemented("Load for \(source)")

            case .amlDefLoadTable(let signature, let oemId, let oemTableId, let rootPath, let parameterPath, let parameterData):
                return try loadTable(signature, oemId, oemTableId, rootPath, parameterPath, parameterData, &context)
                
            case .amlDefLOr(let operand1, let operand2):
                let op1 = try operandAsInteger(operand: operand1, context: &context)
                let op2 = try operandAsInteger(operand: operand2, context: &context)
                return AMLBoolean(op1 != 0 || op2 != 0)
                
            case .amlDefMatch(let searchPackage, let operand1, let match1, let operand2, let match2, let startIndex):
                return try findObjectMatch(searchPackage, operand1, match1, operand2, match2, startIndex, &context)
                
            case .amlDefMid(let operand1, let operand2, let operand3, let target):
                // Operand1 => Buffer | String, Operand2 => Integer, Operand3 => Integer
                let object = try operand1.evaluate(context: &context)
                let index = try operandAsInteger(operand: operand2, context: &context)
                let length = try operandAsInteger(operand: operand3, context: &context)
                #kprint("defmid: object: \(object) index: \(index)")
                let result: AMLObject
                if let string = object.stringValue {
                    result = AMLObject(string.subString(offset: index, length: length))
                } else if let buffer = object.bufferValue {
                    result = AMLObject(buffer.subBuffer(offset: index, length: length))
                } else {
                    throw AMLError.invalidData(reason: "\(object) is not a Buffer or String")
                }
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefMod(let operand1, let operand2, let target):
                let dividend = try operandAsInteger(operand: operand1, context: &context)
                let divisor = try operandAsInteger(operand: operand2, context: &context)
                guard divisor != 0 else {
                    throw AMLError.invalidOperand(reason: "Divisor is zero")
                }
                let result = AMLObject(dividend % divisor)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefMultiply(let operand1, let operand2, let target):
                let op1 = try operandAsInteger(operand: operand1, context: &context)
                let op2 = try operandAsInteger(operand: operand2, context: &context)
                let result = AMLObject(op1 &* op2)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefNAnd(let operand1, let operand2, let target):
                let op1 = try operandAsInteger(operand: operand1, context: &context)
                let op2 = try operandAsInteger(operand: operand2, context: &context)
                let result = AMLObject( ~(op1 & op2))
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefNOr(let operand1, let operand2, let target):
                let op1 = try operandAsInteger(operand: operand1, context: &context)
                let op2 = try operandAsInteger(operand: operand2, context: &context)
                let result = AMLObject( ~(op1 | op2))
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefNot(let operand, let target):
                let op = try operandAsInteger(operand: operand, context: &context)
                let result = AMLObject(~op)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefObjectType(let object):
                let obj = try object.getObject(context: &context)
                return AMLObject(obj.objectType)
                
            case .amlDefOr(let operand1, let operand2, let target):
                let op1 = try operandAsInteger(operand: operand1, context: &context)
                let op2 = try operandAsInteger(operand: operand2, context: &context)
                let result = AMLObject(op1 | op2)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefPackage(let data):
                return try data.evaluate(context: &context)
                
            case .amlDefRefOf(let data):
                let result = try data.evaluate(context: &context)
                return result
                
            case .amlDefShiftLeft(let operand, let count, let target):
                let op = try operandAsInteger(operand: operand, context: &context)
                let shiftCount = try operandAsInteger(operand: count, context: &context)
                let result = AMLObject(op << shiftCount)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefShiftRight(let operand, let count, let target):
                let op = try operandAsInteger(operand: operand, context: &context)
                let shiftCount = try operandAsInteger(operand: count, context: &context)
                let result = AMLObject(op >> shiftCount)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefSizeOf(let name):
                let object = try name.getObject(context: &context)
                if let size = object.sizeof() { return AMLObject(size) }
                throw AMLError.invalidData(reason: "Cannot get sizeof fo \(object)")
                
            case .amlDefStore(let operand, let target):
                let value = try operand.evaluate(context: &context)
                try target.updateValue(to: value, context: &context)
                return value
                
            case .amlDefSubtract(let operand1, let operand2, let target):
                let op1 = try operandAsInteger(operand: operand1, context: &context)
                let op2 = try operandAsInteger(operand: operand2, context: &context)
                let result = AMLObject(op1 &- op2)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefTimer:
                throw AMLError.unimplemented("AMLDefTimer")
                
            case .amlDefToBCD(let operand, let target):
                // Operand => Integer
                var value = try operandAsInteger(operand: operand, context: &context)
                var bcdValue = AMLInteger(0)
                var idx = 0
                
                while value != 0 {
                    let x = value % 10
                    bcdValue |= (x << idx)
                    idx += 4
                    value /= 10
                }
                
                let result = AMLObject(bcdValue)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefToBuffer(let operand, let target):
                let data = try operand.evaluate(context: &context)
                let result = AMLObject(try data.asBuffer())
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefToDecimalString(let operand, let target):
                // Operand => Integer
                let data = try operand.evaluate(context: &context)
                
                let value: AMLString
                if let integer = data.integerValue {
                    value = AMLString(integer: integer, radix: 10)
                } else if let string = data.stringValue {
                    value = string
                } else if let buffer = data.bufferValue {
                    let s = buffer.map { String($0, radix: 10) }.joined(separator: ",")
                    value = AMLString(asciiString: s)
                } else {
                    throw AMLError.invalidData(reason: "Cannot convert to \(data)")
                }
                let result = AMLObject(value)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefToHexString(let operand, let target):
                // Operand => Integer
                let data = try operand.evaluate(context: &context)
                let value: AMLString
                if let integer = data.integerValue {
                    value = AMLString(integer: integer, radix: 16)
                } else if let string = data.stringValue {
                    value = string
                } else if let buffer = data.bufferValue {
                    let s = buffer.map { String($0, radix: 16) }.joined(separator: ",")
                    value = AMLString(asciiString: s)
                } else {
                    throw AMLError.invalidData(reason: "Cannot convert to \(data)")
                }
                let result = AMLObject(value)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefToInteger(let operand, let target):
                let value: AMLInteger
                let data = try operand.evaluate(context: &context)
                if let i = data.integerValue {
                    value = i
                } else if let s = data.stringValue {
                    value = try s.asAMLInteger()
                } else if let b = data.bufferValue {
                    value = try b.asAMLInteger()
                } else {
                    throw AMLError.invalidData(reason: "Cannot convert to \(data)")
                }
                let result = AMLObject(value)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefToString(let operand1, let operand2, let target):
                let buffer = try operandAsBuffer(operand: operand1, context: &context)
                let maxLength = try operandAsInteger(operand: operand2, context: &context)
                let string = buffer.asAMLString(maxLength: maxLength)
                let result = AMLObject(string)
                try target.updateValue(to: result, context: &context)
                return result
                
            case .amlDefWait(_, let operand):
                // Object => AMLEventObject, operand => Integer
                let timeout = try operandAsInteger(operand: operand, context: &context)
                throw AMLError.unimplemented("AMLDefWait, timeout\(timeout)")
                
            case .amlDefXor(let operand1, let operand2, let target):
                let op1 = try operandAsInteger(operand: operand1, context: &context)
                let op2 = try operandAsInteger(operand: operand2, context: &context)
                let result = AMLObject(op1 ^ op2)
                try target.updateValue(to: result, context: &context)
                return result
                
            case let .amlMethodInvocation(data):
                return try data.evaluate(context: &context)
        }
    }
    
    private func concat(_ operand1: AMLTermArg, _ operand2: AMLTermArg, _ target: AMLTarget, _ context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        // Operand1 => ComputationalData
        // Operand2 => ComputationalData
        
        let source1 = try operand1.evaluate(context: &context)
        let source2 = try operand2.evaluate(context: &context)
        let result: AMLObject
        
        func asString(_ object: AMLObject) -> AMLString {
            if let string = object.stringValue {
                return string
            }
            else if let integer = object.integerValue {
                return AMLString(integer: integer, radix: 16)
            }
            else if let buffer = object.bufferValue {
                return buffer.asAMLString()
            }
            else {
                return AMLString(asciiString: "[\(source2.description)]")
            }
        }
        
        // Integer
        if let source1Data = source1.integerValue {
            var data = AMLBuffer(integer: source1Data)
            
            if let source2Data = source2.integerValue {
                data.append(contentsOf: AMLBuffer(integer: source2Data))
            }
            else if let source2Data = source2.stringValue {
                data.append(contentsOf: AMLBuffer(integer: try source2Data.asAMLInteger()))
            }
            else if let source2Data = source2.bufferValue {
                data.append(contentsOf: AMLBuffer(integer: try source2Data.asAMLInteger()))
            }
            else {
                throw AMLError.invalidDataConversion
            }
            result = AMLObject(data)
        }
        // String
        else if var source1Data = source1.stringValue {
            source1Data.append(other: asString(source2))
            result = AMLObject(source1Data)
        }
        // Buffer
        else if let source1Data = source1.bufferValue {
            if let source2Data = source2.bufferValue {
                source1Data.append(source2Data)
            }
            else if let source2Data = source2.integerValue {
                source1Data.append(AMLBuffer(integer: source2Data))
            }
            else if let source2Data = source2.stringValue {
                source1Data.append(source2Data.asAMLBuffer())
            }
            else {
                let source2Data = asString(source2).asAMLBuffer()
                source1Data.append(source2Data)
            }
            result = AMLObject(source1Data)
        }
        // Other
        else {
            var source1Data = asString(source1)
            let source2Data = asString(source2)
            source1Data.append(other: source2Data)
            result = AMLObject(source1Data)
        }
        try target.updateValue(to: result, context: &context)
        return result
        
    }
    
    private func concatResource(_ operand1: AMLTermArg, _ operand2: AMLTermArg, _ target: AMLTarget, _ context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        // Operand1 => Buffer, Operand2 => Buffer
        let buf1 = try operandAsBuffer(operand: operand1, context: &context)
        let buf2 = try operandAsBuffer(operand: operand2, context: &context)
        
        // FIXME: iterate validating the individual entries and add an endtag
        let result = AMLBuffer(buf1[0..<buf1.count-2]) + buf2
        
        let newBuffer = AMLObject(result)
        try target.updateValue(to: newBuffer, context: &context)
        return newBuffer
    }
    
    
    private func loadTable(_ signature: AMLTermArg, _ oemId: AMLTermArg, _ oemTableId: AMLTermArg, _ rootPath: AMLTermArg, _ parameterPath: AMLTermArg, _ parameterData: AMLTermArg, _ context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        throw AMLError.unimplemented("AMLDefLoadTable")
    }
    
    
    private func findObjectMatch(_ searchPkg: AMLTermArg, _ match1: AMLByteData, _ operand1: AMLTermArg, _ match2: AMLByteData, _ operand2: AMLTermArg, _ startIndex: AMLTermArg, _ context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        
        enum AMLMatchOpcode: AMLByteData {
            case mtr = 0
            case meq = 1
            case mle = 2
            case mlt = 3
            case mge = 4
            case mgt = 5
        }
      /*
        // MatchOp SearchPkg MatchOpcode Operand MatchOpcode Operand StartIndex
        let package: AMLTermArg // => Package
        let matchOpcode1: AMLMatchOpcode
        let operand1: AMLTermArg // => Integer
        let matchOpcode2: AMLMatchOpcode
        let operand2: AMLTermArg // => Integer
        let startIndex: AMLTermArg // => Integer
        */
        // FIXME: Implement
        throw AMLError.unimplemented("AMLDefMatch")
    }
    
    
    private enum AMLLogicalCompare {
        case equal
        case lessThan
        case greaterThan
        
        init(_ operand1: AMLInteger, _ operand2: AMLInteger) {
            if operand1 < operand2 {
                self = .lessThan
            } else if operand1 > operand2 {
                self = .greaterThan
            } else {
                self = .equal
            }
        }
        
        var isEqual: Bool {
            if case .equal = self {
                return true
            } else {
                return false
            }
        }
        
        var isNotEqual: Bool {
            return !isEqual
        }
        
        var isLessThan: Bool {
            if case .lessThan = self {
                return true
            } else {
                return false
            }
        }
        
        var isGreaterThan: Bool {
            if case .greaterThan = self {
                return true
            } else {
                return false
            }
        }
        
        var isLessThanOrEqual: Bool {
            return !isGreaterThan
        }
        
        var isGreaterThanOrEqual: Bool {
            return !isLessThan
        }
    }
    
    private func logicalCompare(context: inout ACPI.AMLExecutionContext, operand1: AMLTermArg, operand2: AMLTermArg) throws(AMLError) -> AMLLogicalCompare {
        func compareBuffers(buffer1: AMLBuffer, buffer2: AMLBuffer) -> AMLLogicalCompare {
            let count1 = buffer1.count
            let count2 = buffer2.count
            
            let maxIdx = min(count1, count2)
            for index in 0..<maxIdx {
                let byte1 = buffer1[index]
                let byte2 = buffer2[index]
                
                if byte1 < byte2 {
                    return .lessThan
                }
                if byte1 > byte2 {
                    return .greaterThan
                }
            }
            if count1 < count2 {
                return .lessThan
            } else if count1 > count2 {
                return .greaterThan
            } else {
                return .equal
            }
        }
        
        let data1 = try operand1.evaluate(context: &context)
        let data2 = try operand2.evaluate(context: &context)
        
        if let integer = data1.integerValue {
            return try AMLLogicalCompare(integer, data2.asInteger())
        }
        else if let string = data1.stringValue {
            return try compareBuffers(buffer1: string.data, buffer2: data2.asString().data)
        }
        else if let buffer = data1.bufferValue {
            return try compareBuffers(buffer1: buffer.asAMLBuffer(), buffer2: data2.asBuffer())
        }
        throw AMLError.invalidData(reason: "\(data1.description)/\(data2.description) are not logical operands")
    }
}

struct AMLDefBuffer {
    // BufferOp PkgLength BufferSize ByteList
    let bufferSize: AMLTermArg // => Integer
    let byteList: AMLByteList

    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        let size = try operandAsInteger(operand: bufferSize, context: &context)
        let diff = byteList.count - Int(size)

        let resultBuffer: AMLByteList
        if diff > 0 {
            resultBuffer = Array(byteList.prefix(diff))
        } else if diff < 0  {
            resultBuffer = byteList + Array<AMLByteData>(repeating: 0, count: Int(diff.magnitude))
        } else {
            resultBuffer = byteList
        }
        return AMLObject(AMLBuffer(resultBuffer))
    }
}


struct AMLDefDerefOf {
    // DerefOfOp ObjReference
    let operand: AMLTermArg // => ObjectReference | String

    // FIXME: Implement
    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        let object = try operand.evaluate(context: &context)
        if let name = object.stringValue {
            guard let (node, _) = context.getObject(named: AMLNameString(name.asString())) else {
                throw AMLError.invalidData(reason: "Derefof: invalid object: \(name)")
            }
            return node.object
        }
        return try object.dereference()
    }

    func evaluator() -> AMLTarget.Evaluator {
        return { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject in
            return try evaluate(context: &context)
        }
    }

    func updater() -> AMLTarget.Updater {
        return { (newValue: AMLObject, context: inout ACPI.AMLExecutionContext) in
            fatalError("AMLDefDerefOf.update unimplmented")
        }
    }
}


struct AMLDefIndex {
    // IndexOp BuffPkgStrObj IndexValue Target
    let operand1: AMLTermArg // => Buffer, Package or String
    let operand2: AMLTermArg // => Integer
    let target: AMLTarget

    // FIXME: Implement
    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        let object = try operand1.evaluate(context: &context)
        let index = try operandAsInteger(operand: operand2, context: &context)

        guard let bound = object.maxIndex else {
            throw AMLError.invalidData(reason: "Cannot take an index for a \(object)")
        }
        guard index <= bound else {
            throw AMLError.invalidIndex(index: index, bound: bound)
        }
        let objectReference = AMLObject(object, index: index)
        try target.updateValue(to: objectReference, context: &context)
        return objectReference
    }

    func updateValue(to newValue: AMLObject, context: inout ACPI.AMLExecutionContext) throws(AMLError) {
        let object = try operand1.evaluate(context: &context)
        let index = try operandAsInteger(operand: operand2, context: &context)

        try object.updateValue(at: index, to: newValue)
    }

    func evaluator() -> AMLTarget.Evaluator {
        return { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject in
            return try evaluate(context: &context)
        }
    }

    func updater() -> AMLTarget.Updater {
        return { (newValue: AMLObject, context: inout ACPI.AMLExecutionContext) in
            try updateValue(to: newValue, context: &context)
        }
    }
}


// Handles both Package and VarPackage as the only difference is that the package length is a termarg => Integer for the VarPackage
// and a constant for the package
struct AMLDefPackage {
    // PackageOp PkgLength NumElement PackageElementList
    // VarPackageOp PkgLength VarNumElements PackageElementList

    let numElements: AMLTermArg // => Integer
    let packageElementList: [AMLParsedItem]

    // DefPackage
    init(numElements: AMLByteData, packageElementList: [AMLParsedItem]) {
        self.numElements = AMLTermArg(AMLObject(AMLInteger(numElements)))
        self.packageElementList = packageElementList
    }

    init(varNumElements: AMLTermArg, packageElementList: [AMLParsedItem]) {
        self.numElements = varNumElements
        self.packageElementList = packageElementList
    }


    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        let pkgLength = try operandAsInteger(operand: numElements, context: &context)

        let elementCount = min(packageElementList.count, Int(pkgLength))
        let subElements = packageElementList[0..<elementCount]
        var elements: [AMLObject] = []
        elements.reserveCapacity(subElements.count)
        for element in subElements {
            var object: AMLObject?
            switch element {
                case .type2opcode(let opcode):
                    switch opcode {
                        case .amlDefPackage(let package):
                            object = try package.evaluate(context: &context)
                        case .amlDefBuffer(let buffer):
                            object = try buffer.evaluate(context: &context)
                        default: break
                    }
                case .dataRefObject(let data):
                    object = data
                default:
                    break
            }
            if let object = object {
                elements.append(object)
            } else {
                // FIXME - add an enum for pre-evaulated packages to avoid the default cases
                throw AMLError.invalidData(reason: "Invalid package element \(element)")
            }
        }
        return AMLObject(AMLPackage(numElements: Int(pkgLength), elements: elements))
    }
}


struct AMLDefRefOf {
    // RefOfOp SuperName
    let name: AMLTarget

    func evaluate(context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {
        let object = try name.getObject(context: &context)
        let reference =  AMLObject(object)
        return reference
    }

    func updateValue(to: AMLTermArg, context: inout ACPI.AMLExecutionContext) throws(AMLError) {
        throw AMLError.unimplemented("AMLDefRefOf")
    }

    func evaluator() -> AMLTarget.Evaluator {
        return { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject in
            return try evaluate(context: &context)
        }
    }

    func updater() -> AMLTarget.Updater {
        return { (newValue: AMLObject, context: inout ACPI.AMLExecutionContext) in
            fatalError("AMLDefDerefOf.update unimplemented")
        }
    }
}

private func loadDefinitionBlock(from block: AMLObject, context: inout ACPI.AMLExecutionContext) throws(AMLError) -> Bool {

    func getBuffer() throws(AMLError) -> AMLBuffer? {
        if let buffer = block.bufferValue {
            return buffer.asAMLBuffer()
        }
        if block.operationRegionValue != nil {

            throw AMLError.unimplemented("Loading SSDT")
        }
        return nil
    }

    //guard let buffer = try getBuffer() else { return false }
    guard (try getBuffer()) != nil else { return false }

    return false
}
