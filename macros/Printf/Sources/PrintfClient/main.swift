import Printf

#printf("test %d %d %d\n", 1, 2, 3)

let s: String = #sprintf("Using sprintf: %d", 1)
print("s: ", s)

let s2 = #sprintf("Using sprintf: %d", 1)
print("s2: ", s2)


struct _TTY : UnicodeOutputStream {
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
                print(unicodeScalar, terminator: "")
    }
}
var _tty = _TTY()

@freestanding(expression)
macro myTTYprintf(_ value: StaticString, _ items: PrintfArg...) -> () = #externalMacro(module: "PrintfMacros", type: "PrintfMacro")

@freestanding(expression)
macro serialPrintf(_ value: StaticString, _ items: PrintfArg...) -> () = #externalMacro(module: "PrintfMacros", type: "PrintfMacro")


@MainActor func _myTTYprintf(_ format: StaticString, args: Span<_PrintfArg>) {
    do {
        try _printf(to: &_tty, format: format, args: args)
    } catch {
        fatalError("error")
    }
}

@MainActor func _serialPrintf(_ format: StaticString, args: Span<_PrintfArg>) {
    do {
        try _printf(to: &_tty, format: format, args: args)
    } catch {
        fatalError(error.description)
    }
}

#myTTYprintf("This is from myTTYprintf: %d\n", 123)
#serialPrintf("This is from serialPrintf: 0x%x\n", UInt(123))
