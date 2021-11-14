/*
 * kernel/mm/init.swift
 *
 * Created by Simon Evans on 18/01/2016.
 * Copyright © 2016 - 2017 Simon Evans. All rights reserved.
 *
 * Initial setup for memory management
 *
 */


/* The page table setup by the BIOS boot loader setup 3 mappings of the
 * first 16MB of memory
 * @0 (Zero Page) is unmapped to catch NULL pointer errors.
 *
 * 4K  @ 0x1000 -> 0x100000(1MB)
 *       To allow the TLS address to be put in a GDT entry. This needs to be
 *       below 4GB. This is the first 4KB of the kernel which has data.
 *
 * 2MB @ 0x3000 -> 0x200000(2MB)
 *       An identity mapping used to load the kernel and execute code after
 *       paging is enabled.
 *
 * 1GB @ 0xffff800000000000 (128TB) -> 0x000
 *       Used as a mapping of physical memory accesible from the kernel
 *       address space. It is setup at boot so that the tty drivers can
 *       access the video memory without having to readjust after the
 *       mapping is changed. Defined as PHYSICAL_MEM_BASE.
 *
 * 1GB @ 0xffffffff80000000 (256TB-2GB) -> 0x100000 (1MB)
 *       The kernel's virtual address that it executes at.
 *       Maps to where the kernel is physically loaded.
 *       Defined as KERNEL_VIRTUAL_BASE
 *
 *
 * The EFI Loader sets up the following mappings:
 *
 * 4K @ 0x1000 -> Physical address where kernel is loaded. Used as above.
 *
 * sizeof(Framebuffer) @ 0xffff800000000000+base address of the framebuffer
 *       For screen access.
 *
 * 4GB @ 0x00000000 -> 0xffff8000_00000000 Mapping of Physical RAM
 *
 * sizeof(kernel text+data+bss) @ 0xffffffff80000000 -> Physical address
 * where kernel is loaded covering the loaded kernel
 *
 * setupMM() creates new page tables with the following:
 *
 * 4K @ 0x1000 -> Physical address where kernel is loaded. Used as above.
 *
 * sizeof(RAM) @ 0xffff800000000000 -> 0x0000 To cover all physical RAM
 *
 * This also maps the framebuffer at the same address at the boot code so
 * that the TTY driver continues to work.
 *
 * sizeof(kernel text+data+bss) @ 0xffffffff80000000 -> Physical address
 * where kernel is loaded covering the loaded kernel.
 *
 * The initial page tables setup here are using pages from the kernel BSS
 * as there is not allocPage() at this stage so kernelVirtualAddress() is
 * used to convert virtual addresses in the space to physical addresses for
 * the various page table entries.
 */


private(set) var kernelPhysBase = PhysAddress(0)

