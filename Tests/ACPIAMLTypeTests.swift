//
//  ACPIAMLTypeTests.swift
//  KernelTests
//
//  Created by Simon Evans on 21/11/2025.
//

import Testing
@testable import Kernel


struct ACPIAMLTypeTests {

    @Test func amlStingTests() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var amlString = AMLString()
        #expect(amlString.isEmpty)
        #expect(amlString.count == 0)
        #expect(amlString.description == "")
        #expect(amlString.data.count == 1)
        #expect(amlString.data.last == 0)

        amlString = try AMLString("Hello, World!")
        #expect(!amlString.description.isEmpty)
        #expect(amlString.count == 13)
        #expect(amlString.description == "Hello, World!")
        #expect(amlString.description.utf8.count == 13)
        #expect(amlString.description.utf8.last == 33)

        amlString = AMLString(integer: 0)
        #expect(amlString.description == "00000000000000000000")

        amlString = AMLString(integer: 0x123456789, radix: 16)
        #expect(amlString.description == "0000000123456789")

        // Non-ascii string
        let badString = try? AMLString("hello 😊")
        #expect(badString == nil)

        let hexString = AMLString(asciiString: "0x123")
        #expect(try hexString.asAMLInteger() == AMLInteger(0x123))

        let testString = AMLString(asciiString: "1234567890")
        #expect(testString.description == "1234567890")
        #expect(try testString.asAMLInteger() == AMLInteger(1234567890))

