        BITS 64

        DEFAULT REL
        SECTION .text

        extern init_tty
        extern __bss_start
        extern _end

        extern _TF7startup7startupFT_T_ ; startup:startup()
        global main
        global _start

_start: 
main:   
start_of_kernel:
        mov     esp, 0xA0000            ; Set the stack to the top of 640K
        mov     rdi, 0xB8000
        mov     rcx, 500                ; Clear 2000 bytes as 500x8
        mov     rax, 0x4F201F204F201F20 ; White on Blue spaces
        rep     stosq

        ;; Clear the BSS
        xor     rax, rax
        mov     rdi, __bss_start
        mov     rcx, _end
        sub     rcx, rdi
        rep
        stosb
        call    enable_sse

startup:
        mov     ax,0x18
        mov     fs,ax
        mov     rax, 0x1FF8
        mov     [fs:0], rax
        mov     rax, 0x3f39e0
        mov     [fs:-8], rax
        mov     rax, 0x3f39e8
        mov     [fs:-16], rax
        

        
        call    init_tty
        call    _TF7startup7startupFT_T_
        hlt

        ;; SSE instuctions cause an undefined opcode until enabled in CR0/CR4
enable_sse:
        mov     rax, cr0
        and     ax, 0xFFFB		; Clear coprocessor emulation CR0.EM
        or      ax, 0x2                 ; Set coprocessor monitoring CR0.MP
        mov     cr0, rax
        mov     rax, cr4
        or      ax, 3 << 9		; Set CR4.OSFXSR and CR4.OSXMMEXCPT
        mov     cr4, rax
        ret


        SECTION .data
msg1:           db      "Hello There", 0
counter:        dd 0
