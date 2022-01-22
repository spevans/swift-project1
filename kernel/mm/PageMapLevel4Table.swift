/*
 * kernel/mm/PageMapLevel4Table.swift
 *
 * Created by Simon Evans on 14/11/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * PML4 Table.
 *
 */


private let entriesPerTable = 512
// 4K aligned page table physical address mask
private let pageTableAddressMask: RawAddress = 0x0000_ffff_ffff_f000

struct PageMapLevel4Table {
    private let table: UnsafeMutableBufferPointer<PageMapLevel4Entry>

    init(at address: VirtualAddress) {
        let ptr = UnsafeMutablePointer<PageMapLevel4Entry>(bitPattern: address)
        table = UnsafeMutableBufferPointer(start: ptr, count: entriesPerTable)
    }

    init(at address: PhysAddress) {
        self = PageMapLevel4Table(at: PhysAddress(address.value & ~0xfff).vaddr)
    }

    subscript(index: Int) -> PageMapLevel4Entry {
        get { table[index] }
        set { table[index] = newValue }
    }

    func pageDirectoryPointerTable(at index: Int, readWrite: Bool, userAccess: Bool, writeThrough: Bool, cacheDisable: Bool, noExec: Bool)
    -> PageDirectoryPointerTable {
        if let dir = table[index].pageDirectoryPointerTable  { return dir }
        let newPage = alloc(pages: 1)
        newPage.rawBufferPointer.initializeMemory(as: UInt8.self, repeating: 0)
        let paddr = newPage.baseAddress
        let entry = PageMapLevel4Entry(address: paddr, readWrite: readWrite, userAccess: userAccess,
            writeThrough: writeThrough, cacheDisable: cacheDisable, noExec: noExec)
        table[index] = entry
        return entry.pageDirectoryPointerTable!
    }
}


// This is a PML4 Entry which acts as a directory of PageDirectoryPageTableEntries (PDPTE)
struct PageMapLevel4Entry {
    private let bits: BitArray64


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

    var present: Bool { Bool(bits[0]) }
    var readWrite: Bool { Bool(bits[1]) }
    var userAccess: Bool { Bool(bits[2]) }
    var writeThrough: Bool { Bool(bits[3]) }
    var cacheDisable: Bool { Bool(bits[4]) }
    var accessed: Bool { Bool(bits[5]) }
    var physicalAddress: PhysAddress { PhysAddress(RawAddress(bits.rawValue) & pageTableAddressMask) }
    var executeDisable: Bool { Bool(bits[63]) }

    var pageDirectoryPointerTable: PageDirectoryPointerTable? {
        guard present else { return nil }
        let ptr = UnsafeMutablePointer<PageDirectoryPointerTableEntry>(bitPattern: physicalAddress.vaddr)!
        return PageDirectoryPointerTable(start: ptr)
    }
}
