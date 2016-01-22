/*
 * kernel/mm/init.swift
 *
 * Created by Simon Evans on 18/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Initial setup for memory management
 *
 */

private let kernelBase: VirtualAddress = _kernel_start_addr
private let kernelPhysBase: PhysAddress = 0x100000
private let pmlPage = pageTableBuffer(virtualAddress: initial_pml4_addr)
private let maxInitialPageTables: UInt = 10
private var nextPageTable: UInt = 0


/* After bootup and entry into the kernel the page table setup by the
 * boot loader setup 3 mappings of the first 16MB of memory
 * @0                  as an identity mapping used to load the kernel
 * @0x40000000   (1GB) as the kernel is compiled to start at linear 1G
 * @0x2000000000 (128GB) used as a mapping of physical memory accesible from the kernel
 * address space. It is setup at boot so that the tty drivers can access
 * the video memory without having to readjust after the mapping is changed
 *
 * setupMM() creates new page tables with the following:
 * @0x40000000   (1GB)   a mapping just to cover the physical memory used by the kernel incl
 * data and bss
 * @0x2000000000 (128GB) a mapping of the first 1GB of physical memory
 *
 */

func setupMM() {
    // Setup initial page tables and map kernel

    // _text_start / _text_end
    // _rodata_start / _ro_data_end
    // _data_start / _data_end
    // _bss_start / _kernel_stack
    // enable WP bit in CR0

    let pml4Phys = UInt64(virtualToPhys(initial_pml4_addr))
    printf("Physical address of initial_pml4 (%p) = (%p)\n", initial_pml4_addr, pml4Phys)
    printf("Physical address of initial_page_tables (%p) = (%p)\n", initial_page_tables_addr,
        virtualToPhys(initial_page_tables_addr))

    let kernelSize = _kernel_end_addr - kernelBase
    assert((kernelSize % PAGE_SIZE) == 0)

    addMapping(start: kernelBase, size: kernelSize, physStart: kernelPhysBase)
    printf("Physical address of kernelBase (%p) = (%p)\n", kernelBase,
        virtualToPhys(kernelBase, base: pml4Phys))
    printf("Physical address of kernelEnd (%p) = (%p)\n", kernelBase + kernelSize,
        virtualToPhys(kernelBase + kernelSize, base: pml4Phys))

    // Map physical memory using 1GB pages if available else 2MB pages
    if CPU.pages1G {
        add1GBMapping(UInt(PHYSICAL_MEM_BASE), physAddress: 0)
        print("Added 1GB mapping")
    } else {
        var vaddr = UInt(PHYSICAL_MEM_BASE)
        var paddr :PhysAddress = 0
        let inc :UInt = 0x200000  // 2MB
        for _ in 1...512 {
            add2MBMapping(vaddr, physAddress: paddr)
            vaddr += inc
            paddr += inc
        }
        print("Added 2MB mapping")
    }
    setCR3(UInt64(virtualToPhys(initial_pml4_addr)))
    printf("CR3 Updated")
}


private func getPageAtIndex(dirPage: PageTableDirectory, _ idx: Int) -> PageTableDirectory {
    if !pagePresent(dirPage[idx]) {
        let newPage = nextInitialPageTableAddress()
        let paddr = virtualToPhys(newPage)
        let entry = makePDE(address: paddr, readWrite: true, supervisor: true, writeThrough: true,
            cacheDisable: false, noExec: false)
        dirPage[idx] = entry
    }

    return pageTableBuffer(physAddress: ptePhysicalAddress(dirPage[idx]))
}


private func nextInitialPageTableAddress() -> VirtualAddress {
    if (nextPageTable == maxInitialPageTables) {
        koops("No more free initial page tables")
    }

    let offset = nextPageTable * PAGE_SIZE
    nextPageTable += 1
    return initial_page_tables_addr + offset
}


private func addMapping(start start: VirtualAddress, size: UInt, physStart: PhysAddress) -> Bool {
    let endAddress = start + ((size + PAGE_MASK) & ~PAGE_MASK)
    let pageCnt = ((endAddress - start) / PAGE_SIZE) + 1
    var physAddress = physStart
    var addr = start

    for _ in 0...pageCnt {
        let idx0 = pml4Index(addr)
        let idx1 = pdpIndex(addr)
        let idx2 = pdIndex(addr)
        let idx3 = ptIndex(addr)

        let pdpPage = getPageAtIndex(pmlPage, idx0)
        let pdPage = getPageAtIndex(pdpPage, idx1)
        let ptPage = getPageAtIndex(pdPage, idx2)

        if !pagePresent(ptPage[idx3]) {
            let entry = makePTE(address: physAddress, readWrite: true, supervisor: true,
                writeThrough: true, cacheDisable: false, global: false, noExec: false,
                largePage: false, PAT: false)
            ptPage[idx3] = entry
        } else {
            koops("page is already present!")
        }

        addr += PAGE_SIZE
        physAddress += PAGE_SIZE
    }

    return true
}


private func add2MBMapping(addr: VirtualAddress, physAddress: PhysAddress) {
    let idx0 = pml4Index(addr)
    let idx1 = pdpIndex(addr)
    let idx2 = pdIndex(addr)

    let pdpPage = getPageAtIndex(pmlPage, idx0)
    let pdPage = getPageAtIndex(pdpPage, idx1)

    if !pagePresent(pdPage[idx2]) {
        let entry = makePTE(address: physAddress, readWrite: true, supervisor: true,
            writeThrough: true, cacheDisable: false, global: false, noExec: false,
            largePage: true, PAT: false)
        pdPage[idx2] = entry
    } else {
        koops("2MB mapping cant be added, already present")
    }
}


private func add1GBMapping(addr: VirtualAddress, physAddress: PhysAddress) {
    let idx0 = pml4Index(addr)
    let idx1 = pdpIndex(addr)

    let pdpPage = getPageAtIndex(pmlPage, idx0)
    if !pagePresent(pdpPage[idx1]) {
        let entry = makePTE(address: physAddress, readWrite: true, supervisor: true,
            writeThrough: true, cacheDisable: false, global: false, noExec: false,
            largePage: true, PAT: false)
        pdpPage[idx1] = entry
    } else {
        koops("1GB mapping cant be added, already present")
    }
}