// Setup initial page tables and map kernel
func setupMM(bootParams: BootParams) {

    // Convert a virtual address between kernel_start and kernel_end into a
    // physical address
    kernelPhysBase = bootParams.kernelPhysAddress

    func kernelPhysAddress(_ address: VirtualAddress) -> PhysAddress {
        guard address >= _kernel_start_addr && address < _kernel_end_addr else {
            printf("kernelPhysAddress: invalid address: %p", address)
            stop()
        }
        return kernelPhysBase.advanced(by: address - _kernel_start_addr)
    }

    // Show the current memory ranges
//    for range in bootParams.memoryRanges {
//        print("MM:", bootParams.source, ":", range)
//    }

    let lastEntry = bootParams.memoryRanges[bootParams.memoryRanges.count - 1]
    let highestMemoryAddress = lastEntry.start.advanced(by: lastEntry.size - 1)

    printf("kernel: Highest Address: %#x kernel phys address: %lx\n",
        highestMemoryAddress.value, kernelPhysBase.value)

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

    // Show status of MTRRs
    print("Reading MTRR settings")
    let mtrrs = MTRRS()
    print("MTRR: capabilities: \(mtrrs.capabilities)")
    print("MTRR: control: \(mtrrs.control)")

    // Enable No Execute so data mappings can be set XD (Execute Disable)
    _ = CPU.enableNXE(true)
    // Disble MTRRs
    disableMTRRsetupPAT()

    let mtrrs2 = MTRRS()
    print("MTRR: capabilities: \(mtrrs2.capabilities)")
    print("MTRR: control: \(mtrrs2.control)")

    // Add 4 mappings for text, rodata, data + bss and the stack
    // with appropiate protections. There is a guard page between
    // BSS and stack that isnt mapped.
    // FIXME: Dont waste the physical page that is not mapped under
    // the guard page
    printf("MM: _text:   %p - %p\nMM: _rodata: %p - %p\nMM: _data:   %p - %p\n",
        _kernel_start_addr, _kernel_start_addr + textSize - 1,
        _rodata_start_addr, _rodata_start_addr + rodataSize - 1,
        _data_start_addr, _data_start_addr + dataSize - 1)

    addMapping(start: _kernel_start_addr, size: textSize,
        physStart: kernelPhysBase, readWrite: false, noExec: false)

    let rodataPhys = kernelPhysBase + textSize
    addMapping(start: rodataStart, size: rodataSize,
        physStart: rodataPhys, readWrite: false, noExec: true)

    let dataPhys = rodataPhys + rodataSize
    addMapping(start: dataStart, size: dataSize, physStart: dataPhys,
        readWrite: true, noExec: true)

    let stackPhys = dataPhys + dataSize + PAGE_SIZE
    addMapping(start: _stack_start_addr, size: stackHeapSize,
        physStart: stackPhys, readWrite: true, noExec: true)

    // Add mapping for the symbol and string tables after the stack

    if let symbolTablePtr = bootParams.symbolTablePtr,
        bootParams.symbolTableSize > 0 && bootParams.stringTableSize > 0 {
            let symtabPhys = (stackPhys + stackHeapSize + PAGE_SIZE).pageAddress(pageSize: PAGE_SIZE, roundUp: true)
            addMapping(start: symbolTablePtr.address,
                size: UInt(bootParams.symbolTableSize + bootParams.stringTableSize),
                physStart: symtabPhys, readWrite: true, noExec: true)
    }

    printf("MM: Physical address of kernelBase     (%p): (%p)\n",
        kernelBase, kernelPhysAddress(kernelBase).value)
    printf("MM: Physical address of rodata         (%p): (%p)\n",
        kernelBase + textSize,
        kernelPhysAddress(kernelBase + textSize).value)
    printf("MM: Physical address of data           (%p): (%p)\n",
        kernelBase + textSize + rodataSize,
        kernelPhysAddress(kernelBase + textSize + rodataSize).value)
    printf("MM: Physical address of stack and heap (%p): (%p)\n",
        kernelBase + textSize + rodataSize + dataSize + PAGE_SIZE,
        kernelPhysAddress(kernelBase + textSize + rodataSize + dataSize
            + PAGE_SIZE).value)

#if ENABLE_TLS
    // Map the TLS which resides before 4GB mark and has the same virtual
    // and physical address
    let tlsPage = TLS_END_ADDR & ~PAGE_MASK
    addMapping(start: tlsPage, size: PAGE_SIZE, physStart: kernelPhysBase,
        readWrite: true, noExec: true)
#endif

    mapPhysicalMemory(highestMemoryAddress)
    let pml4paddr = UInt64(kernelPhysAddress(initial_pml4_addr).value)
    printf("MM: Updating CR3 to %p\n", pml4paddr)
    setCR3(pml4paddr)
    CPU.enableWP(true)
    printf("MM: CR3 Updated to %p\n", pml4paddr)

    // Now add in all the RAM memory ranges
    let freeMemoryRanges = bootParams.memoryRanges.filter {
        $0.type == MemoryType.Conventional
    }
    print("MM: Before adding pages to freelist, freePageCount:", freePageCount())
    addPagesToFreePageList(freeMemoryRanges)
    print("MM: After adding pages to freelist, freePageCount:", freePageCount())

    // TODO: Reclaim any memory used in the boot process that can now be used as free RAM
    // eg initial page maps, or EFI memory.
}


