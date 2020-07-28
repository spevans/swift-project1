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


struct PCIConfigSpace {
    let busID: UInt8
    let address: UInt32


    init(busID: UInt8, address: UInt32) {
        self.busID = busID
        self.address = address
    }

    func readConfigByte(atByteOffset offset: UInt) -> UInt8 {
        return 0
    }

    func readConfigWord(atByteOffset offset: UInt) -> UInt16 {
        return 0
    }

    func readConfigDword(atByteOffset offset: UInt) -> UInt32 {
        return 0
    }

    func writeConfigDword(atByteOffset offset: UInt, value: UInt32) {
    }

    func writeConfigWord(atByteOffset offset: UInt, value: UInt16) {
    }

    func writeConfigByte(atByteOffset offset: UInt, value: UInt8) {
    }
}
