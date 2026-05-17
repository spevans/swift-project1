/*
 * StringTests.swift
 *
 * Created by Simon Evans on 02/08/2017.
 * Copyright © 2017 Simon Evans. All rights reserved.
 *
 */


import XCTest
@testable import Kernel

class StringTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }



    func testByteArray2() {
        let x = ByteArray2([2, 1])
        XCTAssertEqual(0x102, x.toInt(), "ByteArray2.toInt")
        XCTAssertEqual(2, x[0], "ByteArray2[0]")
        XCTAssertEqual(1, x[1], "ByteArray2[1]")
    }
}
