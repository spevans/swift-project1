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

    public static func sprintf(_ format: String, _ arguments: CVarArg...) -> String {
        return sprintf(format, arguments)
    }


    static func sprintf(_ format: String, _ arguments: [CVarArg]) -> String {
        let bufferLen = 1024
        var result: String?

        withVaList(arguments) {
            let len = format.utf8.count + 1
            let buffer = UnsafeMutablePointer<CChar>(allocatingCapacity: len)
            var idx = 0
            for ch in format.utf8 {
                buffer[idx] = CChar(ch)
                idx += 1
            }
            buffer[idx] = CChar(0)
            let output = UnsafeMutablePointer<CChar>(allocatingCapacity: bufferLen)
            kvsnprintf(output, bufferLen, buffer, $0)
            result = String(cString: output)
            buffer.deallocateCapacity(len)
            output.deallocateCapacity(bufferLen)
        }

        if (result == nil) {
             return ""
        } else {
             return result!
        }
    }
}


extension UInt16 {

    public init(msb: UInt8, lsb: UInt8) {
        self = UInt16(msb) << 8 | UInt16(lsb)
    }

    // return (msb, lsb)
    public func toBytes() -> (UInt8, UInt8) {
        return (UInt8(self >> 8), UInt8(self & 0xff))
    }


    public func bitSet(_ bit: UInt16) -> Bool {
        return self & (1 << bit) != 0
    }
}


extension UnsafePointer {

    public var address: UInt {
        return ptr_to_uint(self)
    }


    // Increment a pointer by x bytes and recast to a new type
    // Unwrapped result as nil pointers cant be advanced
    public func advancedBy<T>(bytes: Int) -> UnsafePointer<T> {
        return UnsafePointer<T>(bitPattern: ptr_to_uint(self) + UInt(bytes))!
    }
}


extension UnsafeMutablePointer {

    public var address: UInt {
        return ptr_to_uint(self)
    }


    // Increment a pointer by x bytes and recast to a new type
    // Unwrapped result as nil pointers cant be advanced
    public func advancedBy<T>(bytes: Int) -> UnsafeMutablePointer<T> {
        return UnsafeMutablePointer<T>(bitPattern: ptr_to_uint(self) + UInt(bytes))!
    }
}


extension UnsafeBufferPointer {

    public func regionPointer<T>(offset: Int) -> UnsafePointer<T> {
        let max = offset + strideof(T)
        assert(max <= self.count)
        let region = ptr_to_uint(self.baseAddress) + UInt(offset)
        return UnsafePointer<T>(bitPattern: region)!
    }
}


public func dumpRegion(ptr: UnsafePointer<Void>, size: Int) {
    let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(ptr),
        count: size)
    for idx in 0..<buffer.count {
        if idx % 16 == 0 {
            if idx > 0 {
                print("")
            }
            printf("%4.4X: ", idx)
        }
        printf("%2.2x ", buffer[idx])
    }
}
