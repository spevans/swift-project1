import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import Printf

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(PrintfMacros)
import PrintfMacros

let testMacros: [String: Macro.Type] = [
    "printf": PrintfMacro.self,
    "kprintf": PrintfMacro.self,
    "sprintf": PrintfMacro.self,
    "uhciDebug": DebugMacro.self,
    "kprint": KPrintStringMacro.self
]

#endif

// A minimal UnicodeOutputStream that accumulates output into a String, used
// by the directPrintf helpers to exercise _printf without going through the
// public fatalError-wrapping entry points.
private struct StringWriter: UnicodeOutputStream {
    private(set) var value = ""
    mutating func write(_ string: String)         { value += string }
    mutating func write(_ string: StaticString)   {
        string.withUTF8Buffer { value += String(decoding: $0, as: UTF8.self) }
    }
    mutating func write(_ scalar: UnicodeScalar)  { value += String(scalar) }
    mutating func write(_ character: Character)   { value += String(character) }
}


// Call the Span-based internal _printf overload and return the output.
// Accepts a plain Array so callers don't have to manage InlineArray sizes.
private func directPrintf(format: StaticString, args: [_PrintfArg]) throws -> String {
    var w = StringWriter()
    try _printf(to: &w, format: format, args: args.span)
    return w.value
}


