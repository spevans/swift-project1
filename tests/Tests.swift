/*
 * tests/Tests.swift
 *
 * Created by Simon Evans on 01/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Unit tests for String.sprintf() extensions
 */

import XCTest
import Klib


class Tests: XCTestCase {

    var allTests : [(String, () -> Void)] {
        return [
            ("testSprintf", testSprintf),
            ("testUInt16", testUInt16)
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

    func testUInt16() {
        let x = UInt16(msb: 1, lsb: 2)
        XCTAssertEqual(0x102, x, "UInt16(msb, lsb)")
        XCTAssertEqual(1, x.toBytes().0, "UInt16.toBytes() msb")
        XCTAssertEqual(2, x.toBytes().1, "UInt16.toBytes() lsb")
    }
}


public func runTests() {
    XCTMain([Tests()])
}
