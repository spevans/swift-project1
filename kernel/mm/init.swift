/*
 * kernel/mm/init.swift
 *
 * Created by Simon Evans on 18/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Initial setup for memory management
 *
 */

private var kernelPhysBase: PhysAddress!
private(set) var highestMemoryAddress: PhysAddress!
private let pmlPage = pageTableBuffer(virtualAddress: initial_pml4_addr)

/* The page table setup by the BIOS boot loader setup 3 mappings of the
 * first 16MB of memory
 * @0                  as an identity mapping used to load the kernel
 * @0x40000000   (1GB) as the kernel is compiled to start at linear 1G
 * @0x2000000000 (128GB) used as a mapping of physical memory accesible
 * from the kernel address space. It is setup at boot so that the tty
 * drivers can access the video memory without having to readjust after
 * the mapping is changed
 * The identity mapping is removed just before entry to the kernel
 *
 * The EFI boot loader setups 2 mappings:
 * @0x40000000   (1GB) sizeof(kernel text+data+bss)
 * @0x2000000000+base address of the framebuffer for screen access
 *
 *
 * setupMM() creates new page tables with the following:
 * @0x40000000   (1GB)   a mapping just to cover the physical memory
 *                       used by the kernel incl data and bss (same as EFI)
 * @0x2000000000 (128GB) a mapping of physical memory from 0 to highest
 *                       physical address found. If there are any holes in
 * the physical memory these are covered by the mapping as well.
 * This also maps the framebuffer at the same address at the boot code so
 * that the TTY driver continues to work
 *
 * The initial page tables setup here are using pages from the kernel BSS
 * as there is not allocPage() at this stage so kernelVirtualAddress() is
 * used to convert virtual addresses in the space to physical addresses for
 * the various page table entries
 */

func setupMM(bootParams: BootParams) {
    // Setup initial page tables and map kernel

    // Show the current memory ranges
    for range in bootParams.memoryRanges {
        print("MM:", bootParams.source, ":", range)
    }
    kernelPhysBase = bootParams.kernelPhysAddress
    let lastEntry = bootParams.memoryRanges[bootParams.memoryRanges.count - 1]
    highestMemoryAddress = lastEntry.start + lastEntry.size - 1

    printf("kernel: Highest Address: %p kernel phys address: %p\n",
        highestMemoryAddress, kernelPhysBase)

    let textEnd: VirtualAddress = _text_end_addr
    let rodataStart: VirtualAddress = _rodata_start_addr
    let dataStart: VirtualAddress = _data_start_addr
    let bssEnd: VirtualAddress = _bss_end_addr
    let guardPage: VirtualAddress = _guard_page_addr
    let kernelBase: VirtualAddress = _kernel_start_addr

    let textSize = roundToPage(textEnd - _kernel_start_addr)
    let rodataSize = roundToPage(dataStart - rodataStart)
    let dataSize = roundToPage(guardPage - dataStart)
    let stackHeapSize = bssEnd - VirtualAddress(_stack_start_addr)

    // Enable No Execute so data mappings can be set XD (Execute Disable)
    _ = CPU.enableNXE(true)
    CPU.setupPAT()

    // Add 4 mappings for text, rodata, data + bss and the stack
    // with appropiate protections. There is a guard page between
    // BSS and stack that isnt mapped.
    // FIXME: Dont waste the physical page that is not mapped under
    // the guard page
    printf("MM: _text: %p - %p\nMM: _rodata: %p - %p\nMM: _data: %p - %p\n",
        _kernel_start_addr, _kernel_start_addr + textSize - 1,
        _rodata_start_addr, _rodata_start_addr + rodataSize - 1,
        _data_start_addr, _data_start_addr + dataSize - 1)

    addMapping(start: _kernel_start_addr, size: textSize,
        physStart: kernelPhysBase, readWrite: false, noExec: false)

    addMapping(start: rodataStart, size: rodataSize,
        physStart: kernelPhysBase + textSize, readWrite: false, noExec: true)

    addMapping(start: dataStart, size: dataSize,
        physStart: kernelPhysBase + textSize + rodataSize, readWrite: true,
        noExec: true)

    addMapping(start: _stack_start_addr, size: stackHeapSize,
        physStart: kernelPhysBase + textSize + rodataSize + dataSize
            + PAGE_SIZE, readWrite: true, noExec: true)

    printf("MM: Physical address of kernelBase (%p): (%p)\n", kernelBase,
        kernelPhysAddress(kernelBase))
    printf("MM: Physical address of rodata (%p):     (%p)\n",
        kernelBase + textSize, kernelPhysAddress(kernelBase + textSize))
    printf("MM: Physical address of data (%p):       (%p)\n",
        kernelBase + textSize + rodataSize,
        kernelPhysAddress(kernelBase + textSize + rodataSize))
    printf("MM: Physical address of stack and heap (%p): (%p)\n",
        kernelBase + textSize + rodataSize + dataSize + PAGE_SIZE,
        kernelPhysAddress(kernelBase + textSize + rodataSize + dataSize
                + PAGE_SIZE))

    // Map the TLS which resides before 4GB mark and has the same virtual
    // and physical address
    let tlsPage = TLS_END_ADDR & ~PAGE_MASK
    addMapping(start: tlsPage, size: PAGE_SIZE, physStart: kernelPhysBase,
        readWrite: true, noExec: true)

    mapPhysicalMemory(highestMemoryAddress)
    let pml4paddr = UInt64(kernelPhysAddress(initial_pml4_addr))
    printf("MM: Updating CR3 to %p\n", pml4paddr)
    setCR3(pml4paddr)
    CPU.enableWP(true)
    printf("MM: CR3 Updated to %p\n", pml4paddr)
}


