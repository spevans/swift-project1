;;; boot/bootsector.asm
;;;
;;; Created by Simon Evans on 30/10/2015.
;;; Copyright © 2015 Simon Evans. All rights reserved.
;;;
;;; Simple bootsector to load in the boot16to64 code
;;; Start sector, sector count and hard drive are currently
;;; hardcoded and uses extended BIOS to load

        [MAP ALL bootsector.map]
LOAD_SEG        EQU       0x9000  ; 16bit code loaded here

        ORG     0x7C00
        jmp     0x0000:start    ; initialise CS

        ;; This header is filled in by genisoimage and is otherwise
        ;; blank if booting from disk. Starts at offset 8

        OFFSET  8

el_torito_header:
.pvd_lba:       dd      0       ; primary volume descriptor LBA
.image_lba:     dd      0       ; boot file LBA
.image_len:     dd      0       ; boot file length in bytes
.image_csum:    dd      0       ; boot file checksum
.reserved:      times 40 db 0

        OFFSET  64
start:
        cli
        xor     ax, ax
        mov     ss, ax
        mov     sp, 0x2000
        mov     ds, ax
        sti

        mov     [boot_dev], dl
        ;; if image_len != 0 this it is an ISO9690 image
        mov     cx, [el_torito_header.image_len]
        or      cx, [el_torito_header.image_len + 2]
        test    cx, cx
        jz      not_cdrom       ; Load boot16to64.bin

        ;; If booted from the ISO image, sectors are 2048
        ;; bytes so boot16to64.bin was loaded along with the
        ;; bootsector so it just need to be moved to 9000:0000
        ;; memcpy 0x7E00:0000 -> 0x9000:0000, len=1536
        mov     si, end
        mov     bx, 0x9000
        mov     es, bx
        xor     di, di
        mov     cx, (2048 - 512)
        cld
        rep     movsw

        ;; ISO sectors are 2048 instead of 512 divide the
        ;; sector count for the kernel by 4 and round up
        mov     ax, [kernel_sectors]
        add     ax, 3
        shr     ax, 2
        mov     [kernel_sectors], ax

        ;; Convert the kernel LBA to the ISO LBA and add to
        ;; the LBA offset where the boot file resides
        mov     ax, [kernel_lba]
        shr     ax, 2
        add     ax, [el_torito_header.image_lba]
        mov     [kernel_lba], ax
        mov     byte [sector_size], 11 ; 2048 byes per sector
        jmp     LOAD_SEG:0      ; Execute bootsect16to64.bin

not_cdrom:
        xor     ax, ax
        mov     es, ax
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
msg_fail:       db      "Load failed", 0x0A, 0x0D, 0

;;; Bootsector padding, disk image info and signature
;;; The offset 480 is used by an external program to
;;; patch in the secondary loader and kernel image LBA/sector
;;; counts so must always reside at this locatio
        OFFSET  480

;;; DAP (Disk Address Packet) used for LBA BIOS interface
dap:            db      16              ; DAP size
                db      0               ; always 0
dap_count:      dw      0
dap_offset:     dw      0               ; Code is loaded to LOAD_SEG:0000
dap_segment:    dw      LOAD_SEG
dap_lba:        dq      0               ; 64bit LBA address

kernel_lba      dq      0
kernel_sectors: dw      0               ; Kernel size in sectors
boot_dev:       db      0               ; BIOS disk number
sector_size:    db      9               ; ln2 of bytes per sector 9(512) == disk

        OFFSET  510
                dw      0xAA55          ; Boot signature
end:
