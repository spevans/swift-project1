//
//  AddressTests.swift
//  tests
//
//  Created by Simon Evans on 01/08/2019.
//  Copyright © 2019 Simon Evans. All rights reserved.
//

import XCTest

let gb: UInt = 1024 * 1048576
let mb: UInt = 1048576
let kb: UInt = 1024

class AddressTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPhysAddress() {

        let ranges2 = PhysPageRange.createRanges(startAddress: PhysAddress(0x300), size: 3 * gb + 27 * mb + 99 * kb, pageSizes: [4096, 2 * mb, 1 * gb])
        for range in ranges2 {
            print(range)
        }

        let physAddr = PhysAddress(1 * mb)
        let region = PhysPageRange(physAddr, pageSize: 4096, pageCount: 256)
        XCTAssertEqual(region.pageCount, 256)
        XCTAssertEqual(region.pageSize, 4096)
        XCTAssertEqual(region.address , physAddr)

        let (newRegion, result) = region.splitRegion(withFirstRegionCount: 255)
        XCTAssertEqual(newRegion.pageCount, 255)
        XCTAssertEqual(newRegion.pageSize, 4096)
        XCTAssertEqual(newRegion.address, physAddr)

        XCTAssertEqual(result.pageCount, 1)
        XCTAssertEqual(result.pageSize, 4096)
        XCTAssertEqual(result.address, newRegion.endAddress + 1)

        let (newRegion2, result2) = newRegion.splitRegion(withFirstRegionCount: 254)
        XCTAssertEqual(newRegion2.pageCount, 254)
        XCTAssertEqual(newRegion2.pageSize, 4096)
        XCTAssertEqual(newRegion2.address, physAddr)

        XCTAssertEqual(result2.pageCount, 1)
        XCTAssertEqual(result2.pageSize, 4096)
        XCTAssertEqual(result2.address, newRegion2.endAddress + 1)
    }


    // Test when the physical address region starts at zero or end at MAX_PHYSICAL_MEMORY
    func testPhysAddressEdgeCases() {
        let ranges = PhysPageRange.createRanges(startAddress: PhysAddress(0), size: 2 * gb, pageSizes: [4096])
        XCTAssertEqual(ranges.count, 1)
        let range = ranges[0]
        XCTAssertEqual(range.pageCount, 524288)
        XCTAssertEqual(range.pageSize, 4096)
        XCTAssertEqual(range.address, PhysAddress(0))
        let end = 2 * gb - 1
        XCTAssertEqual(range.endAddress, PhysAddress(end))

        let allMemoryRegions4K = PhysPageRange.createRanges(startAddress: PhysAddress(0), size: MAX_PHYSICAL_MEMORY, pageSizes: [4096])
        XCTAssertEqual(allMemoryRegions4K.count, 1)
        let total4KPages = allMemoryRegions4K.map { $0.pageCount }.reduce(0, +)
        XCTAssertEqual(total4KPages, 4096 * 4096)

        let allMemoryRegions1G = PhysPageRange.createRanges(startAddress: PhysAddress(0), size: MAX_PHYSICAL_MEMORY, pageSizes: [4096, 2 * mb, 1 * gb])
        XCTAssertEqual(allMemoryRegions1G.count, 1)
        XCTAssertEqual(allMemoryRegions1G.first?.pageCount, 64)
        XCTAssertEqual(allMemoryRegions1G.first?.pageSize, 1 * gb)
        let total1GPages = allMemoryRegions1G.map { $0.pageCount }.reduce(0, +)
        XCTAssertEqual(total1GPages, 64)
    }
}
