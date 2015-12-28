;;; boot/page_tables.asm
;;;
;;; Copyright © 2015 Simon Evans. All rights reserved.
;;;
;;; Setup 4 level page tables with the PGD at 0x3000
;;; Identity maps the first 16MB so only needs 1 entry
;;; in the PML4/PDP 8 in the PD and 4096 PTEs in the PT
;;; Also maps the first 16MB at the 1GB mark

PAGE_PRESENT    EQU     1
PAGE_WRITEABLE  EQU     2


;;; Setup pagetables a 48KB region @ 0000:3000
;;; PML4 @ 0000:3000, PDP @ 0000:4000, PD @ 0000:5000 PT @ 0000:6000 - 0000:E000

setup_pagetables:
        push    es
        push    di
        xor     eax, eax
        mov     es, ax
        mov     edi, 0x3000
        mov     cr3, edi
        mov     cx, 0x2C00     ; clear 44KB (11 pages)
        cld
        rep     stosd
        mov     edi, cr3
        ;; Page Map Level 4 (PML4)
        mov     eax, 0x4000 | PAGE_PRESENT | PAGE_WRITEABLE
        mov     [es:di], eax

        ;; Page Directory Pointer (PDP)
        ;; Each entry maps 1GB so add 2 entries mapping the
        ;; first 16MB from 0GB and the first 16MB from 1GB
        mov     eax, 0x5000 | PAGE_PRESENT | PAGE_WRITEABLE
        mov     [es:di + 0x1000], eax
        mov     [es:di + 0x1008], eax

        ;; Page Directory (PD), 8 entries
        mov     eax, 0x6000 | PAGE_PRESENT | PAGE_WRITEABLE
        mov     cx, 8

pde_loop:
        mov     [es:di + 0x2000], eax
        add     eax, 0x1000
        add     di, 8
        dec     cx
        jnz     pde_loop

        ;; Page Table Entries (PTEs), 4096 entries of 4KB pages
        ;; maps linear 0-16MB to physical 0-16MB

        mov     eax, PAGE_PRESENT | PAGE_WRITEABLE ; EAX -> physical addr 0
        xor     ebx, ebx
        mov     di, 0x600
        mov     cx, 2048        ; entry count /2 will add 2 PTEs per loop

pte_loop:
        mov     es, di
        mov     [es:0], eax
        mov     [es:4], ebx
        add     eax, 0x1000
        mov     [es:8], eax
        mov     [es:12], ebx
        add     eax, 0x1000
        inc     di
        dec     cx
        jnz     pte_loop
        xor     eax, eax
        mov     di, 0x600
        mov     es, di
        mov     [es:0x0000], eax        ; Unmap page 0 to catch null ptr

        mov     di, 0x3000
        mov     cl, 16
        call    HexDump
        mov     di, 0x4000
        mov     cl, 16
        call    HexDump
        mov     di, 0x6000
        mov     cl, 32
        call    HexDump
        mov     di, 0x6480
        mov     cl, 32
        call    HexDump
        pop     di
        pop     es
        ret


        ; Dump CL bytes from ES:DI
HexDump:
        push    di
        cmp     cl, 0
        je      HexDumpEnd

next_line:
        mov     al, 0x0A         ; reset to a newline
        call    print_char
        mov     al, 0x0D
        call    print_char

        mov     ch, 0           ; number of bytes output perline
        mov     bx, es
        call    printWord       ; print seg:offset
        mov     al, 58          ; ':'
        call    print_char
        mov     bx, di
        call    printWord
        mov     al, 32
        call    print_char

next_byte:
        mov     bl, [es:di]
        call    printByte
        dec     cl
        cmp     cl, 0
        je      HexDumpEnd
        inc     di
        inc     ch
        cmp     ch, 16
        je      next_line
        mov     al, 32          ; space
        call    print_char
        jmp     next_byte

HexDumpEnd:
        mov     al, 0x0A         ; reset to a newline
        call    print_char
        mov     al, 0x0D
        call    print_char

        pop     di
        ret

        ;; print the hex digit in low 4 bits of AL to the screen
PrintNibble:
        and     al, 0xf
        add     al, 48
        cmp     al, 58          ; is AL  A-F?
        jl      less_than_a
        add     al, 7
less_than_a:
        call    print_char
        ret

        ;; print the byte in BL to the screen
printByte:
        mov     al, bl
        shr     al, 4
        call    PrintNibble
        mov     al, bl
        call    PrintNibble
        ret

        ;; print the word in BX to the screen
printWord:
        mov     al, bh
        shr     al, 4
        call    PrintNibble
        mov     al, bh
        call    PrintNibble
        call    printByte
        ret

        ;; print char in AL
print_char:
        push    bx
        mov     bx, 0
        mov     ah, 0xe
        int     0x10
        pop     bx
        ret
