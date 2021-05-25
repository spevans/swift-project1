;;; kernel/traps/entry.asm
;;;
;;; Created by Simon Evans on 01/01/2016.
;;; Copyright © 2016 Simon Evans. All rights reserved.
;;;
;;; Entry point for interrupts and exceptions. This file
;;; just contains stubs for the IDT that do some register
;;; saving then call the real handler store in the
;;; trap_dispatch_table

        GLOBAL  test_breakpoint
        GLOBAL  read_int_nest_count
        GLOBAL  run_first_task
        GLOBAL  set_interrupt_manager
        EXTERN  trap_dispatch_table
        EXTERN  irqHandler
        EXTERN  apicIntHandler
        EXTERN  getFirstTask
        EXTERN  getNextTask



        ;; For exceptions/faults without an error code
        %macro  TRAP_STUB 2

        GLOBAL  %2
        ALIGN   16
%2:
        push    qword 0xffff  ; fake error code
        SAVE_REGS
        mov     rax, [trap_dispatch_table + %1 * 8]
        jmp     _run_handler

        %endmacro


        ;; For exceptions with an error code already pushed onto the stack
        %macro  TRAP_STUB_EC 2

        GLOBAL  %2
        ALIGN   16
%2:
        SAVE_REGS
        mov     rax, [trap_dispatch_table + %1 * 8]
        jmp     _run_handler

        %endmacro



        ;; For IRQs
        %macro  IRQ_STUB 1
        GLOBAL  irq%1_stub
        ALIGN   8
irq%1_stub:
        push    qword %1        ; set 'error code' as the irq
        jmp     _irq_handler

        %endmacro

        ;; For APIC interrupts - treat as IRQ for now

        %macro  APIC_INT_STUB 1
        GLOBAL  apic_int%1_stub
        ALIGN   8
apic_int%1_stub:
        push    qword %1        ; set 'error code' as the irq
        jmp     _apic_int_handler

        %endmacro


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

        ALIGN   16
_run_handler:
        cld             ; ABI required DF to be cleared
        ALIGN_STACK

        call    rax
        UNALIGN_STACK
        RESTORE_REGS
        add     rsp, 8  ; pop error code
        iretq


        IRQ_STUB        00
        IRQ_STUB        01
        IRQ_STUB        02
        IRQ_STUB        03
        IRQ_STUB        04
        IRQ_STUB        05
        IRQ_STUB        06
        IRQ_STUB        07
        IRQ_STUB        08
        IRQ_STUB        09
        IRQ_STUB        10
        IRQ_STUB        11
        IRQ_STUB        12
        IRQ_STUB        13
        IRQ_STUB        14
        IRQ_STUB        15
        IRQ_STUB        16
        IRQ_STUB        17
        IRQ_STUB        18
        IRQ_STUB        19
        IRQ_STUB        20
        IRQ_STUB        21
        IRQ_STUB        22
        IRQ_STUB        23

        APIC_INT_STUB   0
        APIC_INT_STUB   1
        APIC_INT_STUB   2
        APIC_INT_STUB   3
        APIC_INT_STUB   4
        APIC_INT_STUB   5
        APIC_INT_STUB   6


        ALIGN   8
_irq_handler:
        SAVE_REGS
        cld                     ; ABI requires DF clear and stack 16byte aligned
        ALIGN_STACK
        mov     r12, rsp
        mov     rsi, qword [interrupt_manager]
        lock    inc dword [int_nest_count]
        call    irqHandler
        lock    dec dword [int_nest_count]
        mov     rdi, r12
        call    getNextTask
        mov     rsp, [rax + 8]
        RESTORE_REGS
        add     rsp, 8          ; pop irq ('error code')

        iretq


        ALIGN   8
_apic_int_handler:
        SAVE_REGS
        cld                     ; ABI requires DF clear and stack 16byte aligned
        ALIGN_STACK
        ;; mov     r12, rsp
        ;; mov     rsi, qword [interrupt_manager]
        lock    inc dword [int_nest_count]
        call    apicIntHandler
        lock    dec dword [int_nest_count]

;;;         mov     rsp, r12
        UNALIGN_STACK
        RESTORE_REGS
        add     rsp, 8          ; pop irq ('error code')

        iretq



run_first_task:
        SAVE_REGS
        ALIGN_STACK
        cld
        mov     rdi, rsp
        call    getFirstTask
        mov     rsp, [rax + 8]  ; unalign stack
        RESTORE_REGS
        add     rsp, 8  ; skip error code
        iretq


set_interrupt_manager:
        mov qword [interrupt_manager], rdi
        ret

read_int_nest_count:
        mov eax, [int_nest_count]
        ret


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


        int     3
        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        pop     rbp
        ret

;;; RDI: asciiz msg
bochs_msg:
        ret
        push    rax
.loop:
        lodsb
        test    al, al
        je      .end
        out     0xe9, al
        jmp     .loop
.end:
        pop     rax
        ret


in_irq:         db      `\n*** Entering IRQ ***\n`, 0
out_irq:        db      `\n*** Exiting IRQ ***\n`, 0


        section .data

interrupt_manager:      dq  0
int_nest_count:         dd  0
