//
//  kernel/klib/printf.swift
//
//  Created by Simon Evans on 21/04/2017.
//  Copyright © 2017 - 2018 Simon Evans. All rights reserved.
//
//  Simple printf implementation.

// Basic version of printf() so that the klibc version, kprintf(), doesnt have
// to be used. This has a couple of advantages but the main one is that when
// calling a C varargs function, the arguments are allocated in an array on the
// heap. This Swift version has unrolled variants for 0 - 3 arguments that take
// arguments rather than an array with a normal version taking Any... to cover
// the other cases.
// This means that it is possible to call printf() with upto 3 arguments and not
// cause any allocations on the heap (ie no malloc()) calls. This is useful for
// doing printf() debugging where malloc() should not be called (eg in interrupt
// handlers and in a Swift version of malloc()/free())
//
// This version DOES NOT support any floating point or positional arguments used
// for width or argument access (ie no '*' or '$' support). Also pointer
// arguments are not supprted very well (currently via a String(describing:)) so
// cant be used where no malloc()s should happen.
//
// With integers, the size modifiers ('l', 'h') are currently ignored as the
// argument's type is found using 'is' operator. This may change in the future
// if needed.
// Lastly, the non-standard '%@' format is allowed to print any object using
// 'String(describing:)' (as supported by NSString). Again this requires heap
// allocation so cant be used where that is undesired.
//
// The format string is a StaticString to prevent building normal strings and
// using those as insecure format strings although the use of type checks in
// the code make most of the format types irrelevant anyway.
// Width, leading zeros and left alignment are supported by precision currently
// isnt although may be added if it is found to be useful for `%d' and `%x' etc
//
// NOTE: Although UnicodeScalar is used to hold characters, only the ASCII
// subset is supported as these are the only characters that can be displayed
// by the TTY driver so checks are done on the characters/strings to check they
// are ASCII.

//    Syntax of format specifiers in FMT is
//                 `% [FLAGS] [WIDTH] [.PRECISION] [TYPE] CONV'
//    (without the spaces). FLAGS can be any of:
//
//         `-' Left justify the contents of the field.
//         `+' Put a plus character in front of positive signed integers.
//         ` ' Put a space in from of positive signed integers (only if no `+').
//         `#' Put `0' before octal numbers and `0x' or `0X' before hex ones.
//         `0' Pad right-justified fields with zeros, not spaces.
//         `*' NOT SUPPORTED
//
//    WIDTH is a decimal integer defining the field width (for justification
//    purposes). Right justification is the default, use the `-' flag to
//    change this.
//
//    TYPE is an optional type conversion for integer arguments, it can be
//    either `h' to specify a `short int' or `l' to specify a `long int'.
//
//    PRECISION is NOT SUPPORTED
//    CONV defines how to treat the argument, it can be one of:
//
//          'd', 'i'    A signed decimal integer.
//          'u'         An unsigned decimal integer.
//          'b'         Unsigned binary integer.
//          'o'         Unsigned octal integer.
//          'x'         Unsigned hexadecimal integer using lowercase 'a'-'f'
//          'X'         Unsigned heaxdecimal integer using uppercase 'A'-'F'
//          'p'         A pointer, printed in hexadecimal with a preceding
//                          '0x' (i.e. like '%#x') unless the pointer is NULL
//                          when '(nil)' is printed.
//          'c'         A character.
//          's'         A C string. NOT CURRENTLY SUPPORTED
//          '@'         'Any' type rendered using String(describing:)

//
// TODO:  Implement precision and 's' format character
// FIXME: Pointers are not properly supported but could possibly be by using
//        the CVarArg protocol which converts select items to an Int


// A simpler iterator for both an array or arguments and a
// fixed list. This is used for the Array otherwise the
// Array.makeIterator() returns an IndexingIterator<Any>
// which means that the functions below that take an iterator
// need to make generic which results in multiple specialisations.
private struct ArgIterator: IteratorProtocol {
    private var count = 0
    private let argCount: Int
    private let arg1: Any!
    private let arg2: Any!
    private let arg3: Any!
    private let args: [Any]!

    init(count: Int, arg1: Any, arg2: Any, arg3: Any) {
        precondition(count > 0)
        precondition(count < 4)
        argCount = count
        self.arg1 = arg1
        self.arg2 = arg2
        self.arg3 = arg3
        self.args = nil
    }

    init(args: [Any]) {
        self.args = args
        argCount = args.count
        arg1 = nil
        arg2 = nil
        arg3 = nil
    }

