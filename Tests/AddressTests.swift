//
//  AddressTests.swift
//  tests
//
//  Created by Simon Evans on 01/08/2019.
//  Copyright © 2019 Simon Evans. All rights reserved.
//

import XCTest

class AddressTests: XCTestCase {

    func testSplitRegion() {

        let physAddr = PhysAddress(1 * mb)
        let region = PhysPageRange(physAddr, pageSize: PageSize(), pageCount: 256)
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


    func testPhysPageRangeIterator() {
        let pageRange = PhysPageRange(PhysAddress(4096), pageSize: PageSize(), pageCount: 4)
        XCTAssertEqual(pageRange.address, PhysAddress(4096))
        XCTAssertEqual(pageRange.endAddress, PhysAddress(0x4fff))
        var i = pageRange.makeIterator()
        XCTAssertEqual(i.next(), PhysAddress(0x1000))
        XCTAssertEqual(i.next(), PhysAddress(0x2000))
        XCTAssertEqual(i.next(), PhysAddress(0x3000))
        XCTAssertEqual(i.next(), PhysAddress(0x4000))
        XCTAssertNil(i.next())
    }


    func testCreateRanges() {
        do {
            let start = PhysAddress(0xbcb5c000)
            let memoryRange = MemoryRange(type: .BootServicesCode, start: start, size: 0x1000)
            let physPageRanges = memoryRange.physPageRanges(using: [PageSize(4 * kb), PageSize(2 * mb), PageSize(1 * gb)])
            XCTAssertEqual(physPageRanges.count, 1)
            XCTAssertEqual(physPageRanges[0].pageSize, 0x1000)
            XCTAssertEqual(physPageRanges[0].address, start)
            XCTAssertEqual(physPageRanges[0].endAddress, start + 0xfff)
            XCTAssertEqual(physPageRanges[0].pageCount, 1)
        }

        do {
            let start = PhysAddress(0x200_000)
            let memoryRange = MemoryRange(type: .BootServicesCode, start: start, size: 0x200_000)
            let physPageRanges = memoryRange.physPageRanges(using: [PageSize(4 * kb), PageSize(2 * mb), PageSize(1 * gb)])
            XCTAssertEqual(physPageRanges.count, 1)
            XCTAssertEqual(physPageRanges[0].pageSize, 0x200_000)
            XCTAssertEqual(physPageRanges[0].address, start)
            XCTAssertEqual(physPageRanges[0].endAddress, start + 0x1ff_fff)
            XCTAssertEqual(physPageRanges[0].pageCount, 1)
        }

        do {
            let start = PhysAddress(0x40_000_000)
            let memoryRange = MemoryRange(type: .BootServicesCode, start: start, size: 0x40_000_000)
            let physPageRanges = memoryRange.physPageRanges(using: [PageSize(4 * kb), PageSize(2 * mb), PageSize(1 * gb)])
            XCTAssertEqual(physPageRanges.count, 1)
            XCTAssertEqual(physPageRanges[0].pageSize, 0x40_000_000)
            XCTAssertEqual(physPageRanges[0].address, start)
            XCTAssertEqual(physPageRanges[0].endAddress, start + 0x3f_fff_fff)
            XCTAssertEqual(physPageRanges[0].pageCount, 1)
        }

        do {
            let start = PhysAddress(0xbc000000)
            let memoryRange = MemoryRange(type: .BootServicesCode, start: start, size: 0x20000)
            let physPageRanges = memoryRange.physPageRanges(using: [PageSize(4 * kb), PageSize(2 * mb), PageSize(1 * gb)])
            XCTAssertEqual(physPageRanges.count, 1)

            XCTAssertEqual(physPageRanges[0].pageSize, 0x1000)
            XCTAssertEqual(physPageRanges[0].address, start)
            XCTAssertEqual(physPageRanges[0].endAddress, start + 0x1f_fff)
            XCTAssertEqual(physPageRanges[0].pageCount, 32)

            XCTAssertEqual(physPageRanges.first?.address, memoryRange.start)
            XCTAssertEqual(physPageRanges.last?.endAddress, memoryRange.endAddress)
        }

        do {
            let start = (1 * gb) - (4 * mb) - (12 * kb)
            let end = (2 * gb) + (8 * kb)
            let size = end - start
            let memoryRange = MemoryRange(type: .BootServicesCode, start: PhysAddress(start), size: size)
            let physPageRanges = memoryRange.physPageRanges(using: [PageSize(4 * kb), PageSize(2 * mb), PageSize(1 * gb)])
            XCTAssertEqual(physPageRanges.count, 4)
            XCTAssertEqual(physPageRanges[0].pageSize, 0x1000)
            XCTAssertEqual(physPageRanges[0].address, PhysAddress(start))
            XCTAssertEqual(physPageRanges[0].endAddress, PhysAddress(start) + 0x2fff)
            XCTAssertEqual(physPageRanges[0].pageCount, 3)

            XCTAssertEqual(physPageRanges[1].pageSize, 0x200_000)
            XCTAssertEqual(physPageRanges[1].address, PhysAddress(start) + 0x3000)
            XCTAssertEqual(physPageRanges[1].endAddress, (PhysAddress(start) + 0x3000 +  0x400_000) - 1)
            XCTAssertEqual(physPageRanges[1].pageCount, 2)

            XCTAssertEqual(physPageRanges[2].pageSize, 0x40_000_000)
            XCTAssertEqual(physPageRanges[2].address, PhysAddress(start) + 0x3000 +  0x400_000)
            XCTAssertEqual(physPageRanges[2].endAddress, PhysAddress(end) - 0x2001)
            XCTAssertEqual(physPageRanges[2].pageCount, 1)

            XCTAssertEqual(physPageRanges[3].pageSize, 0x1000)
            XCTAssertEqual(physPageRanges[3].address, PhysAddress(end) - 0x2000)
            XCTAssertEqual(physPageRanges[3].endAddress, memoryRange.endAddress)
            XCTAssertEqual(physPageRanges[3].pageCount, 2)

            XCTAssertEqual(physPageRanges.first?.address, memoryRange.start)
            XCTAssertEqual(physPageRanges.last?.endAddress, memoryRange.endAddress)
        }

        do {
            // 4k to 64gb
            let memoryRange = MemoryRange(type: .BootServicesCode, start: PhysAddress(0x1000), size: MAX_PHYSICAL_MEMORY - 4096)
            let physPageRanges = memoryRange.physPageRanges(using: [PageSize(4 * kb), PageSize(2 * mb), PageSize(1 * gb)])

            XCTAssertEqual(physPageRanges.count, 3)
            XCTAssertEqual(physPageRanges[0].pageSize, 0x1000)
            XCTAssertEqual(physPageRanges[0].address, PhysAddress(0x1000))
            XCTAssertEqual(physPageRanges[0].endAddress, PhysAddress(0x1ff_fff)) // 2MB - 1
            XCTAssertEqual(physPageRanges[0].pageCount, 511)

            XCTAssertEqual(physPageRanges[1].pageSize, 0x200_000)
            XCTAssertEqual(physPageRanges[1].address, PhysAddress(0x200_000))
            XCTAssertEqual(physPageRanges[1].endAddress, PhysAddress(0x3f_fff_fff)) // 1GB - 1
            XCTAssertEqual(physPageRanges[1].pageCount, 511)

            XCTAssertEqual(physPageRanges[2].pageSize, 0x40_000_000)
            XCTAssertEqual(physPageRanges[2].address, PhysAddress(0x40_000_000))
            XCTAssertEqual(physPageRanges[2].endAddress, PhysAddress(0xFFF_FFF_FFF)) // 64GB -1
            XCTAssertEqual(physPageRanges[2].pageCount, 63) // 1ff000

            XCTAssertEqual(physPageRanges.first?.address, memoryRange.start)
            XCTAssertEqual(physPageRanges.last?.endAddress, memoryRange.endAddress)
        }

        do {
            // 64gb - last 4K page
            let memoryRange = MemoryRange(type: .BootServicesCode, start: PhysAddress(0), size: MAX_PHYSICAL_MEMORY - 4096)
            let physPageRanges = memoryRange.physPageRanges(using: [PageSize(4 * kb), PageSize(2 * mb), PageSize(1 * gb)])

            XCTAssertEqual(physPageRanges.count, 3)
            XCTAssertEqual(physPageRanges[0].pageSize, 0x40_000_000)
            XCTAssertEqual(physPageRanges[0].address, PhysAddress(0))
            XCTAssertEqual(physPageRanges[0].endAddress, PhysAddress(0xf_bfff_ffff))
            XCTAssertEqual(physPageRanges[0].pageCount, 63)

            XCTAssertEqual(physPageRanges[1].pageSize, 0x200_000)
            XCTAssertEqual(physPageRanges[1].address, PhysAddress(0xf_c000_0000))
            XCTAssertEqual(physPageRanges[1].endAddress, PhysAddress(0xfff_dff_fff))
            XCTAssertEqual(physPageRanges[1].pageCount, 511) // 3fe00_000

            XCTAssertEqual(physPageRanges[2].pageSize, 0x1000)
            XCTAssertEqual(physPageRanges[2].address, PhysAddress(0xfff_e00_000))
            XCTAssertEqual(physPageRanges[2].endAddress, PhysAddress(0xf_ffff_efff))
            XCTAssertEqual(physPageRanges[2].pageCount, 511) // 1ff000

            XCTAssertEqual(physPageRanges.first?.address, memoryRange.start)
            XCTAssertEqual(physPageRanges.last?.endAddress, memoryRange.endAddress)
        }

        do {
            // Test when the physical address region starts at zero or end at MAX_PHYSICAL_MEMORY
            let ranges = PhysPageRange.createRanges(startAddress: PhysAddress(0), endAddress: PhysAddress(2 * gb - 1), pageSizes: [PageSize()])
            XCTAssertEqual(ranges.count, 1)
            let range = ranges[0]
            XCTAssertEqual(range.pageCount, 524288)
            XCTAssertEqual(range.pageSize, 4096)
            XCTAssertEqual(range.address, PhysAddress(0))
            let end = 2 * gb - 1
            XCTAssertEqual(range.endAddress, PhysAddress(end))

            let allMemoryRegions4K = PhysPageRange.createRanges(startAddress: PhysAddress(0), endAddress: PhysAddress(MAX_PHYSICAL_MEMORY - 1), pageSizes: [PageSize()])
            XCTAssertEqual(allMemoryRegions4K.count, 1)
            let total4KPages = allMemoryRegions4K.map { $0.pageCount }.reduce(0, +)
            XCTAssertEqual(total4KPages, 4096 * 4096)

            let allMemoryRegions1G = PhysPageRange.createRanges(startAddress: PhysAddress(0), endAddress: PhysAddress(MAX_PHYSICAL_MEMORY - 1), pageSizes: [PageSize(4 * kb), PageSize(2 * mb), PageSize(1 * gb)])
            XCTAssertEqual(allMemoryRegions1G.count, 1)
            XCTAssertEqual(allMemoryRegions1G.first?.pageCount, 64)
            XCTAssertEqual(allMemoryRegions1G.first?.pageSize, 1 * gb)
            let total1GPages = allMemoryRegions1G.map { $0.pageCount }.reduce(0, +)
            XCTAssertEqual(total1GPages, 64)
        }

        do {
            // Region too small, no ranges returned
            let ranges = PhysPageRange.createRanges(startAddress: PhysAddress(0), endAddress: PhysAddress(99), pageSizes: [PageSize()])
            XCTAssertEqual(ranges.count, 0)
        }

        do {
            // Region overlaps 2 pages but doesnt cover either page fully
            let ranges = PhysPageRange.createRanges(startAddress: PhysAddress(1), endAddress: PhysAddress(6000), pageSizes: [PageSize()])
            XCTAssertEqual(ranges.count, 0)
        }

        do {
            // Region overlaps 3 pages but only covers 1 fully
            let ranges = PhysPageRange.createRanges(startAddress: PhysAddress(100), endAddress: PhysAddress(9099), pageSizes: [PageSize()])
            XCTAssertEqual(ranges.count, 1)
            XCTAssertEqual(ranges[0].pageCount, 1)
            XCTAssertEqual(ranges[0].pageSize, 4096)
            XCTAssertEqual(ranges[0].address, PhysAddress(4096))
        }

        do {
            // 1Gb pages only
            let ranges = PhysPageRange.createRanges(startAddress: PhysAddress(0), endAddress: PhysAddress(1 * gb - 1), pageSizes: [PageSize(1 * gb)])
            XCTAssertEqual(ranges.count, 1)
            XCTAssertEqual(ranges[0].pageCount, 1)
            XCTAssertEqual(ranges[0].pageSize, 1 * gb)
            XCTAssertEqual(ranges[0].address, PhysAddress(0))
        }

        do {
            // 1Gb pages only
            let ranges = PhysPageRange.createRanges(startAddress: PhysAddress(0), endAddress: PhysAddress(1 * gb), pageSizes: [PageSize(1 * gb)])
            XCTAssertEqual(ranges.count, 1)
            XCTAssertEqual(ranges[0].pageCount, 1)
            XCTAssertEqual(ranges[0].pageSize, 1 * gb)
            XCTAssertEqual(ranges[0].address, PhysAddress(0))
        }

        do {
            // 1Gb pages only
            let ranges = PhysPageRange.createRanges(startAddress: PhysAddress(0), endAddress: PhysAddress(1 * gb + 4095), pageSizes: [PageSize(1 * gb)])
            XCTAssertEqual(ranges.count, 1)
            XCTAssertEqual(ranges[0].pageCount, 1)
            XCTAssertEqual(ranges[0].pageSize, 1 * gb)
            XCTAssertEqual(ranges[0].address, PhysAddress(0))
        }
    }

    func testPhysPageRange() {
        let range = PhysPageRange(start: PhysAddress(0xE0000), size: 0x20000)
        XCTAssertEqual(range.address, PhysAddress(0xE0000))
        XCTAssertEqual(range.pageCount, 32)
    }
}
