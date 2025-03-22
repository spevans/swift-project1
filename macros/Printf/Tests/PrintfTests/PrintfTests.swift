import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import Printf

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

@freestanding(expression)
macro sprintf(_ format: StaticString, _ items: PrintfArg...) -> String = #externalMacro(module: "PrintfMacros", type: "PrintfMacro")

#endif


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
            #printf("This is a formatted string", 1)
            """,
            expandedSource: """
            _printf("This is a formatted string", (1)._printfArg)
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
            #kprintf("This is a formatted string", 1, d, Int8(-123))
            """,
            expandedSource: """
            let d = UInt64(1)
            _kprintf("This is a formatted string", (1)._printfArg, (d)._printfArg, (Int8(-123))._printfArg)
            """,
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
            #sprintf("This is a formatted string", 1, d, Int8(-123))
            """,
            expandedSource: """
            let d = UInt64(1)
            String._sprintf("This is a formatted string", (1)._printfArg, (d)._printfArg, (Int8(-123))._printfArg)
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

    func testKprintString() throws {
#if canImport(PrintfMacros)
        assertMacroExpansion(
            """
            let d = UInt64(1)
            #kprint("This is a string")
            """,
            expandedSource: """
            let d = UInt64(1)
            _kprint("This is a string".description)
            """,
            macros: testMacros
        )
#else
        throw XCTSkip("macros are only supported when running tests for the host platform")
#endif
    }

}
