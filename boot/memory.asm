;;; boot/memory.asm
;;;
;;; Created by Simon Evans on 24/12/2015.
;;; Copyright © 2015 Simon Evans. All rights reserved.
;;;
;;; Obtain the memory map from the BIOS
;;; Store a struct bios_boot_params @ 3000:0000 followed by the E820 map

MAX_SMAP_ENTRIES        EQU     200
E820_SIGNATURE          EQU     "PAMS"  ; "SMAP" in LE format

get_memory:
        push    es
        mov     di, 0x3000
        mov     es, di
        ;; clear a page @ 3000:0000
        cld
        xor     edi, edi
        xor     eax, eax
        mov     ecx, 0x400
        rep     stosd
        ;; struct bios_boot_params setup

        mov     dword [es:00], 'BIOS'   ; .signature
        mov     dword [es:08], 0        ; .size (of table)
        mov     dword [es:16], KERNEL_LOAD_ADDR ; physical address of kernel
        mov     dword [es:24], 0x30028  ; .e820_map lo dword
        mov     dword [es:28], 0x0      ; .e820_map hi dword @ 0x030020 PhysAddr
        mov     edi, 40                 ; offset to e832 data
        xor     ebx, ebx

.next_entry:
        mov     eax, 0xe820
        mov     ecx, 20
        mov     edx, E820_SIGNATURE
        int     0x15
        jc      .finished
        cmp     eax, E820_SIGNATURE
        jne     .finished
        inc     dword [es:32]           ; .e820_entries++
        add     edi, 20
        cmp     ebx, 0
        je      .finished
        cmp     dword [es:32], MAX_SMAP_ENTRIES
        jl      .next_entry

.finished:
        mov     [es:08], edi            ; .size (of table)
        pop     es
        ret
