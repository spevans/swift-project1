//
//  KlibTests.swift
//  acpitest
//
//  Created by Simon Evans on 06/12/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

import XCTest
@testable import Kernel

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
    }


    func testBitArray8() {
        var ba = BitArray64()
        XCTAssertEqual(ba.toUInt64(), 0)
        ba[7] = 1
        XCTAssertEqual(ba.toUInt64(), 128)
        XCTAssertEqual(ba.toUInt32(), 128)
        XCTAssertEqual(ba.toUInt16(), 128)
        XCTAssertEqual(ba.toUInt8(), 128)
    }

    func testBitArray64() {
        var ba = BitArray64()
        XCTAssertEqual(ba.toUInt64(), 0)
        XCTAssertEqual(ba[63], 0)
        ba[63] = 1
        XCTAssertEqual(ba[63], 1)
        XCTAssertEqual(ba.toUInt64(), 9223372036854775808)
        XCTAssertEqual(ba.toUInt32(), 0)
        XCTAssertEqual(ba.toUInt16(), 0)
        XCTAssertEqual(ba.toUInt8(), 0)
    }

    func testBitmapAllocator8() {
        var allocator = BitmapAllocator8()
        XCTAssertEqual(allocator.entryCount, 8)
        for _ in 1...8 {
            XCTAssertNotNil(allocator.allocate())
        }
        XCTAssertNil(allocator.allocate())
        XCTAssertFalse(allocator.hasSpace())
        allocator.free(entry: 1)
        XCTAssertTrue(allocator.hasSpace())
        XCTAssertNotNil(allocator.allocate())
    }

    func testBitmapAllocator32() {
        for entries in 1...32 {
            var allocator = BitmapAllocator32(entries: entries)
            XCTAssertEqual(allocator.entryCount, entries)
            for _ in 1...entries {
                XCTAssertNotNil(allocator.allocate())
            }
            XCTAssertNil(allocator.allocate())
            XCTAssertFalse(allocator.hasSpace())
            allocator.free(entry: entries - 1)
            XCTAssertTrue(allocator.hasSpace())
            XCTAssertNotNil(allocator.allocate(), "entries: \(entries)")
        }
    }

    func testBitmapAllocator64() {
        var allocator = BitmapAllocator64()
        XCTAssertEqual(allocator.entryCount, 64)
        for _ in 1...64 {
            XCTAssertNotNil(allocator.allocate())
        }
        XCTAssertNil(allocator.allocate())
        XCTAssertFalse(allocator.hasSpace())
        allocator.free(entry: 1)
        XCTAssertTrue(allocator.hasSpace())
        XCTAssertNotNil(allocator.allocate())
    }

    func testBitmapAllocator128() {
        var allocator = BitmapAllocator128()
        XCTAssertEqual(allocator.entryCount, 128)
        for _ in 1...128 {
            XCTAssertNotNil(allocator.allocate())
        }
        XCTAssertNil(allocator.allocate())
        XCTAssertFalse(allocator.hasSpace())
        allocator.free(entry: 1)
        XCTAssertTrue(allocator.hasSpace())
        XCTAssertNotNil(allocator.allocate())
    }

    func testLargeBitmapAllocator() {
        func testAllocatorOfSize(maxElements: Int) {
            var allocator = LargeBitmapAllocator(maxElements: maxElements)
            XCTAssertEqual(allocator.entryCount, maxElements)
            XCTAssertEqual(allocator.freeEntryCount(), maxElements)
            var entries: [Int] = []
            for _ in 1...maxElements {
                let entry = allocator.allocate()
                XCTAssertNotNil(entry)
                entries.append(entry!)
            }
            XCTAssertEqual(allocator.freeEntryCount(), 0)
            XCTAssertNil(allocator.allocate())
            for entry in entries.reversed() {
                allocator.free(entry: entry)
            }
            XCTAssertEqual(allocator.freeEntryCount(), maxElements)
            XCTAssertEqual(allocator.hasSpace(), true)
        }

        testAllocatorOfSize(maxElements: 1)
        testAllocatorOfSize(maxElements: 63)
        testAllocatorOfSize(maxElements: 64)
        testAllocatorOfSize(maxElements: 1024)
    }

    func testStringToValue() {
        XCTAssertEqual(UInt32("0x99000000"), 0x9000000)
    }
}