// FIXME: Should map more closely to the real map, not map holes
// and map the reserved mem as RO etc
private func mapPhysicalMemory(_ maxAddress: PhysAddress) {
    var inc: UInt = 0

    printf("MM: Mapping physical memory from 0 - %p , freePageCount: %ld\n", maxAddress.value, freePageCount())
    // Map physical memory using 1GB pages if available else 2MB pages
    var mapper = add2MBMapping
    if CPU.capabilities.pages1G {
        inc = 0x40000000    // 1GB
        mapper = add1GBMapping
        print("MM: Using 1GB mappings: ")
    } else {
        inc = 0x200000      // 2MB
        print("MM: Using 2MB mappings: ")
    }

    let pages = (maxAddress.value + (inc - 1)) / inc
    printf("MM: Mapping %u pages of size %#lx\n", pages, inc)
    var vaddr = VirtualAddress(PHYSICAL_MEM_BASE)
    var paddr = PhysAddress(0)

    for _ in 1...pages {
        mapper(vaddr, paddr, true, false)
        vaddr += inc
        paddr = paddr.advanced(by: inc)
    }
    printf("MM: Added mappings upto: %p [%p] freePageCount: %ld\n", vaddr, paddr.value, freePageCount())
}


private func roundToPage(_ size: UInt) -> UInt {
    return (size + PAGE_MASK) & ~PAGE_MASK
}


private var nextIOVirtualAddress: VirtualAddress = 0x4000000000 // 256GB
func mapIORegion(physicalAddr: PhysAddress, size: Int, cacheType: CPU.CacheType = .uncacheable) -> VirtualAddress {
    let newSize = roundToPage(UInt(size))
    let vaddr = nextIOVirtualAddress
    addMapping(start: vaddr, size: newSize, physStart: physicalAddr,
        readWrite: true, noExec: true, cacheType: cacheType)
    nextIOVirtualAddress += newSize
    nextIOVirtualAddress += PAGE_SIZE // Add an extra page to catch overruns

    return vaddr
}


func mapIORegion(region: PhysPageRange, cacheType: CPU.CacheType = .uncacheable) -> MMIORegion {
    let vaddr = nextIOVirtualAddress
    //print("Adding IO mapping for \(region) at 0x\(String(vaddr, radix: 16))")
    addMapping(start: vaddr, size: region.regionSize, physStart: region.address,
               readWrite: true, noExec: true, cacheType: cacheType)
    nextIOVirtualAddress += region.regionSize
    nextIOVirtualAddress += PAGE_SIZE // Add an extra page to catch overruns

    return MMIORegion(physicalRegion: region, virtualAddress: vaddr)
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


// 11.11.8 MTRR Considerations in MP Systems
// Disable MTRR and setup the PAT entries
// NOTE/FIXME This doent disable the MTRR anymore as it appears that when it is disabled
// all of the memorydefaults to UC. Im not sure if this is as intended, the SDM doesnt make
// it clear whether PAT is the only source of memory type information or if the MTRR Control
// Register field Default Type still has any effect even if the field Enable MTRRs is disabled.
private func disableMTRRsetupPAT() {
    noInterrupt {
        // Enter the no-fill cache mode. (Set the CD flag in control register CR0 to 1 and the NW flag to 0.)
        var cr0 = CPU.cr0
        var cr4 = CPU.cr4
        let pge = cr4.pge

        cr0.cacheDisable = true
        cr0.notWriteThrough = false
        CPU.cr0 = cr0

        // Flush all caches using the WBINVD instructions. Note on a processor that supports self-snooping,
        // CPUID feature flag bit 27, this step is unnecessary.
        // if !CPU.hasSelfSnoop {
        wbinvd()

        // If the PGE flag is set in control register CR4, flush all TLBs by clearing that flag.
        if CPU.capabilities.pge {
            cr4.pge = false
            CPU.cr4 = cr4
        }

        // If the PGE flag is clear in control register CR4, flush all TLBs by executing a MOV from control
        // register CR3 to another register and then a MOV from that register back to CR3.
        let cr3 = CPU.cr3
        CPU.cr3 = cr3

        // Disable all range registers (by clearing the E flag in register MTRRdefType).
        //If only variable ranges are being modified, software may clear the valid bits for the affected register pairs instead.
        // (Note see above)
        //MTRRS.disableMTRRs()

        // Flush all caches and all TLBs a second time.
        wbinvd()

        CPU.setupPAT()
        do {
            let cr3 = CPU.cr3
            CPU.cr3 = cr3
        }

        // Enter the normal cache mode to re-enable caching.
        cr0.cacheDisable = false
        cr0.notWriteThrough = false
        CPU.cr0 = cr0

        // Set PGE flag in control register CR4, if cleared
        if CPU.capabilities.pge {
            cr4.pge = pge
            CPU.cr4 = cr4
        }
    }
}
