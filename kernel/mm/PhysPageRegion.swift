//
//  kernel/mm/PhysPageRegion.swift
//
//  Created by Simon Evans on 15/01/2022.
//  Copyright © 2022 Simon Evans. All rights reserved.
//
//  Physical Page Range aligned to a page

#if TEST
import Foundation
#endif

// A page aligned physical address region storing the start address, page size and page count.
struct PhysPageRange: CVarArg, Hashable, Sequence, CustomStringConvertible {
    typealias Stride = Int

    // Use the lower 2 bits to store the page size, 0 = 4K 1 = 2MB 2 = 1G
    private let addressBits: UInt
    let pageCount: Int

    var address: PhysAddress { PhysAddress(addressBits & 0xffff_ffff_ffff_f000) }
    var pageSize: PageSize { PageSize(encoding: Int(addressBits & 0xfff)) }

    var regionSize: UInt { pageSize.regionSize(forPageCount: pageCount) }

    var endAddress: PhysAddress {
        // Avoid overflow if range is the full 64bit region.
        let regionSizeMinusOne = pageSize.regionSize(forPageCount: pageCount - 1) + (pageSize.size - 1)
        return PhysAddress(address.value + regionSizeMinusOne)
    }

    var description: String {
        var result = "0x" + String(address.value, radix: 16) + " - 0x" + String(endAddress.value, radix: 16)
        result += " [\(pageCount) * 0x\(String(pageSize.size, radix: 16))]"
        return result
    }

    init(_ address: PhysAddress, pageSize: PageSize, pageCount: Int) {
        precondition(pageCount > 0)
        self.addressBits = pageSize.roundDown(address.value) | UInt(pageSize.encoding)
        self.pageCount = pageCount
    }

    // Create a page range that covers from start address to for size bytes. The resulting
    // region may have a start address lower then the requested address

    init(start: PhysAddress, size: UInt, pageSize: PageSize = PageSize()) {
        let startAddress = pageSize.roundDown(start)
        let endAddress = pageSize.lastAddressInPage(start + size - 1)
        let pageCount = ((endAddress - startAddress) + 1) / Int(pageSize.size)
        precondition(pageCount > 0)
        self.addressBits = startAddress.value | UInt(pageSize.encoding)
        self.pageCount = pageCount
    }

#if TEST
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
        let address = dest.address
        let physAddress = address - PHYSICAL_MEM_BASE

        self.addressBits = physAddress | UInt(pageSize.encoding)
        self.pageCount = pageSize.pageCountCovering(size: data.count)
    }
