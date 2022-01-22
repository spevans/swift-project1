//
//  kernel/mm/PhysRegion.swift
//  project1
//
//  Created by Simon Evans on 15/01/2022.
//  Copyright © 2022 Simon Evans. All rights reserved.
//

struct PhysRegion {
    let baseAddress: PhysAddress
    let size: UInt

    init(start: PhysAddress, size: UInt) {
        precondition(size > 0)
        self.baseAddress = start
        self.size = size
    }

    init(start: PhysAddress, end: PhysAddress) {
        precondition(start <= end)
        baseAddress = start
        size = UInt(end - start) + 1
    }

    init(_ region: PhysPageAlignedRegion) {
        self.baseAddress = region.baseAddress
        self.size = region.size
    }

    var endAddress: PhysAddress { baseAddress + (size - 1) }
    var physPageAlignedRegion: PhysPageAlignedRegion {
        PhysPageAlignedRegion(start: baseAddress, size: size, pageSize: PageSize())
    }

    func contains(_ other: Self) -> Bool {
        return baseAddress <= other.baseAddress && endAddress >= other.endAddress
    }
}

#if TEST
import Foundation

extension PhysRegion {
    // For testing, create a region with some data in to emulate firmware etc
    // This will leak but its only used for testing so keeping the data around
    // until the end of the tests is fine.
    init(data: Data) {
        var ptr: UnsafeMutableRawPointer? = nil
        let err = posix_memalign(&ptr, Int(PageSize().size), data.count)
        guard err == 0, let ptr2 = ptr else {
            fatalError("posix_mmalign, size: \(data.count) failed: \(err)")
        }
        let dest = ptr2.bindMemory(to: UInt8.self, capacity: data.count)
        data.copyBytes(to: UnsafeMutablePointer<UInt8>(dest), count: data.count)
        let address = dest.address
        self.baseAddress = PhysAddress(address - PHYSICAL_MEM_BASE)
        self.size = UInt(data.count)
    }
}
#endif
