/*
 * kernel/klib/extensions/bytearray.swift
 *
 * Created by Simon Evans on 28/03/2017.
 * Copyright © 2015 - 2017 Simon Evans. All rights reserved.
 *
 * ByteArray<x> types. Treat UInt16/UInt32/UInt64 as arrays of bytes.
 *
 */

struct ByteArray2: CustomStringConvertible {
    private(set) var rawValue: UInt16

    var description: String { return String(rawValue, radix: 16) }


    init() {
        rawValue = 0
    }

    init(_ rawValue: Int) {
        self.rawValue = UInt16(rawValue)
    }

    init(_ rawValue: UInt) {
        self.rawValue = UInt16(rawValue)
    }

    init(_ rawValue: UInt8) {
        self.rawValue = UInt16(rawValue)
    }

    init(withBytes bytes: UInt8...) {
        precondition(bytes.count <= 2)

        self.rawValue = 0
        var shift: UInt16 = 0
        for byte in bytes {
            rawValue |= (UInt16(byte) << shift)
            shift += 8
        }
    }

    init(_ rawValue: UInt16) {
        self.rawValue = rawValue
    }

    subscript(index: Int) -> Int {
        get {
            precondition(index >= 0)
            precondition(index < 2)

            let shift = UInt16(index * 8)
            return Int((rawValue >> shift) & UInt16(UInt8.max))
        }

        set(newValue) {
            precondition(index >= 0)
            precondition(index < 2)
            precondition(newValue >= 0 || newValue <= Int(UInt8.max))

            let shift = UInt16(index * 8)
            let mask = ~(UInt16(UInt8.max) << shift)
            let newValue = UInt16(newValue) << shift
            rawValue &= mask
            rawValue |= newValue
        }
    }

    func toInt() -> Int {
        return Int(rawValue)
    }
}


struct ByteArray4: CustomStringConvertible {
    private(set) var rawValue: UInt32

    var description: String { return String(rawValue, radix: 16) }


    init() {
        rawValue = 0
    }

    init(_ rawValue: Int) {
        self.rawValue = UInt32(rawValue)
    }

    init(_ rawValue: UInt) {
        self.rawValue = UInt32(rawValue)
    }

    init(_ rawValue: UInt8) {
        self.rawValue = UInt32(rawValue)
    }

    init(withBytes bytes: UInt8...) {
        precondition(bytes.count <= 4)

        self.rawValue = 0
        var shift: UInt32 = 0
        for byte in bytes {
            rawValue |= (UInt32(byte) << shift)
            shift += 8
        }
    }

    init(_ rawValue: UInt16) {
        self.rawValue = UInt32(rawValue)
    }

    init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }

    subscript(index: Int) -> Int {
        get {
            precondition(index >= 0)
            precondition(index < 4)

            let shift = UInt32(index * 8)
            return Int((rawValue >> shift) & UInt32(UInt8.max))
        }

        set(newValue) {
            precondition(index >= 0)
            precondition(index < 4)
            precondition(newValue >= 0 || newValue <= Int(UInt8.max))

            let shift = UInt32(index * 8)
            let mask = ~(UInt32(UInt8.max) << shift)
            let newValue = UInt32(newValue) << shift
            rawValue &= mask
            rawValue |= newValue
        }
    }

    func toInt() -> Int {
        return Int(rawValue)
    }
}


struct ByteArray8: CustomStringConvertible {
    private(set) var rawValue: UInt64

    var description: String { return String(rawValue, radix: 16) }


    init() {
        rawValue = 0
    }

    init(_ rawValue: Int) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt8) {
        self.rawValue = UInt64(rawValue)
    }

    init(withBytes bytes: UInt8...) {
        precondition(bytes.count <= 8)

        self.rawValue = 0
        var shift: UInt64 = 0
        for byte in bytes {
            rawValue |= (UInt64(byte) << shift)
            shift += 8
        }
    }


    init(_ rawValue: UInt16) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt32) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }

    subscript(index: Int) -> Int {
        get {
            precondition(index >= 0)
            precondition(index < 8)

            let shift = UInt64(index * 8)
            return Int((rawValue >> shift) & UInt64(UInt8.max))
        }

        set(newValue) {
            precondition(index >= 0)
            precondition(index < 8)
            precondition(newValue >= 0 || newValue <= Int(UInt8.max))

            let shift = UInt64(index * 8)
            let mask = ~(UInt64(UInt8.max) << shift)
            let newValue = UInt64(newValue) << shift
            rawValue &= mask
            rawValue |= newValue
        }
    }

    func toInt() -> Int {
        return Int(rawValue)
    }
}
