        %macro OFFSET 1
        times %1 - ($ - $$)   db 0
        %endmacro


        KERNEL_VIRTUAL_BASE     EQU     0xffffffff81000000     ; 2^64 - 2GB + 16MB
        PHYSICAL_MEM_BASE       EQU     0xffff800000000000     ; 128TB

        CODE_SEG                EQU     0x8
        DATA_SEG                EQU     0x10
        KERNEL_ENTRY            EQU     KERNEL_VIRTUAL_BASE + 0x1000
        TLS_SEG                 EQU     0x18
        TLS_END_ADDR            EQU     0x1FF8

;;; This layout matches include/x86defs.h
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

        %endmacro


        %macro  ALIGN_STACK 0

        ;; Align the stack to 16bytes required for ABI, stores original
        ;; RSP in RDI
        mov     rdi, rsp
        push    rsp
        push    qword [rsp]
        and     rsp, -16

        %endmacro


        %macro  UNALIGN_STACK 0

        mov     rsp, [rsp+8]

        %endmacro
