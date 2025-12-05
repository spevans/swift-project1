//
//  PhysPageAlignedRegionTests.swift
//  tests
//
//  Created by Simon Evans on 15/01/2022.
//  Copyright © 2022 Simon Evans. All rights reserved.
//

import XCTest
@testable import Kernel

class PhysPageAlignedRegionTests: XCTestCase {

    func testPageRangeChunks() {
        let physPageRange = PhysPageAlignedRegion(PhysAddress(0x1000), pageSize: PageSize(), pageCount: 130)
        var iterator = PhysPageAlignedRegionChunksInterator(physPageRange, pagesPerChunk: 128)
        XCTAssertEqual(iterator.next()?.description, "0x1000 - 0x80fff [128 * 0x1000]")
        XCTAssertEqual(iterator.next()?.description, "0x81000 - 0x82fff [2 * 0x1000]")
        XCTAssertNil(iterator.next())
    }

    func testUnalignedPageRegions() {
        let size: UInt = (16 * 32 * 256) / 8
        let fontPhys = PhysAddress(0x120d860)
        let fontPages = PhysPageAlignedRegion(start: fontPhys, size: size)
        XCTAssertEqual(fontPages.baseAddress, PhysAddress(0x120_d000))
        XCTAssertEqual(fontPages.pageCount, 5)
    }

}
