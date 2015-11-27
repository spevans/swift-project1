#!/usr/bin/swift

import Foundation

let args = Process.arguments
guard args.count == 5 else {
      print("usage: \(args[0]) <bootsector.bin> <loader.bin> <kernel.bin> <output>")
      exit(EXIT_FAILURE)
}
//print("Bootsect: \(args[1]) loader: \(args[2]) kernel: \(args[3]) output: \(args[4])")

func openOrQuit(filename: String) -> NSData {
    guard let file = NSData(contentsOfFile: filename) else {
        print("Cant open \(filename)")
        exit(EXIT_FAILURE)
    }
    return file
}


func openOutput(filename: String) -> NSFileHandle {
    if NSFileManager.defaultManager().createFileAtPath(filename, contents: nil, attributes: nil) {
        let output = NSFileHandle(forWritingAtPath: filename)
        if output != nil {
            return output!
        }
    }

    print("Cant open output file: \(filename)")
    exit(EXIT_FAILURE)
}


func patchValue<T>(data: NSData, offset: Int, value: T) {
    guard offset >= 0 && offset < data.length else {
        print("Invalid offset: \(offset)")
        exit(EXIT_FAILURE)
    }
    let ptr = UnsafeMutablePointer<T>(data.bytes + offset)
    ptr.memory = value
}


let bootsect = openOrQuit(args[1])
guard bootsect.length == 512 else {
    print("Bootsector should be 512 bytes but is \(bootsect.length)")
    exit(EXIT_FAILURE)
}
let loader = openOrQuit(args[2])
let kernel = openOrQuit(args[3])
let loaderSectors = UInt16((loader.length + 511) / 512)
let kernelSectors = UInt16((kernel.length + 511) / 512)
let loaderLBA: UInt64 = 1
let kernelLBA = loaderLBA + UInt64(loaderSectors)

print("Loader: LBA: \(loaderLBA) sectors:\(loaderSectors)  kernel: LBA:\(kernelLBA) sectors:\(kernelSectors)")

// Patch in LBA and sector counts
patchValue(bootsect, offset: 482, value: loaderSectors.littleEndian)
patchValue(bootsect, offset: 488, value: loaderLBA.littleEndian)
patchValue(bootsect, offset: 496, value: kernelLBA.littleEndian)
patchValue(bootsect, offset: 504, value: kernelSectors.littleEndian)

// Bootdrive (BIOS 0x80 == hda)
patchValue(bootsect, offset: 506, value: UInt8(0x80))

let output = openOutput(args[4])
output.writeData(bootsect)
output.writeData(loader)

// Make sure kernel starts on a sector boundary
let seek = kernelLBA * 512
output.seekToFileOffset(seek)
output.writeData(kernel)

// FIXME: make padding a cmd line arg
let padding = UInt64(20 * 16 * 63 * 512) - 1
output.seekToFileOffset(padding)
let oneByte = NSMutableData(length:1)
output.writeData(oneByte!)
output.closeFile()
