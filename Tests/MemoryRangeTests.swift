//
//  MemoryRangeTests.swift
//  tests
//
//  Created by Simon Evans on 15/01/2022.
//  Copyright © 2022 Simon Evans. All rights reserved.
//

import XCTest
@testable import Kernel


class MemoryRangeTests: XCTestCase {

    func testRanges1() -> [MemoryRange] {
        /*
         MM: E820 :            0 -        9FBFF     639KB   Conventional
         MM: E820 :        9FC00 -        9FFFF       1KB   E820Reserved
         MM: E820 :        A0000 -        EFFFF     320KB   Hole
         MM: E820 :        F0000 -        FFFFF      64KB   E820Reserved
         MM: E820 :       100000 -       FFFFFF      15MB   Conventional
         MM: E820 :      1000000 -      1543FFF       5MB   Kernel
         MM: E820 :      1544000 -      FFDFFFF     234MB   Conventional
         MM: E820 :      FFE0000 -      FFFFFFF     128KB   E820Reserved
         MM: E820 :     10000000 -     FFFBFFFF    3839MB   Hole
         MM: E820 :     FFFC0000 -     FFFFFFFF     256KB   E820Reserved
         */
        return [
            MemoryRange(type: .Conventional, start: PhysAddress(0), size: 639 * 1024, attributes: [.writeBack]),
            MemoryRange(type: .Reserved, start: PhysAddress(0x9FC00), size: 1024, attributes: []),
            MemoryRange(type: .Hole, start: PhysAddress(0xA0000), size: 320 * 1024, attributes: [.uncacheable, .writeCombining]),
            MemoryRange(type: .Reserved, start: PhysAddress(0xF0000), size: 64 * 1024, attributes: []),
            MemoryRange(type: .Conventional, start: PhysAddress(0x100000), size: 0xFFE0000 - 0x100000, attributes: [.writeBack]),
            MemoryRange(type: .Reserved, start: PhysAddress(0xFFE0000), size: 128 * 1024, attributes: [.readOnly]),
            MemoryRange(type: .Hole, start: PhysAddress(0x10000000), size: 0xFFFC0000 - 0x10000000, attributes: []),
            MemoryRange(type: .Reserved, start: PhysAddress(0xFFFC0000), size: 256 * 1024, attributes: [.writeBack]),
        ]
    }

    func testRanges2() ->[MemoryRange] {
        return [
            MemoryRange(type: .Conventional, start: PhysAddress(0), size: 1024, attributes: [.uncacheable, .writeThrough, .writeBack]),
            MemoryRange(type: .Reserved, start: PhysAddress(1024), size: 1024, attributes: [.uncacheable, .writeThrough, .writeBack]),
            MemoryRange(type: .Kernel, start: PhysAddress(2048), size: 2048, attributes: [.uncacheable, .writeThrough, .writeBack]),
            MemoryRange(type: .BootData, start: PhysAddress(4096), size: 1024, attributes: [.uncacheable, .writeThrough, .writeBack]),
            MemoryRange(type: .ACPINonVolatile, start: PhysAddress(8192), size: 2048, attributes: [.uncacheable, .writeThrough, .writeBack]),
        ]
    }

    func testRanges3() -> [MemoryRange] {
        return [
            MemoryRange(type: .Conventional, start: PhysAddress(0), size: 1024, attributes: [.uncacheable, .writeThrough, .writeBack]),
            MemoryRange(type: .Reserved, start: PhysAddress(1024), size: 1024, attributes: [.uncacheable, .writeThrough, .writeBack]),
            MemoryRange(type: .MemoryMappedIO, start: PhysAddress(2048), size: 2048, attributes: [.uncacheable]),
            MemoryRange(type: .Conventional, start: PhysAddress(4096), size: 1024, attributes: [.uncacheable, .writeThrough, .writeBack]),
            MemoryRange(type: .Conventional, start: PhysAddress(8192), size: 2048, attributes: [.uncacheable, .writeThrough, .writeBack]),
        ]
    }

    func testInsertRange() {
        do {
            var ranges = testRanges1()
            let fb = MemoryRange(type: .FrameBuffer, start: PhysAddress(0xA0000), size: 128 * 1024, attributes: [.uncacheable, .writeCombining])
            ranges.insertRange(fb)
            XCTAssertEqual(ranges.count, 9)
            XCTAssertEqual(ranges[2], fb)
            XCTAssertEqual(ranges[3], MemoryRange(type: .Hole, start: PhysAddress(0xC0000), size: 192 * 1024, attributes: [.uncacheable, .writeCombining]))
        }
        do {
            var ranges = [MemoryRange(type: .Conventional, start: PhysAddress(0x0), size: 1048576, attributes: [.writeBack])]
            let fb = MemoryRange(type: .FrameBuffer, start: PhysAddress(0xA0000), size: 128 * 1024, attributes: [.uncacheable, .writeCombining])
            ranges.insertRange(fb)
            XCTAssertEqual(ranges.count, 3)
            XCTAssertEqual(ranges[0], MemoryRange(type: .Conventional, start: PhysAddress(0x0), size: 0xA0000, attributes: [.writeBack]))
            XCTAssertEqual(ranges[1], fb)
            XCTAssertEqual(ranges[2], MemoryRange(type: .Conventional, start: PhysAddress(0xC0000), size: 0x40000, attributes: [.writeBack]))
        }
    }

