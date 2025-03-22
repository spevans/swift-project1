//
//  PrintfInternal.swift
//  Printf
//
//  Created by Simon Evans on 24/09/2024.
//

private enum FormatChar: UInt8 {
    case startOfFormat   = 37   // '%'

    case binary          = 98   // 'b'
    case character       = 99   // 'c'
    case signedDecimal   = 100  // 'd'
    case signedInteger   = 105  // 'i'
    case octal           = 111  // 'o'
    case pointer         = 112  // 'p'
    case string          = 115  // 's'
    case unsignedDecimal = 117  // 'u'
    case lowerCaseHex    = 120  // 'x'
    case upperCaseHex    = 88   // 'X'

    case space           = 32   // ' '
    case hashSymbol      = 35   // '#'
//    case asterisk        = 42   // '*'
    case plusSign        = 43   // '+'
    case minusSign       = 45   // '-'
    case period          = 46   // '.'
    case zeroDigit       = 48   // '0'
    case oneDigit        = 49   // '1'
    case twoDigit        = 50   // '2'
    case threeDigit      = 51   // '3'
    case fourDigit       = 52   // '4'
    case fiveDigit       = 53   // '5'
    case sixDigit        = 54   // '6'
    case sevenDigit      = 55   // '7'
    case eightDigit      = 56   // '8'
    case nineDigit       = 57   // '9'
    case shortModifier   = 104  // 'h'
    case longModifier    = 108  // 'l'
    case sizeTModifier   = 122  // 'z'

    var char: UnicodeScalar { return UnicodeScalar(Int(self.rawValue))! }
}


// The args are unrolled rather than taking a _PrintfArg... as that would allocate
@inline(never)
internal func _printf<Target: UnicodeOutputStream>(to output: inout Target, format: StaticString, _ arg0: _PrintfArg, _ arg1: _PrintfArg?,
                                                   _ arg2: _PrintfArg?, _ arg3: _PrintfArg?, _ arg4: _PrintfArg?, _ arg5: _PrintfArg?, _ arg6: _PrintfArg?,
                                                   _ arg7: _PrintfArg?, _ arg8: _PrintfArg?, _ arg9: _PrintfArg?, _ arg10: _PrintfArg?) throws(PrintfError) {
    precondition(format.isASCII)

    let buffer = UnsafeBufferPointer(start: format.utf8Start,
                                     count: format.utf8CodeUnitCount)

    func arg(_ index: Int) throws(PrintfError) -> _PrintfArg {
        let result: _PrintfArg? = switch index {
            case 0: arg0
            case 1: arg1
            case 2: arg2
            case 3: arg3
            case 4: arg4
            case 5: arg5
            case 6: arg6
            case 7: arg7
            case 8: arg8
            case 9: arg9
            case 10: arg10
            default: nil
        }
        if let result = result { return result }
        throw PrintfError.missingArgument
    }

    var formatIterator = buffer.makeIterator()

    var argIndex = 0
    while let char = formatIterator.next() {
        if let fc = FormatChar(rawValue: char), fc == .startOfFormat {
            guard let char = formatIterator.next() else {
                throw PrintfError.insufficientFormatChars
            }
            if case .startOfFormat = FormatChar(rawValue: char) {
                output.write(FormatChar.startOfFormat.char)
                continue
            }

            guard let fc = FormatChar(rawValue: char) else {
                throw PrintfError.invalidFormatChar(char)
            }

            let arg = try arg(argIndex)
            argIndex += 1
            try dispatchPrint(to: &output, formatChar: fc, item: arg,
                              formatIterator: &formatIterator)
            continue
        }
        output.write(UnicodeScalar(char))
    }
//    guard argIndex == args.count else {
//        throw PrintfError.excessArguments
//    }
}

private struct _PrintfFormat {
    var radix: UInt64 = 10
    var width: Int = 0
    var lowerCaseHex = true
    var leftAligned = false
    var leadingZero = false
    var leadingPlus = false
    var leadingSpace = false
}

