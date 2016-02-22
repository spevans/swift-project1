;;; boot/isohdr.asm
;;;
;;; Created by Simon Evans on 22/02/2016.
;;; Copyright © 2016 Simon Evans. All rights reserved.
;;;
;;; ISO header containing Apple Partition Map header to provide
;;; a file suitable for the xorrisofs `-isohybrid-mbr' option
;;; Currently doesnt work for booting if used on a USB image

        [MAP ALL isohdr.map]
LOAD_SEG        EQU       0x7c0  ; isohdr.bin loaded here

        ORG     0x0
apm_mbr:        db 0x33, 0xed   ; Apple Partition Map header
                times 30 db 0x90

        jmp     0x07c0:start    ; initialise CS

start:
        cli
        cld
        xor     ax, ax
        mov     ss, ax
        mov     sp, 0x2000
        sti
        mov     ds, ax
        mov     ax, 0x7a0
        mov     es, ax

        ;; Relocate to 0x7A00:0000 so bootsector can be loaded to
        ;; normal position @ 0x7C00:0000
        mov     si, 0x7c00
        xor     di, di
        mov     cx, 0x100
        rep     movsw
        jmp     0x7a0:here
here:
        mov     ax, es
        mov     ds, ax

        mov     [boot_dev], dl
        mov     ax, [lba_offset]
        mov     [dap_lba], ax
        mov     ax, [lba_offset + 2]
        mov     [dap_lba + 2], ax

        ;; Read in bootsector.bin and boot16to64.bin
        mov     ah, 0x42        ; Extended read sectors
        mov     dl, [boot_dev]
        mov     si, dap
        int     0x13
        jc      boot_failure
        mov     si, msg_ok
        call    print
        jmp     LOAD_SEG:0      ; Execute boot16to64

boot_failure:
        ;; Boot failure, print message then reboot
        mov     si, msg_fail
        call    print
        ;; wait for keypress
        xor     ax, ax
        int     0x16
        int     0x19
        jmp     0xf000:0xfff0   ; if int 19 fails


        %include "utils.asm"    ; for print_string

msg_ok:         db      "Loaded OK", 0x0A, 0x0D, 0
msg_fail:       db      "Load failed. Press any key to reboot", 0x0A, 0x0D, 0

;;; Bootsector padding, disk image info and signature
;;; The offset 480 is used by an external program to
;;; patch in the secondary loader and kernel image LBA/sector
;;; counts so must always reside at this locatio
        OFFSET  400

;;; DAP (Disk Address Packet) used for LBA BIOS interface
dap:            db      16              ; DAP size
                db      0               ; always 0
dap_count:      dw      4
dap_offset:     dw      0               ; Code is loaded to LOAD_SEG:0000
dap_segment:    dw      LOAD_SEG
dap_lba:        dq      0               ; 64bit LBA address

sector_lba:     dq      0
boot_dev:       db      0               ; BIOS disk number

                OFFSET  432
lba_offset:     dd      0               ; Patched in by xorrisofs
