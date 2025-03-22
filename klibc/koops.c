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
#include "swift.h"


extern void *_kernel_stack;
extern void *_stack_start;
static const int max_depth = 128;

// Simple function that can be used as a debugger breakpoint.
__attribute__((noinline))
void debugger_hook()
{
  asm volatile ("rdtsc" : : : "memory");
}


void
koops(const char *fmt, ...)
{
        va_list args;
        va_start(args, fmt);
        kvprintf(fmt, args);
        kprintf("\n");
        va_end(args);
        stack_trace(getRSP(), getRBP());
        debugger_hook();
        stop();
}


// Both backtrace() and stack_trace() require the kernel, kstdlib and
// Swift runtime are compiled with "-fno-omit-frame-pointer" and
// "-mno-omit-leaf-frame-pointer" so that the stack frame is preserved
// and stored in RBP.

int
backtrace(void **buffer, int size)
{
        if (buffer == NULL || size == 0) {
                return 0;
        }

        int count = 0;
        void **rbp_ptr = (void **)getRBP();
        while (count < size &&
               (uintptr_t)rbp_ptr > (uintptr_t)&_stack_start
               && (uintptr_t)rbp_ptr < (uintptr_t)&_kernel_stack) {
                *buffer = *(rbp_ptr + 1);
                rbp_ptr = *rbp_ptr;
                count++;
                buffer++;
        }
        return count;
}


// Simple stack backtrace using rbp to walk the stack
// Needs an update for eh_frame at some point. Called from the exception
// handlers.
void
stack_trace(uintptr_t rsp, uintptr_t rbp)
{
        kprintf("stack_trace: RSP: %16.16lx RBP: %16.16lx\n", rsp, rbp);
    return;
        if (rsp == 0) {
                return;
        }
        uint64_t *rsp_ptr = (uint64_t *)rsp;
        kprintf("RSP-24: %lx = %16.16lx\n", rsp-24, *(rsp_ptr-3));
        kprintf("RSP-16: %lx = %16.16lx\n", rsp-16, *(rsp_ptr-2));
        kprintf("RSP-08: %lx = %16.16lx\n", rsp-8, *(rsp_ptr-1));
        kprintf("RSP+00: %lx = %16.16lx\n", rsp, *rsp_ptr);
        kprintf("RSP+08: %lx = %16.16lx\n", rsp+8, *(rsp_ptr+1));
        kprintf("RSP+16: %lx = %16.16lx\n", rsp+16, *(rsp_ptr+2));
        kprintf("RSP+24: %lx = %16.16lx\n", rsp+24, *(rsp_ptr+3));

        if (rbp == 0) {
                kprintf("Frame pointer is NULL\n");
                return;
        }
        void **rbp_ptr = (void **)rbp;
        size_t idx = 0;

        kprintf("rbp_ptr = %p _kernel_stack = %p\n", rbp_ptr, &_kernel_stack);
        return;
        while ((uintptr_t)rbp_ptr > (uintptr_t)&_stack_start
               && (uintptr_t)rbp_ptr < (uintptr_t)&_kernel_stack) {
                if (rbp_ptr == NULL) {
                        kprintf("Frame pointer is NULL\n");
                        return;
                }
                Dl_info info;
                void *ret_addr = *(rbp_ptr+1);
                if (dladdr(ret_addr, &info)) {
                    kprintf("[%p]: %p ret=%s +%lx\n", ret_addr, *(rbp_ptr+1),
                            info.dli_sname,
                            (uintptr_t)ret_addr - (uintptr_t)info.dli_saddr);
                } else {
                    kprintf("[%p]: %p ret=<unavailable>\n", rbp_ptr, ret_addr);
                }
                rbp_ptr = *rbp_ptr;
                idx += 1;
                if (idx >= max_depth) {
                        // temporary safety check
                        kprintf("Exceeded depth of %d\n", max_depth);
                        debugger_hook();
                }
        }
}


void
dump_registers(struct exception_regs *registers)
{
        serial_printf("RAX: %16.16lx ", registers->rax);
        serial_printf("RBX: %16.16lx ", registers->rbx);
        serial_printf("RCX: %16.16lx\n", registers->rcx);
        serial_printf("RDX: %16.16lx ", registers->rdx);
        serial_printf("RSI: %16.16lx ", registers->rsi);
        serial_printf("RDI: %16.16lx\n", registers->rdi);
        serial_printf("RBP: %16.16lx ", registers->rbp);
        serial_printf("RSP: %16.16lx ", registers->rsp);
        serial_printf("RIP: %16.16lx\n", registers->rip);
        serial_printf("R8 : %16.16lx ", registers->r8);
        serial_printf("R9 : %16.16lx ", registers->r9);
        serial_printf("R10: %16.16lx\n", registers->r10);
        serial_printf("R11: %16.16lx ", registers->r11);
        serial_printf("R12: %16.16lx ", registers->r12);
        serial_printf("R13: %16.16lx\n", registers->r13);
        serial_printf("R14: %16.16lx ", registers->r14);
        serial_printf("R15: %16.16lx ", registers->r15);
        serial_printf("CR2: %16.16lx\n", getCR2());
        serial_printf("CS: %lx DS: %lx ES: %lx FS: %lx GS:%lx SS: %lx\n",
                registers->cs, registers->ds, registers->es,
                registers->fs, registers->gs, registers->ss);
}
