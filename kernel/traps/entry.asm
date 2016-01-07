;;; kernel/traps/entry.asm
;;;
;;; Created by Simon Evans on 01/01/2016.
;;; Copyright © 2016 Simon Evans. All rights reserved.
;;;
;;; Entry point for interrupts and exceptions. This file
;;; just contains stubs for the IDT that do some register
;;; saving then call the real handler store in the
;;; trap_dispatch_table

        EXTERN  trap_dispatch_table
        GLOBAL  test_breakpoint


        %macro SAVE_REGS  0

        push    gs
        push    fs
        push    rbp
        push    r15
        push    r14
        push    r13
        push    r12
        push    r11
        push    r10
        push    r9
        push    r8
        push    rdi
        push    rsi
        push    rdx
        push    rcx
        push    rbx
        push    rax
        xor     rax, rax
        mov     ax,ds
        push    rax
        mov     ax, es
        push    rax

        %endmacro


        %macro  RESTORE_REGS  0

        pop     rax
        mov     es, ax
        pop     rax
        mov     ds, ax
        pop     rax
        pop     rbx
        pop     rcx
        pop     rdx
        pop     rsi
        pop     rdi
        pop     r8
        pop     r9
        pop     r10
        pop     r11
        pop     r12
        pop     r13
        pop     r14
        pop     r15
        pop     rbp
        pop     fs
        pop     gs
        add     rsp, 8  ; pop error code

        %endmacro


        ;; For exceptions/faults/irqs without an error code
        %macro  TRAP_STUB 2

        GLOBAL  %2
        ALIGN   16
%2:
        push    qword 0xffff  ; fake error code
        SAVE_REGS
        mov     rax, [trap_dispatch_table + %1 * 8]
        jmp     _run_handler

        %endmacro


        ;; For exceptions with and error code already pushed onto the stack
        %macro  TRAP_STUB_EC 2

        GLOBAL  %2
        ALIGN   16
%2:
        SAVE_REGS
        mov     rax, [trap_dispatch_table + %1 * 8]
        jmp     _run_handler

        %endmacro


        ALIGN   16
_run_handler:
        cld             ; ABI required DF to be cleared
        ;; Align the stack to 16bytes required for ABI
        mov     rdi, rsp
        push    rsp
        push    qword [rsp]
        and     rsp, -16

        ;; Save XMM registers as they are used by Swift 16x 128bit
        sub     rsp, 256
        movaps  [rsp +   0], xmm0
        movaps  [rsp +  16], xmm1
        movaps  [rsp +  32], xmm2
        movaps  [rsp +  48], xmm3
        movaps  [rsp +  64], xmm4
        movaps  [rsp +  80], xmm5
        movaps  [rsp +  96], xmm6
        movaps  [rsp + 112], xmm7
        movaps  [rsp + 128], xmm8
        movaps  [rsp + 144], xmm9
        movaps  [rsp + 160], xmm10
        movaps  [rsp + 176], xmm11
        movaps  [rsp + 192], xmm12
        movaps  [rsp + 208], xmm13
        movaps  [rsp + 224], xmm14
        movaps  [rsp + 240], xmm15

        call    rax

        movaps  xmm0, [rsp + 0]
        movaps  xmm1, [rsp + 16]
        movaps  xmm2, [rsp + 32]
        movaps  xmm3, [rsp + 48]
        movaps  xmm4, [rsp + 64]
        movaps  xmm5, [rsp + 80]
        movaps  xmm6, [rsp + 96]
        movaps  xmm7, [rsp + 112]
        movaps  xmm8, [rsp + 128]
        movaps  xmm9, [rsp + 144]
        movaps  xmm10, [rsp + 160]
        movaps  xmm11, [rsp + 176]
        movaps  xmm12, [rsp + 192]
        movaps  xmm13, [rsp + 208]
        movaps  xmm14, [rsp + 224]
        movaps  xmm15, [rsp + 240]

        add     rsp, 256
        mov     rsp, [rsp+8]

        RESTORE_REGS
        iretq

        TRAP_STUB       0, divide_by_zero_stub
        TRAP_STUB       1, debug_exception_stub
        TRAP_STUB       2, nmi_stub
        TRAP_STUB       3, single_step_stub
        TRAP_STUB       4, overflow_stub
        TRAP_STUB       5, bounds_stub
        TRAP_STUB       6, invalid_opcode_stub
        TRAP_STUB       7, unused_stub
        TRAP_STUB_EC    8, double_fault_stub
        TRAP_STUB_EC    10, invalid_tss_stub
        TRAP_STUB_EC    11, seg_not_present_stub
        TRAP_STUB_EC    12, stack_fault_stub
        TRAP_STUB_EC    13, gpf_stub
        TRAP_STUB_EC    14, page_fault_stub
        TRAP_STUB       16, fpu_fault_stub
        TRAP_STUB_EC    17, alignment_exception_stub
        TRAP_STUB       18, mce_stub
        TRAP_STUB       19, simd_exception_stub


;;; Test function, sets registers to testable patterns
;;; and then calls int 3 (breakpoint)
test_breakpoint:
        push    rbp
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        mov     rax, 0xAAAAAAAAAAAAAAAA
        mov     rbx, 0xBBBBBBBBBBBBBBBB
        mov     rcx, 0xCCCCCCCCCCCCCCCC
        mov     rdx, 0xDDDDDDDDDDDDDDDD
        mov     rdi, 0xD1D1D1D1D1D1D1D1
        mov     rsi, 0x5151515151515151
        mov     r8,  0x0808080808080808
        mov     r9,  0x0909090909090909
        mov     r10, 0x1010101010101010
        mov     r11, 0x1111111111111111
        mov     r12, 0x1212121212121212
        mov     r13, 0x1313131313131313
        mov     r14, 0x1414141414141414
        mov     r15, 0x1515151515151515
        movq    xmm0, rax
        movq    xmm1, rbx
        movq    xmm2, rcx
        movq    xmm3, rdx
        movq    xmm4, rdi
        movq    xmm5, rsi
        movq    xmm6, rbp
        movq    xmm7, rsp
        movq    xmm8, r8
        movq    xmm9, r9
        movq    xmm10, r10
        movq    xmm11, r11
        movq    xmm12, r12
        movq    xmm13, r13
        movq    xmm14, r14
        movq    xmm15, r15

        int     3
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        pop     rbp
        ret
