/*
 * kernel/mm/address.swift
 *
 * Created by Simon Evans on 19/04/2017.
 * Copyright © 2016 - 2017, 2019 Simon Evans. All rights reserved.
 *
 * Virtual and Physical address types.
 *
 */

public typealias RawAddress = UInt  // 64bit address
public typealias VirtualAddress = RawAddress


#if TEST
private let physicalMemory = UnsafeMutableRawPointer.allocate(byteCount: 0x100_000, alignment: 8)   // 1MB
#endif


struct PhysAddress: CVarArg, Comparable, Hashable, CustomStringConvertible {
    let value: RawAddress

    public var description: String {
        return String(value, radix: 16)
    }

    init(_ address: RawAddress) {
        precondition(address < MAX_PHYSICAL_MEMORY, "PhysAddress out of range")
        value = address
    }

    // Map a physical address to a kernel virtual address using the 1-1 mapping
    // of physical memory that is setup at startup.
    var vaddr: VirtualAddress {
        return VirtualAddress(PHYSICAL_MEM_BASE + value);
    }

    var rawPointer: UnsafeMutableRawPointer {
#if TEST
        precondition(value < 0x100_000)
        return physicalMemory.advanced(by: Int(value))
#else
        return UnsafeMutableRawPointer(bitPattern: vaddr)!
#endif
    }

    func pageAddress(pageSize: UInt, roundUp: Bool = false) -> PhysAddress {
        if roundUp {
            return PhysAddress((value + pageSize - 1) & ~(pageSize - 1))
        } else {
            return PhysAddress(value & ~(pageSize - 1))
        }
    }

    var isPageAligned: Bool { (value & UInt(PAGE_MASK)) == 0 }

    func advanced(by n: Int) -> PhysAddress {
        return PhysAddress(value + UInt(n))
    }

    func advanced(by n: UInt) -> PhysAddress {
        return PhysAddress(value + n)
    }

    func distance(to n: PhysAddress) -> Int {
        if n.value > value {
            return Int(n.value - value)
        } else {
            return Int(value - n.value)
        }
    }

    static func +(lhs: PhysAddress, rhs: UInt) -> PhysAddress {
        return lhs.advanced(by: rhs)
    }

    static func +=(lhs: inout PhysAddress, rhs: UInt) {
        lhs = lhs + rhs
    }

    static func +(lhs: PhysAddress, rhs: Int) -> PhysAddress {
        return lhs.advanced(by: rhs)
    }

    static func +=(lhs: inout PhysAddress, rhs: Int) {
        lhs = lhs + rhs
    }

    static func -(lhs: PhysAddress, rhs: UInt) -> PhysAddress {
        return PhysAddress(lhs.value - rhs)
    }

    static func -(lhs: PhysAddress, rhs: PhysAddress) -> Int {
        return lhs.distance(to: rhs)
    }

    static func <(lhs: PhysAddress, rhs: PhysAddress) -> Bool {
        return lhs.value < rhs.value
    }

    public var _cVarArgEncoding: [Int] {
        return _encodeBitsAsWords(value)
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
        defer { currentPage = currentPage + physPageRange.pageSize }
        return currentPage
    }
}


// A page aligned physical address region storing the start address, page size and page count.
struct PhysPageRange: CVarArg, Hashable, Sequence, CustomStringConvertible {
    typealias Stride = Int

    // Use the lower 2 bits to store the page size, 0 = 4K 1 = 2MB 2 = 1G
    private let addressBits: UInt
    let pageCount: Int

    var address: PhysAddress {
        PhysAddress(addressBits & 0xffff_ffff_ffff_f000)
    }

    var regionSize: UInt { pageSize * UInt(pageCount) }

    var endAddress: PhysAddress {
        PhysAddress(address.value + (regionSize - 1))
    }

    var description: String {
        var result = "0x" + String(address.value, radix: 16) + " - 0x" + String(endAddress.value, radix: 16)
        result += "\t\(pageCount) [0x\(String(pageSize, radix: 16))]"
        return result
    }

