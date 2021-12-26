;;; kernel/init/main.asm
;;;
;;; Created by Simon Evans on 13/11/2015.
;;; Copyright © 2015, 2016 Simon Evans. All rights reserved.
;;;
;;; Entry point from jump into long mode. Minimal setup
;;; before calling SwiftKernel.startup

        BITS 64

        DEFAULT REL
        SECTION .text


        extern init_early_tty
        extern init_mm
        extern klibc_start
        extern startup ; SwiftKernel.startup () -> ()
        extern _bss_start
        extern _bss_end
        extern _kernel_stack

        global main
        global task_state_segment

        ;; Entry point after switching to Long Mode, could be from 32 or 64bit
        ;; so 64bit pointers are in 32bit pairs
        ;; EDI:ESI boot params / memory tables
        ;; ECX:EDX framebuffer info (EFI only)

_config_page:
        OFFSET 0x0E40

GDT:
        ;;      Selector 0x0
        dq      0x0000000000000000 ; Null descriptor
        ;; Code descriptor 0x8, base=0, limit=0 Present, Ring 0, RO/EX Longmode
        dq      0x00209A0000000000
        ;; Data descriptor 0x10, base=0, limit=0 Present, Ring 0, RW Longmode
        dq      0x0000920000000000
        ;; Null descriptor
        dq      0x0000000000000000

        ;; TSS (Task State Segment) descriptor 0x20 (16 bytes, filled in by GDT.swift)
        TIMES 16 DB 0

.pointer:
        dw      ($ - GDT) - 1   ; 16bit length -1
        dq      GDT             ; 64bit base address

        ALIGN   8
task_state_segment:     TIMES 104   DB 0

        OFFSET  4096            ; defined as KERNEL_ENTRY in include/macros.asm
main:
        lgdt    [GDT.pointer]
        mov     ax, DATA_SEG            ; Reload all of the segment registers
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        xor     ax, ax
        mov     fs, ax
        mov     gs, ax
        mov     rsp, _kernel_stack      ; Set the stack to just after the BSS
        mov     rbp, rsp

        push    qword CODE_SEG
        push    qword .here
        db      0x48
        ;; Effectively a far jmp to .here to reload CS
        retf
.here:

        ;; convert EDI:ESI => R12, ECX:RDX => R13
        mov     r12, rdi
        shl     r12, 32
        or      r12, rsi
        mov     r13, rcx
        shl     r13, 32
        or      r13, rdx

        ;; Clear the BSS
        xor     rax, rax
        mov     rdi, _bss_start
        mov     rcx, _bss_end
        sub     rcx, rdi
        mov     rdx, rcx
        and     rdx, 3
        shr     rcx, 3
        rep     stosq
        mov     rcx, rdx
        rep     stosb

%ifdef  USEFP
        call    enable_sse
%endif

        mov     rdi, r13        ; framebuffer info
        call    init_early_tty
        mov     rdi, r12
        call    init_mm         ; required for malloc/free

        call    klibc_start
        mov     rdi, r12
        mov     rsi, r13
        call    startup         ; SwiftKernel.startup
        hlt


%ifdef USEFP
        ;; SSE instuctions cause an undefined opcode until enabled in CR0/CR4
        ;; Swift requires this at it uses the SSE registers
enable_sse:
        mov     rax, cr0
        and     ax, 0xFFFB      ; Clear coprocessor emulation CR0.EM
        or      ax, 0x2         ; Set coprocessor monitoring CR0.MP
        mov     cr0, rax
        mov     rax, cr4
        or      ax, 3 << 9      ; Set CR4.OSFXSR and CR4.OSXMMEXCPT
        mov     cr4, rax
        ret
%endif
