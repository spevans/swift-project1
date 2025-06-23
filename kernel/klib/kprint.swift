//
//  kprint.swift
//  project1
//
//  Created by Simon Evans on 25/04/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//

@freestanding(expression)
macro kprint(_ item: StaticString, _ items: CustomStringConvertible...) -> () = #externalMacro(module: "PrintfMacros", type: "KPrintStaticStringMacro")

@freestanding(expression)
macro kprint(_ item: CustomStringConvertible, _ items: CustomStringConvertible...) -> () = #externalMacro(module: "PrintfMacros", type: "KPrintStringMacro")

private var _tty = _TTY()
private var _serial = _Serial()

// kprint via the C early_tty.c driver. This should avoid any memory allocation
// as the pointer to the string is being passed directly and the single unicode
// scalar case is explictly rejected.
@inline(never)
func _kprint(_ string: StaticString) {
    _tty.write(string)
    _tty.write("\n")
}


@inline(never)
@_disfavoredOverload
func _kprint(_ string: String) {
    _tty.write(string)
    _tty.write("\n")
}


@inline(never)
func _kprint(_ firstItem: String, _ items: String..., separator: String = " ",
    terminator: String = "\n") {

    _tty.write(firstItem)
    for item in items {
        _tty.write(separator)
        _tty.write(item)
    }
    _tty.write(terminator)
}


@inline(never)
func _kprint(_ firstItem: StaticString, _ items: String..., separator: String = " ",
    terminator: String = "\n") {

    _tty.write(firstItem)
    for item in items {
        _tty.write(separator)
        _tty.write(item)
    }
    _tty.write(terminator)
}

private func _show_kprintf_error(_ error: PrintfError, forFormat format: StaticString) {
    let msg = switch error {
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
    #kprintf("sprintf: Error with format string '%s': %s\n", format, msg)
}

@inline(never)
func _kprintf(_ format: StaticString, _ arg: _PrintfArg) {
    do {
        try _printf(to: &_tty, format: format, arg, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil)
    } catch {
        _show_kprintf_error(error, forFormat: format)
    }
}


@inline(never)
func _kprintf(_ format: StaticString, _ arg0: _PrintfArg, _ arg1: _PrintfArg? = nil, _ arg2: _PrintfArg? = nil, _ arg3: _PrintfArg? = nil, _ arg4: _PrintfArg? = nil, _ arg5: _PrintfArg? = nil, _ arg6: _PrintfArg? = nil,
              _ arg7: _PrintfArg? = nil, _ arg8: _PrintfArg? = nil, _ arg9: _PrintfArg? = nil, _ arg10: _PrintfArg? = nil) {
    do {
        try _printf(to: &_tty, format: format, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    } catch {
        _show_kprintf_error(error, forFormat: format)
    }
}


@inline(never)
func _serialPrint(_ string: StaticString, terminator: String = "\n") {
    _serial.write(string)
    _serial.write(terminator)
}


@inline(never)
@_disfavoredOverload
func _serialPrint(_ string: String, terminator: String = "\n") {
    _serial.write(string)
    _serial.write(terminator)
}


@inline(never)
func _serialPrintf(_ format: StaticString, _ arg0: _PrintfArg, _ arg1: _PrintfArg? = nil, _ arg2: _PrintfArg? = nil, _ arg3: _PrintfArg? = nil, _ arg4: _PrintfArg? = nil, _ arg5: _PrintfArg? = nil, _ arg6: _PrintfArg? = nil,
                   _ arg7: _PrintfArg? = nil, _ arg8: _PrintfArg? = nil, _ arg9: _PrintfArg? = nil, _ arg10: _PrintfArg? = nil) {
    do {
        try _printf(to: &_serial, format: format, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    } catch {
        _show_kprintf_error(error, forFormat: format)
    }
}
