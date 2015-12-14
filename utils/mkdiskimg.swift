#!/usr/bin/swift

import Foundation


let args = Process.arguments
guard args.count == 5 else {
      fatalError("usage: \(args[0]) <bootsector.bin> <loader.bin> <kernel.bin> <output>")
}
print("Bootsect: \(args[1]) loader: \(args[2]) kernel: \(args[3]) output: \(args[4])")

func openOrQuit(filename: String) -> NSData {
    guard let file = NSData(contentsOfFile: filename) else {
        fatalError("Cant open \(filename)")
    }
    return file
}


func patchValue<T>(data: NSData, offset: Int, value: T) {
    guard offset >= 0 && offset < data.length else {
        fatalError("Invalid offset: \(offset)")
    }
    let ptr = UnsafeMutablePointer<T>(data.bytes + offset)
    ptr.memory = value
}


func writeOutImage(filename: String, _ bootsect: NSData, _ loader: NSData, _ kernel: NSData, _ kernelLBA: Int) {
     let outputData = NSMutableData(data: bootsect)
     outputData.appendData(loader)

     // Make sure kernel starts on a sector boundary
     let seek = kernelLBA * 512
     let kernelPadding = seek - outputData.length
     print("Adding \(kernelPadding) bytes to start of kernel")
     outputData.increaseLengthBy(kernelPadding)
     outputData.appendData(kernel)

     // FIXME: make padding a cmd line arg, this is needed to make a bochs disk image
     let padding = (20 * 16 * 63 * 512)
     outputData.increaseLengthBy(padding - outputData.length)

     guard outputData.writeToFile(filename, atomically: false) else {
         fatalError("Cant write to output file \(filename)");
     }
}


let bootsect = openOrQuit(args[1])
guard bootsect.length == 512 else {
    fatalError("Bootsector should be 512 bytes but is \(bootsect.length)")
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

writeOutImage(args[4], bootsect, loader, kernel, Int(kernelLBA))
