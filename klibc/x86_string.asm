;;; klibc/x86_string.asm
;;;
;;; Created by Simon Evans on 21/12/2015.
;;; Copyright © 2015, 2016 Simon Evans. All rights reserved.
;;;
;;; Misc mem* and str* functions that are easier to do directly in x86 asm.

        global  memchr
        global  memcmp
        global  memcpy
        global  memmove
        global  memsetw
        global  strchr


;;; void *memchr(const void *src, int c, size_t n);
;;; RDI: src, RSI: c, RDX: count
memchr:
        mov     r8, 1
        cmp     rdx, 0
        mov     rax, rsi
        mov     rsi, rdi
        mov     rcx, rdx
        je      .notfound
        repnz   scasb
        jne     .notfound
        mov     r8, rdi
.notfound:
        dec     r8
        mov     rax, r8
        ret


;;; int memcmp(const void *s1, const void *s2, size_t n);
;;; RDI: s1, RDI: s2, RDX: count, returns 0 if same, 1 if diff
memcmp:
        xor     rax, rax
        mov     rcx, rdx
        rep     cmpsb
        setnz   al
        ret


;;; void *memcpy(void *dest, const void *src, size_t n)
;;; RDI: dest, RSI: src, RDX: count, returns dest
memcpy:
        mov     rcx, rdx
        mov     rax, rdi
        test    rdx, rdx
        jz      .exit
        shr     rcx, 3
        rep     movsq
        and     rdx, 7
        mov     rcx, rdx
        rep     movsb
.exit:
        ret


;;; void *memmove(void *dest, const void *src, size_t n);
;;; RDI: dest, RSI: src, RDX: count, returns dest
memmove:
        mov     rcx, rdx
        mov     rax, rdi
        dec     rdx
        test    rcx, rcx
        je      .exit
        cmp     rdi, rsi
        je      .exit
        jl      .forward        ; dest < src so no overlap with forward copy
        add     rsi, rdx
        add     rdi, rdx
        std                     ; copy backwards

.forward:
        rep     movsb
        cld
.exit:
        ret


;;; void *memsetw(void *dest, uint16_t w, size_t count)
;;; RDI: dest, RSI: w, RDX: count. returns dest
memsetw:
        cld
        mov     r8, rdi
        mov     ax, si
        mov     rcx, rdx
        rep     stosw
        mov     rax, r8
        ret


;;; char *strchr(const char *s, int c)
;;; RDI: s, RSI:c returns first occurance of c or NULL
strchr:
        cld
        mov     dx, si
.loop:
        mov     al, [rdi]
        cmp     al, dl
        je      .found
        test    al, al
        je      .notfound
        inc     rdi
        jmp     .loop
.notfound:
        xor     rdi, rdi
.found:
        mov     rax, rdi
        ret
