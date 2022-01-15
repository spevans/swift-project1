//
//  kernel/mm/PhysAddressRegion.swift
//  project1
//
//  Created by Simon Evans on 15/01/2022.
//  Copyright © 2022 Simon Evans. All rights reserved.
//

struct PhysAddressRegion {
    let physAddress: PhysAddress
    let size: UInt

    init(start: PhysAddress, size: UInt) {
        self.physAddress = start
        self.size = size
    }

    init(start: PhysAddress, end: PhysAddress) {
        precondition(start <= end)
        physAddress = start
        size = UInt(end - start) + 1
    }

    init(_ physPageRange: PhysPageRange) {
        self.physAddress = physPageRange.address
        self.size = physPageRange.regionSize
    }

    var endAddress: PhysAddress { physAddress + (size - 1) }
    var physPageRange: PhysPageRange {
        PhysPageRange(start: physAddress, size: size, pageSize: PageSize(PAGE_SIZE))
    }

    func contains(_ other: Self) -> Bool {
        return physAddress <= other.physAddress && endAddress >= other.endAddress
    }
}

#if TEST
import Foundation

extension PhysAddressRegion {
    // For testing, create a region with some data in to emulate firmware etc
    // This will leak but its only used for testing so keeping the data around
    // until the end of the tests is fine.
    init(data: Data) {
        var ptr: UnsafeMutableRawPointer? = nil
        let err = posix_memalign(&ptr, Int(PageSize(PAGE_SIZE).pageSize), data.count)
        guard err == 0, let ptr2 = ptr else {
            fatalError("posix_mmalign, size: \(data.count) failed: \(err)")
        }
        let dest = ptr2.bindMemory(to: UInt8.self, capacity: data.count)
        data.copyBytes(to: UnsafeMutablePointer<UInt8>(dest), count: data.count)
        let address = dest.address
        self.physAddress = PhysAddress(address - PHYSICAL_MEM_BASE)
        self.size = UInt(data.count)
    }
}
#endif
