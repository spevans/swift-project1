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

// Convert a virtual address between kernel_start and kernel_end into a
// physical address
private func kernelPhysAddress(_ address: VirtualAddress) -> PhysAddress {
    let _kernel_start_addr = VirtualAddress(bitPattern: &_kernel_start)
    let _kernel_end_addr = VirtualAddress(bitPattern: &_kernel_end)

    guard address >= _kernel_start_addr && address < _kernel_end_addr else {
        #kprintf("kernelPhysAddress: invalid address: %p", address)
        stop()
    }
    return kernelPhysBase.advanced(by: address - _kernel_start_addr)
}


// Setup initial page tables and map kernel
func setupMM(bootParams: BootParams) {

    kernelPhysBase = bootParams.kernelPhysAddress

    let initial_pml4_addr = VirtualAddress(bitPattern: &initial_pml4)

    // Show the current memory ranges
//    for range in bootParams.memoryRanges {
//        #kprint("MM:", bootParams.source, ":", range)
//    }

    let lastEntry = bootParams.memoryRanges[bootParams.memoryRanges.count - 1]
    let highestMemoryAddress = lastEntry.start.advanced(by: lastEntry.size - 1)

    #kprintf("kernel: Highest Address: %#x kernel phys address: %lx\n",
        highestMemoryAddress.value, kernelPhysBase.value)

#if false
    // Show status of MTRRs
    #kprint("Reading MTRR settings")
    let mtrrs = MTRRS()
    #kprint("MTRR: capabilities: \(mtrrs.capabilities)")
    #kprint("MTRR: control: \(mtrrs.control)")
#endif

    // Enable No Execute so data mappings can be set XD (Execute Disable)
    _ = CPU.enableNXE(true)
    // Disable MTRRs
    disableMTRRsetupPAT()

#if false
    let mtrrs2 = MTRRS()
    #kprint("MTRR: capabilities: \(mtrrs2.capabilities)")
    #kprint("MTRR: control: \(mtrrs2.control)")
#endif

    setupKernelMap(bootParams: bootParams)
    setupInitialPhysicalMap(bootParams.memoryRanges)
    // Create a mapping for the text/framebuffer in the new page maps so that print(), printf()
    // etc still works.
    remapTTY(bootParams.frameBufferInfo)

    let pml4paddr = UInt64(kernelPhysAddress(initial_pml4_addr).value)
    setCR3(pml4paddr)
    CPU.enableWP(true)
    #kprintf("MM: CR3 Updated to %p\n", pml4paddr)
    // Now add in all the RAM memory ranges
    do {
        let freeMemoryRanges = bootParams.memoryRanges.filter {
            $0.type == MemoryType.Conventional && $0.start >= PhysAddress(1 * mb) && $0.endAddress < PhysAddress(16 * mb)
        }
        #kprintf("MM: Before adding pages <16MB to freelist, freePageCount: %d freeIOPageCount: %d\n",
            freePageCount(), freeIOPageCount())
        addPagesToFreePageList(freeMemoryRanges)
        #kprintf("MM: After adding pages <16MB to freelist, freePageCount: %d freeIOPageCount: %d\n",
            freePageCount(), freeIOPageCount())
    }

    // Map the rest of the physical memory
    mapPhysicalMemory(bootParams.memoryRanges)
    #kprintf("MM: After adding pages >16MB to freelist, freePageCount: %d freeIOPageCount: %d\n",
        freePageCount(), freeIOPageCount())

    // TODO: Reclaim any memory used in the boot process that can now be used as free RAM
    // eg initial page maps, or EFI memory.
}

public func printStackUsage(_ msg: String = "") {
    let bottomOfStack = VirtualAddress(bitPattern: &_stack_start)
    let topOfStack = VirtualAddress(bitPattern: &_kernel_stack)
    let size = topOfStack - bottomOfStack
    let sp = getRSP()
    let usage = topOfStack - VirtualAddress(sp)
    #kprintf("STACK: %s start: %p - %p size: 0x%8.8x SP: %p usage: 0x%x\n", msg, bottomOfStack, topOfStack, size, sp, usage)
}

