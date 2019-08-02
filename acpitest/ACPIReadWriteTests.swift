//
//  ACPIReadWriteTests.swift
//  acpitest
//
//  Created by Simon Evans on 16/11/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

import XCTest

class ACPIReadWriteTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRegionSpaceUInt8() {
        let regionSpace = SystemMemorySpace<UInt8>(offset: 0, length: 64, flags: AMLFieldFlags(flags: 0))
        for x in 0...55 {
            var v: AMLInteger = 0xff

            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            var readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 0xaa
            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 0x55
            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 10000
            regionSpace.write(bitOffset: x, width: 16, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 16)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)
        }
    }

    func testRegionSpaceUInt16() {
        let regionSpace = SystemMemorySpace<UInt16>(offset: 0, length: 64, flags: AMLFieldFlags(flags: 0))
        for x in 0...55 {
            var v: AMLInteger = 0xff

            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            var readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 0xaa
            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 0x55
            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 10000
            regionSpace.write(bitOffset: x, width: 16, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 16)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)
        }
    }

    func testRegionSpaceUInt32() {
        let regionSpace = SystemMemorySpace<UInt16>(offset: 0, length: 64, flags: AMLFieldFlags(flags: 0))
        for x in 0...55 {
            var v: AMLInteger = 0xff

            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            var readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 0xaa
            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 0x55
            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 10000
            regionSpace.write(bitOffset: x, width: 16, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 16)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)
        }
    }

    func testRegionSpaceUInt64() {
        let regionSpace = SystemMemorySpace<UInt64>(offset: 0, length: 64, flags: AMLFieldFlags(flags: 0))
        for x in 0...55 {
            var v: AMLInteger = 0xff

            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            var readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 0xaa
            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 0x55
            regionSpace.write(bitOffset: x, width: 8, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 8)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)

            v = 10000
            regionSpace.write(bitOffset: x, width: 16, value: v)
            //print(regionSpace)
            readBack = regionSpace.read(bitOffset: x, width: 16)
            XCTAssertEqual(readBack, v)
            regionSpace.write(bitOffset: 0, width: 64, value: 0)
        }
    }
}
