        BITS 64

        ORG 0x100000

        mov     edi, 0xB8000
        mov     rcx, 500                 ; Clear 2000 bytes as 500x8
        mov     rax, 0x4F201F204F201F20  ; White on Blue spaces
        rep     stosq

        mov     edi, 0xB8000
        mov     rax, 0x1F471F4E1F4F1F4C
        mov     [edi], rax
        jmp     start2

        times (4000*512) - ($-$$) db 0
        ALIGN   16
start2:
        mov     rax, 0x1F451F441F4F1F4D
        mov     [edi+8], rax
        hlt
