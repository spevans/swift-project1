//
//  USBTests.swift
//  tests
//
//  Created by Simon Evans on 27/10/2020.
//  Copyright © 2020 Simon Evans. All rights reserved.
//

import XCTest

enum USB {}

class USBTests: XCTestCase {


    func testConfigDescriptor() throws {
        var getDescriptorConfigData: [UInt8] = [
            0x09, 0x02, 0x3b, 0x00, 0x02, 0x01, 0x01, 0xc0, 0x00, 0x09, 0x04, 0x00, 0x00, 0x01, 0x03, 0x00,
            0x00, 0x01, 0x09, 0x21, 0x10, 0x01, 0x00, 0x01, 0x22, 0x42, 0x00, 0x07, 0x05, 0x81, 0x03, 0x08,
            0x00, 0x01, 0x09, 0x04, 0x01, 0x00, 0x01, 0x03, 0x00, 0x00, 0x01, 0x09, 0x21, 0x10, 0x01, 0x00,
            0x01, 0x22, 0x41, 0x00, 0x07, 0x05, 0x82, 0x03, 0x08, 0x00, 0x01,
            ]

        XCTAssertEqual(getDescriptorConfigData.count, 59)

        let configDescriptor: USB.ConfigDescriptor = try getDescriptorConfigData.withUnsafeMutableBufferPointer {
            let vaddr = VirtualAddress($0.baseAddress!.address)
            let paddr = PhysAddress(vaddr: vaddr)
            let mmioRegion = MMIOSubRegion(baseAddress: paddr, count: $0.count)
            return try USB.ConfigDescriptor(from: mmioRegion)
        }

        print(configDescriptor)

    }


    func testConfigDescriptor2() throws {
        var data: [UInt8] = [
            0x09, 0x02, 0x19, 0x00, 0x01, 0x01, 0x00, 0xe0, 0x00, 0x09, 0x04, 0x00, 0x00, 0x01, 0x09,
            0x00, 0x00, 0x00, 0x07, 0x05, 0x81, 0x03, 0x02, 0x00, 0x0f ]
        XCTAssertEqual(data.count, 25)

        let configDescriptor: USB.ConfigDescriptor = try data.withUnsafeMutableBufferPointer {
            let vaddr = VirtualAddress($0.baseAddress!.address)
            let paddr = PhysAddress(vaddr: vaddr)
            let mmioRegion = MMIOSubRegion(baseAddress: paddr, count: $0.count)
            return try USB.ConfigDescriptor(from: mmioRegion)
        }

        print(configDescriptor)
    }
}
