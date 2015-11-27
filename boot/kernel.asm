        BITS 64

        DEFAULT REL
        SECTION .text

        extern _init_tty
        extern _offset
        extern __bss_start
        extern __bss_end
        extern __TF7startup7startupFT_T_ ; startup:startup()
        global _halt

start_of_kernel:
        mov     esp, 0x2000             ; Reset the SP to top of page1
        mov     rdi, 0xB8000
        mov     rcx, 500                ; Clear 2000 bytes as 500x8
        mov     rax, 0x4F201F204F201F20 ; White on Blue spaces
        rep     stosq

        ;; Clear the BSS
        xor     rax, rax
        mov     rdi, __bss_start
        mov     rcx, __bss_end
        sub     rcx, rdi
        rep
        stosb
        jmp     startup
        mov     rdi, 0xB8000
        mov     rax, 0x1F471F4E1F4F1F4C
        mov     [rdi], rax
        jmp     start2

        ALIGN   16
start2:
        mov     rax, 0x1F451F441F4F1F4D
        mov     [rdi+8], rax
        add     rdi, 160
        lea     rsi, [msg1]
        mov     ah, 0x7
.loop:
        lodsb
        cmp     al, 0
        je      msgend
        stosw
        jmp     .loop

msgend:
        lea     eax,[counter]
        xor     eax,eax
        mov     [counter], eax
.loop:
        inc     dword [counter]
        cmp     dword [counter], 10
        jne     msgend.loop

        mov     dword [_offset], 640
startup:
        call    _init_tty
        call    __TF7startup7startupFT_T_

_halt:
        hlt

        SECTION .data
msg1:           db      "Hello There", 0


counter:        dd 0
