/*
 * kernel/mm/malloc.c
 *
 * Copyright © 2015 - 2017 Simon Evans. All rights reserved.
 *
 * Simple memory management for now just enough to provide a simple malloc()
 *
 * Sizes of memory regions supported and number of regions on a page.
 * Uses a 64bit unsigned int to hold an allocation bitmap - wasteful in
 * the case of slabs of size 32 as only half the page is used.
 *
 * The sizes were chosen as they are all aligned to 16bytes and they
 * exactly fill a 4096K page with a 64byte header - except the 32byte one
 * although there is enough space in the header to have a second allocation
 * bitmap for that case.
 *
 * Any allocations over 4032 bytes just get rounded up to a page size and
 * allocated from the free pages.
 *
 * realloc() isnt currently implemented as it is not needed at the moment.
 * No stats have been gathered to optimise this allocator in anyway its just
 * bare minimum to get everything else working. Anyway, the C++ string
 * libraries that use it do their own realloc routing (malloc/free/computing
 * best next size)
 *
 */

#include <stdatomic.h>
#include "klibc.h"
#include "mm.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"


struct slab_block_info {
        uint16_t slab_size;
        uint16_t slab_count;
};


// Should be 64 bytes
struct slab_header {
        uint64_t slab_size;
        uint64_t allocation_bm[2];
        struct slab_header *next;

        /* debug */
        uint64_t malloc_cnt;
        uint64_t free_cnt;
#ifdef MALLOC_DEBUG
        char signature[8];
        uint64_t checksum;
#else
        char padding[16];
#endif
        char data[4032];                // upto a page
} __attribute__((aligned(4096),packed));


struct malloc_region {
        uint64_t region_size;
        uint64_t padding;
        char data[0];
};


// These block sizes are all mutiples of 16 bytes and fit into 4032,
// the space left after the header. Currently only using 1 of the
// 2 allocation bitmaps, hence no 32byte block. Some of these sizes
// waste a few bytes at the end of the block. All blocks returned are
// aligned to 16bytes.
static const struct slab_block_info slab_info[] = {
        { 48, 64 },
        { 64, 63 },
        { 80, 50 },
        { 96, 42 },
        { 112, 36 },
        { 128, 31 },
        { 144, 28 },
        { 160, 25 },
        { 176, 22 },
        { 192, 21 },
        { 208, 19 },
        { 224, 18 },
        { 288, 14 },
        { 304, 13 },
        { 336, 12 },
        { 400, 10 },
        { 448, 9 },
        { 576, 7 },
        { 672, 6 },
        { 800, 5 },
        { 1008, 4 },
        { 1344, 3 },
        { 2016, 2 },
        { 4032, 1 },
};

static atomic_int malloc_lock;
// List of pages that have free slabs on them, 1 list per slab size
#define SLAB_SIZES (sizeof(slab_info) / sizeof(struct slab_block_info))
static struct slab_header *slabs[SLAB_SIZES];
static const int MAX_SLAB_SIZE = 4032;        // Anything over this gets pages


#ifdef MALLOC_DEBUG
static uint64_t
compute_checksum(struct slab_header *slab)
{
        uint64_t *fields = (uint64_t *)slab;
        uint64_t checksum = 0;
        for (size_t i = 0; i < 7; i++) {
                checksum ^= fields[i];
        }
        return checksum;
}
#endif


static void
update_checksum(struct slab_header *slab)
{
#ifdef MALLOC_DEBUG
        slab->checksum = compute_checksum(slab);
#endif
}


// Convert a page into a slab
static struct slab_header *
add_new_slab(int slab_idx)
{
        struct slab_header *slab = alloc_pages(1);
        slab->slab_size = slab_info[slab_idx].slab_size;
        slab->allocation_bm[0] = 0;
        slab->allocation_bm[1] = 0;
        slab->next = slabs[slab_idx];
#ifdef MALLOC_DEBUG
        strcpy(slab->signature, "MALLOC");      // for debugging
        update_checksum(slab);
#endif
        slabs[slab_idx] = slab;

        return slab;
}


void
init_mm()
{
        atomic_init(&malloc_lock, 0);
}


// Debugging for now, wouldnt work normally as text could be there for other reasons
static void
validate_is_slab(struct slab_header *slab)
{
#ifdef MALLOC_DEBUG
        if (strcmp(slab->signature, "MALLOC")) {
                koops("slab @ %p is not a slab!", slab);
        }
        if (compute_checksum(slab) != slab->checksum) {
                koops("slab @ %p has invalid checksum!", slab);
        }
#endif
}


static int
region_is_slab(struct slab_header *region)
{
        return (region->slab_size <= MAX_SLAB_SIZE);
}


static inline int
map_size_to_idx(size_t size)
{
        for (size_t i = 0; i < SLAB_SIZES; i++) {
                if (size <= slab_info[i].slab_size) {
                        return i;
                }
        }
        koops("map_size_to_idx: bad size %lu\n", size);
}


// Mask of bits used in the allocation bitmap
static inline uint64_t
bitmap_mask(int slab_idx)
{
        uint64_t count = (uint64_t)slab_info[slab_idx].slab_count;
        if (count == 64) {
                return UINT64_MAX;
        }
        uint64_t mask = 1;
        uint64_t result = (mask << count) - 1;

        return result;
}


