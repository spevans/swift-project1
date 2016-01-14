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

    public static func sprintf(format: String, _ arguments: CVarArgType...) -> String {
        return sprintf(format, arguments)
    }


    static func sprintf(format: String, _ arguments: [CVarArgType]) -> String {
        let bufferLen = 1024
        var result: String?

        withVaList(arguments) {
            let len = format.utf8.count + 1
            let buffer = UnsafeMutablePointer<CChar>.alloc(len)
            var idx = 0
            for ch in format.utf8 {
                buffer[idx] = CChar(ch)
                idx += 1
            }
            buffer[idx] = CChar(0)
            let output = UnsafeMutablePointer<CChar>.alloc(bufferLen)
            kvsnprintf(output, bufferLen, buffer, $0)
            result = String.fromCString(output)
            buffer.dealloc(len)
            output.dealloc(bufferLen)
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
}
