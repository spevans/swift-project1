/*
 * utils/efi_patch.swift
 *
 * Created by Simon Evans on 12/02/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Patch values into the EFI header
 *
 */

import Foundation


func openOrQuit(_ filename: String) -> Data {
    let url = URL(fileURLWithPath: filename)
    guard let file = try? Data(contentsOf: url) else {
        fatalError("Cant open \(filename)")
    }
    return file
}


func exitWithMessage(_ msg: String) -> Never {
    print(msg)
    exit(1)
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



func patchEFIHeader(_ header: inout Data, _ loaderSectors: UInt16) -> Int {
    // SizeOfCode
    let sizeOfCode = UInt32(loaderSectors) * 512
    print("SizeOfCode:", sizeOfCode.asHex())
    patchValue(&header, offset: 92, value: sizeOfCode)

    // SizeOfImage (header + loader + kernel)
    let sizeOfImage = UInt32(1 + loaderSectors) * 512
    print("SizeOfImage:", sizeOfImage)
    patchValue(&header, offset: 144, value: sizeOfImage)

    // .text section
    // .text.VirtualSize
    patchValue(&header, offset: 296, value: sizeOfCode)
    // .text.SizeOfRawData
    patchValue(&header, offset: 304, value: sizeOfCode)

    return Int(sizeOfImage)     // Image size rounded up to sector size
}


func writeOutImage(_ filename: String, _ bootsect: Data, _ loader: Data,
    padding: Int = 0) {

    var outputData = bootsect
    outputData.append(loader)

    // FIXME: make padding a cmd line arg, this is needed to make a bochs disk image
    if padding > outputData.count {
        print("Padding output to \(padding) bytes")
        outputData.append(makePadding(count: padding - outputData.count))
    }

    do {
        try outputData.write(to: URL(fileURLWithPath: filename))
    } catch {
        fatalError("Cant write to output file \(filename)")
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


let args = CommandLine.arguments
guard args.count == 5 else {
      exitWithMessage("usage: \(args[0]) <efi_header.bin> <efi_loader.bin> <efi_loader.map> <output>")
}

var bootsect = openOrQuit(args[1])
guard bootsect.count == 512 else {
    exitWithMessage("Bootsector should be 512 bytes but is \(bootsect.count)")
}
var loader = openOrQuit(args[2])
let loaderSectors = UInt16((loader.count + 511) / 512)
let mapFile = args[3]
let outputFile = args[4]
print("Header: \(args[1]) body: \(args[2]) mapfile: \(mapFile) output: \(outputFile)")


let sig: UInt16 = readValue(bootsect, offset: 0)
// Look for 'MZ' EFI signature
guard sig == 0x5a4d else {
    exitWithMessage("Cant Found EFI header")
}

print("Parsing map file")
let symbols = parseMap(mapFile)
guard let bssStart = symbols["_bss_start"] else {
    exitWithMessage("Cant find _bss_start in \(mapFile)")
}

guard let bssEnd = symbols["_bss_end"] else {
    exitWithMessage("Cant find _bss_end in \(mapFile)")
}

let bssSize = bssEnd - bssStart
print("bssStart:", bssStart.asHex(), "bssEnd:", bssEnd.asHex(),
    "bssSize:", bssSize.asHex())
patchValue(&loader, offset: 8, value: bssSize)

let imageSize = patchEFIHeader(&bootsect, loaderSectors)
writeOutImage(outputFile, bootsect, loader, padding: imageSize)