private func setupKernelMap(bootParams: BootParams) {
    let addr = VirtualAddress(KERNEL_VIRTUAL_BASE)
    let idx0 = pml4Index(addr)
    let idx1 = pdpIndex(addr)
    let idx2 = pdIndex(addr)
    precondition(idx2 == 8)
    let idx3 = ptIndex(addr)
    precondition(idx3 == 0)

    let initial_pml4_addr = VirtualAddress(bitPattern: &initial_pml4)
    let kernmap_pml3_addr = VirtualAddress(bitPattern: &kernmap_pml3)
    let kernmap_pml2_addr = VirtualAddress(bitPattern: &kernmap_pml2)
    let kernmap_pml1_addr = VirtualAddress(bitPattern: &kernmap_pml1)

    // Setup the pre allocated page tables in the BSS that allow mapping upto 16MB using 4K pages
    var pml4Page = PageMapLevel4Table(at: initial_pml4_addr)
    let pml4Entry = PageMapLevel4Entry(address: kernelPhysAddress(kernmap_pml3_addr), readWrite: true, userAccess: false,
        writeThrough: true, cacheDisable: false, noExec: false)
    pml4Page[idx0] = pml4Entry

    var pml3Page = pml4Entry.pageDirectoryPointerTable!
    let pml3Entry = PageDirectoryPointerTableEntry(address: kernelPhysAddress(kernmap_pml2_addr), readWrite: true, userAccess: false,
        writeThrough: true, cacheDisable: false, noExec: false)
    pml3Page[idx1] = pml3Entry

    var pml2Page = pml3Entry.pageDirectory!

    let kernelStart = VirtualAddress(bitPattern: &_kernel_start)
    let textEnd = VirtualAddress(bitPattern: &_text_end)
    let rodataStart = VirtualAddress(bitPattern: &_rodata_start)
    let dataStart = VirtualAddress(bitPattern: &_data_start)
    let stackStart = VirtualAddress(bitPattern: &_stack_start)
    let bssEnd = VirtualAddress(bitPattern: &_bss_end)
    let guardPage = VirtualAddress(bitPattern: &_guard_page)
    let kernelBase = VirtualAddress(bitPattern: &_kernel_start)

    let pageSize = PageSize()
    let textSize = pageSize.roundToNextPage(textEnd - kernelStart)
    let rodataSize = pageSize.roundToNextPage(dataStart - rodataStart)
    let dataSize = pageSize.roundToNextPage(guardPage - dataStart)
    let stackHeapSize = bssEnd - VirtualAddress(bitPattern: &_stack_start)

    // Add 4 mappings for text, rodata, data + bss and the stack
    // with appropiate protections. There is a guard page between
    // BSS and stack that isnt mapped.
    // FIXME: Dont waste the physical page that is not mapped under
    // the guard page
    #kprintf("MM: _text:   %p - %p\nMM: _rodata: %p - %p\nMM: _data:   %p - %p\n",
        kernelStart, kernelStart + textSize - 1,
        rodataStart, rodataStart + rodataSize - 1,
        dataStart, dataStart + dataSize - 1)
    #kprintf("MM: stack:  %p - %p\n", stackStart, stackStart + stackHeapSize - 1)

    func addKMapping(start: VirtualAddress, size: UInt, physStart: PhysAddress,
        readWrite: Bool, noExec: Bool) {

        let pageCnt = pageSize.pageCountCovering(size: Int(size))
        var physAddress = physStart
        var addr = start

        let patIndex = CPU.CacheType.writeBack.patEntry

        for _ in 0..<pageCnt {
            let kidx0 = pml4Index(addr)
            let kidx1 = pdpIndex(addr)
            let kidx2 = pdIndex(addr)
            let kidx3 = ptIndex(addr)

            precondition(kidx0 == idx0)
            precondition(kidx1 == idx1)
            precondition(kidx2 >= idx2 && (kidx2 < idx2 + 8))

            if !pml2Page[kidx2].present {
                let paddr = kernelPhysAddress(kernmap_pml1_addr) + (PAGE_SIZE * UInt(kidx2 - idx2))
                let pml2Entry = PageDirectoryEntry(address: paddr, readWrite: true, userAccess: false,
                    writeThrough: true, cacheDisable: false, noExec: false)
                pml2Page[kidx2] = pml2Entry
            }

            var pageTable = pml2Page[kidx2].pageTable!
            if pageTable[kidx3].present {
                #kprintf("mm: Kernel mapping p: %p v: %p %u/%u/%u/%u is present!\n",
                    physAddress, addr, kidx0, kidx1, kidx2, kidx3);
                stop()
            }

            let entry = PageTableEntry(address: physAddress, readWrite: readWrite,
                userAccess: false, patIndex: patIndex, global: false, noExec: noExec)
            pageTable[kidx3] = entry

            addr += pageSize.size
            physAddress = physAddress.advanced(by: pageSize.size)
        }
    }


    addKMapping(start: kernelStart, size: textSize,
        physStart: kernelPhysBase, readWrite: false, noExec: false)

    let rodataPhys = kernelPhysBase + textSize
    addKMapping(start: rodataStart, size: rodataSize,
        physStart: rodataPhys, readWrite: false, noExec: true)

    let dataPhys = rodataPhys + rodataSize
    addKMapping(start: dataStart, size: dataSize, physStart: dataPhys,
        readWrite: true, noExec: true)

    let stackPhys = dataPhys + dataSize + PAGE_SIZE
    addKMapping(start: stackStart, size: stackHeapSize,
        physStart: stackPhys, readWrite: true, noExec: true)

    // Add mapping for the symbol and string tables after the stack

    if let symbolTablePtr = bootParams.symbolTablePtr,
       bootParams.symbolTableSize > 0 && bootParams.stringTableSize > 0 {
        let symtabPhys = pageSize.roundUp(stackPhys + stackHeapSize + pageSize.size)
        addKMapping(start: symbolTablePtr.address,
                    size: UInt(bootParams.symbolTableSize + bootParams.stringTableSize),
                    physStart: symtabPhys, readWrite: true, noExec: true)
    }

    #kprintf("MM: Physical address of kernelBase     (%p): (%p)\n",
        kernelBase, kernelPhysAddress(kernelBase).value)
    #kprintf("MM: Physical address of rodata         (%p): (%p)\n",
        kernelBase + textSize,
        kernelPhysAddress(kernelBase + textSize).value)
    #kprintf("MM: Physical address of data           (%p): (%p)\n",
        kernelBase + textSize + rodataSize,
        kernelPhysAddress(kernelBase + textSize + rodataSize).value)
    #kprintf("MM: Physical address of stack and heap (%p): (%p)\n",
        kernelBase + textSize + rodataSize + dataSize + PAGE_SIZE,
        kernelPhysAddress(kernelBase + textSize + rodataSize + dataSize
            + PAGE_SIZE).value)
}

