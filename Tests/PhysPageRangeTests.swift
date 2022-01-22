//
//  PhysPageAlignedRegionTests.swift
//  tests
//
//  Created by Simon Evans on 15/01/2022.
//  Copyright © 2022 Simon Evans. All rights reserved.
//

import XCTest

class PhysPageAlignedRegionTests: XCTestCase {

    func testPageRangeChunks() {
        let physPageRange = PhysPageAlignedRegion(PhysAddress(0x1000), pageSize: PageSize(), pageCount: 130)
        var iterator = PhysPageAlignedRegionChunksInterator(physPageRange, pagesPerChunk: 128)
        while let chunk = iterator.next() {
            print(chunk)
        }
    }
}
