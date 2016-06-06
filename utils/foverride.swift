#!/usr/bin/swift

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


@noreturn
func exitWithMessage(_ msg: String) {
    print(msg)
    exit(1)
}


extension UInt {
    func asHex() -> String {
        return String(NSString(format:"%x", self))
    }
}

extension Int32 {
    func asHex() -> String {
        return String(NSString(format:"%x", self))
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


func openOrQuit(_ filename: String) -> NSData {
    guard let file = NSMutableData(contentsOfFile: filename) else {
        exitWithMessage("Cant open \(filename)")
    }
    return file
}

func parseMap(_ filename: String) -> Dictionary<String, UInt> {
    guard let kernelMap = try? String(contentsOfFile: filename, encoding: NSASCIIStringEncoding) else {
        exitWithMessage("Cant open \(filename)")
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


let args = Process.arguments
guard args.count == 5 else {
    exitWithMessage("usage: \(args[0]) <kernel.bin> <kernel.map> <function> <new function>")
}

let (binFile, mapFile, oldFunction, newFunction) = (args[1], args[2], args[3], args[4])

print("Parsing", mapFile)
let symbols = parseMap(mapFile)
guard let textStart = symbols["_text_start"] else {
    exitWithMessage("Cant find _text_start address")
}

guard let oldFunc = symbols[oldFunction] else {
    exitWithMessage("Cant find \(args[3]) address")
}

guard let newFunc = symbols[newFunction] else {
    exitWithMessage("Cant find \(args[4]) address")
}

let address = oldFunc - textStart
let target = newFunc - textStart
// May overflow if offset is > ± signed 32bit
// +5 since the jmp is relative to the next instruction
let offset = Int32(Int(target) - Int(address + 5));

print("\(oldFunction):", oldFunc.asHex(), "\(newFunction):", newFunc.asHex())
print("Patching", args[3], oldFunc.asHex(), "[\(address.asHex())] -> ", args[4],
    newFunc.asHex(), "[\(target.asHex())] offset:", offset.asHex())
let bin = openOrQuit(binFile);

let ptr: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer(bin.bytes).advanced(by: Int(address))
let buf: UnsafeMutableBufferPointer<UInt8> = UnsafeMutableBufferPointer(start: ptr, count: 5)
buf[0] = 0xe9   // jmp with 32bit realative offset
buf[1] = UInt8(truncatingBitPattern: offset >> 0)
buf[2] = UInt8(truncatingBitPattern: offset >> 8)
buf[3] = UInt8(truncatingBitPattern: offset >> 16)
buf[4] = UInt8(truncatingBitPattern: offset >> 24)

guard bin.write(toFile: binFile, atomically: true) else {
    exitWithMessage("Cant write output")
}
