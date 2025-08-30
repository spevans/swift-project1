//
//  kernel/mm/PhysRegion.swift
//  project1
//
//  Created by Simon Evans on 15/01/2022.
//  Copyright © 2022 Simon Evans. All rights reserved.
//

struct PhysRegion: CustomStringConvertible {
    let baseAddress: PhysAddress
    let size: UInt

    var description: String {
        #sprintf("%p/0x%x", baseAddress, size)
    }

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