    mutating func next() -> Any? {
        if count < argCount {
            count += 1
            if args != nil { return args[count - 1] }
            if count == 1  { return arg1 }
            if count == 2  { return arg2 }
            if count == 3  { return arg3 }
        }
        return nil
    }
}


// This is used to allow the output to go straight to the display as each
// character is generated without using any allocated String buffers.
// In future it may be replaced with a TextOutputStreable type instead.
// Useing a function allows the underlying printf engine to be used for
// sprintf() as well.
protocol UnicodeOutputStream : TextOutputStream {
    mutating func write(_ unicodeScalar: UnicodeScalar)
}


extension String: UnicodeOutputStream {
    mutating func write(_ unicodeScalar: UnicodeScalar) {
        self += String(unicodeScalar)
    }
}

#if !TEST
@inline(never)
func printf(_ format: StaticString, _ arg1: Any) {
    var output = _tty()
    var iterator = ArgIterator(count: 1, arg1: arg1, arg2: 0, arg3: 0)
    _printf(to: &output, format: format, itemsIterator: &iterator)
}

@inline(never)
func printf(_ format: StaticString, _ arg1: Any, _ arg2: Any) {
    var output = _tty()
    var iterator = ArgIterator(count: 2, arg1: arg1, arg2: arg2, arg3: 0)
    _printf(to: &output, format: format, itemsIterator: &iterator)
}

@inline(never)
func printf(_ format: StaticString, _ arg1: Any, _ arg2: Any, _ arg3: Any) {
    var output = _tty()
    var iterator = ArgIterator(count: 3, arg1: arg1, arg2: arg2, arg3: arg3)
    _printf(to: &output, format: format, itemsIterator: &iterator)
}

func printf(_ format: StaticString, _ items: Any...) {
    var output = _tty()
    var iterator = ArgIterator(args: items)
    _printf(to: &output, format: format, itemsIterator: &iterator)
}


func serialPrintf(_ format: StaticString, _ items: Any...) {
    var output = _serial()
    var iterator = ArgIterator(args: items)
    _printf(to: &output, format: format, itemsIterator: &iterator)
}


// Specialised versions of kprintf() than can be used when malloc() should not
// be called. The arguments are Int/UInt not CVarArg as the latter will involve
// metadata cache lookup that then calls malloc().
@inline(__always)
func kprintf(_ format: StaticString, _ arg1: Int) {
    _ = format.utf8Start.withMemoryRebound(to: Int8.self, capacity: format.utf8CodeUnitCount) {
        (ptr: UnsafePointer<Int8>) -> Int32 in
        kprintf1arg(ptr, arg1)
    }
}


@inline(__always)
func kprintf(_ format: StaticString, _ arg1: UInt) {
    _ = format.utf8Start.withMemoryRebound(to: Int8.self, capacity: format.utf8CodeUnitCount) {
        (ptr: UnsafePointer<Int8>) -> Int32 in
        kprintf1arg(ptr, Int(bitPattern: arg1))
    }
}

#endif  // !TEST


// Calling printf with just a format string and no arguments is inefficient,
// espectially since the only formatting characters supported would be '%%'
// so mark the function as unavailable and suggest using print() instead.
@available(*, unavailable,
    message: "printf(formatString) not supported, use print() instead")
func printf(_ format: StaticString) -> Int {
  fatalError("unavailable function cannot be called")
}


extension String {
    static func sprintf(_ format: StaticString, _ items: Any...) -> String {
        var result = ""
        var iterator = ArgIterator(args: items)
        _printf(to: &result, format: format, itemsIterator: &iterator)
        return result
    }
}


private enum FormatChar: UInt8 {
    case startOfFormat   = 37   // '%'

    case object          = 64   // '@'
    case binary          = 98   // 'b'
    case character       = 99   // 'c'
    case signedDecimal   = 100  // 'd'
    case signedInteger   = 105  // 'i'
    case octal           = 111  // 'o'
    case pointer         = 112  // 'p'
    case unsignedDecimal = 117  // 'u'
    case lowerCaseHex    = 120  // 'x'
    case upperCaseHex    = 88   // 'X'

