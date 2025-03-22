/*
 * kernel/mm/alloc.swift
 *
 * Created by Simon Evans on 19/04/2017.
 * Copyright © 2016 - 2018 Simon Evans. All rights reserved.
 *
 * Allocation of physical memory pages and virtual address space.
 * Simple memory management for now, just enough for alloc_pages() and
 * free_pages() (provided from the BSS) to work.
 */


// Linked list of free (4K) pages - Use physical address 0 as 'nil' and marks
// the end of the list
private struct FreePageListEntry {
    var region: PhysPageAlignedRegion
    var next: FreePageListEntryPtr?
}

private typealias FreePageListEntryPtr = UnsafeMutablePointer<FreePageListEntry>
private var freePageListHead = initFreeList()
private var ioPagesListHead: FreePageListEntryPtr? = nil

// This is called the first time alloc_pages() is called, usually by malloc()
private func initFreeList() -> FreePageListEntryPtr? {
    let pageSize = PageSize()
    let _heap_start_addr = VirtualAddress(bitPattern: &_heap_start)
    let _heap_end_addr = VirtualAddress(bitPattern: &_heap_end)
    let heap_phys = virtualToPhys(address: _heap_start_addr)!
    let pageCount = Int((_heap_end_addr - _heap_start_addr) / pageSize.size)
    #kprintf("init_free_list: heap_start: %p ", _heap_start_addr)
    #kprintf("heap_end: %p ", _heap_end_addr)
    #kprintf("heap_phys: %p ", heap_phys.value)
    #kprintf("pageCount: %d\n", pageCount)

    guard let ptr = FreePageListEntryPtr(bitPattern: _heap_start_addr) else {
        koops("Cant init free list")
    }
    ptr.pointee = FreePageListEntry(
        region: PhysPageAlignedRegion(heap_phys, pageSize: pageSize, pageCount: pageCount),
        next: nil
    )
    // Use single argument versions of #kprintf() which has specialisation for
    // 1 Int or UInt arg. see printf.swift.
    return ptr
}


// Currently used by malloc.c so still need the _cdecl
// Pages are just allocated straight out of a region that is incremented.
// Needs to be converted to a linked list to allow pages to be freed.
@_cdecl("alloc_pages")
public func alloc_pages(pages: Int) -> UnsafeMutableRawPointer {
    return alloc(pages: pages).rawPointer
}

@_cdecl("free_pages")
public func freePages(at address: VirtualAddress, count: Int) {
    let paddr = virtualToPhys(address: address)!
    addPages(PhysPageAlignedRegion(paddr, pageSize: PageSize(), pageCount: count), toList: &freePageListHead)
}


func alloc(pages: Int) -> PhysPageAlignedRegion {
    return alloc(pages: pages, fromList: &freePageListHead)
}


func freePages(pages: PhysPageAlignedRegion) {
    addPages(pages, toList: &freePageListHead)
}


// FIXME, these needs to take a `pages` argument to allocate contiguous pages
func allocIOPage() -> PhysPageAlignedRegion {
    return alloc(pages: 1, fromList: &ioPagesListHead)
}

// TODO - check the pages returned are valid for IO
func freeIOPage(_ pages: PhysPageAlignedRegion) {
    addPages(pages, toList: &ioPagesListHead)
}



// Called from kernel/mm/init
func addPagesToFreePageList(_ ranges: [MemoryRange]) {

    for range in ranges {
        for physPageRange in range.physPageRanges {
            addPagesToFreePageList(pages: physPageRange)
        }
    }
}


// Called from kernel/mm/init
func addPagesToFreePageList(pages: PhysPageAlignedRegion) {

    func splitRange(_ pageRange: PhysPageAlignedRegion, at address: PhysAddress) -> (lower: PhysPageAlignedRegion?, upper: PhysPageAlignedRegion?) {
        if pageRange.endAddress < address {
            return (pageRange, nil)
        }
        if pageRange.baseAddress >= address {
            return (nil, pageRange)
        }
        else {
            let lowerPageCount = (address - pageRange.baseAddress) / Int(pageRange.pageSize.size)
            let (lower, upper) = pageRange.splitRegion(withFirstRegionCount: lowerPageCount)
            #kprint("addPagesToFreePageList split \(pageRange) into \(lower) and \(upper)")
            return (lower, upper)
        }
    }

    // Ignore anything below 1MB
    let (_, upper) = splitRange(pages, at: PhysAddress(0x100000))
    guard let above1MB = upper else { return }

    let (_ioRange, _ramRange) = splitRange(above1MB, at: PhysAddress(0x200000))
    if let ioRange = _ioRange {
        _ = remapAsIORegion(region: ioRange, cacheType: .uncacheable)
        addPages(ioRange, toList: &ioPagesListHead)
    }
    if let ramRange = _ramRange {
        addPages(ramRange, toList: &freePageListHead)
    }
}


func freePageCount() -> Int {
    return freePageCount(onList: freePageListHead)
}


func freeIOPageCount() -> Int {
    return freePageCount(onList: ioPagesListHead)
}

// Free Page List management
private func addPages(_ pages: PhysPageAlignedRegion, toList list: inout FreePageListEntryPtr?) {

    let ptr = FreePageListEntryPtr(bitPattern: pages.vaddr)!
    let entry = FreePageListEntry(region: pages, next: list)
    ptr.pointee = entry
    list = ptr
}


private func freePageCount(onList list: FreePageListEntryPtr?) -> Int {
    var count = 0

    var head = list
    while let ptr = head {
        let entry = ptr.pointee
        let region = entry.region
        count += region.pageCount
        head = entry.next
    }
    return count
}


private func alloc(pages: Int, fromList list: inout FreePageListEntryPtr?) -> PhysPageAlignedRegion {
    precondition(pages > 0)

    var head = list
    var prev: FreePageListEntryPtr? = nil

    while let ptr = head {
        let entry = ptr.pointee
        let region = entry.region
        let pageCount = region.pageCount

        if pageCount == pages {
            // Region is same size as requested so remove from list
            let result = region
            if prev == nil {
                list = entry.next
            } else {
                prev!.pointee.next = entry.next
            }
            return result
        }
        if pageCount > pages {
            let (newRegion, result) = region.splitRegion(withFirstRegionCount: pageCount - pages)
            ptr.pointee.region = newRegion
            return result
        }
        prev = ptr
        head = entry.next
    }

    #kprintf("No more free pages for allocation of: %d pages\n", pages)
    stop()
}