    func testIteratorWithHoles() {
        let smallRanges = testRanges2()
        var newRanges: [MemoryRange] = []
        for range in smallRanges.rangesWithHoles() { newRanges.append(range) }
        XCTAssertEqual(newRanges.count, 6)
        XCTAssertEqual(newRanges[4], MemoryRange(type: .Hole, start: PhysAddress(5120), size: 3072, attributes: []))

    }

    func testMergeRanges() {
        var ranges = testRanges3()
        ranges.mergeRanges()
        // Distjoint Ranges so will not merge
        XCTAssertEqual(ranges, testRanges3())

        ranges.insertRange(MemoryRange(type: .Conventional, start: PhysAddress(5120), size: 3072, attributes: [.uncacheable, .writeThrough, .writeBack]))
        XCTAssertEqual(ranges.count, 6)
        XCTAssertEqual(ranges[3].type, .Conventional)
        XCTAssertEqual(ranges[4].type, .Conventional)
        XCTAssertEqual(ranges[5].type, .Conventional)
        ranges.mergeRanges()
        XCTAssertEqual(ranges.count, 4)
        XCTAssertEqual(ranges[3], MemoryRange(type: .Conventional, start: PhysAddress(4096), size: 6144, attributes: [.uncacheable, .writeThrough, .writeBack]))
    }

