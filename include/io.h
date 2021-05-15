/*
 * include/io.h
 *
 * Created by Simon Evans on 18/04/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * Functions to deal with MMIO where memory operations should
 *  not be reordered by the compiler.
 */


#ifndef __IO_H__
#define __IO_H__

#include <stdint.h>

// Stop the compiler from reording memory access.
#define barrier() __asm__ __volatile__("": : :"memory")


static inline uint8_t
mmio_read_uint8(const volatile void *address) {
        barrier();
        uint8_t value = *(const volatile uint8_t *)address;
        barrier();
        return value;
}

static inline void
mmio_write_uint8(volatile void *address, uint8_t value) {
        barrier();
        *(volatile uint8_t *)address = value;
        barrier();
}

static inline uint16_t
mmio_read_uint16(const volatile void *address) {
        barrier();
        uint16_t value = *(const volatile uint16_t *)address;
        barrier();
        return value;
}

static inline void
mmio_write_uint16(volatile void *address, uint16_t value) {
        barrier();
        *(volatile uint16_t *)address = value;
        barrier();
}

static inline uint32_t
mmio_read_uint32(const volatile void *address) {
        barrier();
        uint32_t value = *(const volatile uint32_t *)address;
        barrier();
        return value;
}

static inline void
mmio_write_uint32(volatile void *address, uint32_t value) {
        barrier();
        *(volatile uint32_t *)address = value;
        barrier();
}

static inline uint64_t
mmio_read_uint64(const volatile void *address) {
        barrier();
        uint64_t value = *(const volatile uint64_t *)address;
        barrier();
        return value;
}

static inline void
mmio_write_uint64(volatile void *address, uint64_t value) {
        barrier();
        *(volatile uint64_t *)address = value;
        barrier();
}


static inline void
memoryBarrier() {
    asm volatile("mfence" : : : "memory");
}

static inline void
readMemoryBarrier() {
    asm volatile("lfence" : : : "memory");
}

static inline void
writeMemoryBarrier() {
    asm volatile("sfence" : : : "memory");
}


#endif // __IO_H__
