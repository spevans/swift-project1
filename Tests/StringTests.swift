//
//  StringTests.swift
//  acpitest
//
//  Created by Simon Evans on 02/08/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

import XCTest

class StringTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSprintf() {
        let output1 = #sprintf("Test: %lx", 0x0123456789abcdef)
        XCTAssertEqual("Test: 123456789abcdef", output1, "`lx' format specifier")

        let output2 = #sprintf("Test: %p", 0x1234567890abcdef)
        XCTAssertEqual("Test: 0x1234567890abcdef", output2, "`p' format specifier")

        let output3 = #sprintf("R8: %16lx", 0x0808080808080808)
        XCTAssertEqual("R8:  808080808080808", output3, "`16.16lx' 64bit number")

        let output4 = #sprintf("R8: %016lx", 0x0808080808080808)
        print(output4)
        XCTAssertEqual("R8: 0808080808080808", output4, "`016.16lx' 64bit number")

        let output5 = #sprintf("RAX: %#16.16lX", 0xaaaaaaaaaaaaaaaa as UInt64)
        XCTAssertEqual("RAX: 0XAAAAAAAAAAAAAAAA", output5, "`#16.16lx' 64bit number hight bit set")
    }

    func testByteArray2() {
        let x = ByteArray2([2, 1])
        XCTAssertEqual(0x102, x.toInt(), "ByteArray2.toInt")
        XCTAssertEqual(2, x[0], "ByteArray2[0]")
        XCTAssertEqual(1, x[1], "ByteArray2[1]")
    }
}
