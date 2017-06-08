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
import PatchUtils


func main() {
    let args = CommandLine.arguments
    guard args.count == 5 else {
        fatalError("usage: \(args[0]) <efi_header.bin> <efi_loader.bin> <efi_loader.map> <output>")
    }

    var bootsect = openOrQuit(args[1])
    guard bootsect.count == sectorSize else {
        fatalError("Bootsector should be \(sectorSize) bytes but is \(bootsect.count)")
    }
    var loader = openOrQuit(args[2])
    let loaderSectors = UInt16((loader.count + sectorSize - 1) / sectorSize)
    let mapFile = args[3]
    let outputFile = args[4]
    print("Header: \(args[1]) body: \(args[2]) mapfile: \(mapFile) output: \(outputFile)")


    let sig: UInt16 = readValue(bootsect, offset: 0)
    // Look for 'MZ' EFI signature
    guard sig == 0x5a4d else {
        fatalError("Cant Found EFI header")
    }

    print("Parsing map file")
    let symbols = parseMap(mapFile)
    guard let bssStart = symbols["_bss_start"] else {
        fatalError("Cant find _bss_start in \(mapFile)")
    }

    guard let bssEnd = symbols["_bss_end"] else {
        fatalError("Cant find _bss_end in \(mapFile)")
    }

    let bssSize = bssEnd - bssStart
    print("bssStart:", bssStart.asHex(), "bssEnd:", bssEnd.asHex(),
        "bssSize:", bssSize.asHex())
    patchValue(&loader, offset: 8, value: bssSize)

    let imageSize = patchEFIHeader(&bootsect, loaderSectors)
    writeOutImage(outputFile, bootsect, loader, padding: imageSize)
    exit(0)
}


func patchEFIHeader(_ header: inout Data, _ loaderSectors: UInt16) -> Int {
    // SizeOfCode
    let sizeOfCode = UInt32(loaderSectors) * UInt32(sectorSize)
    print("SizeOfCode:", sizeOfCode.asHex())
    patchValue(&header, offset: 92, value: sizeOfCode)

    // SizeOfImage (header + loader + kernel)
    let sizeOfImage = UInt32(1 + loaderSectors) * UInt32(sectorSize)
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
        outputData.append(Data(count: padding - outputData.count))
    }

    do {
        try outputData.write(to: URL(fileURLWithPath: filename))
    } catch {
        fatalError("Cant write to output file \(filename)")
    }
}

main()
