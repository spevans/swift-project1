/*
 * kernel/mm/pages.c
 *
 * Created by Simon Evans on 25/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Simple memory management for now just enough alloc_pages() and
 * free_pages() (provided from the BSS)
 *
 */

#include "klibc.h"
#include "mm.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

extern const void * const _heap_start;
extern const void * const _heap_end;
const unsigned long vm_page_mask = PAGE_MASK;
static void *next_free_page = (void *)&_heap_start;


/* These pages are allocated before the MM is setup, mostly for small malloc()s
 * and the page tables needed to map the kernel. They come from an area in the
 * BSS between _heap_start and _heap_end defined by the linker script
 */
static void *
early_alloc_pages(size_t count)
{
        size_t size = count * PAGE_SIZE;
        if (next_free_page + size <= (void *)&_heap_end) {
                void *result = next_free_page;
                next_free_page += size;
                debugf("alloc_pages(%lu) = %p\n", count, result);

                return result;
        }
        koops("alloc_pages(): no more free pages next_free_page=%p count=%lu size=%#lx _heap_end=%p\n",
              next_free_page, count, size, &_heap_end);
}


// Dont acutally free any of these pages though
static void
early_free_pages(void *pages, size_t count)
{
        debugf("freeing %lu pages @ %p\n", count, pages);
}

// Once the MM is setup these can be pointed at more sophisticated versions
void *(*alloc_pages)(size_t count) = early_alloc_pages;
void (*free_pages)(void *pages, size_t count) = early_free_pages;

