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


struct PhysAddress: CVarArg {
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

    func advanced(by n: Int) -> PhysAddress {
        return PhysAddress(value + UInt(n))
    }

    func advanced(by n: UInt) -> PhysAddress {
        return PhysAddress(value + n)
    }

    func distance(to n: PhysAddress) -> UInt {
        return n.value - value
    }

    static func +(lhs: PhysAddress, rhs: UInt) -> PhysAddress {
        return lhs.advanced(by: rhs)
    }

    static func <(lhs: PhysAddress, rhs: PhysAddress) -> Bool {
        return lhs.value < rhs.value
    }

    static func <=(lhs: PhysAddress, rhs: PhysAddress) -> Bool {
        return lhs.value <= rhs.value
    }

    static func ==(lhs: PhysAddress, rhs: PhysAddress) -> Bool {
        return lhs.value == rhs.value
    }

    static func >(lhs: PhysAddress, rhs: PhysAddress) -> Bool {
        return lhs.value > rhs.value
    }

    static func >=(lhs: PhysAddress, rhs: PhysAddress) -> Bool {
        return lhs.value >= rhs.value
    }

    public var _cVarArgEncoding: [Int] {
        return _encodeBitsAsWords(value)
    }
}
