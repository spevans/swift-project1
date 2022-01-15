//
//  kernel/mm/PageSize.swift
//  project1
//
//  Created by Simon Evans on 25/12/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//

struct PageSize {
    let pageSize: UInt

    var pageMask: UInt { pageSize - 1 }
    var pageShift: Int { pageSize.trailingZeroBitCount }

    init(_ pageSize: UInt) {
        precondition(pageSize.nonzeroBitCount == 1) // Must be power of 2
        precondition(pageSize >= 1024)
        self.pageSize = pageSize
    }

    var encoding: Int {
        switch pageSize {
            case 4096: return 1
            case 2048 * 1024: return 2
            case 1024 * 1024 * 1024: return 3
            default: fatalError("Invalid page size: \(pageSize)")
        }
    }

    func isPageAligned(_ address: UInt) -> Bool {
        address & pageMask == 0
    }

    func roundDown(_ address: UInt) -> UInt {
        address & ~pageMask
    }

    func roundUp(_ address: UInt) -> UInt {
        (address + (pageSize - 1)) & ~pageMask
    }

    func lastAddressInPage(_ address: UInt) -> UInt {
        address | pageMask
    }

    func onSamePage(_ address1: UInt, _ address2: UInt) -> Bool {
        address1 & ~pageMask == address2 & ~pageMask
    }

    func pageCountCovering(size: Int) -> Int {
        return ((size - 1) + Int(pageSize)) / Int(pageSize)
    }
}
