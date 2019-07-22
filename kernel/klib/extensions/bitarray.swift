/*
 * kernel/klib/extensions/bitarray.swift
 *
 * Created by Simon Evans on 28/03/2017.
 * Copyright © 2015 - 2017 Simon Evans. All rights reserved.
 *
 * BitArray<x> types. Treat UInt8/UInt16/UInt32/UInt64 as arrays of bits.
 *
 */

struct BitArray8: CustomStringConvertible {
    private(set) var rawValue: UInt8

    var description: String { return String(rawValue, radix: 2) }


    init() {
        rawValue = 0
    }

    init(_ rawValue: Int) {
        self.rawValue = UInt8(rawValue)
    }

    init(_ rawValue: UInt) {
        self.rawValue = UInt8(rawValue)
    }

    init(_ rawValue: UInt8) {
        self.rawValue = rawValue
    }


    subscript(index: Int) -> Int {
        get {
            precondition(index >= 0)
            precondition(index < 8)

            return (rawValue & UInt8(1 << index) == 0) ? 0 : 1
        }

        set(newValue) {
            precondition(index >= 0)
            precondition(index < 8)
            precondition(newValue == 0 || newValue == 1)

            let mask: UInt8 = 1 << index
            if (newValue == 1) {
                rawValue |= mask
            } else {
                rawValue &= ~mask
            }
        }
    }


    subscript(index: ClosedRange<Int>) -> UInt8 {
        get {
            var ret: UInt8 = 0
            var bit: UInt8 = 1

            for i in index {
                let mask: UInt8 = 1 << i
                if rawValue & mask != 0 {
                    ret |= bit
                }
                bit <<= 1
            }
            return ret
        }
        set {
            var bit: UInt8 = 1
            for i in index {
                let mask: UInt8 = 1 << i
                if (newValue & bit) == 0 {
                    rawValue &= ~mask
                } else {
                    rawValue |= mask
                }
                bit <<= 1
            }
        }
    }


    func toInt() -> Int {
        return Int(rawValue)
    }
}


struct BitArray16: CustomStringConvertible {
    private(set) var rawValue: UInt16

    var description: String { return String(rawValue, radix: 2) }


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


    init(_ rawValue: UInt16) {
        self.rawValue = rawValue
    }

    subscript(index: Int) -> Int {
        get {
            precondition(index >= 0)
            precondition(index < 16)

            return (rawValue & UInt16(1 << index) == 0) ? 0 : 1
        }

        set(newValue) {
            precondition(index >= 0)
            precondition(index < 16)
            precondition(newValue == 0 || newValue == 1)

            let mask: UInt16 = 1 << index
            if (newValue == 1) {
                rawValue |= mask
            } else {
                rawValue &= ~mask
            }
        }
    }


    subscript(index: ClosedRange<Int>) -> UInt16 {
        get {
            var ret: UInt16 = 0
            var bit: UInt16 = 1

            for i in index {
                let mask: UInt16 = 1 << i
                if rawValue & mask != 0 {
                    ret |= bit
                }
                bit <<= 1
            }
            return ret
        }
        set {
            var bit: UInt16 = 1
            for i in index {
                let mask: UInt16 = 1 << i
                if (newValue & bit) == 0 {
                    rawValue &= ~mask
                } else {
                    rawValue |= mask
                }
                bit <<= 1
            }
        }
    }

    func toUInt8() -> UInt8 {
        return UInt8(truncatingIfNeeded: rawValue)
    }

    func toInt() -> Int {
        return Int(rawValue)
    }
}


struct BitArray32: CustomStringConvertible {
    private(set) var rawValue: UInt32

    var description: String { return String(rawValue, radix: 2) }


    init() {
        rawValue = 0
    }

    init(_ rawValue: Int) {
        self.rawValue = UInt32(rawValue)
    }

    init(_ rawValue: UInt) {
        self.rawValue = UInt32(rawValue)
    }

    init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }

    init(_ rawValue: UInt16) {
        self.rawValue = UInt32(rawValue)
    }

    init(_ rawValue: UInt8) {
        self.rawValue = UInt32(rawValue)
    }

    subscript(index: Int) -> Int {
        get {
            precondition(index >= 0)
            precondition(index < 32)

            return (rawValue & UInt32(1 << index) == 0) ? 0 : 1
        }

        set(newValue) {
            precondition(index >= 0)
            precondition(index < 32)
            precondition(newValue == 0 || newValue == 1)

            let mask: UInt32 = 1 << index
            if (newValue == 1) {
                rawValue |= mask
            } else {
                rawValue &= ~mask
            }
        }
    }

    subscript(index: ClosedRange<Int>) -> UInt32 {
        get {
            var ret: UInt32 = 0
            var bit: UInt32 = 1

            for i in index {
                let mask: UInt32 = 1 << i
                if rawValue & mask != 0 {
                    ret |= bit
                }
                bit <<= 1
            }
            return ret
        }
        set {
            var bit: UInt32 = 1
            for i in index {
                let mask: UInt32 = 1 << i
                if (newValue & bit) == 0 {
                    rawValue &= ~mask
                } else {
                    rawValue |= mask
                }
                bit <<= 1
            }
        }
    }

    func toUInt8() -> UInt8 {
        return UInt8(truncatingIfNeeded: rawValue)
    }

    func toUInt16() -> UInt16 {
        return UInt16(truncatingIfNeeded: rawValue)
    }

    func toUInt32() -> UInt32 {
        return UInt32(rawValue)
    }

    func toInt() -> Int {
        return Int(rawValue)
    }
}


struct BitArray64: CustomStringConvertible {
    private(set) var rawValue: UInt64

    var description: String { return String(rawValue, radix: 2) }


    init() {
        rawValue = 0
    }

    init(_ rawValue: Int) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }

    init(_ rawValue: UInt16) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt8) {
        self.rawValue = UInt64(rawValue)
    }

    subscript(index: Int) -> Int {
        get {
            precondition(index >= 0)
            precondition(index < 64)

            return (rawValue & (UInt64(1) << index) == 0) ? 0 : 1
        }

        set {
            precondition(index >= 0)
            precondition(index < 64)
            precondition(newValue == 0 || newValue == 1)

            if (newValue == 1) {
                rawValue |= (UInt64(1) << index)
            } else {
                rawValue &= ~(UInt64(1) << index)
            }
        }
    }


    subscript(index: ClosedRange<Int>) -> UInt64 {
        get {
            var ret: UInt64 = 0
            var bit: UInt64 = 1

            for i in index {
                let mask: UInt64 = 1 << i
                if rawValue & mask != 0 {
                    ret |= bit
                }
                bit <<= 1
            }
            return ret
        }
        set {
            var bit: UInt64 = 1
            for i in index {
                let mask: UInt64 = 1 << i
                if (newValue & bit) == 0 {
                    rawValue &= ~mask
                } else {
                    rawValue |= mask
                }
                bit <<= 1
            }
        }
    }

    func toUInt8() -> UInt8 {
        return UInt8(truncatingIfNeeded: rawValue)
    }

    func toUInt16() -> UInt16 {
        return UInt16(truncatingIfNeeded: rawValue)
    }

    func toUInt32() -> UInt32 {
        return UInt32(truncatingIfNeeded: rawValue)
    }

    func toUInt64() -> UInt64 {
        return rawValue
    }

    func toInt() -> Int {
        return Int(rawValue)
    }
}
