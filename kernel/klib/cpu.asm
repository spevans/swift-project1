;;; kernel/klib/cpu.asm
;;;
;;; Created by Simon Evans on 28/12/2015.
;;; Copyright © 2015 Simon Evans. All rights reserved.
;;;
;;; x86 CPU specific instructions

        BITS    64

        global  outb
        global  outw
        global  outl
        global  inb
        global  inw
        global  inl
        global  lgdt
        global  sgdt
        global  reload_segments

        CODE_SEG        EQU     0x8
        DATA_SEG        EQU     0x10
        TLS_SEG         EQU     0x18


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


;;; void lgdt(const struct dt_info *info)
;;; RDI: dt_info structure
lgdt:
        lgdt    [rdi]
        ret


;;; void sgdt(struct dt_info *info)
;;; RDI: dt_info structure
sgdt:
        sgdt    [rdi]
        ret

;;; void reload_segments()
;;; Just a test routine to check the GDT has been set correctly,
;;; The segment registers are reloaded with the values they already had
reload_segments:
        push    qword CODE_SEG
        push    qword .here
        db      0x48
        ;; Effectively a far jmp to .here to reload CS
        retf
.here:
        mov     ax, DATA_SEG
        mov     ss, ax
        mov     ax, TLS_SEG
        mov     fs, ax
        ret
