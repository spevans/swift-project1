/*
 * kernel/klib/kprint.swift
 *
 * Created by Simon Evans on 25/04/2025.
 * Copyright © 2025 Simon Evans. All rights reserved.
 *
 */


@freestanding(expression)
macro kprint(_ item: StaticString, _ items: CustomStringConvertible..., separator: String = " ", terminator: String = "\n") -> () = #externalMacro(module: "PrintfMacros", type: "KPrintStaticStringMacro")

@freestanding(expression)
macro kprint(_ item: CustomStringConvertible, _ items: CustomStringConvertible..., separator: String = " ", terminator: String = "\n") -> () = #externalMacro(module: "PrintfMacros", type: "KPrintStringMacro")


@freestanding(expression)
macro kprintf(_ value: StaticString, _ items: PrintfArg...) -> () = #externalMacro(module: "PrintfMacros", type: "PrintfMacro")

@freestanding(expression)
macro serialPrintf(_ value: StaticString, _ items: PrintfArg...) -> () = #externalMacro(module: "PrintfMacros", type: "PrintfMacro")


private var _tty = _TTY()
private var _serial = _Serial()

// kprint via the C early_tty.c driver. This should avoid any memory allocation
// as the pointer to the string is being passed directly and the single unicode
// scalar case is explictly rejected.
@inline(never)
func _kprint(_ string: StaticString, terminator: String = "\n") {
    _tty.write(string)
    _tty.write(terminator)
}


@inline(never)
func _kprint(_ args: Span<String>, separator: String = " ", terminator: String = "\n") {
    _tty.write(args[0])
    for i in args.indices[1...] {
        _tty.write(separator)
        _tty.write(args[i])
    }
    _tty.write(terminator)
}

func _show_kprintf_error(_ error: PrintfError, forFormat format: StaticString) {
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
func _kprintf(_ format: StaticString, args: Span<_PrintfArg>) {
    do {
        try _printf(to: &_tty, format: format, args: args)
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
func _serialPrintf(_ format: StaticString, args: Span<_PrintfArg>) {
    do {
        try _printf(to: &_serial, format: format, args: args)
    } catch {
        _show_kprintf_error(error, forFormat: format)
    }
}