// Setup page maps covering the first 16MB of RAM using a 4K page size.
// This is mapped starting at 0xffff800000000000
// This uses a set of reserved pages in the BSS for the page tables including
// 8 pages to map the 16MB.

private func setupInitialPhysicalMap(_ memoryRanges: [MemoryRange]) {


    let initial_pml4_addr = VirtualAddress(bitPattern: &initial_pml4)
    let physmap_pml3_addr = VirtualAddress(bitPattern: &physmap_pml3)
    let physmap_pml2_addr = VirtualAddress(bitPattern: &physmap_pml2)
    let physmap_pml1_addr = VirtualAddress(bitPattern: &physmap_pml1)
    let kernmap_pml1_addr = VirtualAddress(bitPattern: &kernmap_pml1)
    let _kernel_start_addr = VirtualAddress(bitPattern: &_kernel_start)
    let _kernel_end_addr = VirtualAddress(bitPattern: &_kernel_end)

    let addr = VirtualAddress(PHYSICAL_MEM_BASE)
    let idx0 = pml4Index(addr)
    let idx1 = pdpIndex(addr)
    let idx2 = pdIndex(addr)
    precondition(idx2 == 0)
    let idx3 = ptIndex(addr)
    precondition(idx3 == 0)

    var pml4Page = PageMapLevel4Table(at: initial_pml4_addr)
    let pml4Entry = PageMapLevel4Entry(address: kernelPhysAddress(physmap_pml3_addr), readWrite: true, userAccess: false,
        writeThrough: true, cacheDisable: false, noExec: true)
    pml4Page[idx0] = pml4Entry

    var pml3Page = pml4Entry.pageDirectoryPointerTable!
    let pml3Entry = PageDirectoryPointerTableEntry(address: kernelPhysAddress(physmap_pml2_addr), readWrite: true, userAccess: false,
        writeThrough: true, cacheDisable: false, noExec: true)
    pml3Page[idx1] = pml3Entry

    var pml2Page = pml3Entry.pageDirectory!

    let patIndex = CPU.CacheType.writeBack.patEntry

    // Add in PageDirectory entries that cover lowest 8x 2MB = 16MB
    for idx in 0...7 {
        let paddr = kernelPhysAddress(physmap_pml1_addr) + (PAGE_SIZE * UInt(idx))
        let pml2Entry = PageDirectoryEntry(address: paddr, readWrite: true, userAccess: false,
            writeThrough: true, cacheDisable: false, noExec: true)
        pml2Page[idx] = pml2Entry
    }

    // FIXME This is a bit hacky as it assumes no range will cover the 16MB bondary
    // but this is true for now as the kernel range starts at 16MB
    let lowMemoryRanges = memoryRanges.filter {
        $0.endAddress < PhysAddress(16 * 1048576)
    }

    // Find all of the usable (RAM) page aligned pages in the region below 16MB. Ignore
    // Map non RAM as RO as it probably contains BIOS etc that still needs to be readable
    for (physPageRange, access) in lowMemoryRanges.align(toPageSize: PageSize()) {
        guard access == .readWrite else { continue }
        for physPage in physPageRange {
            let vaddr = physPage.vaddr
            precondition(physPage.value < 16 * mb)

            let idx2 = pdIndex(vaddr)
            let idx3 = ptIndex(vaddr)
            var pageTable = pml2Page[idx2].pageTable!

            let entry = PageTableEntry(address: physPage, readWrite: true, userAccess: false,
                patIndex: patIndex, global: false, noExec: true)
            pageTable[idx3] = entry
        }
    }

    // The kernel is in the next physical memory at 0x1000000 (16MB) and is already mapped using 4K pages,
    // at its own kernel base. Reuse the page tables and just add entries for the page directories which
    // each cover 2MB of the kernel.
    // This needs to be setup now as the heap pages in the kernel .data section are accessed using the
    // kernel physical mapping.
    let kernelSize = _kernel_end_addr - _kernel_start_addr
    let kernel2MBPages = (kernelSize + UInt(2 * mb) - 1) / (2 * mb)
    #kprintf("kernelStart: %p kernelEnd: %p kernelSize: %lx 2mb pages: %u\n",
        _kernel_start_addr, _kernel_end_addr, kernelSize, kernel2MBPages)

    for idx in 0..<kernel2MBPages {
        let paddr = kernelPhysAddress(kernmap_pml1_addr) + (PAGE_SIZE * idx)
        let pml2Entry = PageDirectoryEntry(address: paddr, readWrite: true, userAccess: false,
            writeThrough: true, cacheDisable: false, noExec: true)
        pml2Page[Int(idx + 8)] = pml2Entry
    }
}


