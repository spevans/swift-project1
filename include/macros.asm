        %macro OFFSET 1
        times %1 - ($ - $$)   db 0
        %endmacro
