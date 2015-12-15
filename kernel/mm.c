/*
 * kernel/mm.c
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Simple memory management for now just enough to provice a simple malloc()
 * and alloc_pages() (provided from the BSS)
 *
 * Sizes of memory regions supported and number of regions on a page.
 * Uses a 64bit unsigned in to hold an allocation bitmap - wasteful in
 * the case of slabs of size 32 as only have the page is used.
 *
 * The sizes were chosen as they are all aligned to 16bytes and they
 * exactly fill a 4096K page with a 64byte header (expect the 32byte one
 * although there is enough space in the header to have a second allocation
 * bitmap for that case.
 *
 * Any allocations over 4032 bytes just get rounded up to a page size and
 * allocated from the free pages.
 *
 * realloc() isnt currently implemented as it is now needed at the moment.
 * No stats have been gathered to optimise this allocator in anyway its just
 * bare minimum to get everything else working. Anyway, the C++ string
 * libraries that use it do there own realloc routing (malloc/free/computing
 * best next size
 *
 */

#include "klibc.h"


#pragma GCC diagnostic ignored "-Wunused-parameter"

extern uintptr_t _bss_end;
const unsigned long PAGE_SIZE = 4096;
const unsigned long vm_page_mask = PAGE_SIZE-1;
static const int MAX_MALLOC_SIZE = 4032;        // Anything over this gets pages
static const int MAX_PAGES = 2048;

// Used for alloc_pages()
char pages[2048][4096]  __attribute__((aligned(4096)));
static size_t next_free_page = 0;

struct slab_block_info {
        uint32_t slab_size;
        uint32_t slab_count;
};


struct slab_block_info slab_info[] = { {32, 64}, {64, 63}, {192, 21}, {448, 9},
                                       {1008, 4}, {2016, 2}, {4032, 1} };
#define SLAB_SIZES 7

// Should be 64 bytes
struct slab_header {
        uint32_t slab_size;
        uint32_t lock;
        struct slab_header *next;
        uint64_t malloc_cnt;
        uint64_t free_cnt;
        uint64_t allocation_bm[2];
        char signature[8];
        char padding[8];                // rather wasteful
        char data[4032];                // upto a page
} __attribute__((aligned(4096),packed));


// List of pages that have free slabs on them, 1 list per slab size
struct slab_header *slabs[SLAB_SIZES];


// Simply alloc out of a fixed pool from the BSS for now
void *
alloc_pages(size_t count)
{
        if (next_free_page + count <= MAX_PAGES) {
                void *result = pages[next_free_page];
                next_free_page += count;
                dprintf("alloc_pages(%lu) = %p\n", count, result);
                return result;
        }
        koops("alloc_pages! next_free_page = %lu count = %lu", next_free_page, count);
}


// Convert a page into a slab
struct slab_header *
add_new_slab(int slab_idx)
{
        struct slab_header *slab = alloc_pages(1);
        slab->slab_size = slab_info[slab_idx].slab_size;
        slab->lock = 0;
        slab->allocation_bm[0] = 0;
        slab->allocation_bm[1] = 0;
        strcpy(slab->signature, "MALLOC");      // for debugging
        slab->next = slabs[slab_idx];
        slabs[slab_idx] = slab;

        return slab;
}


void
init_mm()
{
        for (size_t i = 0; i < SLAB_SIZES; i++) {
                add_new_slab(i);
        }
}


// Debugging for now, wouldnt work normally as text could be there for other reasons
static void
validate_is_slab(struct slab_header *slab)
{
        if (strcmp(slab->signature, "MALLOC")) {
                koops("slab @ %p is not a slab!", slab);
        }
}


static inline int
map_size_to_idx(size_t size)
{
        // Could convert to map the highest bit set in the size
        if (size <= 32)   return 0;
        if (size <= 64)   return 1;
        if (size <= 192)  return 2;
        if (size <= 448)  return 3;
        if (size <= 1008) return 4;
        if (size <= 2016) return 5;
        if (size <= 4032) return 6;
        koops("map_size_to_idx: bad size %lu\n", size);
}


// Mask of bits used in the allocation bitmap
static inline uint64_t
bitmap_mask(int slab_idx)
{
        if (slab_idx == 0) return 0xffffffffffffffff;
        uint64_t mask = (uint64_t)1;
        uint64_t count = (uint64_t)slab_info[slab_idx].slab_count;
        uint64_t result = (mask << count) - 1;

        return result;
}


