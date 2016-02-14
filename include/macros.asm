        %macro OFFSET 1
        times %1 - ($ - $$)   db 0
        %endmacro


        KERNEL_VIRTUAL_BASE     EQU     0x40100000     ; 1GB
        PHYSICAL_MEM_BASE       EQU     0x2000000000   ; 128GB
