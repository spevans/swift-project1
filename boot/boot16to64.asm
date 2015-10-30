;;; Enter 64bit (long mode) from 16bit (real mode)
;;; Doenst go via 32bit so there are no exception
;;; handlers. If a fault occurs in the transition
;;; then a triple fault will occur and the CPU will
;;; reset.

        %define CODE_SEG        0x8
        %define DATA_SEG        0x10

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
        mov     si, msg_dis_intr
        call    print
        call    disable_interrupts

        mov     si, msg_enable_a20
        call    print
        call    enable_a20
        jc      boot_failed
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

        ;; Since this code is loaded at 9000:0000, everything
        ;; is effectivly ORG 0x900000 so add that to the far jmp
        db      0x66, 0xea
        dd      0x90000 + longmode
        dw      CODE_SEG

        ;; Disable all interrupts including NMI and IRQs
%define MASTER_PIC      0x21
%define SLAVE_PIC       0xA1

disable_interrupts:
        cli
        mov     al, 0x80
        out     0x70, al        ; disable NMI
        call    io_delay
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

 .pointer:
        dw      ($ - GDT) - 1   ; 16bit length -1
        dq      0x90000 + GDT   ; 32bit base address


        BITS 64
longmode:
        mov     ax, DATA_SEG
        mov     ds, ax
        mov     es, ax
        mov     fs, ax
        mov     gs, ax
        mov     ss, ax

        mov     edi, 0xB8000
        mov     rcx, 500                 ; Clear 2000 bytes as 500x8
        mov     rax, 0x1F201F201F201F20  ; White on Blue spaces
        rep     stosq

        mov     edi, 0xB8000
        mov     rax, 0x1F6C1F6C1F651F48
        mov     [edi], rax
        hlt

times 4096 - ($-$$) db 0
