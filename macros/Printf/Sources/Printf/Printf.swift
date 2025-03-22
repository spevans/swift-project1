//
//  Printf.swift
//  Printf
//
//  Created by Simon Evans on 23/09/2024.
//  Copyright © Simon Evans. All rights reserved.
//
//  Simple printf implementation.
//

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

//
// TODO:  Implement precision and 's' format character
// FIXME: Pointers are not properly supported but could possibly be by using
//        the CVarArg protocol which converts select items to an Int


@freestanding(expression)
macro kprintf(_ value: StaticString, _ items: PrintfArg...) -> () = #externalMacro(module: "PrintfMacros", type: "PrintfMacro")

@freestanding(expression)
macro sprintf(_ value: StaticString, _ items: PrintfArg...) -> String = #externalMacro(module: "PrintfMacros", type: "PrintfMacro")

@freestanding(expression)
macro serialPrintf(_ value: StaticString, _ items: PrintfArg...) -> () = #externalMacro(module: "PrintfMacros", type: "PrintfMacro")

#if TEST
struct _tty : UnicodeOutputStream {
    mutating func write(_ string: StaticString) {
        if string.utf8CodeUnitCount == 0 { return }
        print(string, terminator: "")
    }

    mutating func write(_ character: Character) {
        print(character, terminator: "")
    }
    mutating func write(_ string: String) {
        if string.isEmpty { return }
        print(string, terminator: "")
    }

    mutating func write(_ unicodeScalar: UnicodeScalar) {
        print(CChar(ch), terminator: "")
    }
}
#endif


enum PrintfError: Error, CustomStringConvertible {
    case invalidNumber
    case invalidString
    case invalidCharacter
    case expectedUnsigned
    case expectedNumber
    case expectedString
    case expectedCharacter
    case insufficientFormatChars
    case insufficientArguments
    case invalidFormatChar(UInt8)
    case missingArgument
    case excessArguments

    var description: String {
        return switch self {
            case .invalidNumber: "Invalid Number"
            case .invalidString: "Invalid String"
            case .invalidCharacter: "Invalid Character"
            case .expectedUnsigned: "Expected an unsigned value"
            case .expectedNumber: "Expected a number"
            case .expectedString: "Expected a string"
            case .expectedCharacter: "Expected a Character"
            case .insufficientFormatChars: "Insufficient Format Characters"
            case .insufficientArguments: "Insufficient Arguments"
            case .invalidFormatChar(let ch): "Invalid Format Character: \(ch)"
            case .missingArgument: "Missing Argument"
            case .excessArguments: "Excess Arguments"
        }
    }
}

public enum _PrintfArg {
    case signedInteger(Int64)
    case unsignedInteger(UInt64)
    case bool(Bool)
    case pointer(UInt)
    case unicodeScalar(UnicodeScalar)
    case character(Character)
    case string(String)
    case staticString(StaticString)
    
    var unsignedValue: UInt64 {
        get throws(PrintfError) {
            switch self {
                case let .unsignedInteger(value): return value
                case let .pointer(value): return UInt64(value)
                case let .bool(value): return value ? 1 : 0
                default: throw PrintfError.expectedUnsigned
            }
        }
    }

    var signedValue: (Bool, UInt64) {
        get throws(PrintfError) {
            switch self {
                case let .signedInteger(value):
                    return (value < 0, value.magnitude)
                case let .unsignedInteger(value):
                    return (false, value)
                case let .pointer(value):
                    return (false, UInt64(value))
                case let .bool(value):
                    return (false, value ? 1 : 0)
                default: throw PrintfError.invalidNumber
            }
        }
    }

    var characterValue: Character {
        get throws(PrintfError) {
            switch self {
                case .character(let value):
                    return value
                case .bool(let value):
                    return Character(UnicodeScalar(value ? "Y" : "N"))
                case .unsignedInteger(let value):
                    return Character(UnicodeScalar(UInt8(truncatingIfNeeded: value)))

                default: throw PrintfError.expectedCharacter
            }
        }
    }

    var stringValue: String {
        get throws(PrintfError) {
            switch self {
                case let .string(value):
                    return value
                case let .bool(value):
                    return  value ? "true" : "false"
                default: throw PrintfError.expectedString
            }
        }
    }
}


public protocol PrintfArg {
    var _printfArg: _PrintfArg { get }
}

extension Int: PrintfArg {
    public var _printfArg: _PrintfArg { .signedInteger(Int64(self)) }
}

extension Int8: PrintfArg {
    public var _printfArg: _PrintfArg { .signedInteger(Int64(self)) }
}

extension Int16: PrintfArg {
    public var _printfArg: _PrintfArg { .signedInteger(Int64(self)) }
}

extension Int32: PrintfArg {
    public var _printfArg: _PrintfArg { .signedInteger(Int64(self)) }
}

extension Int64: PrintfArg {
    public  var _printfArg: _PrintfArg { .signedInteger(Int64(self)) }
}

extension UInt: PrintfArg {
    public var _printfArg: _PrintfArg { .unsignedInteger(UInt64(self)) }
}

extension UInt8: PrintfArg {
    public var _printfArg: _PrintfArg { .unsignedInteger(UInt64(self)) }
}