// Convert a virtual address between kernel_start and kernel_end into a physical
// address
private func kernelPhysAddress(_ address: VirtualAddress) -> PhysAddress {
    guard address >= _kernel_start_addr && address <= _kernel_end_addr else {
        printf("kernelPhysAddress: invalid address: %p", address)
        stop()
    }
    return kernelPhysBase + (address - _kernel_start_addr)
}


// Convert a physical kernel address in a page directory/table entry into a
// virtual address
private func kernelVirtualAddress(_ paddress: PhysAddress) -> VirtualAddress {
    let physAddressMask:UInt = 0x0000fffffffff000
    let address = paddress & physAddressMask
    let kernelSize = _kernel_end_addr - _kernel_start_addr
    guard address >= kernelPhysBase
        && address <= kernelPhysBase + kernelSize else {
        printf("MM: kernelVirtualAddress: invalid address: %p", address)
        stop()
    }
    return _kernel_start_addr + (address - kernelPhysBase)
}


// FIXME: Should map more closely to the real map, not map holes
// and map the reserved mem as RO etc
private func mapPhysicalMemory(_ maxAddress: PhysAddress) {
    var inc: UInt = 0
    var mapper: (UInt, PhysAddress) -> ()

    printf("MM: Mapping physical memory from 0 - %p\n", maxAddress)
    // Map physical memory using 1GB pages if available else 2MB pages
    if CPU.capabilities.pages1G {
        inc = 0x40000000    // 1GB
        printf("MM: Using 1GB mappings: ")
        mapper = add1GBMapping
    } else {
        inc = 0x200000      // 2MB
        mapper = add2MBMapping
        printf("MM: Using 2MB mappings: ")
    }

    let pages = (UInt(maxAddress) + (inc - 1)) / inc
    printf("MM: Mapping %u pages of size %#lx\n", pages, inc)
    var vaddr = UInt(PHYSICAL_MEM_BASE)
    var paddr: PhysAddress = 0

    for _ in 1...pages {
        mapper(vaddr, paddr)
        vaddr += inc
        paddr += inc
    }
    printf("MM: Added mappings upto: %p [%p]\n", vaddr, paddr)
}


private func roundToPage(_ size: UInt) -> UInt {
    return (size + PAGE_MASK) & ~PAGE_MASK
}


private func getPageAtIndex(_ dirPage: PageTableDirectory, _ idx: Int)
    -> PageTableDirectory {
    if !pagePresent(dirPage[idx]) {
        // FIXME: should call a swift func for alloc_pages()
        let newPage = alloc_pages(1)
        let paddr = kernelPhysAddress(newPage.address)
        let entry = makePDE(address: paddr, readWrite: true, userAccess: false,
            writeThrough: true, cacheDisable: false, noExec: false)
        dirPage[idx] = entry
    }

    return pageTableBuffer(virtualAddress: kernelVirtualAddress(dirPage[idx]))
}


