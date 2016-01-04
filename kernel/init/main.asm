;;; kernel/init/main.asm
;;;
;;; Created by Simon Evans on 13/11/2015.
;;; Copyright © 2015 Simon Evans. All rights reserved.
;;;
;;; Entry point from jump into long mode. Minimal setup
;;; before calling SwiftKernel.startup

        BITS 64

        DEFAULT REL
        SECTION .text

        extern _kernel_stack
        extern init_mm
        extern _bss_start
        extern _kernel_end
        extern _TF11SwiftKernel7startupFT_T_ ; SwiftKernel.startup () -> ()

        global main

        ;; Entry point after switching to Long Mode
main:
        mov     esp, _kernel_stack      ; Set the stack to just after the BSS

        ;; Clear the BSS
        xor     rax, rax
        mov     rdi, _bss_start
        mov     rcx, _kernel_end
        sub     rcx, rdi
        shr     rcx, 3
        rep     stosq
        call    enable_sse

        ;; Setup TLS
        mov     ax,0x18
        mov     fs,ax
        mov     rax, 0x1FF8
        mov     [fs:0], rax

        call    init_mm                 ; required for malloc/free
        call    _TF11SwiftKernel7startupFT_T_   ; SwiftKernel.startup
        hlt

        ;; SSE instuctions cause an undefined opcode until enabled in CR0/CR4
        ;; Swift requires this at it uses the SSE registers
enable_sse:
        mov     rax, cr0
        and     ax, 0xFFFB		; Clear coprocessor emulation CR0.EM
        or      ax, 0x2                 ; Set coprocessor monitoring CR0.MP
        mov     cr0, rax
        mov     rax, cr4
        or      ax, 3 << 9		; Set CR4.OSFXSR and CR4.OSXMMEXCPT
        mov     cr4, rax
        ret