#endif

    private init(addressBits: UInt, pageCount: Int) {
        self.addressBits = addressBits
        self.pageCount = pageCount
    }

    var vaddr: VirtualAddress {
        return address.vaddr
    }

    var rawPointer: UnsafeMutableRawPointer {
        return UnsafeMutableRawPointer(bitPattern: vaddr)!
    }

    var rawBufferPointer: UnsafeMutableRawBufferPointer {
        return UnsafeMutableRawBufferPointer(start: rawPointer, count: Int(regionSize))
    }

    func splitRegion(withFirstRegionCount count1: Int) -> (Self, Self) {
        precondition(count1 > 0)
        let count2 = pageCount - count1
        precondition(count2 > 0)

        let region1 = PhysPageRange(addressBits: addressBits, pageCount: count1)
        let region2 = PhysPageRange(addressBits: addressBits + region1.regionSize, pageCount: count2)
        return (region1, region2)
    }

    func makeIterator() -> PhysPageRangeIterator {
        return PhysPageRangeIterator(self)
    }

    func distance(to other: PhysPageRange) -> Int {
        return pageSize.pageCountCovering(size: Int(other.address.value - address.value))
    }

    public var _cVarArgEncoding: [Int] {
        return _encodeBitsAsWords(address)
    }

    func contains(_ other: Self) -> Bool {
        return address <= other.address && endAddress >= other.endAddress
    }

    func extraRanges(containing other: Self) -> (Self?, Self?) {
        precondition(pageSize == other.pageSize)
        precondition(contains(other))

        let before: Self?
        let after: Self?

        if address < other.address {
            let size = UInt(other.address - address)
            before = Self(start: address, size: size, pageSize: pageSize)
        } else {
            before = nil
        }

        if other.endAddress < endAddress {
            let size = UInt(endAddress - other.endAddress)
            after = Self(start: other.endAddress + 1, size: size, pageSize: pageSize)
        } else {
            after = nil
        }
        return (before, after)
    }


    // The smallest pagesize should always be usable to create a range over the whole space
    static func createRanges(startAddress: PhysAddress, endAddress: PhysAddress, pageSizes: [PageSize]) -> [PhysPageRange] {
        guard startAddress.value < MAX_PHYSICAL_MEMORY, endAddress.value < MAX_PHYSICAL_MEMORY else {
            fatalError("Out of range physical region")
        }
        precondition(pageSizes.count > 0)

        let smallestPageSize = pageSizes.min()!
        let smallestPageMask = smallestPageSize.mask
        // Round up the startAddress to a page boundary if not already on one.
        // Round down the endAddress to an end of page address (ie ends in 0x...fff).
        // Use the smallest system page size

        let roundedStartAddress = smallestPageSize.roundUp(startAddress)
        let roundedEndAddress: PhysAddress
        if endAddress.value & ~smallestPageMask == ~smallestPageMask {
            roundedEndAddress = endAddress
        } else {
            let address = (endAddress.value & smallestPageMask)
            guard address > 0 else { return [] }
            roundedEndAddress = PhysAddress(address - 1)
        }
        guard roundedEndAddress > roundedStartAddress else { return [] }

        precondition(roundedStartAddress.isPageAligned) // Aligned to the smallest page size at least.

        var result: [PhysPageRange] = []
        var centralStart = PhysAddress(0)
        var centralEnd = PhysAddress(0)
        var pageSizes = pageSizes.sorted { $0 > $1 }
        var centralRange: PhysPageRange?

        while centralRange == nil {
            let pageSize = pageSizes.removeFirst()
            // Find section of the largest size, this may cover the whole range or,
            // align to the start but not the end or align to the end but not the start
            // or maybe doesnt align to start/end at all

            centralStart = pageSize.roundUp(roundedStartAddress)
            if centralStart < roundedStartAddress || centralStart > roundedEndAddress {
                continue
            }

            let pageCount = UInt((roundedEndAddress - roundedStartAddress) + 1) / pageSize.size
            if pageCount == 0 { continue }
            let range = PhysPageRange(centralStart, pageSize: pageSize, pageCount: Int(pageCount))
            centralRange = range
            centralEnd = range.endAddress
        }

        if centralStart > roundedStartAddress {
            for pageSize in pageSizes {
                let start = pageSize.roundUp(roundedStartAddress)
                if start >= centralStart { continue }
                let pageCount = (centralStart - start) / Int(pageSize.size)

                let range = PhysPageRange(start, pageSize: pageSize, pageCount: pageCount)
                result.append(range)
                centralStart = start
            }
        }
        precondition(centralStart == roundedStartAddress)
        result.append(centralRange!)

        if centralEnd < roundedEndAddress {
            for pageSize in pageSizes {
                let pageCount = UInt(roundedEndAddress - centralEnd) / pageSize.size
                if pageCount == 0  { continue }
                let range = PhysPageRange(centralEnd + 1, pageSize: pageSize, pageCount: Int(pageCount))
                result.append(range)
                centralEnd = centralEnd + (pageSize.size * pageCount)
            }
        }

        result.sort { $0.address < $1.address }
        precondition(result.first!.address == roundedStartAddress)
        precondition(result.last!.endAddress == roundedEndAddress)
        return result
    }
}


struct PhysPageRangeIterator: IteratorProtocol {
    typealias Element = PhysAddress
    private let physPageRange: PhysPageRange
    private var currentPage: PhysAddress

    init(_ physPageRange: PhysPageRange) {
        self.physPageRange = physPageRange
        currentPage = physPageRange.address
    }

    mutating func next() -> Element? {
        guard currentPage < physPageRange.endAddress else { return nil }
        defer { currentPage += physPageRange.pageSize.size }
        return currentPage
    }
}

// Generate PhysPageRanges with fixed pageCount from a large PhysPageRange
// The last element may have pageCount < pagesPerChunk
struct PhysPageRangeChunksInterator: IteratorProtocol {
    typealias Element = PhysPageRange
    private var physPageRange: PhysPageRange?
    private let pageCount: Int


    init(_ physPageRange: PhysPageRange, pagesPerChunk: Int) {
        self.physPageRange = physPageRange
        self.pageCount = pagesPerChunk
    }

    mutating func next() -> Element? {
        guard var pageRange = physPageRange else { return nil }
        if pageRange.pageCount <= self.pageCount {
            physPageRange = nil
        } else {
            (pageRange, self.physPageRange) = pageRange.splitRegion(withFirstRegionCount: self.pageCount)
        }
        return pageRange
    }
}
