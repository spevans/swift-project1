//
//  MemoryBufferReader.swift
//  static_linker
//
//  Created by Simon Evans on 25/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


class MemoryBufferReader {
    var ptr: UnsafePointer<UInt8> = nil
    var buffer: UnsafeBufferPointer<UInt8> = UnsafeBufferPointer<UInt8>(start: nil, count: 0)
    var offset: Int = 0
    var bytesRemaining: Int { return (buffer.count - offset) }


    init?(_ reader: MachOReader, offset: Int, size: Int) {
        do {
            ptr = try reader.memoryReadBuffer(offset, size: size)
            buffer = UnsafeBufferPointer<UInt8>(start: ptr, count: size)
        } catch {
            return nil
        }
    }


    func subBuffer(offset: Int, size: Int) -> UnsafeBufferPointer<UInt8> {
        return UnsafeBufferPointer<UInt8>(start: ptr + offset, count: size)
    }


    func readASCIIZString(maxSize maxSize: Int) throws -> String {
        guard maxSize > 0 else {
            throw MachOReader.ReadError.InvalidOffset
        }

        guard bytesRemaining > 0 else {
            throw MachOReader.ReadError.InvalidOffset
        }

        guard bytesRemaining >= maxSize else {
            throw MachOReader.ReadError.InvalidOffset
        }

        var newString : [CChar] = []
        newString.reserveCapacity(maxSize + 1)
        for _ in 0...maxSize-1 {
            newString.append(CChar(buffer[offset++]))
        }
        newString.append(0) // Terminating nul
        if let result = String(CString: newString, encoding: NSASCIIStringEncoding) {
            return result
        } else {
            throw MachOReader.ReadError.InvalidData(reason: "Invalid string")
        }
    }


    // read from the current offset until the first nul byte is found
    func scanASCIIZString() throws -> String {
        var str : [CChar] = []
        var ch : CChar
        repeat {
            ch = try read()
            str.append(ch)
        }
            while ch != 0
        if let result = String(CString: str, encoding: NSASCIIStringEncoding) {
            return result
        } else {
            throw MachOReader.ReadError.InvalidData(reason: "Invalid string")
        }
    }


    func read<T>() throws -> T {
        guard bytesRemaining > 0 else {
            throw MachOReader.ReadError.InvalidOffset
        }

        guard bytesRemaining >= sizeof(T) else {
            throw MachOReader.ReadError.InvalidOffset
        }
        let resultPtr : UnsafePointer<T> = UnsafePointer(ptr + offset)
        let result = resultPtr.memory
        offset += sizeof(T)

        return result
    }


    func dumpBuffer() {
        var str = "0000: "

        if (buffer.count > 0) {
            for idx in 0..<buffer.count {
                if (idx > 0) && (idx % 32) == 0 {
                    print(str)
                    str = String(format: "%04X: ", idx)
                }

                let data: UInt8 = try! read()
                str += String(format: " %02X", data)
            }
            if !str.isEmpty {
                print(str)
            }
        }
        offset = 0
    }


    func dumpBuffer(startOffset: Int, _ endOffset: Int) {
        let saved = offset
        let count = endOffset - startOffset

        offset = startOffset
        for _ in 0..<count {
            let data: UInt8 = try! read()
            print(String(format: "%02X ", data))
        }
        offset = saved
    }


    func readULEB128() throws -> UInt64 {
        var value: UInt64 = 0
        var shift: UInt64 = 0
        var byte: UInt8 = 0

        repeat {
            byte = try read()
            value |= (UInt64(byte & 0x7f) << shift)
            shift += 7
        } while (byte & 0x80) == 0x80

        return value
    }


    func readSLEB128() throws -> Int64 {
        var value: Int64 = 0
        var shift: Int64 = 0
        var byte: UInt8 = 0

        repeat {
            byte = try read()
            value |= (Int64(byte & 0x7f) << shift)
            shift += 7
        } while (byte & 0x80) == 0x80

        if (Int(shift) < sizeof(Int64)) && (byte & 0x40) == 0x40 {
            // sign bit set so sign extend
            value |= -(1 << shift)
        }

        return value
    }
}
