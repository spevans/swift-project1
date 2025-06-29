//
//  PageSizeTests.swift
//  tests
//
//  Created by Simon Evans on 16/01/2022.
//  Copyright © 2022 Simon Evans. All rights reserved.
//

import XCTest
@testable import Kernel

class PageSizeTests: XCTestCase {

    func testPageSize() {
        let pageSize = PageSize()
        XCTAssertEqual(pageSize.size, 4096)
        XCTAssertEqual(pageSize.mask, 0xffff_ffff_ffff_F000)
        XCTAssertEqual(pageSize.encoding, 1)

        XCTAssertTrue(pageSize.isPageAligned(0xffff000))
        XCTAssertTrue(pageSize.isPageAligned(0xfff1000))
        XCTAssertTrue(pageSize.isPageAligned(0xf0ff000))
        XCTAssertFalse(pageSize.isPageAligned(0xffff001))

        XCTAssertEqual(pageSize.roundDown(0x234), 0x0)
        XCTAssertEqual(pageSize.roundToNextPage(0x234), 0x1000)
        XCTAssertEqual(pageSize.roundDown(0x1234), 0x1000)
        XCTAssertEqual(pageSize.roundToNextPage(0x1234), 0x2000)

        XCTAssertEqual(pageSize.lastAddressInPage(0x234), 0xfff)
        XCTAssertEqual(pageSize.lastAddressInPage(0x1234), 0x1fff)

        XCTAssertTrue(pageSize.onSamePage(0x1234, 0x1001))
        XCTAssertTrue(pageSize.onSamePage(0x1000, 0x1fff))
        XCTAssertFalse(pageSize.onSamePage(0x1234, 0x2001))
        XCTAssertFalse(pageSize.onSamePage(0x1234, 0x2000))

        XCTAssertEqual(pageSize.pageCountCovering(size:0x1234), 2)
        XCTAssertEqual(pageSize.pageCountCovering(size:0x1), 1)
        XCTAssertEqual(pageSize.pageCountCovering(size:0x3001), 4)
        XCTAssertEqual(pageSize.pageCountCovering(size:0x0), 0)

        XCTAssertEqual(pageSize.offsetInPage(0x1234), 0x234)
    }

}
