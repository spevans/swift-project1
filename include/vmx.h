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


struct vcpu_info {
        uint8_t     launched;
        uint8_t     vmexit_status;
        uint8_t     padding[6];
        // Guest registers
        uint64_t    rax;
        uint64_t    rbx;
        uint64_t    rcx;
        uint64_t    rdx;
        uint64_t    rdi;
        uint64_t    rsi;
        uint64_t    rbp;
        uint64_t    r8;
        uint64_t    r9;
        uint64_t    r10;
        uint64_t    r11;
        uint64_t    r12;
        uint64_t    r13;
        uint64_t    r14;
        uint64_t    r15;
} __attribute__((packed));


int
vmentry(struct vcpu_info * _Nonnull info);

void
vmreturn(void);


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
        asm volatile ("vmwrite %1, %2\n\t"
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