private var nextIOVirtualAddress: VirtualAddress = 0x4000000000 // 256GB
func mapIORegion(physicalAddr: PhysAddress, size: Int,
    cacheType: Int = 7 /* Uncacheable */) -> VirtualAddress {
    let newSize = roundToPage(UInt(size))
    let vaddr = nextIOVirtualAddress
    addMapping(start: vaddr, size: newSize, physStart: physicalAddr,
        readWrite: true, noExec: true, cacheType: cacheType)
    nextIOVirtualAddress += newSize
    nextIOVirtualAddress += PAGE_SIZE // Add an extra page to catch overruns

    return vaddr
}



func addMapping(start: VirtualAddress, size: UInt, physStart: PhysAddress,
    readWrite: Bool, noExec: Bool, cacheType: Int = 0 /* WriteBack */) {

    let endAddress = start + size - 1
    let pageCnt = ((size + PAGE_SIZE - 1) / PAGE_SIZE)
    var physAddress = physStart
    var addr = start

    // Encode cacheType (0 - 7) PAT Enrty index
    let writeThrough = (cacheType & 1) == 1
    let cacheDisable = (cacheType & 2) == 2
    let pat = (cacheType & 4) == 4
    for _ in 0..<pageCnt {
        let idx0 = pml4Index(addr)
        let idx1 = pdpIndex(addr)
        let idx2 = pdIndex(addr)
        let idx3 = ptIndex(addr)

        let pdpPage = getPageAtIndex(pmlPage, idx0)
        let pdPage = getPageAtIndex(pdpPage, idx1)
        let ptPage = getPageAtIndex(pdPage, idx2)

        if !pagePresent(ptPage[idx3]) {
            let entry = makePTE(address: physAddress, readWrite: readWrite,
                userAccess: false, writeThrough: writeThrough,
                cacheDisable: cacheDisable, global: false, noExec: noExec,
                largePage: false, PAT: pat)
            ptPage[idx3] = entry
        } else {
            koops("MM: page is already present!")
        }

        addr += PAGE_SIZE
        physAddress += PAGE_SIZE
    }
    printf("MM: Added kernel mapping from %p-%p [%p-%p]\n", start, endAddress,
        physStart, physAddress - 1)
}


private func add2MBMapping(_ addr: VirtualAddress, physAddress: PhysAddress) {
    let idx0 = pml4Index(addr)
    let idx1 = pdpIndex(addr)
    let idx2 = pdIndex(addr)

    let pdpPage = getPageAtIndex(pmlPage, idx0)
    let pdPage = getPageAtIndex(pdpPage, idx1)

    if !pagePresent(pdPage[idx2]) {
        let entry = makePTE(address: physAddress, readWrite: true,
            userAccess: false, writeThrough: true, cacheDisable: false,
            global: false, noExec: true, largePage: true, PAT: false)
        pdPage[idx2] = entry
    } else {
        koops("MM: 2MB mapping cant be added, already present")
    }
}


private func add1GBMapping(_ addr: VirtualAddress, physAddress: PhysAddress) {
    let idx0 = pml4Index(addr)
    let idx1 = pdpIndex(addr)

    let pdpPage = getPageAtIndex(pmlPage, idx0)
    if !pagePresent(pdpPage[idx1]) {
        let entry = makePTE(address: physAddress, readWrite: true,
            userAccess: false, writeThrough: true, cacheDisable: false,
            global: false, noExec: true, largePage: true, PAT: false)
        pdpPage[idx1] = entry
    } else {
        koops("MM: 1GB mapping cant be added, already present")
    }
}

// for debugging
private func printSections() {
    print("kernel: _text_start:   ", asHex(_text_start_addr))
    print("kernel: _text_end:     ", asHex(_text_end_addr))
    print("kernel: _data_start:   ", asHex(_data_start_addr))
    print("kernel: _data_end:     ", asHex(_data_end_addr))
    print("kernel: _bss_start:    ", asHex(_bss_start_addr))
    print("kernel: _bss_end:      ", asHex(_bss_end_addr))
    print("kernel: _kernel_start: ", asHex(_kernel_start_addr))
    print("kernel: _kernel_end:   ", asHex(_kernel_end_addr))
    print("kernel: _guard_page:   ", asHex(_guard_page_addr))
    print("kernel: _stack_start:  ", asHex(_stack_start_addr))
    print("kernel: initial_pml4:  ", asHex(initial_pml4_addr))
}
