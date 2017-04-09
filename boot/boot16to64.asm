;;; boot/boot16to64.asm
;;;
;;; Created by Simon Evans on 30/10/2015.
;;; Copyright © 2015, 2016 Simon Evans. All rights reserved.
;;;
;;; Enter 64bit (long mode) from 16bit (real mode)
;;; Doesnt go via 32bit so there are no exception
;;; handlers. If a fault occurs in the transition
;;; then a triple fault will occur and the CPU will
;;; reset.


        [MAP all boot16to64.map]
        ORG 0x0000

        ;; Code is loaded at 0x9000:0000 by bootloader and entered
        ;; at that address
        push    cs
        pop     ax
        mov     ds, ax
        mov     es, ax
        mov     si, msg_booting
        call    print
        call    cpu_check
        jc      boot_failed

        call    get_memory

        mov     si, msg_enable_a20
        call    print
        call    enable_a20
        jc      boot_failed

        call    disable_nmi
        call    pmode_loader

        mov     si, msg_dis_intr
        call    print
        call    disable_interrupts

        mov     si, msg_pagetables
        call    print
        call    setup_pagetables ; This returns with CR3 setup

        mov     si, msg_goingin
        call    print
        lidt    [IDT.pointer]
        ;; Enter Longmode
        mov     eax, 100000b     ; set PAE bit
        mov     cr4, eax

        mov     ecx, 0xC0000080 ; Read from the EFER MSR.
        rdmsr
        or      eax, 0x00000100 ; Set the LME bit.
        wrmsr

        lgdt    [GDT.pointer]
        mov     eax, cr0
        or      eax, 0x80000001  ; Enable paging and protected mode,
        mov     cr0, eax         ; activating longmode

        mov     edi, PHYSICAL_MEM_BASE >> 32
        mov     esi, 0x30000    ; bootparams converted to kernel's vaddr space
        xor     ecx, ecx        ; ECX:EDX => Framebuffer address (null for text mode)
        xor     edx, edx
        ;; jump to the kernel loading the code selector

        jmp     dword CODE_SEG:0x90000 + here

        BITS    64

here:
        mov rax, KERNEL_ENTRY
        jmp rax

        BITS  16
        ;; Disable all interrupts including NMI and IRQs
MASTER_PIC      EQU     0x21
SLAVE_PIC       EQU     0xA1

disable_nmi:
        mov     al, 0x80
        out     0x70, al        ; disable NMI
        call    io_delay
        ret

disable_interrupts:
        cli
        mov     al, 0xff
        out     MASTER_PIC, al  ; Mask all IRQs
        call    io_delay
        out     SLAVE_PIC, al
        call    io_delay
        ret


boot_failed:
        mov     si, msg_failed
        call    print
        hlt


%include "utils.asm"
%include "a20.asm"
%include "page_tables.asm"
%include "cpu_check.asm"
%include "memory.asm"

msg_booting:    db      "Booting... checking CPU...", 0x0A, 0x0D, 0
msg_dis_intr:   db      "Disabling interrupts...", 0x0A, 0x0D, 0
msg_enable_a20: db      "Enabling A20...", 0x0A, 0x0D, 0
msg_pagetables: db      "Setting up page tables...", 0x0A, 0x0D, 0
msg_goingin:    db      "Entering Long Mode...", 0x0A, 0x0D, 0
msg_failed:     db      "Boot failure.", 0x0A, 0x0D, 0

;;; Pad to 4K (8 sectors) for now. NASM will error if the code gets
;;; larger than this

IDT:
        ALIGN 4
.pointer:
        ;; NULL IDT: 0 base, 0 length
        dw      0               ; 16bit length
        dq      0               ; 32bit base address

GDT:
        dq      0x0000000000000000 ; Null descriptor
        ;; Code descriptor, base=0, limit=0 Present, Ring 0, RO/EX Longmode
        dq      0x00209A0000000000
        ;; Data descriptor, base=0, limit=0 Present, Ring 0, RW Longmode
        dq      0x0000920000000000
        ;; TLS descriptor, base=0x1FF8, limit=0 Present, Ring 0, RW Longmode
        dq      0x0000920000000000


.pointer:
        dw      ($ - GDT) - 1   ; 16bit length -1
        dq      0x90000 + GDT   ; 64bit base address

;;; Include this at the end as it changes the BITS settings
%include "pmode_loader.asm"

times 1536 - ($-$$) db 0