// Map any available RAM above 16MB and add to the free pages list.
private func mapPhysicalMemory(_ ranges: [MemoryRange]) {

    let memoryRanges = ranges.filter {
        $0.start >= PhysAddress(16 * mb) && $0.type == .Conventional
    }
    #kprint("MM: Mapping Physical memory in ranges:")
    for range in memoryRanges {
        #kprint(range)
    }

    guard !memoryRanges.isEmpty else { return }
#if false
    let maxAddress = memoryRanges.last!.endAddress
    #kprintf("MM: Mapping physical memory from %p - %p , freePageCount: %ld\n", memoryRanges[0].start.value, maxAddress.value, freePageCount())
#endif

    let initial_pml4_addr = VirtualAddress(bitPattern: &initial_pml4)
    let pmlPage = PageMapLevel4Table(at: initial_pml4_addr)

    // Break large chunks into 256MB chunks and add them to the free page list as they are mapped.
    // Since the page maps require memory themselves, pages are mapped and added to the free page list
    // in 256MB chunks so more memory is availble for subsequent mapping
    let maxPagesPerLoop = 65536 // 256MB per loop
    for (physPageRange, access) in memoryRanges.align(toPageSize: PageSize()) {
        guard access == .readWrite else { continue }

        var pageRangeIterator = PhysPageAlignedRegionChunksInterator(physPageRange, pagesPerChunk: maxPagesPerLoop)
        while let chunk = pageRangeIterator.next() {
            for physPage in chunk {
                let vaddr = physPage.vaddr

                let idx0 = pml4Index(vaddr)
                let idx1 = pdpIndex(vaddr)
                let idx2 = pdIndex(vaddr)
                let idx3 = ptIndex(vaddr)

                let pdpPage = pmlPage.pageDirectoryPointerTable(at: idx0, readWrite: true, userAccess: false,
                    writeThrough: true, cacheDisable: false, noExec: true)

                let pdPage = pdpPage.pageDirectory(at: idx1, readWrite: true, userAccess: false,
                    writeThrough: true, cacheDisable: false, noExec: true)

                var ptPage = pdPage.pageTable(at: idx2, readWrite: true, userAccess: false,
                    writeThrough: true, cacheDisable: false, noExec: true)

                if !ptPage[idx3].present {
                    let patIndex = CPU.CacheType.writeBack.patEntry
                    let entry = PageTableEntry(address: physPage, readWrite: access == .readWrite,
                        userAccess: false, patIndex: patIndex, global: false, noExec: true)
                    ptPage[idx3] = entry
                } else {
                    #kprint("Cant add mapping for \(physPage) @ 0x\(String(vaddr, radix: 16))")
                    koops("MM: page is already present!")
                }
            }
            addPagesToFreePageList(pages: chunk)
        }
    }
}


// for debugging
private func printSections() {
    #kprint("kernel: _text_start:   ", UInt(bitPattern: _text_start).hex())
    #kprint("kernel: _text_end:     ", UInt(bitPattern: _text_end).hex())
    #kprint("kernel: _data_start:   ", UInt(bitPattern: _data_start).hex())
    #kprint("kernel: _data_end:     ", UInt(bitPattern: _data_end).hex())
    #kprint("kernel: _bss_start:    ", UInt(bitPattern: _bss_start).hex())
    #kprint("kernel: _bss_end:      ", UInt(bitPattern: _bss_end).hex())
    #kprint("kernel: _kernel_start: ", UInt(bitPattern: _kernel_start).hex())
    #kprint("kernel: _kernel_end:   ", UInt(bitPattern: _kernel_end).hex())
    #kprint("kernel: _guard_page:   ", UInt(bitPattern: _guard_page).hex())
    #kprint("kernel: _stack_start:  ", UInt(bitPattern: _stack_start).hex())
    #kprint("kernel: initial_pml4:  ", UInt(bitPattern: initial_pml4).hex())
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
