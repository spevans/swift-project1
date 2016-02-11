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


let args = Process.arguments
guard args.count == 4 else {
      fatalError("usage: \(args[0]) <efi_header.bin> <efi_body.bin> <output>")
}
print("Header: \(args[1]) body: \(args[2]) output: \(args[3])")

func openOrQuit(filename: String) -> NSData {
    guard let file = NSData(contentsOfFile: filename) else {
        fatalError("Cant open \(filename)")
    }
    return file
}


@noreturn
func exitWithMessage(msg: String) {
    print(msg)
    exit(1)
}


func patchValue<T>(data: NSData, offset: Int, value: T) {
    guard offset >= 0 && offset < data.length else {
        fatalError("Invalid offset: \(offset)")
    }
    let ptr = UnsafeMutablePointer<T>(data.bytes + offset)
    ptr.memory = value
}


func readValue<T>(data: NSData, offset: Int) -> T {
    guard offset >= 0 && offset < data.length else {
        fatalError("Invalid offset: \(offset)")
    }
    let ptr = UnsafePointer<T>(data.bytes + offset)
    return ptr.memory
}


extension UInt32 {
    func asHex() -> String {
        return String(NSString(format:"%x", self))
    }
}


func patchEFIHeader(header: NSData, _ loaderSectors: UInt16) -> Int {
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


func writeOutImage(filename: String, _ bootsect: NSData, _ loader: NSData,
    padding: Int = 0) {

    let outputData = NSMutableData(data: bootsect)
    outputData.appendData(loader)

    // FIXME: make padding a cmd line arg, this is needed to make a bochs disk image
    if padding > outputData.length {
        print("Padding output to \(padding) bytes")
        outputData.increaseLengthBy(padding - outputData.length)
    }

    guard outputData.writeToFile(filename, atomically: false) else {
        fatalError("Cant write to output file \(filename)");
    }
}


let bootsect = NSMutableData(data: openOrQuit(args[1]))
guard bootsect.length == 512 else {
    fatalError("Bootsector should be 512 bytes but is \(bootsect.length)")
}
let loader = openOrQuit(args[2])
let loaderSectors = UInt16((loader.length + 511) / 512)
let outputFile = args[3]

let sig: UInt16 = readValue(bootsect, offset: 0)
// Look for 'MZ' EFI signature
guard sig == 0x5a4d else {
    exitWithMessage("Cant Found EFI header")
}

let imageSize = patchEFIHeader(bootsect, loaderSectors)
writeOutImage(outputFile, bootsect, loader, padding: imageSize)
