;;; print_string - print ASCIIZ string in DS:SI via BIOS
print:
        lodsb
        test    al, al
        je      print_return
        mov     ah, 0x0E
        int     0x10
        jmp     print

print_return:
        ret


;;; Simple IO delay by writing to an unused I/O port
io_delay:
        out     0x80, al
        ret
