/*
 * kernel/klib/MemoryBufferReader.swift
 *
 * Created by Simon Evans on 24/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Read different basic types from a memory buffer
 *
 */

enum ReadError: Error {
    case InvalidOffset
    case InvalidData
}

struct MemoryBufferReader {

    let ptr: UnsafeRawPointer
    let buffer: UnsafeBufferPointer<UInt8>
    var offset: Int = 0
    var bytesRemaining: Int { return (buffer.count - offset) }


    init(_ baseAddr: VirtualAddress, size: Int) {
        ptr = UnsafeRawPointer(bitPattern: baseAddr)!
        let bufferPtr = ptr.bindMemory(to: UInt8.self, capacity: size)
        buffer = UnsafeBufferPointer(start: bufferPtr, count: size)
    }


    init(_ basePtr: UnsafeRawPointer, size: Int) {
        ptr = basePtr
        let bufferPtr = ptr.bindMemory(to: UInt8.self, capacity: size)
        buffer = UnsafeBufferPointer(start: bufferPtr, count: size)
    }


    func subBufferAtOffset(_ start: Int, size: Int) -> MemoryBufferReader {
        return MemoryBufferReader(ptr.advanced(by: start), size: size)
    }


    func subBufferAtOffset(_ start: Int) -> MemoryBufferReader {
        let size = buffer.count - start
        return subBufferAtOffset(start, size: size)
    }

    // Functions to convert ASCII strings in memory to String. Inefficient
    // conversions because Foundation isnt available
    // Only really works for 7bit ASCII as it assumes the code is valid UTF-8
    mutating  func readASCIIZString(maxSize: Int) throws -> String {
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
    mutating func scanASCIIZString() throws -> String {
        var result = ""

        var ch: UInt8 = try read()
        while ch != 0 {
            result += String(Character(UnicodeScalar(ch)))
            ch = try read()
        }

        return result
    }


    mutating func read<T>() throws -> T {
        // This is awful but catches attempts to read an optional
        precondition(!"\(type(of: T.self))".hasPrefix("Optional<"), "Dont call read() with an optional")
        precondition(MemoryLayout<T>.stride == MemoryLayout<T>.size, "Size \(type(of: T.self)) != Stride")
        guard bytesRemaining > 0 else {
            throw ReadError.InvalidOffset
        }

        guard bytesRemaining >= MemoryLayout<T>.size else {
            throw ReadError.InvalidOffset
        }
        let result = ptr.load(fromByteOffset: offset, as: T.self)
        offset += MemoryLayout<T>.size

        return result
    }


    func readAtIndex<T>(_ index: Int) throws -> T {
        // This is awful but catches attempts to read an optional
        precondition(!"\(type(of: T.self))".hasPrefix("Optional<"), "Dont call readAtIndex() with an optional")
        precondition(MemoryLayout<T>.stride == MemoryLayout<T>.size, "Size \(type(of: T.self)) != Stride")
        guard index + MemoryLayout<T>.size <= buffer.count else {
            throw ReadError.InvalidOffset
        }
        return ptr.load(fromByteOffset: index, as: T.self)
    }


    /***
    func dumpBuffer() {
        var str = "0000: "

        if (buffer.count > 0) {
            for idx in 0..<buffer.count {
                if (idx > 0) && (idx % 32) == 0 {
                    print(str)
                    str = String(idx, radix: 16format: "%04X: ", idx)
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
            print(String.sprintf("%02X ", data), terminator: "")
        }
        offset = saved
    }
    ***/


    mutating func readULEB128() throws -> UInt64 {
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


    mutating func readSLEB128() throws -> Int64 {
        var value: Int64 = 0
        var shift: Int64 = 0
        var byte: UInt8 = 0

        repeat {
            byte = try read()
            value |= (Int64(byte & 0x7f) << shift)
            shift += 7
        } while (byte & 0x80) == 0x80

        if (Int(shift) < MemoryLayout<Int64>.size) && (byte & 0x40) == 0x40 {
            // sign bit set so sign extend
            value |= -(1 << shift)
        }

        return value
    }
}
