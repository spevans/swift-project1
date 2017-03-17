/*
 * kernel/klib/Extensions.swift
 *
 * Created by Simon Evans on 28/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Misc extensions
 *
 */


extension String {
    static func sprintf(_ format: StaticString, _ arguments: CVarArg...)
        -> String {
        return sprintf(format, arguments)
    }

    static func sprintf(_ format: StaticString, _ arguments: [CVarArg])
        -> String {
        return withVaList(arguments) {
            let args = $0
            return format.utf8Start.withMemoryRebound(to: CChar.self,
                capacity: format.utf8CodeUnitCount) {
                let bufferLen = 1024
                let output = UnsafeMutablePointer<CChar>.allocate(capacity: bufferLen)
                defer {
                    output.deallocate(capacity: bufferLen)
                }

                kvsnprintf(output, bufferLen, $0, args)
                return String(cString: output)
            }
        }
    }


    // Convert a fixed length (not null terminated) raw string upto a
    // maximum length
    init(_ rawPtr: UnsafeRawPointer, maxLength: Int) {
        let ptr = rawPtr.bindMemory(to: UInt8.self, capacity: maxLength)
        let buffer = UnsafeBufferPointer(start: ptr, count: maxLength)
        var str = ""

        for ch in buffer {
            if ch != 0 {
                let us = UnicodeScalar(ch)
                if us.isASCII {
                    str += String(us)
                }
            }
        }
        self = str
    }
}


extension UInt16 {
    init(msb: UInt8, lsb: UInt8) {
        self = UInt16(msb) << 8 | UInt16(lsb)
    }

    // return (msb, lsb)
    func toBytes() -> (UInt8, UInt8) {
        return (UInt8(self >> 8), UInt8(self & 0xff))
    }

    func bitSet(_ bit: UInt16) -> Bool {
        return self & (1 << bit) != 0
    }
}


extension UInt32 {
    init(byte3: UInt8, byte2: UInt8, byte1: UInt8, byte0: UInt8) {
        self = UInt32(byte3) << 24 | UInt32(byte2) << 16 | UInt32(byte1) << 8
        self |= UInt32(byte0)
    }

    func bit(_ bit: UInt32) -> Bool {
        return self & (1 << bit) != 0
    }

    func bit(_ bit: Int) -> Bool {
        return self & (1 << UInt32(bit)) != 0
    }

    subscript(index: Int) -> Int {
        get {
            precondition(index >= 0)
            precondition(index < 32)

            return (self & UInt32(1 << index) == 0) ? 0 : 1
        }

        set(newValue) {
            precondition(index >= 0)
            precondition(index < 32)
            precondition(newValue == 0 || newValue == 1)

            let mask = UInt32(1 << index)
            if (newValue == 1) {
                self |= mask
            } else {
                self &= ~mask
            }
        }
    }
}


extension UInt64 {
    init(msw: UInt32, lsw: UInt32) {
        self = UInt64(msw) << 32 | UInt64(lsw)
    }

    func toWords() -> (UInt32, UInt32) {
        return (UInt32(self >> 32), UInt32(self & 0xffffffff))
    }

    func toBytes() -> [UInt8] {
        return [UInt8(truncatingBitPattern: self),
                UInt8(truncatingBitPattern: self >> 8),
                UInt8(truncatingBitPattern: self >> 16),
                UInt8(truncatingBitPattern: self >> 24),
                UInt8(truncatingBitPattern: self >> 32),
                UInt8(truncatingBitPattern: self >> 40),
                UInt8(truncatingBitPattern: self >> 48),
                UInt8(truncatingBitPattern: self >> 56)]
    }

    init(_ bytes: [UInt8]) {
        self = UInt64(bytes[0]) | UInt64(bytes[1]) << 8
        | UInt64(bytes[2]) << 16 | UInt64(bytes[3]) << 24
        | UInt64(bytes[4]) << 32 | UInt64(bytes[5]) << 40
        | UInt64(bytes[6]) << 48 | UInt64(bytes[7]) << 56
    }

    func bit(_ bit: UInt64) -> Bool {
        return self & (1 << bit) != 0
    }


    subscript(index: Int) -> Int {
        get {
            precondition(index >= 0)
            precondition(index < 64)

            return (self & UInt64(1 << index) == 0) ? 0 : 1
        }

        set(newValue) {
            precondition(index >= 0)
            precondition(index < 64)
            precondition(newValue == 0 || newValue == 1)

            let mask = UInt64(1 << index)
            if (newValue == 1) {
                self |= mask
            } else {
                self &= ~mask
            }
        }
    }
}


