//
//  KlibTests.swift
//  acpitest
//
//  Created by Simon Evans on 06/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

import XCTest

class KlibTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testReservationManager() {
        var rs = ReservationSpace(name: "IO Ports", start: 0, end: 0xffff)
        XCTAssertTrue(rs.reserveSpace(name: "kbd8042", start: 0x60, end: 0x60))
        XCTAssertTrue(rs.reserveSpace(name: "kbd8042", start: 0x64, end: 0x64))
        XCTAssertFalse(rs.reserveSpace(name: "kbd8042", start: 0x60, end: 0x62))

        rs.showReservedSpaces()
    }
}
