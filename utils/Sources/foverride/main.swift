/*
 * utils/foverride.swift
 *
 * Created by Simon Evans on 10/02/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Patch a function to directly jmp to another function. This can be
 * used if a function in the libswiftcore.a needs to be overriden. A
 * relative jmp instruction is patched in to make the code jump to a
 * alternate instruction instead
 */

import Foundation
import PatchUtils


func main() {
    let args = CommandLine.arguments
    guard args.count == 5 else {
        fatalError("usage: \(args[0]) <kernel.bin> <kernel.map> <function> <new function>")
    }

    let (binFile, mapFile, oldFunction, newFunction) = (args[1], args[2],
        args[3], args[4])

    print("Parsing", mapFile)
    let symbols = parseMap(mapFile)
    guard let textStart = symbols["_text_start"] else {
        fatalError("Cant find _text_start address")
    }

    guard let oldFunc = symbols[oldFunction] else {
        fatalError("Cant find \(args[3]) address")
    }

    guard let newFunc = symbols[newFunction] else {
        fatalError("Cant find \(args[4]) address")
    }

    let address = oldFunc - textStart
    let target = newFunc - textStart
    // May overflow if offset is > ± signed 32bit
    // +5 since the jmp is relative to the next instruction
    let offset = Int32(Int(target) - Int(address + 5));

    print("\(oldFunction):", oldFunc.asHex(), "\(newFunction):", newFunc.asHex())
    print("Patching", args[3], oldFunc.asHex(), "[\(address.asHex())] -> ",
        args[4], newFunc.asHex(), "[\(target.asHex())] offset:", offset.asHex())
    let bin = NSMutableData(data: openOrQuit(binFile))
    let rawPtr = bin.mutableBytes + Int(address)
    let ptr = rawPtr.bindMemory(to: UInt8.self, capacity: 5)
    let buf = UnsafeMutableBufferPointer(start: ptr, count: 5)
    buf[0] = 0xe9   // jmp with 32bit realative offset
    buf[1] = UInt8(truncatingIfNeeded: offset >> 0)
    buf[2] = UInt8(truncatingIfNeeded: offset >> 8)
    buf[3] = UInt8(truncatingIfNeeded: offset >> 16)
    buf[4] = UInt8(truncatingIfNeeded: offset >> 24)

    guard bin.write(toFile: binFile, atomically: true) else {
        fatalError("Cant write output")
    }
    exit(0)
}

main()
