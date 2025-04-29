//
//  TestKPrint.swift
//  project1
//
//  Created by Simon Evans on 29/04/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//


@freestanding(expression)
macro kprint(_ item: StaticString, _ items: CustomStringConvertible...) -> () = #externalMacro(module: "PrintfMacros", type: "KPrintStaticStringMacro")

@freestanding(expression)
macro kprint(_ item: CustomStringConvertible, _ items: CustomStringConvertible...) -> () = #externalMacro(module: "PrintfMacros", type: "KPrintStringMacro")

func _kprint(_ string: StaticString) {
    print(string)
}


@inline(never)
@_disfavoredOverload
func _kprint(_ string: String) {
    print(string)
}


@inline(never)
func _kprint(_ firstItem: String, _ items: String..., separator: String = " ",
    terminator: String = "\n") {

    print(firstItem, items, separator: separator, terminator: terminator)
}


@inline(never)
func _kprint(_ firstItem: StaticString, _ items: String..., separator: String = " ",
    terminator: String = "\n") {

    print(firstItem, items, separator: separator, terminator: terminator)
}



@inline(never)
func _kprintf(_ format: StaticString, _ arg0: _PrintfArg, _ arg1: _PrintfArg? = nil, _ arg2: _PrintfArg? = nil, _ arg3: _PrintfArg? = nil, _ arg4: _PrintfArg? = nil, _ arg5: _PrintfArg? = nil, _ arg6: _PrintfArg? = nil,
              _ arg7: _PrintfArg? = nil, _ arg8: _PrintfArg? = nil, _ arg9: _PrintfArg? = nil, _ arg10: _PrintfArg? = nil) {
    do {
        var result = ""
        try _printf(to: &result, format: format, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    } catch {
        fatalError("Error")
    }
}


@inline(never)
func _serialPrint(_ string: StaticString, terminator: String = "\n") {
    print(string, terminator: terminator)
}


@inline(never)
@_disfavoredOverload
func _serialPrint(_ string: String, terminator: String = "\n") {
    print(string, terminator: terminator)
}


@inline(never)
func _serialPrintf(_ format: StaticString, _ arg0: _PrintfArg, _ arg1: _PrintfArg? = nil, _ arg2: _PrintfArg? = nil, _ arg3: _PrintfArg? = nil, _ arg4: _PrintfArg? = nil, _ arg5: _PrintfArg? = nil, _ arg6: _PrintfArg? = nil,
                   _ arg7: _PrintfArg? = nil, _ arg8: _PrintfArg? = nil, _ arg9: _PrintfArg? = nil, _ arg10: _PrintfArg? = nil) {
    do {
        var result = ""
        try _printf(to: &result, format: format, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
        print(result)
    } catch {
        fatalError("Error")
    }
}
