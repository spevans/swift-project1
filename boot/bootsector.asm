;;; Simple bootsector to load in the boot16to64 code
;;; Start sector, sector count and hard drive are currently hardcoded
;;; and uses extended BIOS to load

%define  LOAD_SEG       0x9000  ; 16bit code loaded here

        ORG     0x7C00
        jmp     0x0000:start    ; initialise CS
start:
        xor     ax, ax
        mov     ss, ax
        mov     sp, 0x7C00
        mov     ds, ax
        mov     es, ax

        mov     ah, 0x42         ; Extended read sectors
        mov     dl, [boot_dev]
        mov     si, dap
        int     0x13
        jnc     read_ok
        mov     si, msg_fail
        call    print
        cli
        hlt

read_ok:
        mov     si, msg_ok
        call    print
        jmp     LOAD_SEG:0      ; Execute the loaded code

;;; DAP (Disk Address Packet) used for LBA BIOS interface
dap:            db      16      ; DAP size
                db      0       ; always 0
dap_count:      dw      8       ; allows 4096 bytes of code
dap_offset:     dw      0       ; Code is loaded to LOAD_SEG:0000
dap_segment:    dw      LOAD_SEG
dap_lba:        dq      1       ; 64bit LBA address
boot_dev:       db      0x80    ; First hard disk
msg_ok:         db      "Loaded OK", 0x0A, 0x0D, 0
msg_fail:       db      "Load failed", 0x0A, 0x0D, 0

%include "utils.asm"            ; for print_string

        ;; Bootsector padding and signature
times 510 - ($-$$) db 0
                dw      0xAA55
