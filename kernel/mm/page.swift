/*
 * kernel/mm/init.swift
 *
 * Created by Simon Evans on 22/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Page handling routines
 *
 */

typealias VirtualAddress = UInt
typealias PhysAddress = UInt
typealias PageTableDirectory = UnsafeMutableBufferPointer<PageTableEntry>
typealias PageTableEntry = UInt

let entriesPerPage: UInt = 512
let entriesPerPageMask: UInt = entriesPerPage - 1


// Only Lower 48bits are valid in a physical address and lower 12 are flags
private let physAddressMask  :UInt = 0x0000fffffffff000
private let pagePresent      :UInt = 0b0000000000001
private let readWriteFlag    :UInt = 0b0000000000010
private let userAccessFlag   :UInt = 0b0000000000100
private let writeThruFlag    :UInt = 0b0000000001000
private let cacheDisableFlag :UInt = 0b0000000010000
private let accessedBit      :UInt = 0b0000000100000
private let dirtyBit         :UInt = 0b0000001000000
private let largePageFlag    :UInt = 0b0000010000000     // 2MB or 1GB page
private let PATFlag          :UInt = 0b0000010000000     // PAT flag for 4K pages
private let largePagePATFlag :UInt = 0b1000000000000
private let globalFlag       :UInt = 0b0000100000000
private let executeDisableFlag :UInt = 1 << 63

private let physicalMemPtr = UnsafeMutablePointer<UInt>(bitPattern: PHYSICAL_MEM_BASE)
private let physicalMemory = UnsafeMutableBufferPointer(start: physicalMemPtr,
    count: Int(BootParams.highestMemoryAddress / UInt(sizeof(UInt))) + 1 )


func mapPhysicalRegion<T>(start: PhysAddress, size: Int) -> UnsafeBufferPointer<T> {
    let region = UnsafePointer<T>(bitPattern: PHYSICAL_MEM_BASE + start)
    return UnsafeBufferPointer<T>(start: region, count: size)
}


func mapPhysicalRegion<T>(start: UnsafePointer<T>, size: Int) -> UnsafeBufferPointer<T> {
    let region = UnsafePointer<T>(bitPattern: PHYSICAL_MEM_BASE + start.ptrToUint)
    return UnsafeBufferPointer<T>(start: region, count: size)
}


func ptrFromPhysicalPtr<T>(ptr: UnsafePointer<T>) -> UnsafePointer<T> {
    let ret: UnsafePointer<T> = UnsafePointer(bitPattern: PHYSICAL_MEM_BASE + ptr.ptrToUint)
    return ret;
}


// Map a physical address to a kernel virtual address
func vaddrFromPaddr(ptr: PhysAddress) -> VirtualAddress {
    return PHYSICAL_MEM_BASE + ptr;
}


func copyPhysicalRegion<T>(start: PhysAddress) -> T {
    let region = UnsafePointer<T>(bitPattern: PHYSICAL_MEM_BASE + start)
    return region.memory
}


func pageTableBuffer(virtualAddress address: VirtualAddress) -> PageTableDirectory {
    return PageTableDirectory(start: UnsafeMutablePointer<PageTableEntry>(bitPattern: address),
        count: Int(entriesPerPage))
}


// Needs to have address shifted to new mapping of physical pages
func pageTableBuffer(physAddress address: PhysAddress) -> PageTableDirectory {
    return PageTableDirectory(start: UnsafeMutablePointer<PageTableEntry>(bitPattern: address),
        count: Int(entriesPerPage))
}


func virtualToPhys(address: VirtualAddress, base: UInt64 = getCR3()) -> PhysAddress {
    let idx0 = pml4Index(address)
    let idx1 = pdpIndex(address)
    let idx2 = pdIndex(address)
    let idx3 = ptIndex(address)

    let pdp = (physicalMemory[Int(base >> 3) + idx0] & physAddressMask)
    let pd = (physicalMemory[Int(pdp >> 3) + idx1] & physAddressMask)
    let pt = (physicalMemory[Int(pd >> 3) + idx2] & physAddressMask)
    let physAddress = (physicalMemory[Int(pt >> 3) + idx3] & physAddressMask) + (address & 0b111111111111)
    return physAddress
}


func pml4Index(address: VirtualAddress) -> Int {
    return Int((address >> 39) & entriesPerPageMask)
}


func pdpIndex(address: VirtualAddress) -> Int {
    return Int((address >> 30) & entriesPerPageMask)
}


func pdIndex(address: VirtualAddress) -> Int {
    return Int((address >> 21) & entriesPerPageMask)
}


func ptIndex(address: VirtualAddress) -> Int {
    return Int((address >> 12) & entriesPerPageMask)
}


// 4KB page entry or 2MB/1GB if largePage is set
func makePTE(address address: PhysAddress, readWrite: Bool, userAccess: Bool, writeThrough: Bool,
    cacheDisable: Bool, global: Bool, noExec: Bool,
    largePage: Bool, PAT: Bool) -> PageTableEntry {

        var entry: UInt = address & physAddressMask
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
func makePDE(address address: PhysAddress, readWrite: Bool, userAccess: Bool, writeThrough: Bool,
    cacheDisable: Bool, noExec: Bool) -> PageTableEntry {
        var entry: UInt = address & physAddressMask
        entry |= pagePresent
        entry |= readWrite ? readWriteFlag : 0
        entry |= userAccess ? userAccessFlag : 0
        entry |= writeThrough ? writeThruFlag : 0
        entry |= cacheDisable ? cacheDisableFlag : 0

        return entry
}


func ptePhysicalAddress(entry: PageTableEntry) -> PhysAddress {
    return entry & physAddressMask
}


func pagePresent(entry: PageTableEntry) -> Bool {
    return (entry & pagePresent) == pagePresent
}
