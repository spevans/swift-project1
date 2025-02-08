//
//  ACPIReadWriteTests.swift
//  acpitest
//
//  Created by Simon Evans on 16/11/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

import XCTest


class ACPIReadWriteTests: XCTestCase {

    static override func setUp() {
        FakePhysMemory.addPhysicalMemory(start: PhysAddress(128), size: 64)
    }

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRegionSpaceUInt8() {
        let flags = AMLFieldFlags(fieldAccessType: .ByteAcc, lockRule: .NoLock, updateRule: .Preserve)
        let regionSpace = OpRegionSpace.systemMemory(SystemMemorySpace(offset: 128, length: 64))
        for x in 0...55 {
            var v: AMLInteger = 0xff

            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            var readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 0xaa
            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 0x55
            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 10000
            regionSpace.write(bitOffset: x, width: 16, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 16, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)
        }
    }

    func testRegionSpaceUInt16() {
        let flags = AMLFieldFlags(fieldAccessType: .WordAcc, lockRule: .NoLock, updateRule: .Preserve)
        let regionSpace = OpRegionSpace.systemMemory(SystemMemorySpace(offset: 128, length: 64))
        for x in 0...55 {
            var v: AMLInteger = 0xff

            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            var readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 0xaa
            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 0x55
            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 10000
            regionSpace.write(bitOffset: x, width: 16, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 16, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)
        }
    }

    func testRegionSpaceUInt32() {
        let flags = AMLFieldFlags(fieldAccessType: .DWordAcc, lockRule: .NoLock, updateRule: .Preserve)
        let regionSpace = OpRegionSpace.systemMemory(SystemMemorySpace(offset: 128, length: 64))
        for x in 0...55 {
            var v: AMLInteger = 0xff

            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            var readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 0xaa
            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 0x55
            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 10000
            regionSpace.write(bitOffset: x, width: 16, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 16, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)
        }
    }

    func testRegionSpaceUInt64() {
        let flags = AMLFieldFlags(fieldAccessType: .QWordAcc, lockRule: .NoLock, updateRule: .Preserve)
        let regionSpace = OpRegionSpace.systemMemory(SystemMemorySpace(offset: 128, length: 64))
        for x in 0...55 {
            var v: AMLInteger = 0xff

            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            var readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 0xaa
            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 0x55
            regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)

            v = 10000
            regionSpace.write(bitOffset: x, width: 16, value: v, flags: flags)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 16, flags: flags)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0, flags: flags)
        }
    }
}
