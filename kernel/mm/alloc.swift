/*
 * kernel/mm/alloc.swift
 *
 * Created by Simon Evans on 19/04/2017.
 * Copyright © 2016 - 2017 Simon Evans. All rights reserved.
 *
 * Allocation of physical memory pages and virtual address space.
 * Simple memory management for now, just enough for alloc_pages() and
 * free_pages() (provided from the BSS) to work.
 */


// Linked list of free (4K) pages - Use physical address 0 as 'nil' and marks
// the end of the list
private struct FreePageListEntry {
    let regionStart: PhysPageAddress
    var pageCount: Int
    var next: FreePageListEntryPtr?
}

private typealias FreePageListEntryPtr = UnsafeMutablePointer<FreePageListEntry>
private var freePageListHead: FreePageListEntryPtr? = nil
private var nextFreePage = UnsafeMutableRawPointer(bitPattern: _heap_start_addr)!


// Currently used by malloc.c so still need the _cdecl
// Pages are just allocated straight out of a region that is incremented.
// Needs to be converted to a linked list to allow pages to be freed.
@_cdecl("alloc_pages")
public func alloc_pages(pages: Int) -> VirtualAddress {
    return alloc(pages: pages).address
}


public func alloc(pages: Int) -> UnsafeMutableRawPointer {
    precondition(pages > 0)
    let tmp = nextFreePage.advanced(by: pages * Int(PAGE_SIZE))
    if tmp.address <= _heap_end_addr {
        let result = nextFreePage
        nextFreePage = tmp
        return result
    }

    var head = freePageListHead
    var prev: FreePageListEntryPtr? = nil
    while let ptr = head {
        let entry = ptr.pointee
        if entry.pageCount == pages {
            // Region is same size as requested so remove from list
            let result = entry.regionStart
            if prev == nil {
                freePageListHead = entry.next
            } else {
                prev!.pointee.next = entry.next
            }
            //printf("alloc(pages: %ld) -> %p\n", pages, result.vaddr)
            return UnsafeMutableRawPointer(bitPattern: result.vaddr)!
        }
        if entry.pageCount > pages {
            let newPageCount = entry.pageCount - pages
            let result = entry.regionStart.advanced(by: newPageCount)
            ptr.pointee.pageCount = newPageCount
            //printf("alloc(pages: %ld) -> %p\n", pages, result.vaddr)
            return UnsafeMutableRawPointer(bitPattern: result.vaddr)!
        }
        prev = ptr
        head = entry.next
    }

    printf("No more free pages for allocation of: %d pages\n", pages)
    stop()
}


@_cdecl("free_pages")
public func freePages(at address: VirtualAddress, count: Int) {
    guard address >= _heap_end_addr else {
        printf("Trying to free pre-allocated heap page, ignoring\n")
        return
    }
    let paddr = virtualToPhys(address: address)
    addPagesToFreeList(physPage: PhysPageAddress(paddr, pageSize: PAGE_SIZE), pageCount: count)
}


private func addPagesToFreeList(physPage: PhysPageAddress, pageCount: Int) {
    let ptr = FreePageListEntryPtr(bitPattern: physPage.vaddr)!
    let entry = FreePageListEntry(regionStart: physPage, pageCount: pageCount, next: freePageListHead)
    ptr.pointee = entry
    freePageListHead = ptr
}


func addPagesToFreePageList(_ ranges: [MemoryRange]) {
    for range in ranges {
        let startPage = range.start.pageAddress(pageSize: PAGE_SIZE, roundUp: true)
        let pageCount = startPage.address.distance(to: range.endAddress) / PAGE_SIZE
        addPagesToFreeList(physPage: startPage, pageCount: Int(pageCount))
    }
}