    init(_ address: PhysAddress, pageSize: UInt, pageCount: Int, roundUp: Bool = false) {
        precondition(address.value < MAX_PHYSICAL_MEMORY, "PhysAddress out of range")
        precondition((pageSize & ~pageSize) == 0, "PageSize is not a power of 2")
        precondition(pageCount > 0)

        let pgSize: UInt
        // Encode the page size
        switch pageSize {
        case 4096: pgSize = 1
        case 2048 * 1024: pgSize = 2
        case 1024 * 1024 * 1024: pgSize = 3
        default: fatalError("Invalid page size: \(pageSize)")
        }

        var _address: UInt
        if roundUp {
            _address = (address.value + pageSize - 1) & ~(pageSize - 1)
        } else {
            _address = address.value & ~(pageSize - 1)
        }
        _address |= pgSize
        addressBits = _address
        self.pageCount = pageCount
    }

    private init(addressBits: UInt, pageCount: Int) {
        self.addressBits = addressBits
        self.pageCount = pageCount
    }

    func splitRegion(withFirstRegionCount count1: Int) -> (Self, Self) {
        precondition(count1 > 0)
        let count2 = pageCount - count1
        precondition(count2 > 0)

        let region2 = PhysPageRange(addressBits: addressBits, pageCount: count1)
        let region1 = PhysPageRange(addressBits: addressBits + region2.regionSize, pageCount: count2)
        return (region2, region1)
    }

    func makeIterator() -> PhysPageRangeIterator {
        return PhysPageRangeIterator(self)
    }


    var pageSize: UInt {
        switch (addressBits & 3) {
        case 1: return 4096
        case 2: return 2048 * 1024
        case 3: return 1024 * 1024 * 1024
        default: fatalError("Invalid Page size")
        }
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

    func distance(to other: PhysPageRange) -> Int {
        return Int(other.address.value / pageSize) - Int(address.value / pageSize)
    }


    public var _cVarArgEncoding: [Int] {
        return _encodeBitsAsWords(address)
    }


    // The smallest pagesize should always be usable to create a range over the whole space
    static func createRanges(startAddress: PhysAddress, size: UInt, pageSizes: [UInt]) -> [PhysPageRange] {
        precondition(startAddress.isPageAligned) // Aligned to the smallest page size at least.
        precondition(pageSizes.count > 0)
        guard size >= pageSizes[0] else { return [] }

        var result: [PhysPageRange] = []
        let endAddress = startAddress + (size - 1)

        var centralStart = PhysAddress(0)
        var centralEnd = PhysAddress(0)
        var psizes = pageSizes.sorted { $0 > $1 }

        var centralRange: PhysPageRange?

        while centralRange == nil {
            let pageSize = psizes.removeFirst()
            // Find section of the largest size, this may cover the whole range or,
            // align to the start but not the end or align to the end but not the start
            // or maybe doesnt align to start/end at all

            centralStart = startAddress.pageAddress(pageSize: pageSize, roundUp: true)
            centralEnd = endAddress.pageAddress(pageSize: pageSize, roundUp: false)

            if centralStart == centralEnd, centralStart == startAddress, size == pageSize {
                // Single page covering the whole range
                return [PhysPageRange(startAddress, pageSize: pageSize, pageCount: 1)]
            }

            if centralStart < centralEnd, centralStart >= startAddress, centralEnd <= endAddress {
                // Region is between start and end
                var pageCount = (centralEnd - centralStart) / Int(pageSize)
                if (centralEnd - 1) + pageSize == endAddress {
                    pageCount += 1
                    centralEnd += (pageSize - 1)
                }
                precondition(pageCount > 0)
                centralRange = PhysPageRange(centralStart, pageSize: pageSize, pageCount: pageCount)
            }
        }

        if centralStart > startAddress {
            for pageSize in psizes {
                let start = startAddress.pageAddress(pageSize: pageSize, roundUp: true)
                if start >= centralStart { continue }
                let pageCount = (centralStart - start) / Int(pageSize)

                let range = PhysPageRange(start, pageSize: pageSize, pageCount: pageCount)
                result.append(range)
                centralStart = start
            }
        }
        precondition(centralStart == startAddress)
        result.append(centralRange!)

        if centralEnd < endAddress {
            for pageSize in psizes {
                let end = endAddress.pageAddress(pageSize: pageSize, roundUp: false)
                if end <= centralEnd { continue }
                var pageCount = (end - centralEnd) / Int(pageSize)
                if (end - 1) + pageSize == endAddress {
                    pageCount += 1
                }

                let range = PhysPageRange(centralEnd, pageSize: pageSize, pageCount: pageCount)
                result.append(range)
                centralEnd = end
            }
        }

        result.sort { $0.address < $1.address }
        precondition(result.first!.address == startAddress)
        precondition(result.last!.endAddress == endAddress)
        return result
    }
}
