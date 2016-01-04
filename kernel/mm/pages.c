/*
 * kernel/mm/pages.c
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Simple memory management for now just enough alloc_pages() and
 * free_pages() (provided from the BSS)
 *
 */

#include "klibc.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

const unsigned long vm_page_mask = PAGE_MASK;
// Use BSS for alloc_pages() for now
static const size_t MAX_PAGES = 2048;
static char pages[MAX_PAGES][4096]  __attribute__((aligned(4096)));
static size_t next_free_page = 0;


// Simply alloc out of a fixed pool from the BSS for now
void *
alloc_pages(size_t count)
{
        if (next_free_page + count <= MAX_PAGES) {
                void *result = pages[next_free_page];
                next_free_page += count;
                debugf("alloc_pages(%lu) = %p\n", count, result);
                return result;
        }
        koops("alloc_pages! next_free_page = %lu count = %lu", next_free_page,
              count);
}


void
free_pages(void *pages, size_t count)
{
        debugf("freeing %lu pages @ %p\n", count, pages);
}