extension UInt16: PrintfArg {
    public var _printfArg: _PrintfArg { .unsignedInteger(UInt64(self)) }
}

extension UInt32: PrintfArg {
    public var _printfArg: _PrintfArg { .unsignedInteger(UInt64(self)) }
}

extension UInt64: PrintfArg {
    public var _printfArg: _PrintfArg { .unsignedInteger(UInt64(self)) }
}

extension Bool: PrintfArg {
    public var _printfArg: _PrintfArg { .bool(self) }
}

extension String: PrintfArg {
    public var _printfArg: _PrintfArg { .string(self) }
}

extension Character: PrintfArg {
    public var _printfArg: _PrintfArg { .character(self) }
}

extension StaticString: PrintfArg {
    public var _printfArg: _PrintfArg {
        if self.hasPointerRepresentation {
            .staticString(self)
        } else {
            .unicodeScalar(self.unicodeScalar)
        }
    }
}

extension UnicodeScalar: PrintfArg {
    public var _printfArg: _PrintfArg {
        return .unicodeScalar(self)
    }
}

extension Optional: PrintfArg where Wrapped: _Pointer {
    public var _printfArg: _PrintfArg {
        return switch self {
            case .none: _PrintfArg.pointer(0)
            case .some(let ptr): _PrintfArg.pointer(UInt(bitPattern: ptr))
        }
    }
}

extension UnsafeRawPointer: PrintfArg {
    public var _printfArg: _PrintfArg { _PrintfArg.pointer(UInt(bitPattern: self)) }
}

extension UnsafeMutableRawPointer: PrintfArg {
    public var _printfArg: _PrintfArg { _PrintfArg.pointer(UInt(bitPattern: self)) }
}

extension UnsafePointer: PrintfArg {
    public var _printfArg: _PrintfArg { _PrintfArg.pointer(UInt(bitPattern: self)) }
}

extension UnsafeMutablePointer: PrintfArg {
    public var _printfArg: _PrintfArg { _PrintfArg.pointer(UInt(bitPattern: self)) }
}




// This is used to allow the output to go straight to the display as each
// character is generated without using any allocated String buffers.
// In future it may be replaced with a TextOutputStreamble type instead.
// Useing a function allows the underlying printf engine to be used for
// sprintf() as well.
protocol UnicodeOutputStream {
    mutating func write(_ string: String)
    mutating func write(_ string: StaticString)
    mutating func write(_ unicodeScalar: UnicodeScalar)
    mutating func write(_ character: Character)
}


private struct _sprintfTTY: UnicodeOutputStream {
    private(set) var value = ""

    mutating func write(_ string: String) {
        value += string
    }
    
    mutating func write(_ unicodeScalar: UnicodeScalar) {
        value += String(unicodeScalar)
    }

    mutating func write(_ character: Character) {
        value += String(character)
    }

    mutating func write(_ string: StaticString) {
        string.withUTF8Buffer {
            value += String(decoding: $0, as: UTF8.self)
        }
    }
}


extension String {        
    public static func _sprintf(_ format: StaticString, _ arg0: _PrintfArg, _ arg1: _PrintfArg? = nil, _ arg2: _PrintfArg? = nil, _ arg3: _PrintfArg? = nil,
                         _ arg4: _PrintfArg? = nil, _ arg5: _PrintfArg? = nil, _ arg6: _PrintfArg? = nil, _ arg7: _PrintfArg? = nil,
                         _ arg8: _PrintfArg? = nil, _ arg9: _PrintfArg? = nil, _ arg10: _PrintfArg? = nil) -> String {
        do {
            var output = _sprintfTTY()
            try _printf(to: &output, format: format, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
            return output.value
        } catch  {
            fatalError("_sprintf: Error with format string '\(format)': \(error.description)")
        }
    }
}

#if os(macOS)
import Darwin
#else
import Glibc
#endif

private struct _putcharTTY: UnicodeOutputStream {
    mutating func write(_ string: String) {
        for ch in string.utf8 {
            putchar(Int32(ch))
        }
    }
    
    mutating func write(_ string: StaticString) {
        if string.hasPointerRepresentation {
            string.withUTF8Buffer { buffer in
                for ch in buffer {
                    putchar(Int32(ch))
                }
            }
        } else {
            write(string.unicodeScalar)
        }
    }
    
    mutating func write(_ unicodeScalar: UnicodeScalar) {
        for ch in unicodeScalar.utf8 {
            putchar(Int32(ch))
        }
    }
    
    mutating func write(_ character: Character) {
        for ch in character.utf8 {
            putchar(Int32(ch))
        }
    }
}

public func _printf(_ format: StaticString, _ arg0: _PrintfArg, _ arg1: _PrintfArg? = nil, _ arg2: _PrintfArg? = nil, _ arg3: _PrintfArg? = nil,
                   _ arg4: _PrintfArg? = nil, _ arg5: _PrintfArg? = nil, _ arg6: _PrintfArg? = nil, _ arg7: _PrintfArg? = nil,
                   _ arg8: _PrintfArg? = nil, _ arg9: _PrintfArg? = nil, _ arg10: _PrintfArg? = nil) {

    do {
        var output = _putcharTTY()
        try _printf(to: &output, format: format, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    } catch  {
        fatalError("printf: Error with format string '\(format)': \(error.description)")
    }
}

