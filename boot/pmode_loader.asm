;;; boot/pmode_loader.asm
;;; 
;;; Copyright © 2015 Simon Evans. All rights reserved.
;;;
;;; Loads the kernel into the memory starting @ 1MB
;;; It uses multiple bios calls to load the code in chunks and then
;;; switches into 32bit PM to copy the code to the correct place before
;;; switching back to realmode to load the next chunk switching back and
;;; forth until it is all loaded. Paging is not used to save setting up
;;; the tables just linear segments that map 4GB


BUFFER_SEG              EQU     0x8000
KERNEL_ADDR             EQU     0x100000
SECTORS_PER_READ        EQU     128

        BITS 16

pmode_loader:
        ;; Copy kernel LBA/sector count/hard drive from boot sector
        push    es
        mov     ax, 0x07C0
        mov     es, ax
        mov     eax, [es:496]
        mov     [dap_lba_lo], eax
        mov     eax, [es:500]
        mov     [dap_lba_hi], eax
        mov     ax, [es:504]
        mov     [sector_count], ax
        mov     ah, [es:506]
        mov     [boot_dev], ah
        pop     es

        mov     si, loading_kernel
        call    print
        lgdt    [GDT32.pointer]
        mov     ebp, 0xB8000

load_loop:
        mov     ax, [sector_count]
        cmp     ax, SECTORS_PER_READ
        jle     load_count
        mov     ax, SECTORS_PER_READ

load_count:
        sub     [sector_count], ax
        mov     [dap_count], ax
        mov     ah, 0x42
        mov     dl, [boot_dev]
        mov     si, dap
        int     0x13
        jnc     read_ok
        mov     si, lba_read_fail
        call    print
        cli
        hlt

read_ok:
        ;;  Data read from disk is at BUFFER_SEG:0000
        mov     esi, BUFFER_SEG
        shl     esi, 4
        mov     cx, [dap_count]
        shl     ecx, 9          ; convert sector count to bytes
        mov     edi, [kernel_addr]
        add     [kernel_addr], ecx
        call    pm_memcpy
        cmp     word [sector_count], 0
        je      kernel_loaded
        add     dword [dap_lba_lo], SECTORS_PER_READ
        adc     dword [dap_lba_hi], 0
        jmp     load_loop


kernel_loaded:
        mov     si, read_finished
        call    print
        ret

pm_memcpy:
        cli
        push    ds
        push    es
        mov     eax, cr0
        or      eax, 1
        mov     cr0,eax
        jmp     dword CODE_SEG:0x90000 + pm32_memcpy

memcpy_ret:
        sti
        pop     es
        pop     ds
        ret

        ALIGN   4
GDT32:
        dq      0x0000000000000000      ; null descriptor
        dq      0x00CF9A000000FFFF      ; 4G RPL0 code @ 0x0
        dq      0x00CF92000000FFFF      ; 4G RPL0 data @ 0x0
        dq      0x000F9A000000FFFF      ; 1MB  RPL0 code @ 0 16bit
.pointer:
        dw      ($ - GDT32) - 1
        dq      0x90000 + GDT32         ; 32bit base address

loading_kernel: db      "Loading kernel", 0x0A, 0x0D, 0
lba_read_fail:  db      "Load failed", 0
read_finished:  db      "Kernel read finished", 0x0A, 0x0D, 0

kernel_addr:    dd      KERNEL_ADDR     ; Destination address for kernel
sector_count    dw      0               ; Total sectors to load

;;; DAP (Disk Address Packet) used for LBA BIOS interface
dap:            db      16              ; DAP size
                db      0               ; always 0
dap_count:      dw      0
dap_offset:     dw      0               ; BUFFER_SEG:0000 is bounce buffer
dap_segment:    dw      BUFFER_SEG
dap_lba_lo:     dd      0               ; low 32bit LBA address
dap_lba_hi:     dd      0               ; high 32bit LBA address
boot_dev:       db      0               ; BIOS disk number


        BITS 32
        ALIGN 4

        ;; ESI: 32bit source addr EDI: 32bit dest addr ECX: count
pm32_memcpy:
        mov     ax, DATA_SEG
        mov     ds, ax
        mov     es, ax
        mov     word [ds:ebp], 0x0721 ; Print a '!' for each block copied
        add     ebp, 2
        shr     ecx, 2
        cld
        rep     movsd           ; copy data

        ;; Jump to a 16bit selector still in protected mode
        jmp     0x18:0x90000 + .j2

        BITS 16
        ALIGN 4

.j2:
        ;; Move back to real mode and do a far jump to reload CS
        mov     eax, cr0
        and     eax, 0xFFFFFFFE
        mov     cr0, eax
        jmp     0x9000:memcpy_ret
