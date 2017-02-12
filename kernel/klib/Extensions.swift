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
    func bit(_ bit: UInt32) -> Bool {
        return self & (1 << bit) != 0
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
