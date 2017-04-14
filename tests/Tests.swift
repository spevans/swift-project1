/*
 * tests/Tests.swift
 *
 * Created by Simon Evans on 01/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Unit tests for String.sprintf() extensions
 */

import XCTest


func printf(_ format: StaticString, _ arguments: CVarArg...) {
    print(String.sprintf(format, arguments))
}

class Tests: XCTestCase {

    static var allTests : [(String, (Tests) -> () throws -> Void)] {
        return [
            ("testSprintf", testSprintf),
            ("testByteArray2", testByteArray2)
        ]
    }


    func testSprintf() {
        let output1 = String.sprintf("Test: %lx", 0x0123456789abcdef)
        XCTAssertEqual("Test: 123456789abcdef", output1, "`lx' format specifier")

        let output2 = String.sprintf("Test: %p", 0x1234567890abcdef)
        XCTAssertEqual("Test: 0x1234567890abcdef", output2, "`p' format specifier")

        let output3 = String.sprintf("R8: %16.16lx", 0x0808080808080808)
        XCTAssertEqual("R8: 0808080808080808", output3, "`16.16lx' 64bit number")

        let output4 = String.sprintf("RAX: %#16.16lX", 0xaaaaaaaaaaaaaaaa as UInt64)
        XCTAssertEqual("RAX: 0xAAAAAAAAAAAAAAAA", output4, "`#16.16lx' 64bit number hight bit set")
    }

    func testByteArray2() {
        let x = ByteArray2([2, 1])
        XCTAssertEqual(0x102, x.toInt(), "ByteArray2.toInt")
        XCTAssertEqual(2, x[0], "ByteArray2[0]")
        XCTAssertEqual(1, x[1], "ByteArray2[1]")
    }
}


@_silgen_name("runTests")
public func runTes() {
    XCTMain([ testCase(Tests.allTests) ])
}
