/*
 * kernel/klib/MemoryBufferReader.swift
 *
 * Created by Simon Evans on 24/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Read different basic types from a memory buffer
 *
 */

public enum ReadError: ErrorType {
    case InvalidOffset
    case InvalidData
}


public class MemoryBufferReader {
    let ptr: UnsafePointer<UInt8>
    let buffer: UnsafeBufferPointer<UInt8>
    var offset: Int = 0
    var bytesRemaining: Int { return (buffer.count - offset) }


    public init(_ baseAddr: UInt, size: Int) {
        ptr = UnsafePointer<UInt8>(bitPattern: baseAddr)
        buffer = UnsafeBufferPointer<UInt8>(start: ptr, count: size)
    }


    public init(_ basePtr: UnsafePointer<UInt8>, size: Int) {
        ptr = basePtr
        buffer = UnsafeBufferPointer<UInt8>(start: ptr, count: size)
    }


    func subBuffer(start: Int, size: Int) -> MemoryBufferReader {
        return MemoryBufferReader(ptr.advancedBy(start), size: size)
    }


    func subBuffer(start: Int) -> MemoryBufferReader {
        let size = buffer.count - start
        return subBuffer(start, size: size)
    }

    // Functions to convert ASCII strings in memory to String. Inefficient
    // conversions because Foundation isnt available
    // Only really works for 7bit ASCII as it assumes the code is valid UTF-8
    func readASCIIZString(maxSize maxSize: Int) throws -> String {
        guard maxSize > 0 else {
            throw ReadError.InvalidOffset
        }

        guard bytesRemaining > 0 else {
            throw ReadError.InvalidOffset
        }

        guard bytesRemaining >= maxSize else {
            throw ReadError.InvalidOffset
        }

        var result = ""
        for _ in 0...maxSize-1 {
            let ch: UInt8 = try read()
            if ch == 0 {
                break
            }
            result += String(Character(UnicodeScalar(ch)))
        }

        return result
    }


    // read from the current offset until the first nul byte is found
    func scanASCIIZString() throws -> String {
        var result = ""

        var ch: UInt8 = try read()
        while ch != 0 {
            result += String(Character(UnicodeScalar(ch)))
            ch = try read()
        }

        return result
    }


    public func read<T>() throws -> T {
        guard bytesRemaining > 0 else {
            throw ReadError.InvalidOffset
        }

        guard bytesRemaining >= sizeof(T) else {
            throw ReadError.InvalidOffset
        }
        let resultPtr : UnsafePointer<T> = UnsafePointer(ptr + offset)
        let result = resultPtr.memory
        offset += sizeof(T)

        return result
    }


    public func readAtIndex<T>(index: Int) throws -> T {
        guard index + sizeof(T) <= buffer.count else {
            throw ReadError.InvalidOffset
        }
        let resultPtr : UnsafePointer<T> = UnsafePointer(ptr + index)
        let result = resultPtr.memory

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


    public func dumpBuffer(startOffset: Int, _ endOffset: Int) {
        let saved = offset
        let count = endOffset - startOffset

        offset = startOffset
        for _ in 0..<count {
            let data: UInt8 = try! read()
            print(String.sprintf("%02X ", data), terminator: "")
        }
        offset = saved
    }


    public func readULEB128() throws -> UInt64 {
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


    public func readSLEB128() throws -> Int64 {
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
