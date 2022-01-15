//
//  TestUtils.swift
//  tests
//
//  Created by Simon Evans on 02/08/2019.
//  Copyright © 2019 Simon Evans. All rights reserved.
//

import Foundation

// Mock functions and types

func printk(_ format: String, _ arguments: CVarArg...) {
    print(String(format: format, arguments))
}

func vaddrFromPaddr(_ addr: UInt) -> UInt {
    return addr
}

func testBundle() -> Bundle {
    for bundle in Bundle.allBundles {
        if let bundleId = bundle.bundleIdentifier, bundleId == "org.si.acpi-tests" {
            return bundle
        }
    }
    fatalError("Cant find test bundle")
}

func openOrQuit(filename: String) -> Data {
    guard let file = try? Data(contentsOf: URL(fileURLWithPath: filename)) else {
        fatalError("Cant open \(filename)")
    }
    return file
}


// Dummy IO and PCI Config space

private var ioSpace = Array<UInt8>(repeating: 0, count: 64 * 1024)

func inb(_ port: UInt16) -> UInt8 {
    let index = Int(port)
    return ioSpace[index]
}

func inw(_ port: UInt16) -> UInt16 {
    let index = Int(port)
    return UInt16(ioSpace[index + 1]) << 8 | UInt16(ioSpace[index])
}

func inl(_ port: UInt16) -> UInt32 {
    let index = Int(port)
    return UInt32(ioSpace[index + 3]) << 24 | UInt32(ioSpace[index + 2]) << 16 | UInt32(ioSpace[index + 1]) << 8 | UInt32(ioSpace[index])

}

func outb(_ port: UInt16, _ value: UInt8) {
    let index = Int(port)
    ioSpace[index] = value
}

func outw(_ port: UInt16, _ value: UInt16) {
    let index = Int(port)
    ioSpace[index] = UInt8(truncatingIfNeeded: value)
    ioSpace[index + 1] = UInt8(truncatingIfNeeded: value >> 8)
}

func outl(_ port: UInt16, _ value: UInt32) {
    let index = Int(port)
    ioSpace[index] = UInt8(truncatingIfNeeded: value)
    ioSpace[index + 1] = UInt8(truncatingIfNeeded: value >> 8)
    ioSpace[index + 2] = UInt8(truncatingIfNeeded: value >> 16)
    ioSpace[index + 3] = UInt8(truncatingIfNeeded: value >> 24)
}

func noInterrupt<Result>(_ task: () -> Result) -> Result {
    let result: Result = task()
    return result
}

func mapIORegion(region: PhysPageRange, cacheType: CPU.CacheType = .uncacheable) -> MMIORegion {
    return MMIORegion(physPageRange: region)
}

func mapRORegion(region: PhysPageRange, cacheType: CPU.CacheType = .writeBack) -> MMIORegion {
    return MMIORegion(physPageRange: region)
}

func mapRORegion(region: PhysAddressRegion) -> MMIORegion {
    return MMIORegion(region: region)
}

func unmapMMIORegion(_ mmioRegion: MMIORegion) {
}

func koops(_ message: String) -> Never {
    fatalError(message)
}

internal struct _tty : UnicodeOutputStream {
    mutating func write(_ string: String) {
        // FIXME: Get precondition to work
        //precondition(string._guts.isASCII, "String must be ASCII")
        if string.isEmpty { return }
        print(string)
    }

    mutating func write(_ unicodeScalar: UnicodeScalar) {
        if let ch = Int32(exactly: unicodeScalar.value) {
            print(String(CChar(ch)))
        }
    }
}


internal struct _serial: UnicodeOutputStream {
    mutating func write(_ string: String) {
        if string.isEmpty { return }
        print("serial:", string)
    }

    mutating func write(_ unicodeScalar: UnicodeScalar) {
        if unicodeScalar.isASCII, let ch = Int32(exactly: unicodeScalar.value) {
            print(String(CChar(ch)))
        }
    }
}
