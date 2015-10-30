;;; Setup 4 level page tables with the PGD at 0x1000
;;; Identity maps the first 2MB so only needs 1 entry
;;; in the PML4/PDP/PD and 512 PTEs in the PT

PAGE_PRESENT    EQU     1
PAGE_WRITEABLE  EQU     2


;;; Setup pagetables at in 16K region @ 0000:1000
;;; PML4 @ 0000:1000, PDP @ 0000:2000, PD @ 0000:3000 PT @ 0000:4000

setup_pagetables:
        push    es
        push    di
        xor     eax, eax
        mov     es, ax
        mov     edi, 0x1000      ; clear 16KB (4x pages)
        mov     cr3, edi
        mov     ecx, 0x1000
        cld
        rep     stosd
        mov     edi, cr3

        ;; Page Map Level 4 (PML4)
        mov     eax, 0x2000
        or      eax, PAGE_PRESENT | PAGE_WRITEABLE
        mov     [es:di], eax

        ;; Page Directory Pointer (PDP)
        mov     eax, 0x3000
        or      eax, PAGE_PRESENT | PAGE_WRITEABLE
        mov     [es:di + 0x1000], eax

        ;; Page Directory (PD)
        mov     eax, 0x4000
        or      eax, PAGE_PRESENT | PAGE_WRITEABLE
        mov     [es:di + 0x2000], eax

        ;; Page Table Entries (PTEs), 512 entries of 4KB pages
        ;; maps linear 0-2MB to physical 0-2MB

        mov     eax, PAGE_PRESENT | PAGE_WRITEABLE ; EAX -> physical addr 0
        mov     di, 0x4000
        mov     cx, 512         ; entry count

pte_loop:
        mov     [es:di], eax
        add     eax, 0x1000
        add     di, 8
        dec     cx
        jnz     pte_loop

        mov     di, 0x1000
        mov     cl, 16
        call    HexDump
        mov     di, 0x2000
        mov     cl, 16
        call    HexDump
        mov     di, 0x3000
        mov     cl, 16
        call    HexDump
        mov     di, 0x4480
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

; print the hex digit in low 4 bits of AL to the screen
PrintNibble:
        and     al, 0xf
        add     al, 48
        cmp     al, 58          ; is AL  A-F?
        jl      less_than_a
        add     al, 7
less_than_a:
        call    print_char
        ret

; print the byte in BL to the screen
printByte:
        mov     al, bl
        shr     al, 4
        call    PrintNibble
        mov     al, bl
        call    PrintNibble
        ret

; print the word in BX to the screen
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
