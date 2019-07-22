;;; kernel/vm/vmentry.asm
;;;
;;; Created by Simon Evans on 20/07/2019.
;;; Copyright © 2019 Simon Evans. All rights reserved.
;;;
;;; Entry point for calling vmlaunch, vmentry and vmexit


        BITS 64

        DEFAULT REL
        SECTION .text

        global  vmentry
        global  vmreturn


        LAUNCHED        EQU 0
        VMEXIT_STATUS   EQU 1
        VCPU_REGS       EQU 24

        ;; RDI => struct vpcu
vmentry:
        push    rbp
        push    rbx
        push    r12
        push    r13
        push    r14
        push    r15
        push    rdi

        push    rdi             ; Extra storage to save RDI after vmreturn
        ;; Save RSP to be restored on VM exit
        mov     rdx, 0x6C14     ; HOST_RSP
        vmwrite rdx, rsp
        mov     rdx, 0x6C16
        mov     rbx, vmentry.entered
        vmwrite rdx, rbx

        ;; Load guest registers
        mov     rax, [rdi + VCPU_REGS + 0]
        mov     rbx, [rdi + VCPU_REGS + 8]
        mov     rcx, [rdi + VCPU_REGS + 16]
        mov     rdx, [rdi + VCPU_REGS + 24]
        mov     rsi, [rdi + VCPU_REGS + 40]
        mov     rbp, [rdi + VCPU_REGS + 48]
        mov     r8,  [rdi + VCPU_REGS + 56]
        mov     r9,  [rdi + VCPU_REGS + 64]
        mov     r10, [rdi + VCPU_REGS + 72]
        mov     r11, [rdi + VCPU_REGS + 80]
        mov     r12, [rdi + VCPU_REGS + 88]
        mov     r13, [rdi + VCPU_REGS + 96]
        mov     r14, [rdi + VCPU_REGS + 104]
        mov     r15, [rdi + VCPU_REGS + 112]

        cmp     BYTE [rdi + LAUNCHED], 1
        mov     rdi, [rdi + VCPU_REGS + 32]
        je      .resume
        vmlaunch
        jmp     .entered
.resume:
        vmresume

.entered:
        ;; save guest RDI to stack
        mov     [rsp + 8], rdi
        pop     rdi
        pop     QWORD [rdi + VCPU_REGS +  32]
        ;; Save ZF/CF
        setbe   BYTE [rdi + VMEXIT_STATUS]
        ;; Save guest registers
        mov     [rdi + VCPU_REGS + 112], r15
        mov     [rdi + VCPU_REGS + 104], r14
        mov     [rdi + VCPU_REGS +  96], r13
        mov     [rdi + VCPU_REGS +  88], r12
        mov     [rdi + VCPU_REGS +  80], r11
        mov     [rdi + VCPU_REGS +  72], r10
        mov     [rdi + VCPU_REGS +  64], r9
        mov     [rdi + VCPU_REGS +  56], r8
        mov     [rdi + VCPU_REGS +  48], rbp
        mov     [rdi + VCPU_REGS +  40], rsi
        mov     [rdi + VCPU_REGS +  24], rdx
        mov     [rdi + VCPU_REGS +  16], rcx
        mov     [rdi + VCPU_REGS +   8], rbx
        mov     [rdi + VCPU_REGS +   0], rax
        pushf
        pop     rax
        and     rax, 0x41
        mov     BYTE [rdi + VMEXIT_STATUS], al

        pop     r15
        pop     r14
        pop     r13
        pop     r12
        pop     rbx
        pop     rbp
        ret
