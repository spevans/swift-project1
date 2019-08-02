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