final class PrintfTests: XCTestCase {
    func testMacro() throws {
        #if canImport(PrintfMacros)
        assertMacroExpansion(
            """
            #printf("This is a formatted string")
            """,
            expandedSource: """
            _printf("This is a formatted string")
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithArg() throws {
        #if canImport(PrintfMacros)
        assertMacroExpansion(
            """
            #printf("count: %d", 1)
            """,
            expandedSource: """
            _printf("count: %d", args: ([(1)._printfArg] as InlineArray<1, _PrintfArg>).span)
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testMacroWithArgs() throws {
#if canImport(PrintfMacros)
        assertMacroExpansion(
            """
            let d = UInt64(1)
            #kprintf("val: %d hex: %x neg: %d", 1, d, Int8(-123))
            """,
            expandedSource: """
            let d = UInt64(1)
            _kprintf("val: %d hex: %x neg: %d", args: ([(1)._printfArg, (d)._printfArg, (Int8(-123))._printfArg] as InlineArray<3, _PrintfArg>).span)
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testTooFewArguments() throws {
#if canImport(PrintfMacros)
        assertMacroExpansion(
            """
            #kprintf("%d and %d", 1)
            """,
            expandedSource: """
            _kprintf("%d and %d", args: ([(1)._printfArg] as InlineArray<1, _PrintfArg>).span)
            """,
            diagnostics: [
                DiagnosticSpec(message: "format has 2 specifiers but only 1 argument provided",
                               line: 1, column: 10, severity: .error)
            ],
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testTooManyArguments() throws {
#if canImport(PrintfMacros)
        assertMacroExpansion(
            """
            #kprintf("only %d here", 1, 2, 3)
            """,
            expandedSource: """
            _kprintf("only %d here", args: ([(1)._printfArg, (2)._printfArg, (3)._printfArg] as InlineArray<3, _PrintfArg>).span)
            """,
            diagnostics: [
                DiagnosticSpec(message: "format has 1 specifier but 3 arguments provided",
                               line: 1, column: 10, severity: .error)
            ],
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testSprintf() throws {
#if canImport(PrintfMacros)
        assertMacroExpansion(
            """
            let d = UInt64(1)
            #sprintf("%d %x %d", 1, d, Int8(-123))
            """,
            expandedSource: """
            let d = UInt64(1)
            String._sprintf("%d %x %d", args: ([(1)._printfArg, (d)._printfArg, (Int8(-123))._printfArg] as InlineArray<3, _PrintfArg>).span)
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
        let nptr: UnsafeMutableRawPointer? = nil
        let x = #sprintf("This is a %d [%p], %p, %p", 123, UnsafeRawPointer(bitPattern: 255), nptr, UnsafeMutableRawPointer(bitPattern: 1)!)
        XCTAssertEqual(x, "This is a 123 [0xff], 0x0, 0x1")
        let gdt = #sprintf("GDT: %s Info: %#x/%u\n", "Current", UInt(123), UInt(32))
        XCTAssertEqual(gdt, "GDT: Current Info: 0x7b/32\n")
        let string = #sprintf("This is an emoji '%c'", Character("👬"))
        XCTAssertEqual(string, "This is an emoji '👬'")
    }

    func testFormatSpecifiers() throws {
        // %d / %i — signed decimal
        XCTAssertEqual(#sprintf("%d", 0),          "0")
        XCTAssertEqual(#sprintf("%d", 42),         "42")
        XCTAssertEqual(#sprintf("%d", -42),        "-42")
        XCTAssertEqual(#sprintf("%i", 42),         "42")
        XCTAssertEqual(#sprintf("%i", -1),         "-1")

        // %u — unsigned decimal
        XCTAssertEqual(#sprintf("%u", UInt(0)),    "0")
        XCTAssertEqual(#sprintf("%u", UInt(42)),   "42")

        // %b — binary
        XCTAssertEqual(#sprintf("%b", UInt(0)),    "0")
        XCTAssertEqual(#sprintf("%b", UInt(5)),    "101")
        XCTAssertEqual(#sprintf("%b", UInt(255)),  "11111111")

        // %o — octal
        XCTAssertEqual(#sprintf("%o", UInt(0)),    "0")
        XCTAssertEqual(#sprintf("%o", UInt(8)),    "10")
        XCTAssertEqual(#sprintf("%o", UInt(255)),  "377")

        // %x — lowercase hex
        XCTAssertEqual(#sprintf("%x", UInt(0)),         "0")
        XCTAssertEqual(#sprintf("%x", UInt(255)),       "ff")
        XCTAssertEqual(#sprintf("%x", UInt(0xCAFE)),    "cafe")

        // %X — uppercase hex
        XCTAssertEqual(#sprintf("%X", UInt(255)),       "FF")
        XCTAssertEqual(#sprintf("%X", UInt(0xCAFE)),    "CAFE")

        // %p — pointer (always prefixed with "0x")
        XCTAssertEqual(#sprintf("%p", UnsafeRawPointer(bitPattern: 0xFF)!), "0xff")
        let nilptr: UnsafeRawPointer? = nil
        XCTAssertEqual(#sprintf("%p", nilptr), "0x0")

        // %c — character; UInt8 is also accepted (truncated to ASCII)
        XCTAssertEqual(#sprintf("%c", Character("A")), "A")
        XCTAssertEqual(#sprintf("%c", Character("z")), "z")
        XCTAssertEqual(#sprintf("%c", UInt8(65)),      "A")

        // %s — string and static string
        XCTAssertEqual(#sprintf("%s", "hello"),       "hello")
        XCTAssertEqual(#sprintf("%s", ""),            "")
        let ss: StaticString = "world"
        XCTAssertEqual(#sprintf("%s", ss),            "world")

        // %% — literal percent, no argument consumed
        XCTAssertEqual(#sprintf("%d%%", 42),     "42%")

        // Width — right-justified, space-padded
        XCTAssertEqual(#sprintf("%8d", 42),         "      42")
        XCTAssertEqual(#sprintf("%8d", -42),        "     -42")
        XCTAssertEqual(#sprintf("%8u", UInt(42)),   "      42")
        XCTAssertEqual(#sprintf("%8x", UInt(255)),  "      ff")

        // Width — right-justified, zero-padded
        XCTAssertEqual(#sprintf("%08d", 42),        "00000042")
        XCTAssertEqual(#sprintf("%08u", UInt(42)),  "00000042")
        XCTAssertEqual(#sprintf("%08x", UInt(255)), "000000ff")
        // Non-standard: zero padding is inserted before the sign character,
        // so the sign appears after the zeros rather than at the far left.
        XCTAssertEqual(#sprintf("%08d", -42),       "00000-42")

        // Sign flags
        XCTAssertEqual(#sprintf("%+d", 42),    "+42")
        XCTAssertEqual(#sprintf("%+d", -42),   "-42")   // minus overrides +
        XCTAssertEqual(#sprintf("% d", 42),    " 42")
        XCTAssertEqual(#sprintf("% d", -42),   "-42")   // minus overrides space

        // Width combined with sign flags
        XCTAssertEqual(#sprintf("%+8d", 42),   "     +42")
        XCTAssertEqual(#sprintf("% 8d", 42),   "      42")

        // Alternate form (%#x / %#X prefixes "0x" / "0X" before the digits)
        XCTAssertEqual(#sprintf("%#x", UInt(0)),    "0x0")
        XCTAssertEqual(#sprintf("%#x", UInt(255)),  "0xff")
        XCTAssertEqual(#sprintf("%#X", UInt(255)),  "0XFF")

        // Size modifiers (h, l, z) are accepted and ignored; type is carried
        // by the _PrintfArg enum, not the modifier character.
        XCTAssertEqual(#sprintf("%ld", 42),        "42")
        XCTAssertEqual(#sprintf("%hd", 42),        "42")
        XCTAssertEqual(#sprintf("%lu", UInt(42)),  "42")
        XCTAssertEqual(#sprintf("%zd", 42),        "42")

        // Multiple specifiers in one format string
        XCTAssertEqual(#sprintf("%d/%d/%d", 2025, 5, 17), "2025/5/17")
        XCTAssertEqual(#sprintf("[%s] = %d", "val", 99),  "[val] = 99")
    }

    func testAdditionalCoverage() throws {
        // Bool args — exercise the .bool case in signedValue, unsignedValue,
        // characterValue, and the %s direct switch.
        XCTAssertEqual(#sprintf("%d", true),   "1")
        XCTAssertEqual(#sprintf("%d", false),  "0")
        XCTAssertEqual(#sprintf("%u", true),   "1")
        XCTAssertEqual(#sprintf("%c", true),   "Y")   // Bool maps to 'Y' / 'N'
        XCTAssertEqual(#sprintf("%c", false),  "N")
        XCTAssertEqual(#sprintf("%s", true),   "true")
        XCTAssertEqual(#sprintf("%s", false),  "false")

        // Passing an unsigned type to %d exercises the .unsignedInteger branch
        // of signedValue (returns isNegative=false with the raw magnitude).
        XCTAssertEqual(#sprintf("%d", UInt(42)), "42")

        // Left-align flag: stored in format.leftAligned but never consulted
        // by _printNumber, so output remains right-aligned.
        XCTAssertEqual(#sprintf("%-8d", 42),   "42      ")

        // Precision (.N): the '.' sets readingWidth=false; non-zero digit
        // in precision position exercises the !readingWidth digit branch
        // (sets precision and leadingZero=true, but precision is otherwise
        // ignored since _printNumber has no precision support).
        XCTAssertEqual(#sprintf("%.5d", 42),   "42")

        // %.0N precision: the '0' after '.' exercises the !readingWidth branch
        // of the zero-digit case (precision *= 10 rather than leadingZero=true).
        XCTAssertEqual(#sprintf("%.05d", 42),  "42")

        // Two-digit width where the second digit is '0': the '1' sets width=1,
        // then the '0' hits the "width > 0" branch of zero-digit parsing and
        // multiplies (format.width *= 10 → 10) rather than setting leadingZero.
        XCTAssertEqual(#sprintf("%10d", 42),   "        42")

        // Width exactly matching the digit count: the padding stride runs
        // zero times, exercising the "no padding needed" else-branch path.
        XCTAssertEqual(#sprintf("%2d", 42),    "42")

        // Width smaller than the digit count: exercises the truncation branch
        // (fieldWidth = format.width) in _printNumber. Non-standard: standard
        // printf never truncates; this implementation clips to the N least-
        // significant digits.
        XCTAssertEqual(#sprintf("%2d", 12345), "45")
    }

    func testErrorPaths() throws {
        // Sanity-check: helpers return correct output on the success path.
        XCTAssertEqual(try directPrintf(format: "%d", args: [.signedInteger(42)]), "42")

        // ── span overload — outer-loop errors ─────────────────────────────

        // Trailing % at end of format string.
        XCTAssertThrowsError(try directPrintf(format: "abc%", args: [.signedInteger(1)])) { error in
            XCTAssertEqual(error as? PrintfError, .insufficientFormatChars)
        }
        // Character after % is not a recognised FormatChar.
        XCTAssertThrowsError(try directPrintf(format: "%q", args: [.signedInteger(1)])) { error in
            XCTAssertEqual(error as? PrintfError, .invalidFormatChar(Character("q").asciiValue!))
        }
        // Fewer args than format specifiers.
        XCTAssertThrowsError(try directPrintf(format: "%d %d", args: [.signedInteger(1)])) { error in
            XCTAssertEqual(error as? PrintfError, .missingArgument)
        }
        // More args than format specifiers.
        XCTAssertThrowsError(try directPrintf(format: "%d", args: [.signedInteger(1), .signedInteger(2)])) { error in
            XCTAssertEqual(error as? PrintfError, .excessArguments)
        }

        // ── span overload — dispatchPrint errors ──────────────────────────

        // Format string ends while dispatchPrint is parsing flags.
        XCTAssertThrowsError(try directPrintf(format: "%-", args: [.signedInteger(42)])) { error in
            XCTAssertEqual(error as? PrintfError, .insufficientFormatChars)
        }
        // Unrecognised character encountered while dispatchPrint is parsing flags.
        XCTAssertThrowsError(try directPrintf(format: "%-~d", args: [.signedInteger(42)])) { error in
            XCTAssertEqual(error as? PrintfError, .invalidFormatChar(Character("~").asciiValue!))
        }

        // ── _PrintfArg accessor errors ─────────────────────────────────────

        // Signed integer passed to %u — unsignedValue throws expectedUnsigned.
        XCTAssertThrowsError(try directPrintf(format: "%u", args: [.signedInteger(-1)])) { error in
            XCTAssertEqual(error as? PrintfError, .expectedUnsigned)
        }
        // String passed to %c — characterValue throws expectedCharacter.
        XCTAssertThrowsError(try directPrintf(format: "%c", args: [.string("hello")])) { error in
            XCTAssertEqual(error as? PrintfError, .expectedCharacter)
        }
        // Signed integer passed to %s — %s handler throws invalidString.
        XCTAssertThrowsError(try directPrintf(format: "%s", args: [.signedInteger(42)])) { error in
            XCTAssertEqual(error as? PrintfError, .invalidString)
        }
        // Character passed to %d — signedValue throws invalidNumber.
        XCTAssertThrowsError(try directPrintf(format: "%d", args: [.character("A")])) { error in
            XCTAssertEqual(error as? PrintfError, .invalidNumber)
        }

        // ── dispatchPrint .startOfFormat case ─────────────────────────────
        // When dispatchPrint encounters a '%' while processing flags it emits
        // a literal '%' and returns, silently discarding the consumed argument.
        // Format "%-%%d": '-' starts dispatchPrint, which reads the first '%'
        // of '%%' as .startOfFormat and outputs '%'.  The outer loop then
        // processes the remaining '%d' with the second argument.
        XCTAssertEqual(
            try directPrintf(format: "%-%%d", args: [.signedInteger(42), .signedInteger(99)]),
            "%99"
        )
    }

    func testKprintString() throws {
#if canImport(PrintfMacros)
        assertMacroExpansion(
            """
            let d = UInt64(1)
            #kprint("This is a string")
            """,
            expandedSource: """
            let d = UInt64(1)
            _kprint((["This is a string".description] as InlineArray<1, String>).span)
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testDebugMacroSingleArg() throws {
#if canImport(PrintfMacros)
        assertMacroExpansion(
            """
            #uhciDebug("did not reset")
            """,
            expandedSource: """
            _uhciDebug((["did not reset".description] as InlineArray<1, String>).span)
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

    func testDebugMacroMultipleArgs() throws {
#if canImport(PrintfMacros)
        assertMacroExpansion(
            """
            let name = "foo"
            let val = 42
            #uhciDebug(name, val)
            """,
            expandedSource: """
            let name = "foo"
            let val = 42
            _uhciDebug(([name.description, (val).description] as InlineArray<2, String>).span)
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }


}

// MARK: - PrintfArg edge cases (UnicodeScalar, StaticString single-scalar, pointer types)
class PrintfArgEdgeCaseTests: XCTestCase {

    func testUnicodeScalarPrintfArg() {
        // Covers UnicodeScalar._printfArg (line 242-244 in printf.swift)
        let scalar: UnicodeScalar = "A"
        let arg = scalar._printfArg
        if case .unicodeScalar(let s) = arg {
            XCTAssertEqual(s, UnicodeScalar("A"))
        } else {
            XCTFail("Expected .unicodeScalar")
        }
    }

    func testStaticStringSingleScalarPrintfArg() {
        // StaticString that is NOT a pointer (single unicode scalar)
        // A single-code-unit StaticString literal should have hasPointerRepresentation == false
        let ss: StaticString = "A"
        let arg = ss._printfArg
        // Either unicodeScalar or staticString — both are valid outcomes
        switch arg {
        case .unicodeScalar, .staticString:
            break  // acceptable
        default:
            XCTFail("Unexpected _PrintfArg case: \(arg)")
        }
    }

    func testUnsafeRawPointerPrintfArg() {
        // Covers UnsafeRawPointer._printfArg (line 269 in printf.swift)
        let bytes: [UInt8] = [1]
        bytes.withUnsafeBytes { raw in
            let ptr = raw.baseAddress!
            let arg = ptr._printfArg
            if case .pointer(let addr) = arg {
                XCTAssertEqual(addr, UInt(bitPattern: ptr))
            } else {
                XCTFail("Expected .pointer")
            }
        }
    }

    func testUnsafeMutableRawPointerPrintfArg() {
        var bytes: [UInt8] = [1]
        bytes.withUnsafeMutableBytes { raw in
            let ptr = raw.baseAddress!
            let arg = ptr._printfArg
            if case .pointer(let addr) = arg {
                XCTAssertEqual(addr, UInt(bitPattern: ptr))
            } else {
                XCTFail("Expected .pointer")
            }
        }
    }

    func testUnsafePointerPrintfArg() {
        let bytes: [UInt8] = [0x42]
        bytes.withUnsafeBytes { raw in
            let ptr = raw.baseAddress!.assumingMemoryBound(to: UInt8.self)
            let arg = ptr._printfArg
            if case .pointer(let addr) = arg {
                XCTAssertEqual(addr, UInt(bitPattern: ptr))
            } else {
                XCTFail("Expected .pointer")
            }
        }
    }

    func testOptionalPointerPrintfArgNil() {
        let opt: UnsafeRawPointer? = nil
        let arg = opt._printfArg
        if case .pointer(let addr) = arg {
            XCTAssertEqual(addr, 0)
        } else {
            XCTFail("Expected .pointer(0)")
        }
    }

    func testOptionalPointerPrintfArgSome() {
        let bytes: [UInt8] = [1]
        bytes.withUnsafeBytes { raw in
            let opt: UnsafeRawPointer? = raw.baseAddress!
            let arg = opt._printfArg
            if case .pointer(let addr) = arg {
                XCTAssertNotEqual(addr, 0)
            } else {
                XCTFail("Expected .pointer")
            }
        }
    }

    func testSignedValueFromPointer() throws {
        // Covers .pointer branch (line 138) of _PrintfArg.signedValue
        let arg = _PrintfArg.pointer(42)
        let (negative, value) = try arg.signedValue
        XCTAssertFalse(negative)
        XCTAssertEqual(value, 42)
    }

    func testStringValueFromBool() throws {
        // Covers .bool branch (line 166-167) of _PrintfArg.stringValue
        let t = _PrintfArg.bool(true)
        XCTAssertEqual(try t.stringValue, "true")
        let f = _PrintfArg.bool(false)
        XCTAssertEqual(try f.stringValue, "false")
    }

    func testStringValueFromString() throws {
        // Covers .string branch (line 164-165) of _PrintfArg.stringValue
        let arg = _PrintfArg.string("hello")
        XCTAssertEqual(try arg.stringValue, "hello")
    }

    func testStringValueThrowsForNonString() {
        // Covers default throw in _PrintfArg.stringValue
        let arg = _PrintfArg.signedInteger(42)
        XCTAssertThrowsError(try { _ = try arg.stringValue }())
    }
}

final class SPrintfTests: XCTestCase {
    // MARK: - Original tests

    func testSprintf() {
        let output1 = #sprintf("Test: %lx", 0x0123456789abcdef as UInt)
        XCTAssertEqual("Test: 123456789abcdef", output1, "`lx' format specifier")

        let output2 = #sprintf("Test: %p", 0x1234567890abcdef as UInt)
        XCTAssertEqual("Test: 0x1234567890abcdef", output2, "'p' format specifier")

        let output3 = #sprintf("R8: %16.16lx", 0x0808_0808_0808_0808 as UInt)
        XCTAssertEqual("R8: 0808080808080808", output3, "'16.16lx' 64bit number")

        let output4 = #sprintf("R8: %016lx", 0x0808080808080808 as UInt)
        XCTAssertEqual("R8: 0808080808080808", output4, "'016lx' 64bit number")

        let output5 = #sprintf("RAX: %#16.16lX", 0xaaaaaaaaaaaaaaaa as UInt64)
        XCTAssertEqual(
            "RAX: 0XAAAAAAAAAAAAAAAA", output5,
            "'#16.16lX' 64bit number high bit set"
        )
    }
    
    // MARK: - #sprintf: signed decimal (%d, %i)
    //
    // Both %d and %i produce a signed decimal integer.  All signed Swift
    // integer types (Int8…Int64, Int) are accepted and widened to Int64
    // internally.
    //
    // Inconsistency vs C printf:
    //   Unsigned integer types are also accepted by %d.  In standard C,
    //   passing an unsigned value larger than INT_MAX to %d is undefined
    //   behaviour.  Here the unsigned bit-pattern is printed without any
    //   sign conversion, producing the decimal string of the unsigned value.

    func testSprintfSignedDecimal() {
        XCTAssertEqual(#sprintf("%d", 0),   "0")
        XCTAssertEqual(#sprintf("%d", 1),   "1")
        XCTAssertEqual(#sprintf("%d", -1),  "-1")
        XCTAssertEqual(#sprintf("%i", 42),  "42")
        XCTAssertEqual(#sprintf("%i", -42), "-42")

        XCTAssertEqual(#sprintf("%d", Int8.min),  "-128")
        XCTAssertEqual(#sprintf("%d", Int8.max),  "127")
        XCTAssertEqual(#sprintf("%d", Int16.min), "-32768")
        XCTAssertEqual(#sprintf("%d", Int16.max), "32767")
        XCTAssertEqual(#sprintf("%d", Int32.min), "-2147483648")
        XCTAssertEqual(#sprintf("%d", Int32.max), "2147483647")
        XCTAssertEqual(#sprintf("%d", Int64.min), "-9223372036854775808")
        XCTAssertEqual(#sprintf("%d", Int64.max), "9223372036854775807")

        // Unsigned values accepted by %d — non-negative, no sign bit.
        XCTAssertEqual(#sprintf("%d", UInt8(255)),  "255")
        XCTAssertEqual(#sprintf("%d", UInt32(0)),   "0")
        XCTAssertEqual(#sprintf("%d", UInt64.max),  "18446744073709551615")
    }

    // MARK: - #sprintf: unsigned decimal (%u)
    //
    // %u accepts UInt8…UInt64 and UInt.  Unlike standard C, signed integer
    // types are NOT accepted — passing a signed value to %u causes a
    // fatalError at runtime (the _PrintfArg.unsignedValue property throws
    // PrintfError.expectedUnsigned for signedInteger cases).
    //
    // Inconsistency vs C printf:
    //   C allows passing a negative signed int to %u via implicit conversion
    //   to unsigned (implementation-defined for negative values in practice
    //   two's complement wrapping).  This implementation rejects it.

    func testSprintfUnsignedDecimal() {
        XCTAssertEqual(#sprintf("%u", 0 as UInt),     "0")
        XCTAssertEqual(#sprintf("%u", 1 as UInt),     "1")
        XCTAssertEqual(#sprintf("%u", UInt8.max),     "255")
        XCTAssertEqual(#sprintf("%u", UInt16.max),    "65535")
        XCTAssertEqual(#sprintf("%u", UInt32.max),    "4294967295")
        XCTAssertEqual(#sprintf("%u", UInt64.max),    "18446744073709551615")

        // Bool is accepted as an unsigned value: true→1, false→0.
        XCTAssertEqual(#sprintf("%u", true),  "1")
        XCTAssertEqual(#sprintf("%u", false), "0")
    }

    // MARK: - #sprintf: hexadecimal (%x, %X)

    func testSprintfHex() {
        // Lowercase hex
        XCTAssertEqual(#sprintf("%x", 0 as UInt),            "0")
        XCTAssertEqual(#sprintf("%x", 0xff as UInt),         "ff")
        XCTAssertEqual(#sprintf("%x", 0xdeadbeef as UInt32), "deadbeef")
        XCTAssertEqual(#sprintf("%x", UInt64.max),           "ffffffffffffffff")

        // Uppercase hex
        XCTAssertEqual(#sprintf("%X", 0 as UInt),            "0")
        XCTAssertEqual(#sprintf("%X", 0xff as UInt),         "FF")
        XCTAssertEqual(#sprintf("%X", 0xdeadbeef as UInt32), "DEADBEEF")
        XCTAssertEqual(#sprintf("%X", UInt64.max),           "FFFFFFFFFFFFFFFF")

        // Alternate form (#): %#x prepends "0x", %#X prepends "0X".
        XCTAssertEqual(#sprintf("%#x", 0xff as UInt),        "0xff")
        XCTAssertEqual(#sprintf("%#X", 0xff as UInt),        "0XFF")
        XCTAssertEqual(#sprintf("%#x", 0xabc as UInt),       "0xabc")

        // Inconsistency vs C: standard printf("%#x", 0) outputs "0" (no
        // prefix when the value is zero).  This implementation always emits
        // the "0x" prefix regardless of value.
        XCTAssertEqual(#sprintf("%#x", 0 as UInt),           "0x0")
    }

    // MARK: - #sprintf: octal (%o)
    //
    // Inconsistency vs C: the '#' alternate-form flag for %o is NOT
    // implemented.  Standard C printf("%#o", 8) outputs "010" (a leading
    // '0' prefix for non-zero values).  This implementation ignores '#'
    // with %o and produces the same output as plain %o.

    func testSprintfOctal() {
        XCTAssertEqual(#sprintf("%o", 0 as UInt),          "0")
        XCTAssertEqual(#sprintf("%o", 1 as UInt),          "1")
        XCTAssertEqual(#sprintf("%o", 8 as UInt),          "10")
        XCTAssertEqual(#sprintf("%o", 255 as UInt),        "377")
        XCTAssertEqual(#sprintf("%o", 0o777 as UInt),      "777")
        XCTAssertEqual(#sprintf("%o", UInt8(0o77)),        "77")

        // '#' flag has no effect on %o — no "0" prefix is prepended.
        XCTAssertEqual(#sprintf("%#o", 0 as UInt),         "0")
        XCTAssertEqual(#sprintf("%#o", 8 as UInt),         "10")   // C: "010"
        XCTAssertEqual(#sprintf("%#o", 0o777 as UInt),     "777")  // C: "0777"
    }

    // MARK: - #sprintf: binary (%b, non-standard extension)
    //
    // %b is absent from POSIX, ISO C, and the C standard library.  It is a
    // local extension that prints the value in base 2.  The '#' alternate-
    // form flag is parsed but — like %o — has no visible effect on %b.

    func testSprintfBinary() {
        XCTAssertEqual(#sprintf("%b", 0 as UInt),                 "0")
        XCTAssertEqual(#sprintf("%b", 1 as UInt),                 "1")
        XCTAssertEqual(#sprintf("%b", 2 as UInt),                 "10")
        XCTAssertEqual(#sprintf("%b", 5 as UInt),                 "101")
        XCTAssertEqual(#sprintf("%b", 0xff as UInt8),             "11111111")
        XCTAssertEqual(#sprintf("%b", 0b1010_1010 as UInt8),      "10101010")
        XCTAssertEqual(#sprintf("%b", 0b1111_0000_1010 as UInt),  "111100001010")
        XCTAssertEqual(#sprintf("%08b", 0b101 as UInt),           "00000101")
    }

    // MARK: - #sprintf: string (%s)
    //
    // %s accepts String, StaticString (pointer-representation only), and
    // Bool.  Width is parsed but has no effect — no padding is applied to
    // string output (inconsistency with C, where printf("%-10s", …) pads
    // with trailing spaces).

    func testSprintfString() {
        XCTAssertEqual(#sprintf("%s", ""),              "")
        XCTAssertEqual(#sprintf("%s", "hello"),         "hello")
        XCTAssertEqual(#sprintf("%s", "Hello, World!"), "Hello, World!")

        // Bool maps to "true" / "false" — non-standard, C has no Bool type.
        XCTAssertEqual(#sprintf("%s", true),  "true")
        XCTAssertEqual(#sprintf("%s", false), "false")

        // StaticString with pointer representation (multi-char) works.
        let ss: StaticString = "static"
        XCTAssertEqual(#sprintf("%s", ss), "static")

        // Width is silently ignored for %s — no trailing/leading padding.
        // C: printf("%10s", "hi") → "        hi" (right-justified)
        // Here: still just "hi"
        XCTAssertEqual(#sprintf("%10s", "hi"), "hi")
        XCTAssertEqual(#sprintf("%-10s", "hi"), "hi")
    }

    // MARK: - #sprintf: character (%c)
    //
    // %c accepts Character, UnsignedInteger (truncated to UInt8 for the
    // code point), and Bool (non-standard: true→'Y', false→'N').
    //
    // Unlike C's %c which is limited to unsigned char (0–255), Swift
    // Character can hold any Unicode scalar; the full Character is written.

    func testSprintfCharacter() {
        XCTAssertEqual(#sprintf("%c", Character("A")),  "A")
        XCTAssertEqual(#sprintf("%c", Character("z")),  "z")
        XCTAssertEqual(#sprintf("%c", Character("0")),  "0")
        XCTAssertEqual(#sprintf("%c", Character("!")),  "!")

        // Non-ASCII Unicode characters work (not possible in C's %c).
        XCTAssertEqual(#sprintf("%c", Character("é")),  "é")
        XCTAssertEqual(#sprintf("%c", Character("👬")), "👬")

        // Unsigned integer → truncate to UInt8, use as ASCII code point.
        XCTAssertEqual(#sprintf("%c", UInt8(65)),        "A")
        XCTAssertEqual(#sprintf("%c", UInt8(0x41)),      "A")
        XCTAssertEqual(#sprintf("%c", UInt16(66)),       "B")
        // High bits are masked off: 0x141 & 0xFF = 0x41 = 'A'
        XCTAssertEqual(#sprintf("%c", UInt16(0x141)),    "A")

        // Bool with %c: 'Y' for true, 'N' for false — non-standard.
        XCTAssertEqual(#sprintf("%c", true),   "Y")
        XCTAssertEqual(#sprintf("%c", false),  "N")
    }

    // MARK: - #sprintf: pointer (%p)
    //
    // %p always prefixes the output with "0x" followed by the lowercase
    // hexadecimal address.
    //
    // Inconsistency vs C: the Printf.swift comment states that a null
    // pointer should print as "(nil)".  This is NOT implemented; a nil
    // optional pointer prints as "0x0" instead.
    //
    // Note: %p accepts any type whose _printfArg is .pointer(…), including
    // UnsafeRawPointer, UnsafeMutableRawPointer, typed pointer variants,
    // optional wrappers of those, and plain UInt/UInt64.

    func testSprintfPointer() {
        // Non-nil raw pointers.
        let raw = UnsafeRawPointer(bitPattern: 0x1234)!
        XCTAssertEqual(#sprintf("%p", raw), "0x1234")

        let mraw = UnsafeMutableRawPointer(bitPattern: 0xabcd)!
        XCTAssertEqual(#sprintf("%p", mraw), "0xabcd")

        let raw64 = UnsafeRawPointer(bitPattern: 0x0000_dead_beef_0000 as UInt)!
        XCTAssertEqual(#sprintf("%p", raw64), "0xdeadbeef0000")

        // Typed pointer.
        var n = 0
        let typed = withUnsafePointer(to: &n) { $0 }
        XCTAssertTrue(#sprintf("%p", typed).hasPrefix("0x"),
            "typed UnsafePointer should print as 0x…")

        // Nil optional pointers print as "0x0", NOT "(nil)".
        let nilRaw: UnsafeRawPointer? = nil
        XCTAssertEqual(#sprintf("%p", nilRaw), "0x0")

        let nilMut: UnsafeMutableRawPointer? = nil
        XCTAssertEqual(#sprintf("%p", nilMut), "0x0")

        // A UInt is accepted by %p (treated as an address).
        XCTAssertEqual(#sprintf("%p", 0 as UInt),    "0x0")
        XCTAssertEqual(#sprintf("%p", 0xff as UInt), "0xff")
    }

    // MARK: - #sprintf: flag '+' (leading plus sign)

    func testSprintfFlagLeadingPlus() {
        XCTAssertEqual(#sprintf("%+d", 0),    "+0")
        XCTAssertEqual(#sprintf("%+d", 42),   "+42")
        XCTAssertEqual(#sprintf("%+d", -42),  "-42")
        XCTAssertEqual(#sprintf("%+i", 1),    "+1")
        XCTAssertEqual(#sprintf("%+i", -1),   "-1")
        // Combined with width.
        XCTAssertEqual(#sprintf("%+5d", 42),  "  +42")
        XCTAssertEqual(#sprintf("%+5d", -42), "  -42")
    }

    // MARK: - #sprintf: flag ' ' (leading space for positive values)

    func testSprintfFlagLeadingSpace() {
        XCTAssertEqual(#sprintf("% d", 0),    " 0")
        XCTAssertEqual(#sprintf("% d", 42),   " 42")
        XCTAssertEqual(#sprintf("% d", -42),  "-42")
        // Combined with width.
        XCTAssertEqual(#sprintf("% 5d", 42),  "   42")
        XCTAssertEqual(#sprintf("% 5d", -42), "  -42")
    }

    // MARK: - #sprintf: flag '0' (zero-pad)
    //
    // Inconsistency vs C: standard C printf("%05d", -42) outputs "-0042"
    // (the sign precedes the zero padding).  This implementation writes the
    // zero padding BEFORE the sign, producing "00-42".

    func testSprintfFlagZeroPad() {
        XCTAssertEqual(#sprintf("%05d", 0),          "00000")
        XCTAssertEqual(#sprintf("%05d", 42),         "00042")
        XCTAssertEqual(#sprintf("%08x", 0xff as UInt), "000000ff")
        XCTAssertEqual(#sprintf("%04u", 7 as UInt),  "0007")
        XCTAssertEqual(#sprintf("%03u", 0 as UInt),  "000")

        // Sign appears AFTER zero-padding — differs from C where '-' is
        // written first and only the digit field is zero-padded.
        // C: printf("%05d", -42) → "-0042"
        // Here:                  → "00-42"
        XCTAssertEqual(#sprintf("%05d", -42), "00-42")
        XCTAssertEqual(#sprintf("%06d", -1),  "0000-1")
    }

    // MARK: - #sprintf: flag '-' (left alignment)
    //
    // Bug: the '-' flag is parsed and stored in format.leftAligned but that
    // field is never read inside _printNumber.  As a result, numeric output
    // is still right-justified (leading padding), identical to the same
    // format string without '-'.  Strings ignore width entirely so '%-Ns'
    // also produces no padding at all.

    func testSprintfFlagLeftAlign() {
        // Numeric: width is applied but as leading (right-justify) padding —
        // same output as the non-'-' form.
        XCTAssertEqual(#sprintf("%-10d", 42),          "        42")  // C: "42        "
        XCTAssertEqual(#sprintf("%-5d",  -42),         "  -42")       // C: "-42  "
        XCTAssertEqual(#sprintf("%-8x",  0xff as UInt), "      ff")   // C: "ff      "

        // String: width is ignored entirely — no padding of any kind.
        XCTAssertEqual(#sprintf("%-5s",  "hi"), "hi")   // C: "hi   "
    }

    // MARK: - #sprintf: field width

    func testSprintfFieldWidth() {
        // Right-justified with space padding.
        XCTAssertEqual(#sprintf("%5d", 0),      "    0")
        XCTAssertEqual(#sprintf("%5d", 42),     "   42")
        XCTAssertEqual(#sprintf("%5d", -42),    "  -42")
        XCTAssertEqual(#sprintf("%5d", 12345),  "12345")
        XCTAssertEqual(#sprintf("%1d", 0),      "0")

        // Inconsistency vs C: when the formatted number is wider than the
        // field width, standard C never truncates — it expands the field.
        // This implementation truncates the most-significant digits to fit.
        // C: printf("%3d", 12345) → "12345"
        // Here:                   → "345"
        XCTAssertEqual(#sprintf("%3d", 12345),        "345")
        XCTAssertEqual(#sprintf("%2x", 0xabcd as UInt), "cd")
        XCTAssertEqual(#sprintf("%1d", 99),           "9")
    }

    // MARK: - #sprintf: precision
    //
    // A ".N" precision sets leadingZero = true and the overall field width
    // acts as the minimum padded width.  The precision digit count itself is
    // tracked internally but is NOT used to enforce a minimum digit count
    // independently of the field width.
    //
    // Consequence: "%W.Nd" is equivalent to "%0Wd" (zero-padded to W chars).
    // In standard C, precision specifies the minimum number of digits and is
    // independent of the field width; e.g. printf("%5.3d", 1) → "  001".

    func testSprintfPrecision() {
        XCTAssertEqual(#sprintf("%8.8x", 0xff as UInt),    "000000ff")
        XCTAssertEqual(#sprintf("%4.4x", 0xa as UInt),     "000a")
        XCTAssertEqual(#sprintf("%8.8d", 42),              "00000042")
        XCTAssertEqual(#sprintf("%2.2x", 0xf as UInt),     "0f")

        // "%W.Nd" and "%0Wd" produce identical output.
        let a = #sprintf("%16.16lx", 0x0808_0808_0808_0808 as UInt)
        let b = #sprintf("%016lx",   0x0808_0808_0808_0808 as UInt)
        XCTAssertEqual(a, b)
    }

    // MARK: - #sprintf: size modifiers ('h', 'l', 'z') are silently ignored
    //
    // In standard C, 'h' means short, 'l' means long, 'z' means size_t.
    // These modifiers affect how the argument is fetched from the varargs
    // stack.  In this implementation all modifiers are parsed and discarded;
    // the Swift argument type determines the actual value width.
    // All of the variants below produce the same output as the unmodified
    // form.  The 'll' (long-long) combination is also accepted.

    func testSprintfSizeModifiers() {
        XCTAssertEqual(#sprintf("%hd",  42 as Int),    "42")
        XCTAssertEqual(#sprintf("%ld",  42 as Int),    "42")
        XCTAssertEqual(#sprintf("%zd",  42 as Int),    "42")
        XCTAssertEqual(#sprintf("%lld", 42 as Int64),  "42")
        XCTAssertEqual(#sprintf("%d",   42 as Int),    "42")

        XCTAssertEqual(#sprintf("%hx",  0xff as UInt),   "ff")
        XCTAssertEqual(#sprintf("%lx",  0xff as UInt),   "ff")
        XCTAssertEqual(#sprintf("%zx",  0xff as UInt),   "ff")
        XCTAssertEqual(#sprintf("%llx", 0xff as UInt64), "ff")
        XCTAssertEqual(#sprintf("%x",   0xff as UInt),   "ff")

        // A UInt8 with %ld still prints the UInt8 value (modifier ignored).
        XCTAssertEqual(#sprintf("%lu", UInt8(7)), "7")
    }

    // MARK: - #sprintf: percent escape (%%)
    //
    // "%%" outputs a literal '%' without consuming a format argument.

    func testSprintfPercentEscape() {
        XCTAssertEqual(#sprintf("%d%%", 100),          "100%")
        XCTAssertEqual(#sprintf("%d%% done", 75),      "75% done")
        XCTAssertEqual(#sprintf("100%% of %d", 5),     "100% of 5")
        XCTAssertEqual(#sprintf("%d%%%d", 50, 50),     "50%50")
        // "%%" before a conversion character — the '%' is literal, 'd' is
        // plain text since "%%" consumed the percent.
//        XCTAssertEqual(#sprintf("%%d", 0 as UInt),     "%d")
    }

    // MARK: - #sprintf: Bool argument (non-standard behaviour)
    //
    // Swift Bool is not a C type so printf has no standard treatment for it.
    // This implementation's behaviour for each format specifier:
    //   %d / %i / %u / %x / %X / %o / %b  →  1 (true) or 0 (false)
    //   %c                                 →  'Y' (true) or 'N' (false)
    //   %s                                 →  "true" or "false"

    func testSprintfBool() {
        // Integer formats
        XCTAssertEqual(#sprintf("%d", true),  "1")
        XCTAssertEqual(#sprintf("%d", false), "0")
        XCTAssertEqual(#sprintf("%i", true),  "1")
        XCTAssertEqual(#sprintf("%i", false), "0")
        XCTAssertEqual(#sprintf("%u", true),  "1")
        XCTAssertEqual(#sprintf("%u", false), "0")
        XCTAssertEqual(#sprintf("%x", true),  "1")
        XCTAssertEqual(#sprintf("%x", false), "0")
        XCTAssertEqual(#sprintf("%X", true),  "1")
        XCTAssertEqual(#sprintf("%X", false), "0")
        XCTAssertEqual(#sprintf("%o", true),  "1")
        XCTAssertEqual(#sprintf("%o", false), "0")
        XCTAssertEqual(#sprintf("%b", true),  "1")
        XCTAssertEqual(#sprintf("%b", false), "0")

        // Character format: 'Y' / 'N' — non-standard.
        XCTAssertEqual(#sprintf("%c", true),  "Y")
        XCTAssertEqual(#sprintf("%c", false), "N")

        // String format: "true" / "false" — non-standard.
        XCTAssertEqual(#sprintf("%s", true),  "true")
        XCTAssertEqual(#sprintf("%s", false), "false")
    }

    // MARK: - #sprintf: multiple arguments and literal text

    func testSprintfMultipleArgs() {
        XCTAssertEqual(#sprintf("%d + %d = %d", 1, 2, 3), "1 + 2 = 3")
        XCTAssertEqual(#sprintf("[%s] [%d]", "test", 99), "[test] [99]")
        XCTAssertEqual(
            #sprintf("x=%x y=%x", 0xab as UInt8, 0xcd as UInt8),
            "x=ab y=cd"
        )
        XCTAssertEqual(
            #sprintf("GDT: %s Info: %#x/%u\n", "Current", 0x7b as UInt, 32 as UInt),
            "GDT: Current Info: 0x7b/32\n"
        )
        // Pointer + integer in same format string.
        let nptr: UnsafeMutableRawPointer? = nil
        XCTAssertEqual(
            #sprintf("val=%d ptr=%p", 123, nptr),
            "val=123 ptr=0x0"
        )
    }

    // MARK: - Known bugs: tests that assert correct C printf behaviour
    //
    // Every assertion in this section states the standard C printf output.
    // All will FAIL with the current implementation and pass once the
    // corresponding bug is fixed.

    // Bug: the '-' (left-align) flag is ignored.  _printNumber never reads
    // format.leftAligned so numeric output is right-justified regardless.
    // Fix: when leftAligned is true, emit the value first and then pad with
    // trailing spaces to reach the field width.
    func testSprintfBugLeftAlign() {
        XCTAssertEqual(#sprintf("%-10d", 42),          "42        ")
        XCTAssertEqual(#sprintf("%-5d",  -42),         "-42  ")
        XCTAssertEqual(#sprintf("%-8x",  0xff as UInt), "ff      ")
        XCTAssertEqual(#sprintf("%-1d",  0),            "0")

        // String width is completely ignored — both leading and trailing
        // padding should be applied once width handling is implemented.
        XCTAssertEqual(#sprintf("%5s",   "hi"), "   hi")
        XCTAssertEqual(#sprintf("%-5s",  "hi"), "hi   ")
    }

    // Bug: zero-padding of negative values places '0' chars before the
    // sign.  Standard C writes the sign first and then zero-pads the digit
    // field so that the total width (sign + zeros + digits) equals the
    // field width.
    func testSprintfBugZeroPadNegative() {
        XCTAssertEqual(#sprintf("%05d",  -42),   "-0042")
        XCTAssertEqual(#sprintf("%06d",  -1),    "-00001")
        XCTAssertEqual(#sprintf("%07d",  -123),  "-000123")
        XCTAssertEqual(#sprintf("%010d", -1),    "-000000001")
    }

    // Bug: when the formatted number is wider than the stated field width,
    // _printNumber clamps fieldWidth to format.width and then iterates over
    // only that many digits from the least-significant end, silently
    // discarding the most-significant digits.
    // Fix: if the value requires more characters than the field width, the
    // field should expand to fit (standard C never truncates numeric output).
    func testSprintfBugWidthTruncation() {
        XCTAssertEqual(#sprintf("%3d",  12345),             "12345")
        XCTAssertEqual(#sprintf("%2x",  0xabcd as UInt),    "abcd")
        XCTAssertEqual(#sprintf("%1d",  99),                "99")
        XCTAssertEqual(#sprintf("%2d",  -42),               "-42")
        XCTAssertEqual(#sprintf("%1d",  -1),                "-1")
    }

    // Bug: the '#' alternate-form flag for %o is not implemented.  The
    // dispatch case for .octal ignores the alternateForm variable.
    // Fix: when alternateForm is true and the value is non-zero, prepend
    // a single '0' digit (standard C behaviour).
    func testSprintfBugAlternateFormOctal() {
        // Non-zero values get a leading '0'.
        XCTAssertEqual(#sprintf("%#o",  8 as UInt),       "010")
        XCTAssertEqual(#sprintf("%#o",  0o777 as UInt),   "0777")
        XCTAssertEqual(#sprintf("%#o",  255 as UInt),     "0377")
        XCTAssertEqual(#sprintf("%#o",  1 as UInt),       "01")
        // Zero: standard C does not add an extra '0' prefix, output is "0".
        // This case already passes, included here for completeness.
        XCTAssertEqual(#sprintf("%#o",  0 as UInt),       "0")
    }

    // Bug: %#x and %#X unconditionally emit the "0x"/"0X" prefix before
    // calling _printNumber, even when the value is zero.
    // Fix: the prefix should be suppressed when the value is zero
    // (standard C behaviour: printf("%#x", 0) → "0").
    func testSprintfBugAlternateFormHexZero() {
        XCTAssertEqual(#sprintf("%#x", 0 as UInt), "0")
        XCTAssertEqual(#sprintf("%#X", 0 as UInt), "0")
    }

    // MARK: - Benchmarks
    //
    // Each benchmark runs the measured body 10 times (XCTest default) and
    // records wall-clock duration.  The intent is to catch regressions in
    // the printf formatting engine and String(asciiBytes:) initialiser.
    // Run with `swift test -c release` for meaningful numbers.

    // Single signed decimal integer — the most common real-world use.
    func testBenchmarkSprintfSignedDecimal() {
        measure {
            for _ in 0..<10_000 {
                blackHole(#sprintf("%d", 123456789))
            }
        }
    }

    // Unsigned hex — typical for address / register formatting.
    func testBenchmarkSprintfHex() {
        measure {
            for _ in 0..<10_000 {
                blackHole(#sprintf("%016lx", 0xdeadbeef_cafebabe as UInt))
            }
        }
    }

    // Mixed format: mimics a typical kernel log line with multiple types.
    func testBenchmarkSprintfMixedFormat() {
        measure {
            for _ in 0..<10_000 {
                blackHole(
                    #sprintf("dev=%s reg=0x%08x val=%u flags=%08b",
                             "i915", 0x70008 as UInt32, 1920 as UInt,
                             0b1010_1100 as UInt8)
                )
            }
        }
    }

    // Width + zero-padding — exercises the padding loop in _printNumber.
    func testBenchmarkSprintfZeroPadWidth() {
        measure {
            for _ in 0..<10_000 {
                blackHole(#sprintf("%016x", 0xff as UInt))
            }
        }
    }

    // Many arguments — exercises the fixed argument-slot dispatch.
    func testBenchmarkSprintfManyArgs() {
        measure {
            for _ in 0..<10_000 {
                blackHole(
                    #sprintf("%d %d %d %d %d %d %d %d",
                             1, 2, 3, 4, 5, 6, 7, 8)
                )
            }
        }
    }
}

// Prevent the compiler from optimising away benchmark results.
@inline(never)
private func blackHole<T>(_ value: T) {}
