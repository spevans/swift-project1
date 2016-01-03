;;; kernel/init/string.asm
;;;
;;; Created by Simon Evans on 21/12/2015.
;;; Copyright © 2015, 2016 Simon Evans. All rights reserved.
;;;
;;; Misc mem* and str* functions that are easier to do directly in asm

        global  memchr
        global  memmove
        global  memsetw
        global  stpcpy
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
        rep     scasb
        jne     .notfound
        mov     r8, rsi
.notfound:
        dec     r8
        mov     rax, r8
        ret


;;; void *memmove(void *dst, const void *src, size_t len);
;;; RDI: dest, RSI: src, RDX: count, returns dest
memmove:
        mov     rcx, rdx
        mov     rax, rdi
        mov     r8, rsi
        cld
        cmp     rdx, 0
        je      .exit
        cmp     rdi, rsi
        je      .exit
        jl      .forward        ; dest < src so no overlap with forward copy
        add     rsi, rdx
        jl      .forward
        std                     ; copy backwards
        xchg    rdi, rsi

.forward:
        rep     movsb
.exit:
        cld
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


;;; char *stpcpy(char *dest, const char *src)
;;; RDI: dest, RSI: src returns dest+strlen(src)
stpcpy:
        cld
.loop:
        lodsb
        stosb
        test    al, al
        jne     .loop
        dec     rdi
        mov     rax, rdi
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