void *
malloc(size_t size)
{
        void *retval = NULL;
        //debugf("malloc(%lu): ", size);
        if (sizeof(struct slab_header) != PAGE_SIZE) {
                koops("slab_header is %lu bytes", sizeof(struct slab_header));
        }
        if (read_int_nest_count() > 0) {
                koops("malloc called in interrupt handler");
        }

        if (size > (UINT32_MAX - sizeof(struct malloc_region))) {
                koops("Trying to allocate %lu bytes!", size);
        }
        uint64_t flags = local_irq_save();
        if (atomic_fetch_add(&malloc_lock, 1) != 0) {
                koops("(malloc)malloc_lock != 0");
        }

        if (size > MAX_SLAB_SIZE) {
                size_t pages = (sizeof(struct malloc_region) + size + PAGE_MASK) / PAGE_SIZE;
                struct malloc_region *result = alloc_pages(pages);
                result->region_size = (pages * PAGE_SIZE) - sizeof(struct malloc_region);
                debugf("Wanted %lu got %u\n", size, result->region_size);
                retval = result->data;
        } else {
                int slab_idx = map_size_to_idx(size);
                struct slab_header *slab = slabs[slab_idx];
                int freebit;
                if (!slab) {
                        slab = add_new_slab(slab_idx);
                        freebit = 0;
                } else {
                        validate_is_slab(slab);
                        uint64_t allocation_mask = bitmap_mask(slab_idx);
                        uint64_t free_bits = slab->allocation_bm[0] ^ allocation_mask;
                        freebit = __builtin_ffsl(free_bits);

                        if (unlikely(freebit == 0)) {
                                slab = add_new_slab(slab_idx);
                        } else {
                                freebit--;
                        }
                }
                size_t offset = freebit * slab_info[slab_idx].slab_size;
                retval = &slab->data[offset];

                uint64_t free_mask = (uint64_t)1 << freebit;
                slab->allocation_bm[0] |= free_mask;
                slab->malloc_cnt++;
                update_checksum(slab);
                debugf("malloc(%lu)=%p slab=%p offset=%lx [%"PRIu64 "/%"PRIu64"]\n",
                       size, retval, slab, offset, slab->malloc_cnt, slab->free_cnt);
        }
        if (atomic_fetch_sub(&malloc_lock, 1) != 1) {
                koops("(malloc)malloc_lock != 1");
        }
        load_eflags(flags);
        return retval;
}


void
free(void *ptr)
{
        debugf("free(%p)=", ptr);
        if (unlikely(ptr == NULL)) {
                return;
        }
        if (read_int_nest_count() > 0) {
                koops("malloc called in interrupt handler");
        }

        uint64_t flags = local_irq_save();
        if (atomic_fetch_add(&malloc_lock, 1) != 0) {
                koops("(free)malloc_lock != 0");
        }

        uint64_t p = (uint64_t)ptr;
        struct slab_header *slab = (struct slab_header *)(p & ~PAGE_MASK);
        if (!region_is_slab(slab)) {
                size_t pages = (slab->slab_size + sizeof(struct malloc_region)) / PAGE_SIZE;
                free_pages(slab, pages);
        } else {
                validate_is_slab(slab);
                debugf("slab=%p ", slab);
                debugf("cs=%"PRIx64 "\n", slab->checksum);
                debugf("size=%u  ", slab->slab_size);
                size_t offset = (ptr - (void *)slab);
                debugf("offset=%"PRIu64, offset);
                if (unlikely(offset < 64)) {
                        koops("free(%p) offset = %lu", ptr, offset);
                }
                if (unlikely((offset - 64) % slab->slab_size)) {
                        koops("free(%p) is not on a valid boundary for slab size of %lu (%lx)",
                              ptr, slab->slab_size, offset - 64);
                }
                int bit_idx = (offset-64) / slab->slab_size;
                uint64_t bitmap_mask = (uint64_t)1 << bit_idx;
                debugf("  bit_idx = %d mask=%"PRIx64"\n", bit_idx, bitmap_mask);
                if (likely(slab->allocation_bm[0] & bitmap_mask)) {
                        slab->allocation_bm[0] &= ~bitmap_mask;
                        slab->free_cnt++;
                        debugf(" alloc_bm = %"PRIx64 " freecnt=%"PRIu64 " ",
                               slab->allocation_bm[0], slab->free_cnt);
                } else {
                        koops("%p is not allocated, alloc=%"PRIx64 " mask = %"PRIx64,
                              ptr, slab->allocation_bm[0], bitmap_mask);
                }
#ifdef MALLOC_DEBUG
                memset(ptr, 0xAA, slab->slab_size);
#endif
                update_checksum(slab);
                debugf("\ncs=%"PRIx64 "\n", slab->checksum);
        }
        if (atomic_fetch_sub(&malloc_lock, 1) != 1) {
                koops("(free)malloc_lock != 1");
        }
        load_eflags(flags);
}


size_t
malloc_usable_size(const void *ptr)
{
        size_t retval = 0;

        if (read_int_nest_count() > 0) {
                koops("malloc called in interrupt handler");
        }
        if (ptr == NULL) {
                return 0;
        }

        uint64_t flags = local_irq_save();
        if (atomic_fetch_add(&malloc_lock, 1) != 0) {
                koops("(usable_size)malloc_lock != 0");
        }

        debugf("%s(%p)=", __func__, ptr);
        uint64_t p = (uint64_t)ptr;
        struct slab_header *slab = (struct slab_header *)(p & ~PAGE_MASK);
        if (region_is_slab(slab)) {
                validate_is_slab(slab);
                retval = slab->slab_size;
        } else {
                struct malloc_region *region = (struct malloc_region *)slab;
                retval = region->region_size;
        }
        debugf("malloc_usable_size(%p) = %lu\n", ptr, retval);
        if (atomic_fetch_sub(&malloc_lock, 1) != 1) {
                koops("(usable_size)malloc_lock != 1");
        }

        load_eflags(flags);
        return retval;
}
