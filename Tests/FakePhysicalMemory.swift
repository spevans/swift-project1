//
//  FakePhysicalMemory.swift
//
//  Created by Simon Evans on 09/11/2024.
//  Copyright © 2024 Simon Evans. All rights reserved.
//


import Foundation

private var physicalMemory: [FakePhysMemory] = []
struct FakePhysMemory {
    let start: PhysAddress
    let end: PhysAddress
    let ptr: UnsafeMutableRawPointer

    init(region: PhysPageAlignedRegion) {
        self.start = region.baseAddress
        self.end = region.endAddress
        let size = Int(region.size)
        self.ptr = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 8)
        for index in 0..<size {
            ptr.storeBytes(of: 0, toByteOffset: index, as: UInt8.self)
        }
    }

    static func addPhysicalMemory(start: PhysAddress, size: Int) {
        precondition(size > 0)
        let region = PhysPageAlignedRegion(start: start, size: UInt(size))
        let fakeMemory = FakePhysMemory(region: region)
        physicalMemory.append(fakeMemory)
    }
}


extension PhysAddress {
    var vaddr: VirtualAddress {
        for entry in physicalMemory {
            if self.value >= entry.start.value && self.value <= entry.end.value {
                let offset = self.value - entry.start.value
                let ptr = entry.ptr.advanced(by: Int(offset))
                return VirtualAddress(bitPattern: ptr)
            }
        }
        // Default to the normal value which will work for the PhysPageAlignedRegion and PhysRegion
        // using the Data backed memory
        return VirtualAddress(PHYSICAL_MEM_BASE + value);
    }

}


extension PhysPageAlignedRegion {
    // For testing, create a region with some data in to emulate firmware etc
    // This will leak but its only used for testing so keeping the data around
    // until the end of the tests is fine.
    init(data: Data, pageSize: PageSize = PageSize()) {
        var ptr: UnsafeMutableRawPointer? = nil
        let err = posix_memalign(&ptr, Int(pageSize.size), data.count)
        guard err == 0, let ptr2 = ptr else {
            fatalError("posix_mmalign, alignment: \(pageSize.size), size: \(data.count) failed: \(err)")
        }
        let dest = ptr2.bindMemory(to: UInt8.self, capacity: data.count)
        data.copyBytes(to: UnsafeMutablePointer<UInt8>(dest), count: data.count)
        let physAddress = PhysAddress(dest.address - PHYSICAL_MEM_BASE)
        let pageCount = pageSize.pageCountCovering(size: data.count)
        self.init(physAddress, pageSize: pageSize, pageCount: pageCount)
    }
}

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
