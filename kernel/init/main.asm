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

;;; This first page is mapped at both 0x1000 and 0xffffffff80100000 and
;;; holds the TLS so that the TLS can exist in the first 4GB since the
;;; TLS entry in the GDT only allows a 32bit base address.
_config_page:
        OFFSET 0x0E40

GDT:
        ;;      Selector 0x0
        dq      0x0000000000000000 ; Null descriptor
        ;; Code descriptor 0x8, base=0, limit=0 Present, Ring 0, RO/EX Longmode
        dq      0x00209A0000000000
        ;; Data descriptor 0x10, base=0, limit=0 Present, Ring 0, RW Longmode
        dq      0x0000920000000000

%ifdef ENABLE_TLS
        ;; TLS descriptor 0x18, base=0x1FF8, limit=0 Present, Ring 0, RW Longmode
        dq      0x0000920000000000
%else
        dq      0x0000000000000000 ; Null descriptor
%endif

        ;; TSS (Task State Segment) descriptor 0x20 (16 bytes, filled in by GDT.swift)
        TIMES 16 DB 0

.pointer:
        dw      ($ - GDT) - 1   ; 16bit length -1
        dq      GDT             ; 64bit base address

        ALIGN   8
task_state_segment:     TIMES 104   DB 0

%ifdef ENABLE_TLS
        OFFSET  0x0F00          ; 248 bytes for TLS bss
tls_bss:

        OFFSET  0x0FF8
tls_end_addr:   dq  0x1FF8

%endif

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

%ifdef ENABLE_TLS
        call    setup_tls
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

%ifdef ENABLE_TLS
        ;; Setup TLS - Update the GDT entry for select 0x18 to have the address
        ;; of tls_end which is allocated in the config area above.
setup_tls:
        mov     rbx, GDT
        add     rbx, 0x18
        mov     eax, [tls_end_addr]
        mov     edx, eax
        mov     ecx, eax
        shl     ecx, 16         ; ecx hold low 32bit of descriptor (limit  = 0)
        mov     [rbx], ecx
        mov     ecx, eax
        shr     ecx, 16
        and     ecx, 0xff
        or      ecx, 0x9200
        and     eax, 0xff000000
        or      eax, ecx
        mov     [rbx+4], eax
        ;; Load the newly created TLS entry into FS
        mov     ax, 0x18
        mov     fs, ax
        ret
%endif


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