    func testPageOrSubPageAligned() {

        do {
            let ranges = [
                MemoryRange(type: .Conventional, start: PhysAddress(0x800), size: 0x1000, attributes: [.uncacheable]),
                MemoryRange(type: .Conventional, start: PhysAddress(0x1900), size: 0xf00, attributes: [.writeThrough]),
                MemoryRange(type: .BootData, start: PhysAddress(0x2800), size: 0x3f00, attributes: [.writeBack]),
            ]
            var iterator = MemoryRange.PageOrSubPageAligned(ranges: ranges, toPageSize: PageSize())
            XCTAssertEqual(iterator.next(), MemoryRange(type: .Conventional, start: PhysAddress(0x800), endAddress: PhysAddress(0xfff), attributes: [.uncacheable]))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .Conventional, start: PhysAddress(0x1000), endAddress: PhysAddress(0x17ff), attributes: [.uncacheable]))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .Hole, start: PhysAddress(0x1800), endAddress: PhysAddress(0x18ff), attributes: []))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .Conventional, start: PhysAddress(0x1900), endAddress: PhysAddress(0x1fff), attributes: [.writeThrough]))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .Conventional, start: PhysAddress(0x2000), endAddress: PhysAddress(0x27ff), attributes: [.writeThrough]))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .BootData, start: PhysAddress(0x2800), endAddress: PhysAddress(0x2fff), attributes: [.writeBack]))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .BootData, start: PhysAddress(0x3000), endAddress: PhysAddress(0x5fff), attributes: [.writeBack]))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .BootData, start: PhysAddress(0x6000), endAddress: PhysAddress(0x66ff), attributes: [.writeBack]))
            XCTAssertEqual(iterator.next(), nil)
        }

        do {
            let ranges = testRanges1()
            var iterator = MemoryRange.PageOrSubPageAligned(ranges: ranges, toPageSize: PageSize())
            XCTAssertEqual(iterator.next(), MemoryRange(type: .Conventional, start: PhysAddress(0), size: 636 * 1024, attributes: [.writeBack]))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .Conventional, start: PhysAddress(636 * 1024), size: 3 * 1024, attributes: [.writeBack]))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .Reserved, start: PhysAddress(0x9FC00), size: 1024, attributes: []))
            XCTAssertEqual(iterator.next(), ranges[2])
            XCTAssertEqual(iterator.next(), ranges[3])
            XCTAssertEqual(iterator.next(), ranges[4])
            XCTAssertEqual(iterator.next(), ranges[5])
            XCTAssertEqual(iterator.next(), ranges[6])
            XCTAssertEqual(iterator.next(), ranges[7])
            XCTAssertEqual(iterator.next(), nil)
        }

        do {
            var ranges = testRanges2()
            ranges.append(MemoryRange(type: .BootData, start: PhysAddress(0x2FF0), size: 0x100, attributes: [.readOnly, .writeBack]))
            var iterator = MemoryRange.PageOrSubPageAligned(ranges: ranges, toPageSize: PageSize())
            XCTAssertEqual(iterator.next(), ranges[0])
            XCTAssertEqual(iterator.next(), ranges[1])
            XCTAssertEqual(iterator.next(), ranges[2])
            XCTAssertEqual(iterator.next(), ranges[3])
            XCTAssertEqual(iterator.next(), MemoryRange(type: .Hole, start: PhysAddress(5120), size: 3072, attributes: []))
            XCTAssertEqual(iterator.next(), ranges[4])
            XCTAssertEqual(iterator.next(), MemoryRange(type: .Hole, start: PhysAddress(10240), size: 2032, attributes: []))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .BootData, start: PhysAddress(0x2FF0), size: 0x10, attributes: [.readOnly, .writeBack]))
            XCTAssertEqual(iterator.next(), MemoryRange(type: .BootData, start: PhysAddress(0x3000), size: 0xF0, attributes: [.readOnly, .writeBack]))
            XCTAssertEqual(iterator.next(), nil)
        }
    }

    func testAlignToPageSize() {

        struct MappableRange: Equatable {
            let physRange: PhysPageAlignedRegion
            let access: MemoryType.Access

            init(_ range: (UInt, UInt, MemoryType.Access)) {
                physRange = PhysPageAlignedRegion(PhysAddress(range.0), pageSize: PageSize(), pageCount: Int(range.1 / UInt(PAGE_SIZE)))
                access = range.2
            }

            init(_ range: (PhysPageAlignedRegion, MemoryType.Access)) {
                physRange = range.0
                access = range.1
            }

        }

        do {
            let ranges = [
                MemoryRange(type: .Conventional, start: PhysAddress(0x800), size: 0x400, attributes: [])
            ]
            let alignedRanges = ranges.align(toPageSize: PageSize())
            XCTAssertEqual(alignedRanges.count, 1)
            XCTAssertEqual(MappableRange(alignedRanges[0]), MappableRange((0, 4096, MemoryType.Access.unusable)))
        }

        do {
            /*
             MemoryRange(type: .Conventional, start: 0, size: 0x400)
             MemoryRange(type: .E820Reserved, start: 0x400, endAddress: 0x9FBFF),
             MemoryRange(type: .Reserved, start: 0x9FC00, size: 1024),
             MemoryRange(type: .Hole, start: 0xA0000, size: 320 * 1024),
             MemoryRange(type: .Reserved, start: 0xF0000, size: 64 * 1024),
             MemoryRange(type: .Conventional, start: 0x100000, size: 0xFFE0000 - 0x100000),
             MemoryRange(type: .Reserved, start: 0xFFE0000, size: 128 * 1024),
             MemoryRange(type: .Hole, start: 0x10000000, size: 0xFFFC0000 - 0x10000000),
             MemoryRange(type: .Reserved, start: 0xFFFC0000, size: 256 * 1024),
             */
            var ranges = testRanges1()
            ranges.insertRange(MemoryRange(type: .E820Reserved, start: PhysAddress(0x400), size: 0x100, attributes: [.nonVolatile]))
            ranges.insertRange(MemoryRange(type: .FrameBuffer, start: PhysAddress(0xA0000), size: 128 * 1024, attributes: [.uncacheable, .writeCombining]))
            ranges.insertRange(MemoryRange(type: .MemoryMappedIO, start: PhysAddress(0x100000000), size: 1024, attributes: [.uncacheable]))

            let alignedRanges = ranges.align(toPageSize: PageSize())

            XCTAssertEqual(alignedRanges.count, 11)
            XCTAssertEqual(MappableRange(alignedRanges[0]), MappableRange((0, 0x1000, .readOnly)))
            XCTAssertEqual(MappableRange(alignedRanges[1]), MappableRange((0x1000, 0x9e000, .readWrite)))
            XCTAssertEqual(MappableRange(alignedRanges[2]), MappableRange((0x9f000, 0x1000, .reserved)))
            XCTAssertEqual(MappableRange(alignedRanges[3]), MappableRange((0xa0000, 0x20000, .mmio)))
            XCTAssertEqual(MappableRange(alignedRanges[4]), MappableRange((0xc0000, 0x30000, .unusable)))
            XCTAssertEqual(MappableRange(alignedRanges[5]), MappableRange((0xf0000, 0x10000, .reserved)))
            XCTAssertEqual(MappableRange(alignedRanges[6]), MappableRange((0x100000, 0xfee0000, .readWrite)))
            XCTAssertEqual(MappableRange(alignedRanges[7]), MappableRange((0xffe0000, 0x20000, .reserved)))
            XCTAssertEqual(MappableRange(alignedRanges[8]), MappableRange((0x10000000, 0xeffc0000, .unusable)))
            XCTAssertEqual(MappableRange(alignedRanges[9]), MappableRange((0xfffc0000, 0x40000, .reserved)))
            XCTAssertEqual(MappableRange(alignedRanges[10]), MappableRange((0x100000000, 0x1000, .mmio)))
        }
    }
}
