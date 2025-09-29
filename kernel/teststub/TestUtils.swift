//
//  TestUtils.swift
//  tests
//
//  Created by Simon Evans on 02/08/2019.
//  Copyright © 2019 Simon Evans. All rights reserved.
//

import Foundation

let PAGE_SIZE = UInt(4096)
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

public func outb(_ port: UInt16, _ value: UInt8) {
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

struct CPU {
    // TODO: Use the real one as this is a straight copy
    enum CacheType: Int, CustomStringConvertible {
        case writeBack = 0
        case writeCombining = 1
        case weakUncacheable = 2
        case uncacheable = 3
        case reserved1 = 4 // WriteBack
        case writeProtected = 5
        case reserved2 = 6 // weakUncacheable
        case writeThrough = 7

        var description: String {
            switch self {
                case .writeBack:
                    "WB"
                case .writeCombining:
                    "WC"
                case .weakUncacheable:
                    "WU"
                case .uncacheable:
                    "UN"
                case .reserved1:
                    "R1"
                case .writeProtected:
                    "WP"
                case .reserved2:
                    "R2"
                case .writeThrough:
                    "WT"
            }
        }

        // This value is stored as three bits in a Page Table Entry mapping a page.
        var patEntry: Int { rawValue }
    }
}

func mapIORegion(region: PhysRegion, cacheType: CPU.CacheType = .uncacheable) -> MMIORegion {
    return MMIORegion(region)
}

func mapRORegion(region: PhysPageAlignedRegion, cacheType: CPU.CacheType = .writeBack) -> MMIORegion {
    return MMIORegion(region)
}

func mapRORegion(region: PhysRegion) -> MMIORegion {
    return MMIORegion(region)
}

func unmapMMIORegion(_ mmioRegion: MMIORegion) {
}

func mapRegion(region: PhysRegion, readWrite: Bool, cacheType: CPU.CacheType) -> MMIORegion {
    return MMIORegion(region)
}

func koops(_ message: String) -> Never {
    fatalError(message)
}

internal struct _tty : UnicodeOutputStream {
    mutating func write(_ string: StaticString) {
        print(string, terminator: "")
    }

    mutating func write(_ character: Character) {
        print(character, terminator: "")
    }

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
    mutating func write(_ string: StaticString) {
        print(string, terminator: "")
    }

    mutating func write(_ character: Character) {
        print(character, terminator: "")
    }

    mutating func write(_ string: String) {
        print(string, terminator: "")
    }

    mutating func write(_ unicodeScalar: UnicodeScalar) {
        if unicodeScalar.isASCII, let ch = Int32(exactly: unicodeScalar.value) {
            print(String(CChar(ch)), terminator: "")
        }
    }
}

func printStackUsage(_ msg: String = "") {
    if msg != "" {
        print(msg)
    }
}

public typealias ExceptionRegisters = UnsafeMutablePointer<exception_regs>

func sti() {
    print("Enabling interrupts")
}
