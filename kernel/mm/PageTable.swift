/*
 * kernel/mm/PageTable.swift
 *
 * Created by Simon Evans on 20/10/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * 4K Page Table and the entry in the table.
 *
 */


private let entriesPerTable = 512
// Only Lower 48bits are valid in a physical address and lower 12 are flags
private let pageAddressMask: RawAddress = 0x0000_ffff_ffff_f000


struct PageTable {
    typealias Index = Int
    typealias Element = PageTableEntry

    private let table: UnsafeMutableBufferPointer<PageTableEntry>

    init(start: UnsafeMutablePointer<PageTableEntry>) {
        table = UnsafeMutableBufferPointer(start: start, count: entriesPerTable)
    }

    subscript(index: Int) -> PageTableEntry {
        get { table[index] }
        set { table[index] = newValue }
    }
}


// 4K Page Table Entry
struct PageTableEntry: Equatable, CustomStringConvertible {
    private var bits: BitArray64

    init(address: PhysAddress, readWrite: Bool, userAccess: Bool,
        patIndex: Int, global: Bool, noExec: Bool) {

        precondition(address & pageAddressMask == address)

        let writeThrough = (patIndex & 1) == 1
        let cacheDisable = (patIndex & 2) == 2
        let pat = (patIndex & 4) == 4

        var bits = BitArray64(address.value)
        bits[0] = 1
        bits[1] = readWrite ? 1 : 0
        bits[2] = userAccess ? 1 : 0
        bits[3] = writeThrough ? 1 : 0
        bits[4] = cacheDisable ? 1 : 0
        bits[7] = pat ? 1 : 0
        bits[8] = global ? 1 : 0
        bits[63] = noExec ? 1 : 0
        self.bits = bits
    }

    init(address: PhysAddress, readWrite: Bool, userAccess: Bool,
        patIndex: Int, global: Bool, noExec: Bool, largePage: Bool) {

        precondition(address & pageAddressMask == address)
        let writeThrough = (patIndex & 1) == 1
        let cacheDisable = (patIndex & 2) == 2
        let pat = (patIndex & 4) == 4

        var bits = BitArray64(address.value)
        bits[0] = 1
        bits[1] = readWrite ? 1 : 0
        bits[2] = userAccess ? 1 : 0
        bits[3] = writeThrough ? 1 : 0
        bits[4] = cacheDisable ? 1 : 0
        bits[7] = pat ? 1 : 0
        bits[8] = global ? 1 : 0
        bits[63] = noExec ? 1 : 0
        self.bits = bits
    }

    private init(_ rawValue: UInt64) {
        bits = BitArray64(rawValue)
    }

    static func NotPresent() -> Self {
        return Self(0)
    }

    var rawValue: UInt64 { bits.rawValue }
    var present: Bool { Bool(bits[0]) }
    var readWrite: Bool {
        get { Bool(bits[1]) }
        set { bits[1] = newValue ? 1 : 0 }
    }
    var userAccess: Bool { Bool(bits[2]) }
    var writeThrough: Bool { Bool(bits[3]) }
    var cacheDisable: Bool { Bool(bits[4]) }
    var accessed: Bool {
        get { Bool(bits[5]) }
        set { bits[5] = newValue ? 1 : 0 }
    }
    var dirty: Bool {
        get { Bool(bits[6]) }
        set { bits[6] = newValue ? 1 : 0 }
    }
    var pat: Bool { Bool(bits[7]) }
    var global: Bool { Bool(bits[8]) }
    var physicalAddress: PhysAddress { PhysAddress(RawAddress(bits.rawValue) & pageAddressMask) }
    var protectionKey: Int { Int(bits[59...62]) }
    var executeDisable: Bool { Bool(bits[63]) }

    var patIndex: Int {
        get { bits[3] + (2 * bits[4]) + (4 * bits[7]) }
        set {
            bits[3] = (newValue & 1)
            bits[4] = (newValue >> 1) & 1
            bits[7] = (newValue >> 2) & 1
        }
    }

    var pageAddress: PhysAddress? {
        guard present else { return nil }
        return physicalAddress
    }

    var description: String {
        var result = "\(String(bits.rawValue, radix: 16)): "
        if !present {
            return result + " not present"
        }
        result += "present, readWrite: \(readWrite) userAccess: \(userAccess) writeThrough: \(writeThrough)"
            + " cacheDisable: \(cacheDisable) accessed: \(accessed) dirty: \(dirty) pat: \(pat) global: \(global)"
            + " patIndex: \(patIndex) protectionKey: \(protectionKey) executeDisable: \(executeDisable)"
            + " addr: \(physicalAddress)"
        return result
    }
}
