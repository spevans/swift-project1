;;; boot/a20.asm
;;; 
;;; Copyright © 2015 Simon Evans. All rights reserved.
;;; 
;;; Enable the A20 gate using various methods.
;;; Starts with a check to see if its even needed

FAST_A20_GATE   EQU     0x92
A20_TEST_COUNT  EQU     5


;;; Enable the A20 using differnt methods, returns carry set if not enabled
enable_a20:
        call    check_a20
        jnc     enabled_ok
        call    enable_a20_bios
        call    check_a20
        jnc     enabled_ok
        call    enable_a20_fast
        jnc     enabled_ok
        call    enable_a20_8042
        call    check_a20
enabled_ok:
        ret


;;; Enable the A20 using the BIOS if supported
enable_a20_bios:
        mov     ax, 0x2401
        int     0x15
        ret


;;; Enable the A20 using the 'Fast A20 Gate' if supported
enable_a20_fast:
        in      al, FAST_A20_GATE
        test    al, 2            ; check if enabled
        jnz     a20_fast_return ; already is, return
        or      al, 2            ; set a20 enable
        and     al, 0xFE         ; Clear the reset bit
        out     FAST_A20_GATE, al
a20_fast_return:
        ret


;;; Enable the A20 using the keyboard controller
enable_a20_8042:
        call    empty_8042
        mov     al, 0xD1
        out     0x64, al        ; command write
        call    empty_8042
        mov     al, 0xDF
        out     0x60, al        ; A20 on
        call    empty_8042
        mov     al, 0xff
        out     0x64, al        ; extra for UHCI
        call    empty_8042
        ret

empty_8042:
        call    io_delay
        in      al, 0x64        ; read status
        test    al, 1           ; output buffer?
        jne     no_output       ; no, check if input empty
        call    io_delay        ; yes, read and ignore
        in      al, 0x60
        jmp     empty_8042
no_output:
        test    al, 2           ; Buffer empty, all done
        jne     empty_8042
        ret


;;; Test if A20 is opened, returns carry set on error
check_a20:
        push    ds
        push    es
        xor     ax, ax
        mov     ds, ax
        mov     ax, 0xffff
        mov     es, ax
        mov     ax, [0x1000]
        mov     cx, A20_TEST_COUNT

check_loop:
        ;; Test if DS:1000h (0x1000) == ES:1010h (0x101000 if enabled)
        call    io_delay
        mov     bx, [0x1000]     ; read DS:1000
        cmp     bx, [es:0x1010]  ; read ES:1010
        jne     a20_enabled     ; not equal so A20 is enabled
        inc     bx              ; are equal so alter one
        mov     [0x1000], bx
        cmp     bx, [es:0x1010]
        jne     a20_enabled     ; not equal anymore so A20 is enabled
        dec     cx
        jnz     check_loop
        stc                     ; After multiple checks A20 still disabled
        jmp     a20_return

a20_enabled:
        clc

a20_return:
        mov     [0x1000], ax
        pop     es
        pop     ds
        ret