// Currently the 'l' and 'h' modifiers are ignored.
private func dispatchPrint<Target: UnicodeOutputStream>(to output: inout Target,
                                                        formatChar: FormatChar, item: _PrintfArg,
                                                        formatIterator: inout UnsafeBufferPointer<UInt8>.Iterator) throws(PrintfError)  {
    var readingWidth = true
    var alternateForm = false
    var precision = 0
    var format = _PrintfFormat()

    var nextChar = formatChar
    while true {
        switch nextChar {

            case .character:
                let ch = try item.characterValue
                output.write(ch)
                return

            case .signedDecimal, .signedInteger:
                format.radix = 10
                let (isNegative, number) = try item.signedValue
                _printNumber(to: &output,
                             isNegative: isNegative,
                             number: number,
                             format: format)
                return

            case .unsignedDecimal:
                format.radix = 10
                try _printNumber(to: &output,
                                 isNegative: false,
                                 number: item.unsignedValue,
                                 format: format)
                return

            case .binary:
                format.radix = 2
                // guard let number = item.unsignedValue else {fatalError()}
                try _printNumber(to: &output,
                                 isNegative: false,
                                 number: item.unsignedValue,
                                 format: format)
                return

            case .octal:
                format.radix = 8
                try _printNumber(to: &output,
                                 isNegative: false,
                                 number: item.unsignedValue,
                                 format: format)
                return

            case .pointer:
                format.radix = 16
                format.lowerCaseHex = true
                output.write(FormatChar.zeroDigit.char)
                output.write(FormatChar.lowerCaseHex.char)
                try _printNumber(to: &output,
                                 isNegative: false,
                                 number: item.unsignedValue,
                                 format: format)
                return

            case .string:
                switch item {
                    case .string(let string):
                        output.write(string)
                    case .staticString(let string):
                        output.write(string)
                    case .bool(let value):
                        output.write(value ? "true" : "false")
                    default: throw .invalidString
                }
                return

            case .lowerCaseHex:
                if alternateForm {
                    output.write(FormatChar.zeroDigit.char)
                    output.write(FormatChar.lowerCaseHex.char)
                }
                format.lowerCaseHex = true
                format.radix = 16
                try _printNumber(to: &output,
                                 isNegative: false,
                                 number: item.unsignedValue,
                                 format: format)
                return

            case .upperCaseHex:
                if alternateForm {
                    output.write(FormatChar.zeroDigit.char)
                    output.write(FormatChar.upperCaseHex.char)
                }
                format.lowerCaseHex = false
                format.radix = 16
                try _printNumber(to: &output,
                                 isNegative: false,
                                 number: item.unsignedValue,
                                 format: format)
                return

            case .longModifier: precision += 0 //longModifier = true
            case .shortModifier: precision += 0  //shortModifier = true
            case .sizeTModifier: precision += 0  //sizeTModifier = true

            case .startOfFormat:
                output.write(FormatChar.startOfFormat.char)
                return

            case .minusSign: format.leftAligned = true
            case .plusSign:  format.leadingPlus = true
            case .space:     format.leadingSpace = true

                //        case .asterisk:   fatalError("* not supported")
            case .hashSymbol: alternateForm = true
            case .period:     readingWidth = false

            case .zeroDigit:
                if readingWidth {
                    if format.width > 0 {
                        format.width *= 10
                    } else {
                        format.leadingZero = true
                    }
                } else {
                    precision *= 10
                }

            case .oneDigit, .twoDigit, .threeDigit, .fourDigit, .fiveDigit,
                    .sixDigit, .sevenDigit, .eightDigit, .nineDigit:
                let d = Int(nextChar.rawValue) - 0x30
                if readingWidth {
                    format.width = (format.width * 10) + d
                } else {
                    precision = (precision * 10) + d
                    format.leadingZero = true
                }
        }

        guard let char = formatIterator.next() else {
            throw .insufficientFormatChars
        }
        guard let fc = FormatChar(rawValue: char) else {
            throw .invalidFormatChar(char)
        }
        nextChar = fc
    }
}



// Prints a number with a sign if needed in a specified radix
private func _printNumber<Target: UnicodeOutputStream>(to output: inout Target, isNegative: Bool, number: UInt64, format: _PrintfFormat) {

    let digits: StaticString = format.lowerCaseHex ? "0123456789abcdef" : "0123456789ABCDEF"
    precondition(format.radix <= 16)
    precondition(format.width >= 0)
    precondition(format.width < 100)


    func _countDigits() -> Int {
        precondition(format.radix > 1)

        if number == 0 {
            return 1
        }

        var x = number
        var count = 0
        while x != 0 {
            x /= format.radix
            count += 1
        }
        return count
    }

    func digit(at: Int) -> UnicodeScalar {
        let digitsBuffer = UnsafeBufferPointer(start: digits.utf8Start,
                                               count: digits.utf8CodeUnitCount)

        precondition(at >= 0)
        var x = number
        for _ in 0..<at {
            x /= format.radix
        }

        let val = x % format.radix
        let c = Int(val)
        return UnicodeScalar(digitsBuffer[c])
    }


    let padChar = format.leadingZero ? FormatChar.zeroDigit.char : FormatChar.space.char
    var fieldWidth = _countDigits()

    if isNegative || format.leadingPlus || format.leadingSpace {
        fieldWidth += 1
    }

    if format.width != 0 && fieldWidth > format.width {
        fieldWidth = format.width
    } else {
        for _ in stride(from: fieldWidth, to: format.width, by: 1) {
            output.write(padChar)
        }
    }

    if isNegative {
        output.write(FormatChar.minusSign.char)
        fieldWidth -= 1
    } else {
        if format.leadingPlus {
            output.write(FormatChar.plusSign.char)
            fieldWidth -= 1
        } else if format.leadingSpace {
            output.write(FormatChar.space.char)
            fieldWidth -= 1
        }
    }

    for x in stride(from: fieldWidth - 1, through: 0, by: -1) {
        output.write(digit(at: x))
    }
}
