/*
 * klibc/malloc.c
 *
 * Copyright © 2015 - 2018 Simon Evans. All rights reserved.
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
 * No stats have been gathered to optimise this allocator in anyway its just
 * bare minimum to get everything else working. Anyway, the C++ string
 * libraries that use it do their own realloc routing (malloc/free/computing
 * best next size).
 *
 */

#define DEBUG 0
#include <stdatomic.h>
#include <assert.h>
#include "klibc.h"
#include "mm.h"

//#define MALLOC_DEBUG

#pragma GCC diagnostic ignored "-Wunused-parameter"


struct slab_block_info {
        uint16_t slab_size;
        uint16_t slab_count;
};


// Should be 64 bytes
struct slab_header {
        uint64_t slab_size;
        // Bits in bitmap are 0=allocated 1=free
        uint64_t allocation_bm[2];
        struct slab_header *next;
        struct slab_header *prev;

        /* debug */
        uint32_t malloc_cnt;
        uint32_t free_cnt;
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
        { 32, 126 },
        { 48, 84  },
        { 64, 63  },
        { 96, 42  },
        { 112, 36 },
        { 144, 28 },
        { 192, 21 },
        { 224, 18 },
        { 288, 14 },
        { 336, 12 },
        { 448, 9 },
        { 576, 7 },
        { 672, 6 },
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

static void
dump_header(struct slab_header *slab)
{
        kprintf("Slab header @ %p\n", slab);
        kprintf("slab_size: %lu\n", slab->slab_size);
        if (slab->slab_size > MAX_SLAB_SIZE) {
                return;
        }
        kprintf("allocation_bm[0]: %016lx\n", slab->allocation_bm[0]);
        kprintf("allocation_bm[1]: %016lx\n", slab->allocation_bm[1]);
        kprintf("next: %p prev: %p malloc_cnt: %u, free_cnt: %u\n",
                slab->next, slab->prev, slab->malloc_cnt, slab->free_cnt);
        char sig_tmp[9];
        memcpy(sig_tmp, slab->signature, 8);
        sig_tmp[8] = '\0';
        kprintf("signature: %s\n", sig_tmp);
        kprintf("checksum: %016lx\n", slab->checksum);
        kprintf("computed: %016lx\n", compute_checksum(slab));
}
#endif


static void
update_checksum(struct slab_header *slab)
{
#ifdef MALLOC_DEBUG
        slab->checksum = compute_checksum(slab);
#endif
}


// Mask of bits used in the allocation bitmap
static inline uint64_t
bitmap_mask(int count)
{
        assert(count >= 0 && count <= 64);
        if (count == 64) {
                return UINT64_MAX;
        }
        uint64_t mask = 1;
        uint64_t result = (mask << count) - 1;

        return result;
}


static inline void
set_bitmap_mask(struct slab_header *slab, int slab_idx)
{
        assert(slab_idx >= 0);
        assert(slab_idx < (int)SLAB_SIZES);
        int count = slab_info[slab_idx].slab_count;
        int lo_count = (count < 64) ? count : 64;
        int hi_count = (count > 64) ? count - 64 : 0;
        slab->allocation_bm[0] = bitmap_mask(lo_count);
        slab->allocation_bm[1] = bitmap_mask(hi_count);
}


static inline void
set_bitmap_entry(struct slab_header *slab, int bit_idx)
{
        assert(bit_idx < 128);
        int idx = bit_idx / 64;
        int bit = bit_idx % 64;
        uint64_t mask = 1 << bit;
        debugf("set_bitmap_entry: bit_idx=%d idx=%d bit=%d bm: %16.16lx %16.16lx mask: %"PRIx64 "\n",
               bit_idx, idx, bit, slab->allocation_bm[1],
               slab->allocation_bm[0], mask);
        slab->allocation_bm[idx] |= mask;
        debugf("set_bitmap_entry: bm[0]=%"PRIx64 " bm[1]=%"PRIx64 "\n",
               slab->allocation_bm[0], slab->allocation_bm[1]);
}


static inline void
clear_bitmap_entry(struct slab_header *slab, int bit_idx)
{
        assert(bit_idx < 128);
        int idx = bit_idx / 64;
        int bit = bit_idx % 64;
        uint64_t mask = 1 << bit;
        debugf("clear_bitmap_entry: bit_idx=%d idx=%d bit=%d bm: %16.16lx %16.16lx mask: %"PRIx64 "\n",
               bit_idx, idx, bit, slab->allocation_bm[1],
               slab->allocation_bm[0], mask);
        slab->allocation_bm[idx] &= ~mask;

        debugf("clear_bitmap_entry: bm[0]=%"PRIx64 " bm[1]=%"PRIx64 "\n",
               slab->allocation_bm[0], slab->allocation_bm[1]);
}


static inline int
test_bitmap_entry(struct slab_header *slab, int bit_idx)
{
        assert(bit_idx < 128);
        int idx = bit_idx / 64;
        int bit = bit_idx % 64;
        uint64_t mask = 1 << bit;
        return (slab->allocation_bm[idx] & mask) != 0;
}


// Returns bit_idx (0-127) of lowest bit that is set, -1 if none found
static int
find_lowest_bit(struct slab_header *slab, int slab_idx)
{
        assert(slab_idx >= 0);
        assert(slab_idx < (int)SLAB_SIZES);
        int count = slab_info[slab_idx].slab_count;
        assert(count > 0);
        assert(count < 128);
        int lo_count = (count < 64) ? count : 64;
        int hi_count = (count > 64) ? count - 64 : 0;

        debugf("find_lowest_bit: slab=%p bm=%16.16lx %16.16lx count=%d lo=%d hi=%d\n",
               slab, slab->allocation_bm[1], slab->allocation_bm[0],
               count, lo_count, hi_count);

        int freebit = __builtin_ffsl(slab->allocation_bm[0]);
        if (freebit == 0 && hi_count > 0) {
                freebit = __builtin_ffsl(slab->allocation_bm[1]);
                if (freebit == 0) {
                        return -1;
                }
                assert(freebit < hi_count+1);
                freebit += 63;
        } else {
                freebit--;
                assert(freebit < lo_count);
        }
        assert(freebit >= -1 && freebit < 128);
        debugf("find_lowest_bit: slab=%p bm=%16.16lx %16.16lx freebit=%d\n",
               slab, slab->allocation_bm[1], slab->allocation_bm[0], freebit);
        return freebit;
}



// Convert a page into a slab
static struct slab_header *
add_new_slab(int slab_idx)
{
        struct slab_header *slab = alloc_pages(1);
        slab->slab_size = slab_info[slab_idx].slab_size;
        set_bitmap_mask(slab, slab_idx);
        slab->prev = NULL;
        struct slab_header *current_head = slabs[slab_idx];
        slab->next = current_head;
        if (current_head) {
                current_head->prev = slab;
                update_checksum(current_head);
        }
        slabs[slab_idx] = slab;

        slab->malloc_cnt = 0;
        slab->free_cnt = 0;
#ifdef MALLOC_DEBUG
        strcpy(slab->signature, "#MALLOC");      // for debugging
        update_checksum(slab);
        dump_header(slab);
#endif
        return slab;
}


void
init_mm()
{
        atomic_init(&malloc_lock, 0);
}


// Debugging for now, wouldnt work normally as text could be there for other reasons
static void
validate_is_slab(const char *caller, struct slab_header *slab, uintptr_t arg)
{
#ifdef MALLOC_DEBUG
        if (memcmp(slab->signature, "#MALLOC", 8)) {
                dump_header(slab);
                koops("%s(%#lx): slab @ %p is not a slab!", caller, arg, slab);
        }
        if (compute_checksum(slab) != slab->checksum) {
                dump_header(slab);
                koops("%s(%#lx): slab @ %p has invalid checksum!", caller, arg, slab);
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


void *
malloc(size_t size)
{
        void *retval = NULL;
        debugf("malloc(%ld)\n", size);
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
                debugf("Wanted %lu got %lu\n", size, result->region_size);
                retval = result->data;
                memset(retval, 0x0, result->region_size);
        } else {
                int slab_idx = map_size_to_idx(size);
                struct slab_header *slab = slabs[slab_idx];
                int freebit;
                if (!slab) {
                        slab = add_new_slab(slab_idx);
                        freebit = 0;
                } else {
                        validate_is_slab(__func__, slab, (uintptr_t)size);
                        freebit = find_lowest_bit(slab, slab_idx);
                        if (unlikely(freebit == -1)) {
                                slab = add_new_slab(slab_idx);
                                freebit = 0;
                        }
                }
                assert(freebit >= 0 && freebit < 128);
                size_t offset = freebit * slab_info[slab_idx].slab_size;
                debugf("malloc(%lu) slab=%p offset=%lx freebit=%d bm=%16.16lx %16.16lx\n",
                       size, slab, offset, freebit, slab->allocation_bm[1], slab->allocation_bm[0]);
                retval = &slab->data[offset];
                clear_bitmap_entry(slab, freebit);
                slab->malloc_cnt++;
                update_checksum(slab);
                memset(retval, 0xAA, slab->slab_size);
                debugf("malloc(%lu)=%p slab=%p offset=%lx [%u/%u] freebit=%d bm=%16.16lx %16.16lx\n",
                       size, retval, slab, offset, slab->malloc_cnt, slab->free_cnt, freebit,
                       slab->allocation_bm[1], slab->allocation_bm[0]);
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
                validate_is_slab(__func__, slab, (uintptr_t)ptr);
                size_t offset = (ptr - (void *)slab);
                debugf("slab=%p size=%lu  offset=%"PRIu64 "\n", slab, slab->slab_size, offset);
                if (unlikely(offset < 64)) {
                        koops("free(%p) offset = %lu", ptr, offset);
                }
                if (unlikely((offset - 64) % slab->slab_size)) {
                        koops("free(%p) is not on a valid boundary for slab size of %lu (%lx)",
                              ptr, slab->slab_size, offset - 64);
                }
                int bit_idx = (offset-64) / slab->slab_size;
                debugf("  bit_idx = %d bm=%16.16lx %16.16lx\n", bit_idx,
                       slab->allocation_bm[1], slab->allocation_bm[0]);
                if (likely(test_bitmap_entry(slab, bit_idx) == 0)) {
                        set_bitmap_entry(slab, bit_idx);
                        slab->free_cnt++;
                } else {
                        koops("%p is not allocated, alloc=%"PRIx64 "\n",
                              ptr, slab->allocation_bm[0]);
                }
#ifdef MALLOC_DEBUG
                memset(ptr, 0xAA, slab->slab_size);
                update_checksum(slab);
                debugf("\ncs=%"PRIx64 "\n", slab->checksum);
#else
                debugf("\n");
#endif
        }
        if (atomic_fetch_sub(&malloc_lock, 1) != 1) {
                koops("(free)malloc_lock != 1");
        }
        load_eflags(flags);
}


size_t
malloc_usable_size(void * _Nullable ptr)
{
        size_t retval = 0;

        if (read_int_nest_count() > 0) {
                koops("malloc_usable_size called in interrupt handler");
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
                validate_is_slab(__func__, slab, (uintptr_t)ptr);
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


void *
realloc(void *ptr, size_t size)
{
        if (ptr == NULL) {
                return malloc(size);
        }
        if (size == 0) {
                free(ptr);
                return NULL;
        }
        size_t current_size = malloc_usable_size(ptr);
        if (size <= current_size) {
                return ptr;
        }
        void *new = malloc(size);
        memcpy(new, ptr, current_size);
        return new;
}


int
posix_memalign(void **memptr, size_t alignment, size_t size)
{
        void *mem = malloc(size);
        *memptr = mem;
        return 0;
}
