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

    init(_ address: RawAddress) {
        precondition(address < MAX_PHYSICAL_MEMORY, "PhysAddress out of range")
        value = address
    }

    // Map a physical address to a kernel virtual address using the 1-1 mapping
    // of physical memory that is setup at startup.
    var vaddr: VirtualAddress {
        return VirtualAddress(PHYSICAL_MEM_BASE + value);
    }

    public var description: String {
        return String(value, radix: 16)
    }

    var rawPointer: UnsafeMutableRawPointer {
        return UnsafeMutableRawPointer(bitPattern: vaddr)!
    }


    func pageAddress(pageSize: PageSize, roundUp: Bool = false) -> PhysAddress {
        if roundUp {
            return pageSize.roundUp(self)
        } else {
            return pageSize.roundDown(self)
        }
    }

    var isPageAligned: Bool { PageSize().isPageAligned(value) }

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

    static func &(lhs: PhysAddress, rhs: RawAddress) -> PhysAddress {
        return PhysAddress(lhs.value & rhs)
    }

    static func |(lhs: PhysAddress, rhs: RawAddress) -> PhysAddress {
        return PhysAddress(lhs.value & rhs)
    }

    public var _cVarArgEncoding: [Int] {
        return _encodeBitsAsWords(value)
    }
}

extension PageSize {
    func isPageAligned(_ address: PhysAddress) -> Bool {
        isPageAligned(address.value)
    }

    func roundDown(_ address: PhysAddress) -> PhysAddress {
        PhysAddress(roundDown(address.value))
    }

    func roundUp(_ address: PhysAddress) -> PhysAddress {
        PhysAddress(roundToNextPage(address.value))
    }

    func lastAddressInPage(_ address: PhysAddress) -> PhysAddress {
        PhysAddress(lastAddressInPage(address.value))
    }

    func onSamePage(_ address1: PhysAddress, _ address2: PhysAddress) -> Bool {
        onSamePage(address1.value, address2.value)
    }
}