extension UnsafePointer {
    var address: UInt {
        return UInt(bitPattern: self)
    }

    // Increment a pointer by x bytes and recast to a new type
    // Unwrapped result as nil pointers cant be advanced
    func advancedBy<T>(bytes: Int) -> UnsafePointer<T> {
        return UnsafePointer<T>(bitPattern: UInt(bitPattern: self) + UInt(bytes))!
    }
}


extension UnsafeMutablePointer {
    var address: UInt {
        return UInt(bitPattern: self)
    }

    // Increment a pointer by x bytes and recast to a new type
    // Unwrapped result as nil pointers cant be advanced
    func advancedBy<T>(bytes: Int) -> UnsafeMutablePointer<T> {
        return UnsafeMutablePointer<T>(bitPattern: UInt(bitPattern: self) + UInt(bytes))!
    }
}


extension UnsafeBufferPointer {
    func regionPointer<T>(offset: Int) -> UnsafePointer<T> {
        let max = offset + MemoryLayout<T>.stride
        assert(max <= self.count)
        let region = UInt(bitPattern: self.baseAddress) + UInt(offset)
        return UnsafePointer<T>(bitPattern: region)!
    }
}


extension UnsafeRawPointer {
    var address: UInt {
        return UInt(bitPattern: self)
    }
}


extension UnsafeMutableRawPointer {
    var address: UInt {
        return UInt(bitPattern: self)
    }
}


/// Convert the given numeric value to a hexadecimal string.
public func asHex<T : Integer>(_ x: T) -> String {
  return "0x" + String(x.toIntMax(), radix: 16)
}



struct BitField8: CustomStringConvertible {
    private(set) var rawValue: UInt8

    var description: String { return String(rawValue, radix: 2) }


    init() {
        rawValue = 0
    }

    init(rawValue: Int) {
        self.rawValue = UInt8(rawValue)
    }


    init(rawValue: UInt8) {
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

            let mask = UInt8(1 << index)
            if (newValue == 1) {
                rawValue |= mask
            } else {
                rawValue &= ~mask
            }
        }
    }


    subscript(index: CountableClosedRange<Int>) -> UInt8 {
        get {
            var ret: UInt8 = 0
            var bit: UInt8 = 1

            for i in index {
                let mask = 1 << UInt8(i)
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
                let mask = 1 << UInt8(i)
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


struct BitField32: CustomStringConvertible {
    private(set) var rawValue: UInt32

    var description: String { return String(rawValue, radix: 2) }


    init() {
        rawValue = 0
    }

    init(rawValue: Int) {
        self.rawValue = UInt32(rawValue)
    }

    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    init(rawValue: UInt16) {
        self.rawValue = UInt32(rawValue)
    }

    init(rawValue: UInt8) {
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

            let mask = UInt32(1 << index)
            if (newValue == 1) {
                rawValue |= mask
            } else {
                rawValue &= ~mask
            }
        }
    }


    subscript(index: CountableClosedRange<Int>) -> UInt32 {
        get {
            var ret: UInt32 = 0
            var bit: UInt32 = 1

            for i in index {
                let mask = 1 << UInt32(i)
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
                let mask = 1 << UInt32(i)
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
        return UInt8(truncatingBitPattern: rawValue)
    }


    func toUInt32() -> UInt32 {
        return UInt32(rawValue)
    }

    func toInt() -> Int {
        return Int(rawValue)
    }
}


struct BitField64: CustomStringConvertible {
    private(set) var rawValue: UInt64

    var description: String { return String(rawValue, radix: 2) }


    init() {
        rawValue = 0
    }

    init(rawValue: Int) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }

    init(rawValue: UInt16) {
        self.rawValue = UInt64(rawValue)
    }

    init(rawValue: UInt8) {
        self.rawValue = UInt64(rawValue)
    }

    subscript(index: Int) -> Int {
        get {
            precondition(index >= 0)
            precondition(index < 64)

            return (rawValue & UInt64(1 << index) == 0) ? 0 : 1
        }

        set {
            precondition(index >= 0)
            precondition(index < 64)
            precondition(newValue == 0 || newValue == 1)

            if (newValue == 1) {
                rawValue |= UInt64(1 << index)
            } else {
                rawValue &= ~(UInt64(1 << index))
            }
        }
    }


    subscript(index: CountableClosedRange<Int>) -> UInt64 {
        get {
            var ret: UInt64 = 0
            var bit: UInt64 = 1

            for i in index {
                let mask = 1 << UInt64(i)
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
                let mask = 1 << UInt64(i)
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
        return UInt8(truncatingBitPattern: rawValue)
    }


    func toInt() -> Int {
        return Int(rawValue)
    }
}
