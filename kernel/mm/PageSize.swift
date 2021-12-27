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
}
