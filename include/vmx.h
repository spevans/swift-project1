/*
 * include/x86funcs.h
 *
 * Created by Simon Evans on 01/07/2019.
 * Copyright © 2019 Simon Evans. All rights reserved.
 *
 * Header file for x86 specific instructions. Most functions are one
 * instruction and by making them static inline Swift will include them
 * directly into the output making them inline assembly
 *
 * VMX instruction wrappers.
 *
 */

#include <stdint.h>


static inline uint64_t
vmxon(const uint64_t region) //const void * _Nonnull region)
{
        uint64_t res;
        asm volatile ("vmxon (%1)\n\t"
                      "pushf\n\t"
                      "popq %0\n\t"
                      "andq $0x41, %0\n\t"
                      : "=r" (res)
                      : "r"(&region), "m"(region)
                      : "memory", "cc");
        return res;
}


static inline uint64_t
vmxoff()
{
        uint64_t res;
        asm volatile ("vmxoff\n\t"
                      "pushf\n\t"
                      "popq %0\n\t"
                      "andq $0x41, %0\n\t"
                      : "=r" (res)
                      :
                      : "cc");
        return res;
}


static inline uint64_t
vmclear(const uint64_t region)
{
        uint64_t res;
        asm volatile ("vmclear (%1)\n\t"
                      "pushf\n\t"
                      "popq %0\n\t"
                      "andq $0x41, %0\n\t"
                      : "=r" (res)
                      : "r"(&region), "m"(region)
                      : "memory", "cc");
        return res;
}


static inline uint64_t
vmptrld(const uint64_t region)
{
        uint64_t res;
        asm volatile ("vmptrld (%1)\n\t"
                      "pushf\n\t"
                      "popq %0\n\t"
                      "andq $0x41, %0\n\t"
                      : "=r" (res)
                      : "r"(&region), "m"(region)
                      : "memory", "cc");
        return res;
}


static inline uint64_t
vmread(const uint32_t index, uint64_t * const _Nonnull result)
{
        uint64_t res;
        uint64_t data;
        asm volatile ("vmread %2, %1\n\t"
                      "pushf\n\t"
                      "popq %0\n\t"
                      "andq $0x41, %0\n\t"
                      : "=r" (res), "=a" (data)
                      : "d" ((uint64_t)index)
                      : "memory", "cc");
        *result = data;
        return res;
}


static inline uint64_t
vmwrite(const uint32_t index, uint64_t data)
{
        uint64_t res;
        asm volatile ("vmwrite %2, %1\n\t"
                      "pushf\n\t"
                      "popq %0\n\t"
                      "andq $0x41, %0\n\t"
                      : "=r" (res)
                      : "a" (data), "d" ((uint64_t)index)
                      : "memory", "cc");
        return res;
}


static inline uint64_t
vmlaunch()
{
        uint64_t res;
        asm volatile ("vmlaunch\n\t"
                      "pushf\n\t"
                      "popq %0\n\t"
                      "andq $0x41, %0\n\t"
                      : "=r" (res)
                      :
                      : "memory", "cc");
        return res;
}


static inline uint64_t
vmresume()
{
        uint64_t res;
        asm volatile ("vmresume\n\t"
                      "pushf\n\t"
                      "popq %0\n\t"
                      "andq $0x41, %0\n\t"
                      : "=r" (res)
                      :
                      : "memory", "cc");
        return res;
}
