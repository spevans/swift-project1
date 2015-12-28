;;; kernel/init/io.asm
;;;
;;; Created by Simon Evans on 28/12/2015.
;;; Copyright © 2015 Simon Evans. All rights reserved.
;;;
;;; x86 port I/O functions

        global  outb
        global  outw
        global  outl
        global  inb
        global  inw
        global  inl

        
;;; void outb(uint16_t port, uint8_t data)
;;; RDI: port, RSI: data
outb:
        mov     ax, si
        mov     dx, di
        out     dx, al
        ret

;;; void outw(uint16_t port, uint16_t data)
;;; RDI: port, RSI: data
outw:
        mov     ax, si
        mov     dx, di
        out     dx, ax
        ret

;;; void outl(uint16_t port, uint32_t data)
;;; RDI: port, RSI: data
outl:
        mov     eax, esi
        mov     dx, di
        out     dx, eax
        ret


;;; uint8_t inb(uint16_t port)
;;; RDI: port, returns al = data
inb:
        xor     rax, rax
        mov     dx, di
        in      al, dx
        ret

;;; uint16_t inb(uint16_t port)
;;; RDI: port, returns al = data
inw:
        xor     rax, rax
        mov     dx, di
        in      ax, dx
        ret


;;; uint32_t inb(uint16_t port)
;;; RDI: port, returns al = data
inl:
        xor     rax, rax
        mov     dx, di
        in      eax, dx
        ret
