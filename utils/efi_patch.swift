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


func openOrQuit(_ filename: String) -> NSData {
    guard let file = NSData(contentsOfFile: filename) else {
        exitWithMessage("Cant open \(filename)")
    }
    return file
}


@noreturn
func exitWithMessage(_ msg: String) {
    print(msg)
    exit(1)
}


func patchValue<T>(_ data: NSData, offset: Int, value: T) {
    guard offset >= 0 && offset < data.length else {
        exitWithMessage("Invalid offset: \(offset)")
    }
    let ptr = UnsafeMutablePointer<T>(data.bytes + offset)
    ptr.pointee = value
}


func readValue<T>(_ data: NSData, offset: Int) -> T {
    guard offset >= 0 && offset < data.length else {
        exitWithMessage("Invalid offset: \(offset)")
    }
    let ptr = UnsafePointer<T>(data.bytes + offset)
    return ptr.pointee
}


extension UInt32 {
    func asHex() -> String {
        return String(NSString(format:"%x", self))
    }
}


extension UInt {
    func asHex() -> String {
        return String(NSString(format:"%x", self))
    }
}



func patchEFIHeader(_ header: NSData, _ loaderSectors: UInt16) -> Int {
    // SizeOfCode
    let sizeOfCode = UInt32(loaderSectors) * 512
    print("SizeOfCode:", sizeOfCode.asHex())
    patchValue(header, offset: 92, value: sizeOfCode)

    // SizeOfImage (header + loader + kernel)
    let sizeOfImage = UInt32(1 + loaderSectors) * 512
    print("SizeOfImage:", sizeOfImage)
    patchValue(header, offset: 144, value: sizeOfImage)

    // .text section
    // .text.VirtualSize
    patchValue(header, offset: 296, value: sizeOfCode)
    // .text.SizeOfRawData
    patchValue(header, offset: 304, value: sizeOfCode)

    return Int(sizeOfImage)     // Image size rounded up to sector size
}


func writeOutImage(_ filename: String, _ bootsect: NSData, _ loader: NSData,
    padding: Int = 0) {

    let outputData = NSMutableData(data: bootsect)
    outputData.append(loader)

    // FIXME: make padding a cmd line arg, this is needed to make a bochs disk image
    if padding > outputData.length {
        print("Padding output to \(padding) bytes")
        outputData.increaseLength(by: padding - outputData.length)
    }

    guard outputData.write(toFile: filename, atomically: false) else {
        exitWithMessage("Cant write to output file \(filename)");
    }
}


func parseHex(_ number: String) -> UInt? {
     if (number.hasPrefix("0x")) {
        return UInt(number.stringByReplacingOccurrencesOfString("0x", withString: ""),
            radix: 16)
    } else {
        return nil
    }
}


func parseMap(_ filename: String) -> Dictionary<String, UInt> {
    guard let kernelMap = try? String(contentsOfFile: filename, encoding: NSASCIIStringEncoding) else {
        exitWithMessage("Cant open \(filename)")
    }

    var symbols = Dictionary<String, UInt>(minimumCapacity: 16384)
    for line in kernelMap.componentsSeparatedByString("\n") {
        // Split by multiple spaces
        let components = line.componentsSeparatedByString(" ").flatMap {
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
      exitWithMessage("usage: \(args[0]) <efi_header.bin> <efi_loader.bin> <efi_loader.map> <output>")
}

let bootsect = NSMutableData(data: openOrQuit(args[1]))
guard bootsect.length == 512 else {
    exitWithMessage("Bootsector should be 512 bytes but is \(bootsect.length)")
}
let loader = openOrQuit(args[2])
let loaderSectors = UInt16((loader.length + 511) / 512)
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
patchValue(loader, offset: 8, value: bssSize)

let imageSize = patchEFIHeader(bootsect, loaderSectors)
writeOutImage(outputFile, bootsect, loader, padding: imageSize)
