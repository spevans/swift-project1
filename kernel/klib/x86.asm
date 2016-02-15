;;; kernel/klib/x86.asm
;;;
;;; Created by Simon Evans on 28/12/2015.
;;; Copyright © 2015, 2016 Simon Evans. All rights reserved.
;;;
;;; x86 CPU specific functions

        BITS    64

        global  reload_segments


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
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     ax, TLS_SEG
        mov     fs, ax
        ret
