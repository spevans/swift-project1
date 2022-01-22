/*
 * kernel/mm/mapping.swift
 *
 * Created by Simon Evans on 26/12/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * Memory mapping routines.
 *
 */

// Add a mapping to a physical region, a mapping cant already exist
func mapIORegion(region: PhysPageRange, cacheType: CPU.CacheType = .uncacheable) -> MMIORegion {
    let vaddr = region.address.vaddr
    //print("Adding IO mapping for \(region) at 0x\(String(vaddr, radix: 16)) \(cacheType)")
    addMapping(start: vaddr, size: region.regionSize, physStart: region.address,
               readWrite: true, noExec: true, cacheType: cacheType)

    return MMIORegion(physPageRange: region)
}

func mapRORegion(region: PhysPageRange, cacheType: CPU.CacheType = .writeBack) -> MMIORegion {
    let vaddr = region.address.vaddr
    //print("Adding RO mapping for \(region) at 0x\(String(vaddr, radix: 16)) \(cacheType)")
    addMapping(start: vaddr, size: region.regionSize, physStart: region.address,
               readWrite: false, noExec: true, cacheType: cacheType)

    return MMIORegion(physPageRange: region)
}

func mapRORegion(region: PhysRegion) -> MMIORegion {
    let physPageRegion = region.physPageRange
    let vaddr = physPageRegion.address.vaddr
    //print("Adding RO mapping for \(region) [\(physPageRegion)] at 0x\(String(vaddr, radix: 16))")
    addMapping(start: vaddr, size: physPageRegion.regionSize, physStart: physPageRegion.address,
               readWrite: false, noExec: true, cacheType: .writeBack)

    return MMIORegion(region: region)
}


// Converts an existing mapping to MMIO by changing its cacheType
func remapAsIORegion(region: PhysPageRange, cacheType: CPU.CacheType = .uncacheable) -> MMIORegion {
    //print("Remapping to IO mapping for \(region) at 0x\(String(vaddr, radix: 16)) \(cacheType)")
    for page in region {
        guard changeEntry(address: page.vaddr, cacheType: cacheType, readWrite: true) else {
            fatalError("remapAsIORegion: Tried to remap non-mapped region: \(region)")
        }
    }
    return MMIORegion(physPageRange: region)
}


func unmapMMIORegion(_ mmioRegion: MMIORegion) {
    let pageRange = mmioRegion.physAddressRegion.physPageRange
    //print("unmapIORegion:", pageRange)
    for page in pageRange {
        guard removeMapping(address: page.vaddr) else {
            fatalError("unmapIORegion: Tried to unmap non-mapped region: \(mmioRegion)")
        }
    }
}


func addMapping(start: VirtualAddress, size: UInt, physStart: PhysAddress,
                readWrite: Bool, noExec: Bool, cacheType: CPU.CacheType = .writeBack) {

    let pageCnt = ((size + PAGE_SIZE - 1) / PAGE_SIZE)
    var physAddress = physStart
    var addr = start
    let pmlPage = PageMapLevel4Table(at: initial_pml4_addr)

    // Encode cacheType (0 - 7) PAT Entry index
    let patIndex = cacheType.patEntry

    for _ in 0..<pageCnt {
        let idx0 = pml4Index(addr)
        let idx1 = pdpIndex(addr)
        let idx2 = pdIndex(addr)
        let idx3 = ptIndex(addr)

        let pdpPage = pmlPage.pageDirectoryPointerTable(at: idx0, readWrite: true, userAccess: false,
            writeThrough: true, cacheDisable: false, noExec: false)

        let pdPage = pdpPage.pageDirectory(at: idx1, readWrite: true, userAccess: false,
            writeThrough: true, cacheDisable: false, noExec: false)

        var ptPage = pdPage.pageTable(at: idx2, readWrite: true, userAccess: false,
            writeThrough: true, cacheDisable: false, noExec: false)

        if !ptPage[idx3].present {
            let entry = PageTableEntry(address: physAddress, readWrite: readWrite,
                userAccess: false, patIndex: patIndex, global: false, noExec: noExec)
            ptPage[idx3] = entry
        } else {
            koops("MM: page is already present!")
        }

        addr += PAGE_SIZE
        physAddress = physAddress.advanced(by: PAGE_SIZE)
    }
    printf("MM: Added kernel mapping from %p-%p [%p-%p]\n", start, addr - 1, physStart.value, physAddress.value - 1)
}


private func removeMapping(address: VirtualAddress) -> Bool {
    //print("MM: Removing mapping at 0x\(String(address, radix: 16))")
    let idx0 = pml4Index(address)
    let idx1 = pdpIndex(address)

    let pmlPage = PageMapLevel4Table(at: initial_pml4_addr)
    guard var pdpt = pmlPage[idx0].pageDirectoryPointerTable else { return false }

    let pdptEntry = pdpt[idx1]
    guard pdptEntry.present else { return false }
    
    if pdptEntry.isLargePage {
        pdpt[idx1] = PageDirectoryPointerTableEntry.NotPresent()
    } else {
        let idx2 = pdIndex(address)
        var pd = pdptEntry.pageDirectory!
        let pdEntry = pd[idx2]
        guard pdEntry.present else { return false }
        if pdEntry.isLargePage {
            pd[idx2] = PageDirectoryEntry.NotPresent()
        } else {
            let idx3 = ptIndex(address)
            var pt = pdEntry.pageTable!
            let ptEntry = pt[idx3]
            guard ptEntry.present else { return false }
            pt[idx3] = PageTableEntry.NotPresent()
        }
    }
    invlpg(address)
    return true
}


