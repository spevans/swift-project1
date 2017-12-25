/*
 * klibc/koops.c
 *
 * Created by Simon Evans on 15/01/2016.
 * Copyright © 2016 - 2017 Simon Evans. All rights reserved.
 *
 * koops() and related stack dumping functions for kernel panics.
 *
 */

#include <stdint.h>
#include "klibc.h"
#include "x86defs.h"


extern void *_kernel_stack;
static const int max_depth = 40;


void
koops(const char *fmt, ...)
{
        va_list args;
        va_start(args, fmt);
        kvprintf(fmt, args);
        kprintf("\n");
        va_end(args);
        __builtin_trap();
}


// Simple stack backtrace using rbp to walk the stack
// Needs an update for eh_frame at some point
void
stack_trace(uintptr_t rsp, uintptr_t rbp)
{
        kprintf("stack_trace: RSP: %16.16lx RBP: %16.16lx\n", rsp, rbp);
        if (rsp == 0) {
                return;
        }
        //void **rsp_ptr = (void *)rsp;
        uint64_t *rsp_ptr = (uint64_t *)rsp;
        //let rsp_ptr = UnsafePointer<UInt>(bitPattern: UInt(rsp))
        kprintf("RSP-24: %lx = %16.16lx\n", rsp-24, *(rsp_ptr-3));
        kprintf("RSP-16: %lx = %16.16lx\n", rsp-16, *(rsp_ptr-2));
        kprintf("RSP-08: %lx = %16.16lx\n", rsp-8, *(rsp_ptr-1));
        kprintf("RSP+00: %lx = %16.16lx\n", rsp, *rsp_ptr);
        kprintf("RSP+08: %lx = %16.16lx\n", rsp+8, *(rsp_ptr+1));
        kprintf("RSP+16: %lx = %16.16lx\n", rsp+16, *(rsp_ptr+2));
        kprintf("RSP+24: %lx = %16.16lx\n", rsp+24, *(rsp_ptr+3));

        //uintptr_t rbp_addr = rbp;
        if (rbp == 0) {
                kprintf("Frame pointer is NULL\n");
                return;
        }
        void **rbp_ptr = (void **)rbp;
        size_t idx = 0;

        kprintf("rbp_ptr = %p _kernel_stack = %p\n", rbp_ptr, &_kernel_stack);
        while ((uintptr_t)rbp_ptr < (uintptr_t)&_kernel_stack) {
                if (rbp_ptr == NULL) {
                        kprintf("Frame pointer is NULL\n");
                        return;
                }
                kprintf("[%p]: %p ret=%p\n", rbp_ptr, *rbp_ptr, *(rbp_ptr+1));
                rbp_ptr = *rbp_ptr;
                idx += 1;
                if (idx >= max_depth) {
                        // temporary safety check
                        kprintf("Exceeded depth of %d\n", max_depth);
                        return;
                }
        }
}


void
dump_registers(struct exception_regs *registers)
{
        kprintf("RAX: %16.16lx ", registers->rax);
        kprintf("RBX: %16.16lx ", registers->rbx);
        kprintf("RCX: %16.16lx\n", registers->rcx);
        kprintf("RDX: %16.16lx ", registers->rdx);
        kprintf("RSI: %16.16lx ", registers->rsi);
        kprintf("RDI: %16.16lx\n", registers->rdi);
        kprintf("RBP: %16.16lx ", registers->rbp);
        kprintf("RSP: %16.16lx ", registers->rsp);
        kprintf("RIP: %16.16lx\n", registers->rip);
        kprintf("R8 : %16.16lx ", registers->r8);
        kprintf("R9 : %16.16lx ", registers->r9);
        kprintf("R10: %16.16lx\n", registers->r10);
        kprintf("R11: %16.16lx ", registers->r11);
        kprintf("R12: %16.16lx ", registers->r12);
        kprintf("R13: %16.16lx\n", registers->r13);
        kprintf("R14: %16.16lx ", registers->r14);
        kprintf("R15: %16.16lx ", registers->r15);
        kprintf("CR2: %16.16lx\n", getCR2());
        kprintf("CS: %lx DS: %lx ES: %lx FS: %lx GS:%lx SS: %lx\n",
                registers->cs, registers->ds, registers->es,
                registers->fs, registers->gs, registers->ss);
}
