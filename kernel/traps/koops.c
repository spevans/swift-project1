#include <stdint.h>
#include "klibc.h"
#include "x86defs.h"


extern void *_kernel_stack;

// Simple stack backtrace using rbp to walk the stack
// Needs an update for eh_frame at some point
void
stack_trace(uintptr_t rsp, uintptr_t rbp)
{
        void **rsp_ptr = (void *)rsp;
        //let rsp_ptr = UnsafePointer<UInt>(bitPattern: UInt(rsp))
        kprintf("RSP: %lx = %p\n", rsp, *rsp_ptr);

        //uintptr_t rbp_addr = rbp;
        void **rbp_ptr = (void **)rbp;
        size_t idx = 0;

        while ((uintptr_t)rbp_ptr < (uintptr_t)_kernel_stack) {
                if (rbp_ptr == NULL) {
                        return;
                }
                kprintf("[%p]: %p ret=%p\n", rbp_ptr, *rbp_ptr, *(rbp_ptr+1));
                rbp_ptr = *rbp_ptr;
                idx += 1;
                if (idx > 10) {
                        // temporary safety check
                        kprintf("Exceeded depth of 10");
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
        stack_trace(registers->rsp, registers->rbp);
}
