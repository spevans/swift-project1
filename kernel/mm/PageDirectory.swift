/*
 * kernel/mm/PageDirectory.swift
 *
 * Created by Simon Evans on 14/11/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * 4K Page Directory or 2MB Pages.
 *
 */


// (PML5) -> PML4 -> PDPT -> PDE -> PT

// PML4E PageMapLevel4Entry -> PDPTE Buffer == [PageDirectoryPointerTableEntry]
// PDPTE PageDirectoryPointerTableEntry -> PDE Buffer == [PageDirectoryEntry]
// PDE PageDirectoryEntry -> PTE Buffer == [PageTableEntry]
// PTE -> 4K page

private let entriesPerTable = 512
// 4K aligned page table physical address mask
private let pageTableAddressMask: RawAddress = 0x0000_ffff_ffff_f000
// 2MB Large Page physical address mask
private let largePageAddressMask: RawAddress = 0x0000_ffff_ffe0_0000


struct PageDirectory {
    typealias Index = Int
    typealias Element = PageDirectoryEntry

    private let table: UnsafeMutableBufferPointer<PageDirectoryEntry>

    init(start: UnsafeMutablePointer<PageDirectoryEntry>) {
        table = UnsafeMutableBufferPointer(start: start, count: entriesPerTable)
    }

    subscript(index: Int) -> PageDirectoryEntry {
        get { table[index] }
        set { table[index] = newValue }
    }

    func pageTable(at index: Int, readWrite: Bool, userAccess: Bool, writeThrough: Bool, cacheDisable: Bool, noExec: Bool)
    -> PageTable {
        if let dir = table[index].pageTable { return dir }
        let newPage = alloc(pages: 1)
        newPage.rawBufferPointer.initializeMemory(as: UInt8.self, repeating: 0)
        let paddr = newPage.address
        let entry = PageDirectoryEntry(address: paddr, readWrite: readWrite, userAccess: userAccess,
            writeThrough: writeThrough, cacheDisable: cacheDisable, noExec: noExec)
        table[index] = entry
        return entry.pageTable!
    }
}


// Page Directory Entry or 2MB Page
struct PageDirectoryEntry: Equatable {
    private var bits: BitArray64

    init (address: PhysAddress, readWrite: Bool, userAccess: Bool,
        writeThrough: Bool, cacheDisable: Bool, noExec: Bool) {

        precondition(address & pageTableAddressMask == address)

        var bits = BitArray64(address.value)
        bits[0] = 1
        bits[1] = readWrite ? 1 : 0
        bits[2] = userAccess ? 1 : 0
        bits[3] = writeThrough ? 1 : 0
        bits[4] = cacheDisable ? 1 : 0
        bits[63] = noExec ? 1 : 0
        self.bits = bits
    }

    init(largePageAddress address: PhysAddress, readWrite: Bool, userAccess: Bool,
        patIndex: Int, global: Bool, noExec: Bool) {

        precondition(address & largePageAddressMask == address)

        let writeThrough = (patIndex & 1) == 1
        let cacheDisable = (patIndex & 2) == 2
        let pat = (patIndex & 4) == 4

        var bits = BitArray64(address.value)
        bits[0] = 1
        bits[1] = readWrite ? 1 : 0
        bits[2] = userAccess ? 1 : 0
        bits[3] = writeThrough ? 1 : 0
        bits[4] = cacheDisable ? 1 : 0
        bits[7] = 1
        bits[8] = global ? 1 : 0
        bits[12] = pat ? 1 : 0
        bits[63] = noExec ? 1 : 0
        self.bits = bits
    }

    private init(_ rawValue: UInt64) {
        self.bits = BitArray64(rawValue)
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
    var accessed: Bool { Bool(bits[5]) }
    var isLargePage: Bool { Bool(bits[7]) }
    var isDirectory: Bool { !isLargePage }
    var isGlobal: Bool { Bool(bits[8]) }
    var physicalAddress: PhysAddress { PhysAddress(RawAddress(bits.rawValue) & pageTableAddressMask) }
    var executeDisable: Bool { Bool(bits[63]) }

    var pageTable: PageTable? {
        guard present && isDirectory else { return nil }
        let ptr = UnsafeMutablePointer<PageTableEntry>(bitPattern: physicalAddress.vaddr)!
        return PageTable(start: ptr)
    }

    var largePageAddress: PhysAddress? {
        guard present && isLargePage else { return nil }
        return PhysAddress(RawAddress(bits.rawValue) & largePageAddressMask)
    }

    var patIndex: Int {
        get {
            guard bits[7] == 1 else { return 0 }
            var value = (bits[12] == 1) ? 4 : 0
            value |= (bits[4] == 1) ? 2 : 0
            value |= (bits[3] == 1) ? 1 : 0
            return value
        }

        set {
            bits[3] = (newValue & 1)
            bits[4] = (newValue >> 1) & 1
            bits[12] = (newValue >> 2) & 1
        }
    }
}