        let nonNumberString = AMLString(asciiString: "abc123")
        #expect(throws: (AMLError).self) {
            try nonNumberString.asAMLInteger()
        }


        let subString1 = testString.subString(offset: 0, length: 3)
        #expect(subString1.description == "123")

        let subString2 = testString.subString(offset: 0, length: 10)
        #expect(subString2.description == "1234567890")

        let subString3 = testString.subString(offset: 9, length: 1)
        #expect(subString3.description == "0")

        let subString4 = testString.subString(offset: 9, length: 2)
        #expect(subString4.description == "0")

        let subString5 = testString.subString(offset: 9, length: 2)
        #expect(subString5.description == "0")

        let subString6 = testString.subString(offset: 9, length: 0)
        #expect(subString6.description == "")

        let subString7 = testString.subString(offset: 12, length: 30)
        #expect(subString7.description == "")

    }

    @Test func amlBufferTests() async throws {
        let amlBuffer = AMLBuffer(integer: AMLInteger(0x0102030405060708))
        #expect(amlBuffer.count == 8)
    }

    @Test func amlSharedBufferTests() async throws {
        let amlSharedBuffer = AMLSharedBuffer(AMLBuffer(integer: 0x0123456789abcdef))
        let subBuf1 = amlSharedBuffer.subBuffer(offset: 0, length: 4)
        #expect(subBuf1.count == 4)
        #expect(subBuf1.asAMLBuffer() == [0xef, 0xcd, 0xab, 0x89])

        let subBuf2 = amlSharedBuffer.subBuffer(offset: 0, length: 10)
        #expect(subBuf2.count == 8)
        #expect(subBuf2.asAMLBuffer() == amlSharedBuffer.asAMLBuffer())

        let subBuf3 = amlSharedBuffer.subBuffer(offset: 4, length: 0)
        #expect(subBuf3.count == 0)
        #expect(subBuf3.asAMLBuffer() == [])

        let subBuf4 = amlSharedBuffer.subBuffer(offset: 8, length: 4)
        #expect(subBuf4.count == 0)
        #expect(subBuf4.asAMLBuffer() == [])

        let subBuf5 = amlSharedBuffer.subBuffer(offset: 7, length: 2)
        #expect(subBuf5.count == 1)
        #expect(subBuf5.asAMLBuffer() == [0x01])
    }

    @Test func testAMLByteIterator() throws {
        let value = AMLInteger(0xbbbb_aaaa_9999_1255)
        var iterator = AMLByteIterator(value, totalBits: 32) //, accessWidth: 8, initialBitCount: 0)

        #expect(iterator.nextBits(8) == AMLInteger(0x55))
        #expect(iterator.nextBits(8) == AMLInteger(0x12))
        #expect(iterator.nextBits(8) == AMLInteger(0x99))
        #expect(iterator.nextBits(8) == AMLInteger(0x99))
        #expect(iterator.nextBits(8) == nil)

        iterator = try AMLByteIterator(AMLBuffer(integer: value), totalBits: 32)
        #expect(iterator.nextBits(8) == AMLInteger(0x55))
        #expect(iterator.nextBits(8) == AMLInteger(0x12))
        #expect(iterator.nextBits(8) == AMLInteger(0x99))
        #expect(iterator.nextBits(8) == AMLInteger(0x99))
        #expect(iterator.nextBits(8) == nil)
        #expect(iterator.nextBits(1) == nil)

        iterator = AMLByteIterator(value, totalBits: 32)
        #expect(iterator.nextBits(16) == AMLInteger(0x1255))
        #expect(iterator.nextBits(16) == AMLInteger(0x9999))
        #expect(iterator.nextBits(16) == nil)
        #expect(iterator.nextBits(1) == nil)

        iterator = try AMLByteIterator(AMLBuffer(integer: value), totalBits: 32)
        #expect(iterator.nextBits(16) == AMLInteger(0x1255))
        #expect(iterator.nextBits(16) == AMLInteger(0x9999))
//        #expect(iterator.nextBits(16) == nil)
        #expect(iterator.nextBits(1) == nil)


        iterator = AMLByteIterator(value, totalBits: 32)
        #expect(iterator.nextBits(3) == AMLInteger(0x5))
        #expect(iterator.nextBits(16) == AMLInteger(0x224a))
        #expect(iterator.nextBits(13) == AMLInteger(0x1333))
        #expect(iterator.nextBits(1) == nil)

        iterator = try AMLByteIterator(AMLBuffer(integer: value), totalBits: 32)
        #expect(iterator.nextBits(3) == AMLInteger(0x5))
        #expect(iterator.nextBits(16) == AMLInteger(0x224a))
        #expect(iterator.nextBits(16) == nil)
        #expect(iterator.bitsRemaining == 13)
        #expect(iterator.nextBits(13) == AMLInteger(0x1333))
        #expect(iterator.bitsRemaining == 0)
        #expect(iterator.nextBits(1) == nil)


        iterator = AMLByteIterator(value, totalBits: 32)
        #expect(iterator.bitsRemaining == 32)
        #expect(iterator.nextBits(32) == AMLInteger(0x9999_1255))
        #expect(iterator.bitsRemaining == 0)
        #expect(iterator.nextBits(32) == nil)

        iterator = try AMLByteIterator(AMLBuffer(integer: value), totalBits: 32)
        #expect(iterator.bitsRemaining == 32)
        #expect(iterator.nextBits(32) == AMLInteger(0x9999_1255))
        #expect(iterator.bitsRemaining == 0)
        #expect(iterator.nextBits(32) == nil)


        iterator = AMLByteIterator(value, totalBits: 32)
        #expect(iterator.nextBits(4) == AMLInteger(0x5))
        #expect(iterator.bitsRemaining == 28)
        #expect(iterator.nextBits(28) == AMLInteger(0x0_9999_125))
        #expect(iterator.nextBits(1) == nil)

        iterator = try AMLByteIterator(AMLBuffer(integer: value), totalBits: 32)
        #expect(iterator.nextBits(4) == AMLInteger(0x5))
        #expect(iterator.nextBits(28) == AMLInteger(0x0_9999_125))
        #expect(iterator.nextBits(1) == nil)
        #expect(iterator.bitsRemaining == 0)
        #expect(iterator.nextBits(1) == nil)

        var buffer = AMLBuffer(integer: 0x1234567890abcdef)
        buffer.append(contentsOf: [0x01, 0x10])
        iterator = try AMLByteIterator(buffer, totalBits: 79)
        #expect(iterator.nextBits(3) == 7)
        #expect(iterator.nextBits(64) == 0x22468ACF121579BD)
        #expect(iterator.nextBits(12) == 0x200)
        #expect(iterator.bitsRemaining == 0)
        #expect(iterator.nextBits(64) == nil)

        // Large bitwidths exceeding the input data
        iterator = AMLByteIterator(AMLInteger(123), totalBits: 256)
        #expect(iterator.nextBits(8) == 123)
        #expect(iterator.nextBits(16) == 0)
        #expect(iterator.nextBits(32) == 0)
        for _ in 1...3 {
            #expect(iterator.nextBits(64) == AMLInteger(0))
        }
        #expect(iterator.bitsRemaining == 8)
        #expect(iterator.nextBits(8) == AMLInteger(0))
        #expect(iterator.bitsRemaining == (0))
        #expect(iterator.nextBits(64) == nil)

        iterator = try AMLByteIterator(AMLBuffer(integer: 123), totalBits: 256)
        #expect(iterator.nextBits(9) == 123)
        #expect(iterator.nextBits(16) == 0)
        #expect(iterator.nextBits(32) == 0)
        for _ in 1...3 {
            #expect(iterator.nextBits(64) == AMLInteger(0))
        }
        #expect(iterator.bitsRemaining == 7)
        #expect(iterator.nextBits(7) == AMLInteger(0))
        #expect(iterator.bitsRemaining == (0))
        #expect(iterator.nextBits(64) == nil)
    }
}


