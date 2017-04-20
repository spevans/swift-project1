/*
 * kernel/mm/page.swift
 *
 * Created by Simon Evans on 22/01/2016.
 * Copyright © 2016 - 2017 Simon Evans. All rights reserved.
 *
 * Page handling routines
 *
 */

typealias PageTableDirectory = UnsafeMutableBufferPointer<PageTableEntry>
typealias PageTableEntry = UInt

let entriesPerPage: UInt = 512
let entriesPerPageMask: UInt = entriesPerPage - 1


// Only Lower 48bits are valid in a physical address and lower 12 are flags
private let physAddressMask:    UInt = 0x0000fffffffff000
private let pagePresent:        UInt = 0b0000000000001
private let readWriteFlag:      UInt = 0b0000000000010
private let userAccessFlag:     UInt = 0b0000000000100
private let writeThruFlag:      UInt = 0b0000000001000
private let cacheDisableFlag:   UInt = 0b0000000010000
private let accessedBit:        UInt = 0b0000000100000
private let dirtyBit:           UInt = 0b0000001000000
private let largePageFlag:      UInt = 0b0000010000000     // 2MB or 1GB page
private let PATFlag:            UInt = 0b0000010000000     // PAT flag for 4K pages
private let largePagePATFlag:   UInt = 0b1000000000000
private let globalFlag:         UInt = 0b0000100000000
private let executeDisableFlag: UInt = 1 << 63



func mapPhysicalRegion<T>(start: PhysAddress, size: Int) -> UnsafeBufferPointer<T> {
    let region = UnsafePointer<T>(bitPattern: start.vaddr)
    return UnsafeBufferPointer<T>(start: region, count: size)
}


func mapPhysicalRegion<T>(start: UnsafePointer<T>, size: Int) -> UnsafeBufferPointer<T> {
    let region = UnsafePointer<T>(bitPattern: PHYSICAL_MEM_BASE + start.address)
    return UnsafeBufferPointer<T>(start: region, count: size)
}


func pageTableBuffer(virtualAddress address: VirtualAddress) -> PageTableDirectory {
    return PageTableDirectory(start: UnsafeMutablePointer<PageTableEntry>(bitPattern: address),
        count: Int(entriesPerPage))
}


// Needs to have address shifted to new mapping of physical pages
func pageTableDirectoryAt(address: PhysAddress) -> PageTableDirectory {
    let vaddr = address.vaddr
    let ptr = UnsafeMutablePointer<PageTableEntry>(bitPattern: vaddr)
    return PageTableDirectory(start: ptr, count: Int(entriesPerPage))
}


func virtualToPhys(address: VirtualAddress, base: UInt64 = getCR3()) -> PhysAddress {
    let pml4 = UInt(base)
    let idx0 = pml4Index(address)
    let idx1 = pdpIndex(address)

    let pageDirectory = pageTableDirectoryAt(address: PhysAddress(pml4 & physAddressMask))
    let pml4e = pageDirectory[idx0]

    let pdpDirectory = pageTableDirectoryAt(address: PhysAddress(pml4e & physAddressMask))
    let pdpe = pdpDirectory[idx1]
    if largePageFlagSet(pdpe) { // 1GB Pages
        var physAddress = (pdpe & 0x0000_fffC_0000_0000)
        physAddress |= (address & 0x3_ffff_ffff)
        return PhysAddress(physAddress)
    }

    let idx2 = pdIndex(address)
    let pdDirectory = pageTableDirectoryAt(address: PhysAddress(pdpe & physAddressMask))
    let pde = pdDirectory[idx2]
    if largePageFlagSet(pde) { // 2MB Pages
        var physAddress = pde & 0x0000_ffff_ffe0_0000
        physAddress |= (address & 0x1f_ffff)
        return PhysAddress(physAddress)
    }

    let idx3 = ptIndex(address)
    let ptDirectory = pageTableDirectoryAt(address: PhysAddress(pde & physAddressMask))
    let pte = ptDirectory[idx3]
    var physAddress = pte & 0x0000_ffff_ffff_f000
    physAddress |= (address & 0x0fff)
    return PhysAddress(physAddress)
}


func pml4Index(_ address: VirtualAddress) -> Int {
    return Int((address >> 39) & entriesPerPageMask)
}


func pdpIndex(_ address: VirtualAddress) -> Int {
    return Int((address >> 30) & entriesPerPageMask)
}


func pdIndex(_ address: VirtualAddress) -> Int {
    return Int((address >> 21) & entriesPerPageMask)
}


func ptIndex(_ address: VirtualAddress) -> Int {
    return Int((address >> 12) & entriesPerPageMask)
}


// 4KB page entry or 2MB/1GB if largePage is set
func makePTE(address: PhysAddress, readWrite: Bool, userAccess: Bool,
    writeThrough: Bool, cacheDisable: Bool, global: Bool, noExec: Bool,
    largePage: Bool, PAT: Bool) -> PageTableEntry {

        var entry: PageTableEntry = address.value & physAddressMask
        entry |= pagePresent
        entry |= readWrite ? readWriteFlag : 0
        entry |= userAccess ? userAccessFlag : 0
        entry |= writeThrough ? writeThruFlag : 0
        entry |= cacheDisable ? cacheDisableFlag : 0
        entry |= global ? globalFlag : 0
        entry |= noExec ? executeDisableFlag : 0
        if (largePage) {
            entry |= largePageFlag
            entry |= PAT ? largePagePATFlag : 0
        } else {
            entry |= PAT ? PATFlag : 0
        }

        return entry
}


// Entry in Page Directory, Page Directory Pointer or Page Map Level 4 tables
func makePDE(address: PhysAddress, readWrite: Bool, userAccess: Bool,
    writeThrough: Bool, cacheDisable: Bool, noExec: Bool) -> PageTableEntry {
        var entry: PageTableEntry = address.value & physAddressMask
        entry |= pagePresent
        entry |= readWrite ? readWriteFlag : 0
        entry |= userAccess ? userAccessFlag : 0
        entry |= writeThrough ? writeThruFlag : 0
        entry |= cacheDisable ? cacheDisableFlag : 0

        return entry
}


func ptePhysicalAddress(_ entry: PageTableEntry) -> PhysAddress {
    return PhysAddress(entry & physAddressMask)
}


func pagePresent(_ entry: PageTableEntry) -> Bool {
    return (entry & pagePresent) == pagePresent
}


func largePageFlagSet(_ entry: PageTableEntry) -> Bool {
    return (entry & largePageFlag) == largePageFlag
}