    case space           = 32   // ' '
    case hashSymbol      = 35   // '#'
    case asterisk        = 42   // '*'
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


@inline(never)
@_semantics("optimize.sil.specialize.generic.never")
private func _printf<Target: UnicodeOutputStream>(to output: inout Target,
    format: StaticString,
    itemsIterator: inout ArgIterator) {
    precondition(format.isASCII)

    let buffer = UnsafeBufferPointer(start: format.utf8Start,
        count: format.utf8CodeUnitCount)

    var formatIterator = buffer.makeIterator()

    while let char = formatIterator.next() {
        if let fc = FormatChar(rawValue: char) {
            if fc == .startOfFormat {
                if let char = formatIterator.next() {
                    if let fc = FormatChar(rawValue: char) {
                        dispatchPrint(to: &output, formatChar: fc,
                            itemsIterator: &itemsIterator,
                            formatIterator: &formatIterator)
                        continue
                    }
                    fatalError("Invalid format character \(char)'")
                }
                fatalError("Ran out of format chars")
            }
        }
        output.write(UnicodeScalar(char))
    }
}


// Currently the 'l' and 'h' modifiers are ignored and the Integer type
// determined as below. May be altered to use CVarArg in the future.
// Although this function is only used inside 'dispatchPrint' below it
// is extracted as a seperate function. Originally it was lexically scoped
// inside dispatchPrint and the 'width', 'leftAligned' and 'leadingZero'
// arguments were captured. However because they are 'var' they were allocated
// on the heap. Moving this function outide and passing the argumnts prevents
// this allocation.
@inline(__always)
private func _printUnsigned<Target: UnicodeOutputStream>(to output: inout Target,
    digits: StaticString, radix: UInt, data: Any?, width: Int, leftAligned: Bool,
    leadingZero: Bool) {
    var number: UInt = 0

    if data is Int {
        number = UInt(data as! Int)
    } else if data is UInt8 {
        number = UInt(data as! UInt8)
    } else if data is UInt16 {
        number = UInt(data as! UInt16)
    } else if data is UInt32 {
        number = UInt(data as! UInt32)
    } else if data is UInt64 {
        number = UInt(data as! UInt64)
    } else if data is UInt {
        number = data as! UInt
    } else {
        return
    }

    printUnsigned(to: &output, number: number, radix: radix, digits: digits,
        width: width, leftAligned: leftAligned, leadingZero: leadingZero)
}


@inline(never)
private func dispatchPrint<Target: UnicodeOutputStream>(to output: inout Target,
    formatChar: FormatChar, itemsIterator: inout ArgIterator,
    formatIterator: inout UnsafeBufferPointer<UInt8>.Iterator) {

    let digits: StaticString = "0123456789abcdef"
    //var longModifier = false
    //var shortModifier = false
    //var sizeTModifier = false
    var readingWidth = true
    var alternateForm = false
    var precision = 0

    var leadingZero = false
    var leftAligned = false
    var leadingPlus = false
    var leadingSpace = false
    var width = 0

    var nextChar = formatChar
    while true {
        switch nextChar {

        case .character:
            if let data = itemsIterator.next() as? Int {
                if let ch = UnicodeScalar(data), ch.isASCII {
                    output.write(ch)
                }
            }
            return

        case .signedDecimal, .signedInteger:
            if let data = itemsIterator.next() as? Int {
                printSigned(to: &output, number: data, width: width,
                    digits: digits, leftAligned: leftAligned,
                    leadingZero: leadingZero,
                    leadingPlus: leadingPlus,
                    leadingSpace: leadingSpace)
            }
            return

        case .binary:
            _printUnsigned(to: &output, digits: digits, radix: 2,
                data: itemsIterator.next(), width: width,
                leftAligned: leftAligned, leadingZero: leadingZero)
            return

        case .octal:
            _printUnsigned(to: &output, digits: digits, radix: 8,
                data: itemsIterator.next(), width: width,
                leftAligned: leftAligned, leadingZero: leadingZero)
            return

        case .pointer:
            output.write(FormatChar.zeroDigit.char)
            output.write(FormatChar.lowerCaseHex.char)
            let data = itemsIterator.next()
            _printUnsigned(to: &output, digits: digits, radix: 16,
                data: data, width: width,
                leftAligned: leftAligned, leadingZero: leadingZero)
            return

        case .lowerCaseHex:
            if alternateForm {
                output.write(FormatChar.zeroDigit.char)
                output.write(FormatChar.lowerCaseHex.char)
            }
            _printUnsigned(to: &output, digits: digits, radix: 16,
                data: itemsIterator.next(), width: width,
                leftAligned: leftAligned, leadingZero: leadingZero)
            return

        case .upperCaseHex:
            if alternateForm {
                output.write(FormatChar.zeroDigit.char)
                output.write(FormatChar.upperCaseHex.char)
            }
            _printUnsigned(to: &output, digits: "0123456789ABCDEF", radix: 16,
                data: itemsIterator.next(), width: width,
                leftAligned: leftAligned, leadingZero: leadingZero)
            return

        case .unsignedDecimal:
            _printUnsigned(to: &output, digits: digits, radix: 10,
                data: itemsIterator.next(), width: width,
                leftAligned: leftAligned, leadingZero: leadingZero)
            return

        case .object:
            // This allocates on the heap
            if let data = itemsIterator.next() {
                output.write(String(describing: data))
            }
            return

        case .longModifier: precision += 0 //longModifier = true
        case .shortModifier: precision += 0  //shortModifier = true
        case .sizeTModifier: precision += 0  //sizeTModifier = true

        case .startOfFormat:
            return output.write(FormatChar.startOfFormat.char)

        case .minusSign: leftAligned = true
        case .plusSign:  leadingPlus = true
        case .space:     leadingSpace = true

        case .asterisk:   fatalError("* not supported")
        case .hashSymbol: alternateForm = true
        case .period:     readingWidth = false

        case .zeroDigit:
            if readingWidth {
                if width > 0 {
                    width *= 10
                } else {
                    leadingZero = true
                }
            } else {
                precision *= 10
            }

        case .oneDigit, .twoDigit, .threeDigit, .fourDigit, .fiveDigit,
             .sixDigit, .sevenDigit, .eightDigit, .nineDigit:
            let d = Int(nextChar.rawValue) - 0x30
            if readingWidth {
                width = (width * 10) + d
            } else {
                precision = (precision * 10) + d
                leadingZero = true
            }
        }

        guard let char = formatIterator.next() else {
            fatalError("Ran out of format characters")
        }
        guard let fc = FormatChar(rawValue: char) else {
            fatalError("Invalid format character: \(char)")
        }
        nextChar = fc
    }
}


// Separate versions are used for signed and unsigned since they handle the
// data differently. Unsigned can used difference radix (eg 2, 8, 16) and
// doesnt use a leading '-' or '+'. Signed numbers are always base-10 and
// optionally have '+' etc.
@inline(never)
private func printUnsigned<Target: UnicodeOutputStream>(to output: inout Target,
    number: UInt, radix: UInt, digits: StaticString, width: Int = 0,
    leftAligned: Bool, leadingZero: Bool) {

    precondition(digits.isASCII)
    precondition(digits.utf8CodeUnitCount >= Int(radix))
    precondition(width >= 0)
    precondition(width < 100)  // Safety value

    func _countDigits() -> Int {
        precondition(radix > 1)

        if number == 0 {
            return 1
        }

        var x = number
        var count = 0
        while x != 0 {
            x /= radix
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
            x /= radix
        }

        let val = x % radix
        return UnicodeScalar(digitsBuffer[Int(val)])
    }


    let padChar = leadingZero ? FormatChar.zeroDigit.char : FormatChar.space.char
    let fieldWidth = _countDigits()

    if !leftAligned {
        for _ in stride(from: fieldWidth, to: width, by: 1) {
            output.write(padChar)
        }
    }

    for x in stride(from: fieldWidth - 1, through: 0, by: -1) {
        output.write(digit(at: x))
    }
}


// Prints a base-10 number with a sign if needed
@inline(never)
private func printSigned<Target: UnicodeOutputStream>(to output: inout Target,
    number: Int, width: Int = 0, digits: StaticString, leftAligned: Bool,
    leadingZero: Bool, leadingPlus: Bool,
    leadingSpace: Bool) {
    let radix = 10
    precondition(digits.isASCII)
    precondition(digits.utf8CodeUnitCount >= radix)
    precondition(width >= 0)
    precondition(width < 100)

    func _countDigits() -> Int {
        precondition(radix > 1)

        if number == 0 {
            return 1
        }

        var x = number
        var count = 0
        while x != 0 {
            x /= radix
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
            x /= radix
        }

        let val = x % radix
        let c = val < 0 ? -val : val
        return UnicodeScalar(digitsBuffer[c])
    }


    let padChar = leadingZero ? FormatChar.zeroDigit.char : FormatChar.space.char
    var fieldWidth = _countDigits()

    if number < 0 || leadingPlus || leadingSpace {
        fieldWidth += 1
    }

    if width != 0 && fieldWidth > width {
        fieldWidth = width
    } else {
        for _ in stride(from: fieldWidth, to: width, by: 1) {
            output.write(padChar)
        }
    }

    if number < 0 {
        output.write(FormatChar.minusSign.char)
        fieldWidth -= 1
    } else {
        if leadingPlus {
            output.write(FormatChar.plusSign.char)
            fieldWidth -= 1
        } else if leadingSpace {
            output.write(FormatChar.space.char)
            fieldWidth -= 1
        }
    }

    for x in stride(from: fieldWidth - 1, through: 0, by: -1) {
        output.write(digit(at: x))
    }
}
