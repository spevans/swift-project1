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
    var region: PhysPageRange
    var next: FreePageListEntryPtr?
}

private typealias FreePageListEntryPtr = UnsafeMutablePointer<FreePageListEntry>
private var freePageListHead = initFreeList()

// This is called the first time alloc_pages() is called, usually by malloc()
private func initFreeList() -> FreePageListEntryPtr? {
    let heap_phys = virtualToPhys(address: _heap_start_addr)
    let pageCount = Int((_heap_end_addr - _heap_start_addr) / PAGE_SIZE)
    kprintf("init_free_list: heap_start: %p ", _heap_start_addr)
    kprintf("heap_end: %p ", _heap_end_addr)
    kprintf("heap_phys: %p ", heap_phys.value)
    kprintf("pageCount: %llu\n", pageCount)

    guard let ptr = FreePageListEntryPtr(bitPattern: _heap_start_addr) else {
        koops("Cant init free list")
    }
    ptr.pointee = FreePageListEntry(
        region: PhysPageRange(heap_phys, pageSize: PAGE_SIZE, pageCount: pageCount),
        next: nil
    )
    // Use single argument versions of kprintf() which has specialisation for
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


func alloc(pages: Int) -> PhysPageRange {
    precondition(pages > 0)

    var head = freePageListHead
    var prev: FreePageListEntryPtr? = nil

    while let ptr = head {
        let entry = ptr.pointee
        let region = entry.region
        let pageCount = region.pageCount

        if pageCount == pages {
            // Region is same size as requested so remove from list
            let result = region
            if prev == nil {
                freePageListHead = entry.next
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

    kprintf("No more free pages for allocation of: %d pages\n", pages)
    stop()
}


@_cdecl("free_pages")
public func freePages(at address: VirtualAddress, count: Int) {
    let paddr = virtualToPhys(address: address)
    addPagesToFreeList(physPage: PhysPageRange(paddr, pageSize: PAGE_SIZE, pageCount: count))
}


func freePages(pages: PhysPageRange) {
    addPagesToFreeList(physPage: pages)
}

private func addPagesToFreeList(physPage: PhysPageRange) {
    let ptr = FreePageListEntryPtr(bitPattern: physPage.vaddr)!
    let entry = FreePageListEntry(region: physPage, next: freePageListHead)
    ptr.pointee = entry
    freePageListHead = ptr
}


func addPagesToFreePageList(_ ranges: [MemoryRange]) {
    for range in ranges {
        for pages in range.physPageRanges {
            addPagesToFreeList(physPage: pages)
        }
    }
}
