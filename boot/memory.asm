;;; boot/memory.asm
;;;
;;; Created by Simon Evans on 24/12/2015.
;;; Copyright © 2015 Simon Evans. All rights reserved.
;;;
;;; Obtain the memory map from the BIOS

;;; Store memory map at 3000:0000 starting with a 4byte entry count
MAX_SMAP_ENTRIES        EQU     200
E820_SIGNATURE          EQU     "PAMS"  ; "SMAP" in LE format

get_memory:
        push    es
        mov     di, 0x3000
        mov     es, di
        mov     dword [es:0], 0
        ;; clear the memory region
        cld
        xor     edi, edi
        xor     eax, eax
        mov     ecx, 0x1000
        rep     stosd
        mov     di, 4
        xor     ebx, ebx
        xor     ebp, ebp

.next_entry:
        mov     eax, 0xe820
        mov     ecx, 20
        mov     edx, E820_SIGNATURE
        int     0x15
        jc      .finished
        cmp     eax, E820_SIGNATURE
        jne     .finished
        inc     dword [es:0]
        cmp     ebx, 0
        je      .finished
        add     di, 20
        cmp     ebp, MAX_SMAP_ENTRIES
        jl      .next_entry

.finished:
        pop     es
        ret
