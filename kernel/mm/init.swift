/*
 * kernel/mm/init.swift
 *
 * Created by Simon Evans on 18/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Initial setup for memory management
 *
 */

private let kernelPhysBase: PhysAddress = 0x100000
private let pmlPage = pageTableBuffer(virtualAddress: initial_pml4_addr)


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

    let textEnd = ptr_value(_text_end_addr)
    let rodataStart = ptr_value(_rodata_start_addr)
    let dataStart = ptr_value(_data_start_addr)
    let bssEnd = ptr_value(_bss_end_addr)
    let pml4Phys = UInt64(virtualToPhys(initial_pml4_addr))

    let kernelBase: VirtualAddress = _kernel_start_addr
    let textSize = roundToPage(textEnd - _kernel_start_addr)
    let rodataSize = roundToPage(dataStart - rodataStart)
    let dataSize = roundToPage(bssEnd - dataStart)

    // Enable No Execute so data mappings can be set XD (Execute Disable)
    CPU.enableNXE(true)

    // Add 3 mappings for text, rodata and data + bss with appropiate protections
    printf("_text:   %p - %p\n_rodata: %p - %p\n_data:   %p - %p\n",
        _kernel_start_addr, _kernel_start_addr + textSize,
        ptr_value(_rodata_start_addr), ptr_value(_rodata_start_addr) + rodataSize,
        ptr_value(_data_start_addr), ptr_value(_data_start_addr) + dataSize)

    addMapping(start: _kernel_start_addr, size: textSize, physStart: kernelPhysBase,
        readWrite: false, noExec: false)
    addMapping(start: rodataStart, size: rodataSize, physStart: kernelPhysBase + textSize,
        readWrite: false, noExec: true)
    addMapping(start: dataStart, size: dataSize, physStart: kernelPhysBase + textSize + rodataSize,
        readWrite: true, noExec: true)


    printf("Physical address of kernelBase (%p) = (%p)\n", kernelBase, virtualToPhys(kernelBase, base: pml4Phys))
    printf("Physical address of rodata (%p) = (%p)\n", kernelBase + textSize,
        virtualToPhys(kernelBase + textSize, base: pml4Phys))
    printf("Physical address of data (%p) = (%p)\n", kernelBase + textSize + rodataSize,
        virtualToPhys(kernelBase + textSize + rodataSize, base: pml4Phys))

    mapPhysicalMemory(BootParams.highestMemoryAddress())
    setCR3(UInt64(virtualToPhys(initial_pml4_addr)))
    CPU.enableWP(true)
    print("CR3 Updated")
}


// FIXME: Should map more closely to the real map, not map holes
// and map the reserved mem as RO etc
private func mapPhysicalMemory(maxAddress: UInt64) {
    var inc: UInt = 0
    var mapper :(UInt, PhysAddress) -> ()

    printf("Mapping physical memory from 0 - %p\n", maxAddress)

    // Map physical memory using 1GB pages if available else 2MB pages
    if CPU.capabilities.pages1G {
        inc = 0x40000000    // 1GB
        printf("Using 1GB mappings: ")
        mapper = add1GBMapping
    } else {
        inc = 0x200000      // 2MB
        mapper = add2MBMapping
        printf("Using 2MB mappings: ")
    }

    let pages = (UInt(maxAddress) + (inc - 1)) / inc
    printf("Mapping %u pages of size %#lx\n", pages, inc)
    var vaddr = UInt(PHYSICAL_MEM_BASE)
    var paddr: PhysAddress = 0

    for _ in 1...pages {
        mapper(vaddr, paddr)
        vaddr += inc
        paddr += inc
    }
    printf("Added mappings upto: %p\n", vaddr)
}


private func roundToPage(size: UInt) -> UInt {
    return (size + PAGE_MASK) & ~PAGE_MASK
}


private func getPageAtIndex(dirPage: PageTableDirectory, _ idx: Int) -> PageTableDirectory {
    if !pagePresent(dirPage[idx]) {
        let newPage = ptr_value(alloc_pages(1))
        let paddr = virtualToPhys(newPage)
        let entry = makePDE(address: paddr, readWrite: true, userAccess: false, writeThrough: true,
            cacheDisable: false, noExec: false)
        dirPage[idx] = entry
    }

    return pageTableBuffer(physAddress: ptePhysicalAddress(dirPage[idx]))
}


private func addMapping(start start: VirtualAddress, size: UInt, physStart: PhysAddress, readWrite: Bool,
    noExec: Bool) -> Bool {

    let endAddress = start + size
    let pageCnt = ((endAddress - start) / PAGE_SIZE)
    var physAddress = physStart
    var addr = start

    for _ in 0..<pageCnt {
        let idx0 = pml4Index(addr)
        let idx1 = pdpIndex(addr)
        let idx2 = pdIndex(addr)
        let idx3 = ptIndex(addr)

        let pdpPage = getPageAtIndex(pmlPage, idx0)
        let pdPage = getPageAtIndex(pdpPage, idx1)
        let ptPage = getPageAtIndex(pdPage, idx2)

        if !pagePresent(ptPage[idx3]) {
            let entry = makePTE(address: physAddress, readWrite: readWrite, userAccess: false,
                writeThrough: true, cacheDisable: false, global: false, noExec: noExec,
                largePage: false, PAT: false)
            ptPage[idx3] = entry
        } else {
            koops("page is already present!")
        }

        addr += PAGE_SIZE
        physAddress += PAGE_SIZE
    }
    printf("Added kernel mapping from %p-%p [%p-%p]\n", start, endAddress, physStart, physAddress)

    return true
}


private func add2MBMapping(addr: VirtualAddress, physAddress: PhysAddress) {
    let idx0 = pml4Index(addr)
    let idx1 = pdpIndex(addr)
    let idx2 = pdIndex(addr)

    let pdpPage = getPageAtIndex(pmlPage, idx0)
    let pdPage = getPageAtIndex(pdpPage, idx1)

    if !pagePresent(pdPage[idx2]) {
        let entry = makePTE(address: physAddress, readWrite: true, userAccess: false,
            writeThrough: true, cacheDisable: false, global: false, noExec: true,
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
        let entry = makePTE(address: physAddress, readWrite: true, userAccess: false,
            writeThrough: true, cacheDisable: false, global: false, noExec: true,
            largePage: true, PAT: false)
        pdpPage[idx1] = entry
    } else {
        koops("1GB mapping cant be added, already present")
    }
}
