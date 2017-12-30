/*
 * kernel/mm/address.swift
 *
 * Created by Simon Evans on 19/04/2017.
 * Copyright © 2016 - 2017 Simon Evans. All rights reserved.
 *
 * Virtual and Physical address types.
 *
 */

public typealias RawAddress = UInt  // 64bit address
public typealias VirtualAddress = RawAddress


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

    func pageAddress(pageSize: UInt, roundUp: Bool = false) -> PhysPageAddress {
        return PhysPageAddress(self, pageSize: pageSize, roundUp: roundUp)
    }

    func advanced(by n: Int) -> PhysAddress {
        return PhysAddress(value + UInt(n))
    }

    func advanced(by n: UInt) -> PhysAddress {
        return PhysAddress(value + n)
    }

    func distance(to n: PhysAddress) -> UInt {
        if n.value > value {
            return n.value - value
        } else {
            return value - n.value
        }
    }

    static func +(lhs: PhysAddress, rhs: UInt) -> PhysAddress {
        return lhs.advanced(by: rhs)
    }

    static func +(lhs: PhysAddress, rhs: Int) -> PhysAddress {
        return lhs.advanced(by: rhs)
    }

    static func <(lhs: PhysAddress, rhs: PhysAddress) -> Bool {
        return lhs.value < rhs.value
    }

    public var _cVarArgEncoding: [Int] {
        return _encodeBitsAsWords(value)
    }
}


struct PhysPageAddress: CVarArg, Comparable, Hashable, Strideable, CustomStringConvertible {
    typealias Stride = Int

    let address: PhysAddress
    let pageSize: UInt

    public var description: String {
        return String(address.value, radix: 16)
    }

    init(_ address: PhysAddress, pageSize: UInt, roundUp: Bool = false) {
        precondition(address.value < MAX_PHYSICAL_MEMORY, "PhysAddress out of range")
        precondition((pageSize & ~pageSize) == 0, "PageSize is not a power of 2")
        if roundUp {
            self.address = PhysAddress((address.value + pageSize - 1) & ~(pageSize - 1))
        } else {
            self.address = PhysAddress(address.value & ~(pageSize - 1))
        }
        self.pageSize = pageSize
    }

    var vaddr: VirtualAddress {
        return address.vaddr
    }

    func distance(to other: PhysPageAddress) -> Int {
        return Int(other.address.value / pageSize) - Int(address.value / pageSize)
    }

    func advanced(by n: Int) -> PhysPageAddress {
        return PhysPageAddress(address + (UInt(n) * pageSize), pageSize: pageSize)
    }

    func advanced(by n: UInt) -> PhysPageAddress {
        return PhysPageAddress(address + (n * pageSize), pageSize: pageSize)
    }

    static func +(lhs: PhysPageAddress, rhs: UInt) -> PhysPageAddress {
        return lhs.advanced(by: rhs)
    }

    static func +(lhs: PhysPageAddress, rhs: Int) -> PhysPageAddress {
        return lhs.advanced(by: rhs)
    }

    static func ==(lhs: PhysPageAddress, rhs: PhysPageAddress) -> Bool {
        return lhs.address == rhs.address
    }

    static func <(lhs: PhysPageAddress, rhs: PhysPageAddress) -> Bool {
        return lhs.address < rhs.address
    }

    public var _cVarArgEncoding: [Int] {
        return _encodeBitsAsWords(address)
    }
}