private func changeEntry(address: VirtualAddress, cacheType: CPU.CacheType, readWrite: Bool) -> Bool {
    let idx0 = pml4Index(address)
    let idx1 = pdpIndex(address)
    let idx2 = pdIndex(address)
    let idx3 = ptIndex(address)

    let patIndex = cacheType.patEntry
    let pmlPage = PageMapLevel4Table(at: initial_pml4_addr)
    guard var pdpt = pmlPage[idx0].pageDirectoryPointerTable else { return false }
    let pdptEntry = pdpt[idx1]
    guard pdptEntry.present else { return false }
    if pdptEntry.isLargePage {
        var newEntry = pdptEntry
        newEntry.patIndex = patIndex
        newEntry.readWrite = readWrite
        if newEntry == pdptEntry { return true }
        pdpt[idx1] = newEntry
    } else {
        var pd = pdptEntry.pageDirectory!
        let pdEntry = pd[idx2]
        guard pdEntry.present else { return false }
        if pdEntry.isLargePage {
            var newEntry = pdEntry
            newEntry.patIndex = patIndex
            newEntry.readWrite = readWrite
            if newEntry == pdEntry { return true }
            pd[idx2] = newEntry
        } else {
            var pt = pdEntry.pageTable!
            let ptEntry = pt[idx3]
            guard ptEntry.present else { return false }
            var newEntry = ptEntry
            newEntry.patIndex = patIndex
            newEntry.readWrite = readWrite
            if newEntry == ptEntry { return true }
            pt[idx3] = newEntry
        }
    }

    invlpg(address)
    return true
}


#if false
private func add4KMapping(_ addr: VirtualAddress, physAddress: PhysAddress, readWrite: Bool, noExec: Bool) {
    let idx0 = pml4Index(addr)
    let idx1 = pdpIndex(addr)
    let idx2 = pdIndex(addr)
    let idx3 = ptIndex(addr)

    let pmlPage = PageMapLevel4Table(at: initial_pml4_addr)
    let pdpPage = pmlPage.pageDirectoryPointerTable(at: idx0, readWrite: readWrite, userAccess: false,
        writeThrough: true, cacheDisable: false, noExec: noExec)

    let pdPage = pdpPage.pageDirectory(at: idx1, readWrite: readWrite, userAccess: false,
        writeThrough: true, cacheDisable: false, noExec: noExec)

    var ptPage = pdPage.pageTable(at: idx2, readWrite: readWrite, userAccess: false,
        writeThrough: true, cacheDisable: false, noExec: noExec)

    if !ptPage[idx3].present {
        let patIndex = CPU.CacheType.writeBack.patEntry
        let entry = PageTableEntry(address: physAddress, readWrite: readWrite,
                userAccess: false, patIndex: patIndex, global: false, noExec: noExec)
        ptPage[idx3] = entry
    } else {
        koops("MM: page is already present!")
    }
}


private func add2MBMapping(_ addr: VirtualAddress, physAddress: PhysAddress, readWrite: Bool, noExec: Bool) {
    let idx0 = pml4Index(addr)
    let idx1 = pdpIndex(addr)
    let idx2 = pdIndex(addr)

    let pmlPage = PageMapLevel4Table(at: initial_pml4_addr)
    let pdpPage = pmlPage.pageDirectoryPointerTable(at: idx0, readWrite: readWrite, userAccess: false,
        writeThrough: true, cacheDisable: false, noExec: noExec)

    var pdPage = pdpPage.pageDirectory(at: idx1, readWrite: readWrite, userAccess: false,
        writeThrough: true, cacheDisable: false, noExec: noExec)

    if !pdPage[idx2].present {
        let patIndex = CPU.CacheType.writeBack.patEntry
        let entry = PageDirectoryEntry(largePageAddress: physAddress, readWrite: readWrite,
            userAccess: false, patIndex: patIndex, global: false, noExec: noExec)
        pdPage[idx2] = entry
    } else {
        koops("MM: 2MB mapping cant be added, already present")
    }
}


private func add1GBMapping(_ addr: VirtualAddress, physAddress: PhysAddress, readWrite: Bool, noExec: Bool) {
    let idx0 = pml4Index(addr)
    let idx1 = pdpIndex(addr)

    let pmlPage = PageMapLevel4Table(at: initial_pml4_addr)
    var pdpPage = pmlPage.pageDirectoryPointerTable(at: idx0, readWrite: readWrite, userAccess: false,
        writeThrough: true, cacheDisable: false, noExec: noExec)

    if !pdpPage[idx1].present {
        let patIndex = CPU.CacheType.writeBack.patEntry
        let entry = PageDirectoryPointerTableEntry(largePageAddress: physAddress, readWrite: readWrite,
            userAccess: false, patIndex: patIndex, global: false, noExec: noExec)
        printf("1GB Mapping entry: %16.16llx\n", entry);
        pdpPage[idx1] = entry
    } else {
        koops("MM: 1GB mapping cant be added, already present")
    }
}
#endif
