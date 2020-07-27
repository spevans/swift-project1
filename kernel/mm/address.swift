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

    static func +(lhs: PhysAddress, rhs: Int) -> PhysAddress {
        return lhs.advanced(by: rhs)
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


// A page aligned physical address region storing the start address, page size and page count.
struct PhysPageRange: CVarArg, Hashable, CustomStringConvertible {
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


    static func createRanges(startAddress: PhysAddress, size: UInt, pageSizes: [UInt]) -> [PhysPageRange] {
        precondition(pageSizes.count > 0)
        guard size >= pageSizes[0] else { return [] }

        func createRange(start: PhysAddress, end: PhysAddress, pageSize: UInt) -> PhysPageRange? {
            let s = start.pageAddress(pageSize: pageSize, roundUp: true)    // round up to next page
            let e = end.pageAddress(pageSize: pageSize)                     // round down to current page
            if e >= s {
                let pageCount = 1 + ((e - s) / Int(pageSize))
                if pageCount > 0 {
                    return PhysPageRange(s, pageSize: pageSize, pageCount: pageCount)
                }
            }
            return nil
        }

        var result: [PhysPageRange] = []
        let endAddress = startAddress + (size - 1)
        var frontEnd = endAddress
        var backStart = PhysAddress(0)

        for pageSize in pageSizes.sorted().reversed() {
            if startAddress < frontEnd, let range = createRange(start: startAddress, end: frontEnd, pageSize: pageSize) {
                result.append(range)
                if range.endAddress == endAddress {
                    break
                }
                // There is no front block if the original region started at Physical 0
                if range.address.value > 0 {
                    frontEnd = PhysAddress(range.address.value - 1)
                }

                if backStart.value == 0 {
                    backStart = range.endAddress + 1
                    continue
                }
            }
            if let range = createRange(start: backStart, end: endAddress, pageSize: pageSize) {
                result.append(range)
                if range.endAddress == endAddress {
                    break
                }
                backStart = range.endAddress + 1
            }
        }
        result.sort { $0.address < $1.address }
        return result
    }
}
