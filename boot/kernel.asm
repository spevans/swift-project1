        BITS 64

        SECTION .text

extern _init_tty

        mov     rdi, 0xB8000
        mov     rcx, 500                 ; Clear 2000 bytes as 500x8
        mov     rax, 0x4F201F204F201F20  ; White on Blue spaces
        rep     stosq

        mov     rdi, 0xB8000
        mov     rax, 0x1F471F4E1F4F1F4C
        mov     [rdi], rax
        jmp     start2

        ALIGN   16
start2:
        mov     rax, 0x1F451F441F4F1F4D
        mov     [rdi+8], rax
        add     rdi, 160
        lea     rsi, [rel msg1]
        mov     ah, 0x7
.loop:
        lodsb
        cmp     al, 0
        je      .msgend
        stosw
        jmp     .loop

.msgend:
        call    _init_tty
        hlt


       SECTION .data

msg1:   db      "Hello There", 0
