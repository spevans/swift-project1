//
//  ACPIReadWriteTests.swift
//  acpitest
//
//  Created by Simon Evans on 16/11/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

import XCTest
@testable import Kernel

extension AMLDefOpRegion {
    func read(bitOffset: UInt, width: UInt, flags: AMLFieldFlags,
              context: inout ACPI.AMLExecutionContext) throws(AMLError) -> AMLObject {

        let amlAccessField = AMLAccessField(type: AMLAccessType(value: 0), attrib: 0)
        let fieldSettings = AMLFieldSettings(
            bitOffset: bitOffset,
            bitWidth: width, fieldFlags: flags,
            accessField: amlAccessField, extendedAccessField: nil
        )
        return try read(fieldSettings: fieldSettings, context: &context)
    }

    func write(bitOffset: UInt, width: UInt, value: AMLObject, flags: AMLFieldFlags,
               context: inout ACPI.AMLExecutionContext) throws(AMLError) {
        let amlAccessField = AMLAccessField(type: AMLAccessType(value: 0), attrib: 0)
        let fieldSettings = AMLFieldSettings(
            bitOffset: bitOffset,
            bitWidth: width, fieldFlags: flags,
            accessField: amlAccessField, extendedAccessField: nil
        )
        try write(value: value, fieldSettings: fieldSettings, context: &context)
    }
}


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

    func testRegionSpaceUInt8() throws {
        let flags = AMLFieldFlags(fieldAccessType: .ByteAcc, lockRule: .NoLock, updateRule: .Preserve)
        let regionMemory = mapIORegion(region: PhysRegion(start: PhysAddress(128), size: 64))
        let regionSpace = try AMLDefOpRegion(fullname: AMLNameString("test"), regionType: .systemMemory,
                                         offset: AMLTermArg(128), length: AMLTermArg(64))
        var context = ACPI.AMLExecutionContext(scope: AMLNameString("\\"))

        let amlAccessField = AMLAccessField(type: AMLAccessType(value: 0), attrib: 0)


        for x: UInt in 0...55 {
            for idx in 0..<regionMemory.regionSize { regionMemory.write(value: 0 as UInt8, toByteOffset: idx) }
            //opRegionSpace.reset()
            var v = AMLObject(0xff)

            var fieldSettings = AMLFieldSettings(bitOffset: x, bitWidth: 8, fieldFlags: flags,
                                                 accessField: amlAccessField, extendedAccessField: nil)
            try regionSpace.write(value: v, fieldSettings: fieldSettings, context: &context)
            //print(regionSpace)
            var readBack = try regionSpace.read(fieldSettings: fieldSettings, context: &context)
            XCTAssertEqual(readBack, v, "bitOffset: \(x)")

            v = AMLObject(0xaa)
            try regionSpace.write(value: v, fieldSettings: fieldSettings, context: &context)
            //print(regionSpace)
            readBack = try regionSpace.read(fieldSettings: fieldSettings, context: &context)
            XCTAssertEqual(readBack, v, "bitOffset: \(x)")

            v = AMLObject(0x55)
            try regionSpace.write(value: v, fieldSettings: fieldSettings, context: &context)
            //print(regionSpace)
            readBack = try regionSpace.read(fieldSettings: fieldSettings, context: &context)
            XCTAssertEqual(readBack, v, "bitOffset: \(x)")

            v = AMLObject(10000)
            fieldSettings = AMLFieldSettings(bitOffset: x, bitWidth: 16, fieldFlags: flags,
                                             accessField: amlAccessField, extendedAccessField: nil)

            try regionSpace.write(value: v, fieldSettings: fieldSettings, context: &context)
            //print(regionSpace)
            readBack = try regionSpace.read(fieldSettings: fieldSettings, context: &context)
            XCTAssertEqual(readBack, v, "bitOffset: \(x)")
        }
    }

    func testRegionSpaceUInt16() throws {
        let flags = AMLFieldFlags(fieldAccessType: .WordAcc, lockRule: .NoLock, updateRule: .WriteAsZeros)
        let regionMemory = mapIORegion(region: PhysRegion(start: PhysAddress(128), size: 64))
        let regionSpace = try AMLDefOpRegion(fullname: AMLNameString("test"), regionType: .systemMemory,
                                         offset: AMLTermArg(128), length: AMLTermArg(64))

        var context = ACPI.AMLExecutionContext(scope: AMLNameString("\\"))

        for x: UInt in 0...55 {
            // Reset the region
            for idx in 0..<regionMemory.regionSize {
                regionMemory.write(value: 0 as UInt8, toByteOffset: idx)
            }
            var v = AMLObject(0xff)

            try regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags, context: &context)
            //print(regionSpace)
            var readBack = try regionSpace.read(bitOffset: x, width: 8, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)

            v = AMLObject(0xaa)
            try regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags, context: &context)
            //print(regionSpace)
            readBack = try regionSpace.read(bitOffset: x, width: 8, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)

            v = AMLObject(0x55)
            try regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags, context: &context)
            readBack = try regionSpace.read(bitOffset: x, width: 8, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)

            v = AMLObject(10000)
            // Reset the region
            for idx in 0..<regionMemory.regionSize {
                regionMemory.write(value: 0 as UInt8, toByteOffset: idx)
            }
            try regionSpace.write(bitOffset: x, width: 16, value: v, flags: flags, context: &context)
            readBack = try regionSpace.read(bitOffset: x, width: 16, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)
        }
    }

    func testRegionSpaceUInt32() throws {
        let flags = AMLFieldFlags(fieldAccessType: .DWordAcc, lockRule: .NoLock, updateRule: .Preserve)
        let regionMemory = mapIORegion(region: PhysRegion(start: PhysAddress(128), size: 64))
        let regionSpace = try AMLDefOpRegion(fullname: AMLNameString("test"), regionType: .systemMemory,
                                         offset: AMLTermArg(128), length: AMLTermArg(64))
        var context = ACPI.AMLExecutionContext(scope: AMLNameString("\\"))

        for x: UInt in 0...55 {
            // Reset the region
            for idx in 0..<regionMemory.regionSize {
                regionMemory.write(value: 0 as UInt8, toByteOffset: idx)
            }
//            opRegionSpace.reset()
            var v = AMLObject(0xff)

            try regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags, context: &context)
            //print(regionSpace)
            var readBack = try regionSpace.read(bitOffset: x, width: 8, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)

            v = AMLObject(0xaa)
            try regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags, context: &context)
            //print(regionSpace)
            readBack = try regionSpace.read(bitOffset: x, width: 8, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)

            v = AMLObject(0x55)
            try regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags, context: &context)
            //print(regionSpace)
            readBack = try regionSpace.read(bitOffset: x, width: 8, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)

            v = AMLObject(10000)
            try regionSpace.write(bitOffset: x, width: 16, value: v, flags: flags, context: &context)
            //print(regionSpace)
            readBack = try regionSpace.read(bitOffset: x, width: 16, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)
        }
    }

    func testRegionSpaceUInt64() throws {
        let flags = AMLFieldFlags(fieldAccessType: .QWordAcc, lockRule: .NoLock, updateRule: .Preserve)
        let regionMemory = mapIORegion(region: PhysRegion(start: PhysAddress(128), size: 64))
        let regionSpace = try AMLDefOpRegion(fullname: AMLNameString("test"), regionType: .systemMemory,
                                         offset: AMLTermArg(128), length: AMLTermArg(64))

        var context = ACPI.AMLExecutionContext(scope: AMLNameString("\\"))

        for x: UInt in 0...55 {
            // Reset the region
            for idx in 0..<regionMemory.regionSize {
                regionMemory.write(value: 0 as UInt8, toByteOffset: idx)
            }
            var v = AMLObject(0xff)

            try regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags, context: &context)
            var readBack = try regionSpace.read(bitOffset: x, width: 8, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)

            v = AMLObject(0xaa)
            try regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags, context: &context)
            //print(regionSpace)
            readBack = try regionSpace.read(bitOffset: x, width: 8, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)

            v = AMLObject(0x55)
            try regionSpace.write(bitOffset: x, width: 8, value: v, flags: flags, context: &context)
            //print(regionSpace)
            readBack = try regionSpace.read(bitOffset: x, width: 8, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)

            v = AMLObject(10000)
            try regionSpace.write(bitOffset: x, width: 16, value: v, flags: flags, context: &context)
            //print(regionSpace)
            readBack = try regionSpace.read(bitOffset: x, width: 16, flags: flags, context: &context)
            XCTAssertEqual(readBack, v)
        }
    }

    func testRegionSpaceBits() throws {
        var flags = AMLFieldFlags(fieldAccessType: .AnyAcc, lockRule: .NoLock, updateRule: .Preserve)

        let memory: [UInt8] = [0b0000_0001, 0b0010_0011, 0b0100_0101, 0b0110_0111, 0b1000_1001] // 0x01 0x23 0x45 0x56 0x78
        let regionMemory = mapIORegion(region: PhysRegion(start: PhysAddress(128), size: 64))
        let regionSpace = try AMLDefOpRegion(fullname: AMLNameString("test"), regionType: .systemMemory,
                                         offset: AMLTermArg(128), length: AMLTermArg(64))
        for (index, data) in memory.enumerated() {
            regionMemory.write(value: data, toByteOffset: index)
        }
        var context = ACPI.AMLExecutionContext(scope: AMLNameString("\\"))


        let amlAccessField = AMLAccessField(type: AMLAccessType(value: 0), attrib: 0)
        var fieldSettings = AMLFieldSettings(bitOffset: 4, bitWidth: 4, fieldFlags: flags,
                                             accessField: amlAccessField, extendedAccessField: nil)
        XCTAssertEqual(try regionSpace.read(fieldSettings: fieldSettings, context: &context), AMLObject(0x0))

        fieldSettings = AMLFieldSettings(bitOffset: 2, bitWidth: 13, fieldFlags: flags,
                                             accessField: amlAccessField, extendedAccessField: nil)
        XCTAssertEqual(try regionSpace.read(fieldSettings: fieldSettings, context: &context), AMLObject(0b0_1000_1100_0000))

        fieldSettings = AMLFieldSettings(bitOffset: 0, bitWidth: 13, fieldFlags: flags,
                                             accessField: amlAccessField, extendedAccessField: nil)
        XCTAssertEqual(try regionSpace.read(fieldSettings: fieldSettings, context: &context), AMLObject(0b0_0011_0000_0001))

        fieldSettings = AMLFieldSettings(bitOffset: 7, bitWidth: 24, fieldFlags: flags,
                                             accessField: amlAccessField, extendedAccessField: nil)
        XCTAssertEqual(try regionSpace.read(fieldSettings: fieldSettings, context: &context), AMLObject(0b110_0111_0100_0101_0010_0011_0))


        fieldSettings = AMLFieldSettings(bitOffset: 7, bitWidth: 26, fieldFlags: flags,
                                             accessField: amlAccessField, extendedAccessField: nil)
        XCTAssertEqual(try regionSpace.read(fieldSettings: fieldSettings, context: &context), AMLObject(0b1_0110_0111_0100_0101_0010_0011_0))

        flags = AMLFieldFlags(fieldAccessType: .DWordAcc, lockRule: .NoLock, updateRule: .WriteAsOnes)
        fieldSettings = AMLFieldSettings(bitOffset: 0, bitWidth: 32, fieldFlags: flags,
                                             accessField: amlAccessField, extendedAccessField: nil)
        // Reset the region
        for idx in 0..<regionMemory.regionSize {
            regionMemory.write(value: 0 as UInt8, toByteOffset: idx)
        }

        for (index, data) in  [UInt8(0), 0, 0, 0].enumerated() {
            XCTAssertEqual(regionMemory.read(fromByteOffset: index), data)
        }
        XCTAssertEqual(try regionSpace.read(fieldSettings: fieldSettings, context: &context), AMLObject(0x0))

        fieldSettings = AMLFieldSettings(bitOffset: 1, bitWidth: 2, fieldFlags: flags,
                                             accessField: amlAccessField, extendedAccessField: nil)
        try regionSpace.write(value: AMLObject(1), fieldSettings: fieldSettings, context: &context)
        for (index, data) in  [UInt8(0xfb), 0xff, 0xff, 0xff].enumerated() {
            XCTAssertEqual(regionMemory.read(fromByteOffset: index), data)
        }
        fieldSettings = AMLFieldSettings(bitOffset: 0, bitWidth: 32, fieldFlags: flags,
                                             accessField: amlAccessField, extendedAccessField: nil)
        XCTAssertEqual(try regionSpace.read(fieldSettings: fieldSettings, context: &context), AMLObject(0xff_ff_ff_fb))
    }

    func testAMLNamedField() throws {
        ACPIDebug = false
        let regionMemory = mapIORegion(region: PhysRegion(start: PhysAddress(128), size: 32))
        let regionSpace = try AMLDefOpRegion(fullname: AMLNameString("test"), regionType: .systemMemory,
                                         offset: AMLTermArg(128), length: AMLTermArg(32))

        var context = ACPI.AMLExecutionContext(scope: AMLNameString("\\"))

        let fieldSettings = AMLFieldSettings(
            bitOffset: 0,
            bitWidth: 256,
            fieldFlags: AMLFieldFlags(fieldAccessType: .ByteAcc,
                                      lockRule: .NoLock,
                                      updateRule: .Preserve),
            accessField: AMLAccessField(type: AMLAccessType(value: 0), attrib: 0),
            extendedAccessField: nil
        )

        let field = AMLNamedField(name: AMLNameString("TEST"),
                                  opRegion: regionSpace,
                                  fieldSettings: fieldSettings
        )
        let string = AMLString(asciiString: "This is a string")
        try field.updateValue(to: AMLObject(string), context: &context)
        let value = try field.readValue(context: &context)
        let buffer = value.bufferValue!.asAMLBuffer()
        let outputString = AMLString(buffer: buffer)
        XCTAssertEqual(string.data, outputString.data)
    }

    func testAMLBitStorage() {
        var storage = AMLBitStorage()
        storage.append(1, bitWidth: 1)
        storage.append(2, bitWidth: 2)
        storage.append(3, bitWidth: 3)
        storage.append(4, bitWidth: 4)
        storage.append(5, bitWidth: 5)
        storage.append(6, bitWidth: 6)
        XCTAssertEqual(storage.result().integerValue, 0b000110001010100011101)

        storage.append(7, bitWidth: 3)
        XCTAssertEqual(storage.result().integerValue, 0b111000110001010100011101)

        storage.append(0x1234567890abcdef, bitWidth: 64)
        XCTAssertEqual(storage.result().bufferValue?.asAMLBuffer(), [
            0b00011101, 0b00010101, 0b11100011,
            0xef, 0xcd, 0xab, 0x90, 0x78, 0x56, 0x34, 0x12
        ] as [UInt8])

        storage = AMLBitStorage()
        storage.append(0, bitWidth: 61)
        storage.append(0x7f, bitWidth: 7)
        XCTAssertEqual(storage.result().bufferValue?.asAMLBuffer(), [
            0,0,0,0,0,0,0,0b11100000, 0b1111
        ])
    }
}

