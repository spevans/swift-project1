/*
 * utils/PatchUtils.swift
 *
 * Created by Simon Evans on 30/07/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Utility methods shared between the binary patch utilities
 *
 */

import Foundation


let sectorSize = 512


func openOrQuit(_ filename: String) -> Data {
    let url = URL(fileURLWithPath: filename)
    guard let file = try? Data(contentsOf: url) else {
        fatalError("Cant open \(filename)")
    }
    return file
}


// FIXME: workaround until Data(count:) works correctly to use calloc()
func makePadding(count: Int) -> Data {
    if var p = Data(count: count) {
        p.resetBytes(in: Range<Int>(0..<count))
        return p
    } else {
        fatalError("memory")
    }
}


// Allows arbitary offsets not necessarily aligned to the width of T
func patchValue<T>(_ data: inout Data, offset: Int, value: T) {
    guard offset >= 0 else {
        fatalError("offset < 0: \(offset)")
    }
    guard offset + sizeof(T.self) <= data.count else {
        fatalError("offset overflow: \(offset) > \(data.count)")
    }

    // FIXME:
    // This is how it should work but Data.swift if broken
    //var value = value
    //let x = Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    //let range: Range<Int> = offset..<(offset + x.count)
    //print(#function, "offset: \(offset), value: \(value), range, \(range)")
    //data.replaceBytes(in: range, with: x) - needs fixing


    let d = NSMutableData(data: data)
    let ptr = d.mutableBytes + offset

    ptr.bindMemory(to: T.self, capacity: 1).pointee = value
    let buffer = d.mutableBytes.bindMemory(to: UInt8.self, capacity: data.count)
    data = Data(buffer: UnsafeBufferPointer(start: buffer, count: data.count))
}


func readValue<T>(_ data: Data, offset: Int) -> T {
    let range: Range<Int> = offset..<(offset + sizeof(T.self))
    let value = data.subdata(in: range)
    return value.withUnsafeBytes { $0.pointee }
}


extension Int32 {
    func asHex() -> String {
        return String(format:"%x", self)
    }
}


extension UInt32 {
    func asHex() -> String {
        return String(format:"%x", self)
    }
}


extension UInt {
    func asHex() -> String {
        return String(format:"%x", self)
    }
}


func parseHex(_ number: String) -> UInt? {
     if (number.hasPrefix("0x")) {
        return UInt(number.replacingOccurrences(of: "0x", with: ""),
            radix: 16)
    } else {
        return nil
    }
}


func parseMap(_ filename: String) -> Dictionary<String, UInt> {
    guard let kernelMap = try? String(contentsOfFile: filename,
        encoding: String.Encoding.ascii) else {
        fatalError("Cant open \(filename)")
    }

    var symbols = Dictionary<String, UInt>(minimumCapacity: 16384)
    for line in kernelMap.components(separatedBy: "\n") {
        // Split by multiple spaces
        let components = line.components(separatedBy: " ").flatMap {
            $0 == "" ? nil : $0
        }

        // Ignore any lines which arent [<Hex>, <String>] but allow lines
        // which are [<Hex>, <String>, = .]
        if components.count == 4 {
            if components[2] != "=" || components[3] != "." {
                continue
            }
        } else if components.count != 2 {
            continue
        }

        if components[1] == "0x0" {
            continue
        }
        guard let address = parseHex(components[0]) else {
            continue
        }
        let symbol = components[1]
        symbols[symbol] = address
    }
    return symbols
}
