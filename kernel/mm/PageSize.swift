//
//  kernel/mm/PageSize.swift
//  project1
//
//  Created by Simon Evans on 25/12/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//

struct PageSize: Equatable {
    let size: UInt

    init(_ size: UInt) {
        precondition(size.nonzeroBitCount == 1) // Must be power of 2
        precondition(size >= 1024)
        self.size = size
    }

    init() {
        self.size = UInt(PAGE_SIZE)
    }

    init(encoding: Int) {
        switch encoding {
            case 1: self.size = 4096
            case 2: self.size = 2048 * 1024
            case 3: self.size = 1024 * 1024 * 1024
            default: fatalError("Invalid Page size")
        }
    }

    var mask: UInt { ~(size - 1) }

    var encoding: Int {
        switch size {
            case 4096: return 1
            case 2048 * 1024: return 2
            case 1024 * 1024 * 1024: return 3
            default: fatalError("Invalid page size: \(size)")
        }
    }

    func isPageAligned(_ address: UInt) -> Bool {
        address & ~mask == 0
    }

    func roundDown(_ address: UInt) -> UInt {
        address & mask
    }

    func roundToNextPage(_ address: UInt) -> UInt {
        (address + (size - 1)) & mask
    }

    func lastAddressInPage(_ address: UInt) -> UInt {
        address | ~mask
    }

    func onSamePage(_ address1: UInt, _ address2: UInt) -> Bool {
        address1 & mask == address2 & mask
    }

    func pageCountCovering(size: Int) -> Int {
        return ((size - 1) + Int(self.size)) / Int(self.size)
    }

    func regionSize(forPageCount pages: Int) -> UInt {
        size * UInt(pages)
    }

    func offsetInPage(_ address: UInt) -> UInt {
        address & ~mask
    }
}

extension PageSize: Comparable {
    static func < (lhs: PageSize, rhs: PageSize) -> Bool {
        lhs.size < rhs.size
    }
}