void *
malloc(size_t size)
{
        dprintf("malloc(%lu): ", size);
        if (sizeof(struct slab_header) != PAGE_SIZE) {
                koops("slab_header is %lu bytes", sizeof(struct slab_header));
        }

        if (size > MAX_MALLOC_SIZE) {
                size_t pages = (size + vm_page_mask) / PAGE_SIZE;
                return alloc_pages(pages);
        }
        int slab_idx = map_size_to_idx(size);
        struct slab_header *slab = slabs[slab_idx];
        validate_is_slab(slab);

        uint64_t allocation_mask = bitmap_mask(slab_idx);
        uint64_t free_bits = slab->allocation_bm[0] ^ allocation_mask;
        int freebit = __builtin_ffsl(free_bits);

        dprintf("slab for idx:%d has [%3lu/%3lu/%0.16lX/%0.16lX/%0.16lX]   ", slab_idx,
                slab->malloc_cnt, slab->free_cnt, slab->allocation_bm[0], free_bits,
                allocation_mask);

        if (unlikely(freebit == 0)) {
                slab = add_new_slab(slab_idx);
                dprintf(" got new slab @ %p ", slab);
                free_bits = slab->allocation_bm[0] ^ allocation_mask;
                freebit = __builtin_ffsl(free_bits);
                if(unlikely(freebit == 0)) {
                        koops("new slab for idx:%d has filled up [%"PRIu64 "/%"PRIu64" /%"PRIX64 "]!", slab_idx,
                              slab->malloc_cnt, slab->free_cnt, slab->allocation_bm[0]);
                }
        }
        freebit--;
        size_t offset = freebit * slab_info[slab_idx].slab_size;
        void *result = &slab->data[offset];

        uint64_t free_mask = (uint64_t)1 << freebit;
        dprintf("free_mask = %16lx allocation_bm = %16lx\n", free_mask,slab->allocation_bm[0]);
        slab->allocation_bm[0] |= free_mask;
        slab->malloc_cnt++;

        dprintf("malloc(%lu)=%p slab=%p offset=%lx [%"PRIu64 "/%"PRIu64"]\n",
                size, result, slab, offset, slab->malloc_cnt, slab->free_cnt);
        return result;
}


// Doesnt currently work if the page being freed came from alloc_pages()
void
free(void *ptr)
{
        dprintf("free(%p)=", ptr);
        if (unlikely(ptr == NULL)) {
                return;
        }

        uint64_t p = (uint64_t)ptr;
        struct slab_header *slab = (struct slab_header *)(p & ~vm_page_mask);
        validate_is_slab(slab);
        dprintf("slab=%p ", slab);
        dprintf("size=%u  ", slab->slab_size);
        size_t offset = (ptr - (void *)slab);
        dprintf("offset=%"PRIu64, offset);
        if (unlikely(offset < 64)) {
                koops("free(%p) offset = %lu", ptr, offset);
        }
        if (unlikely((offset - 64) % slab->slab_size)) {
                koops("free(%p) is not on a valid boundary for slab size of %u (%lx)",
                      ptr, slab->slab_size, offset - 64);
        }
        int bit_idx = (offset-64) / slab->slab_size;
        uint64_t bitmap_mask = (uint64_t)1 << bit_idx;
        dprintf("  bit_idx = %d mask=%"PRIx64, bit_idx, bitmap_mask);
        if (likely(slab->allocation_bm[0] & bitmap_mask)) {
                slab->allocation_bm[0] &= ~bitmap_mask;
                slab->free_cnt++;
                dprintf(" alloc_bm = %"PRIx64 " freecnt=%"PRIu64 " ok\n", slab->allocation_bm[0], slab->free_cnt);
        } else {
                koops("%p is not allocated, alloc=%"PRIx64 " mask = %"PRIx64,
                      ptr, slab->allocation_bm[0], bitmap_mask);
        }
        memset(ptr, 0xAA, slab->slab_size);
}


//UNIMPLEMENTED(malloc_default_zone)

// Doesnt currently work if the page being freed came from alloc_pages()
size_t
malloc_usable_size(void *ptr)
{
        dprintf("%s: %p ", __func__, ptr);
        uint64_t p = (uint64_t)ptr;
        struct slab_header *slab = (struct slab_header *)(p & ~vm_page_mask);
        validate_is_slab(slab);
        dprintf("size = %u\n", slab->slab_size);
        return slab->slab_size;
}


size_t
malloc_size(void *ptr)
{
        return malloc_usable_size(ptr);
}


// Only works for anonoymous mmap (fd == -1), ignore protection settings for now
void *mmap(void *addr, size_t len, int prot, int flags, int fd, unsigned long offset) {
        if (fd != -1) {
                koops("mmap with fd=%d!", fd);
        }

        // round up to page size
        size_t pages = (len + PAGE_SIZE) / PAGE_SIZE;
        void *result = alloc_pages(pages);
        dprintf("mmap=(addr=%p,len=%lX,prot=%X,flags=%X,fd=%d,offset=%lX)=%p\n",
                addr, len, prot, flags, fd, offset, result);

        return result;
}
