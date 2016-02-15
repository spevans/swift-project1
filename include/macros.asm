        %macro OFFSET 1
        times %1 - ($ - $$)   db 0
        %endmacro


        KERNEL_VIRTUAL_BASE     EQU     0x40100000     ; 1GB
        PHYSICAL_MEM_BASE       EQU     0x2000000000   ; 128GB

        CODE_SEG                EQU     0x8
        DATA_SEG                EQU     0x10
        TLS_SEG                 EQU     0x18
        KERNEL_ENTRY            EQU     0x40100000
