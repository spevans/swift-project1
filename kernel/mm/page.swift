/*
 * kernel/mm/page.swift
 *
 * Created by Simon Evans on 22/01/2016.
 * Copyright © 2016 - 2017 Simon Evans. All rights reserved.
 *
 * Page handling routines
 *
 */


private let entriesPerPage: UInt = 512
private let entriesPerPageMask: UInt = entriesPerPage - 1


func virtualToPhys(address: VirtualAddress, base: UInt64 = getCR3()) -> PhysAddress? {
    // Quick lookups in premapped areas
    if address >= PHYSICAL_MEM_BASE && address < PHYSICAL_MEM_BASE + 0x400_000_000_000 { // 64TB window
        return PhysAddress(address - PHYSICAL_MEM_BASE)
    }
    if address >= _kernel_start_addr && address < _kernel_end_addr {
        if kernelPhysBase.value != 0 {
            return kernelPhysBase.advanced(by: address - _kernel_start_addr)
        }
    }

    // Otherwise walk the page tables
    let pml4 = PhysAddress(RawAddress(base))

    let pageDirectory = PageMapLevel4Table(at: pml4)
    let idx0 = pml4Index(address)
    let pml4e = pageDirectory[idx0]

    let idx1 = pdpIndex(address)
    guard let pdpte = pml4e.pageDirectoryPointerTable?[idx1] else { return nil }
    if let physAddress = pdpte.largePageAddress { // 1GB Pages
        return physAddress + (address & 0x3_ffff_ffff)
    }

    let idx2 = pdIndex(address)
    guard let pde = pdpte.pageDirectory?[idx2] else { return nil }
    if let physAddress = pde.largePageAddress { // 2MB Pages
        return physAddress + (address & 0x1f_ffff)
    }

    let idx3 = ptIndex(address)
    guard let pageAddress = pde.pageTable?[idx3].pageAddress else { return nil }
    return pageAddress + (address & 0x0fff)
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
