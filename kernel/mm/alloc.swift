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


private var nextFreePage = UnsafeMutableRawPointer(bitPattern: _heap_start_addr)!

// Currently used by malloc.c so still need the _cdecl
// Pages are just allocated straight out of a region that is incremented.
// Needs to be converted to a linked list to allow pages to be freed.
@_cdecl("alloc_pages")
public func alloc_pages(pages: Int) -> UInt {
    return alloc(pages: pages).address
}

public func alloc(pages: Int) -> UnsafeMutableRawPointer {
    precondition(pages > 0)
    let tmp = nextFreePage.advanced(by: pages * Int(PAGE_SIZE))
    if tmp.address > _heap_end_addr {
        printf("No more free pages for allocation of: %d pages\n", pages)
        hlt()
    }

    let result = nextFreePage
    nextFreePage = tmp

    return result
}


@_cdecl("free_pages")
// Dont actually free the pages yet
public func freePages(at address: VirtualAddress, count: Int) {
}
