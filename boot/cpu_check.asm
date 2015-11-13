;;; cpu_check.asm - Check the CPU is sufficient for 64bit long mode

FEATURE_BIT_LONG_MODE   EQU     1 << 29

;;; Returns carry set if cpu not good enough
cpu_check:
        ;; check CPUID supported by seeing if ID bit in EFLAGS can be toggled

        pushfd

        pushfd
        pop     eax             ; EAX = EFLAGS
        mov     ecx, eax
        xor     ecx, 0x00200000  ; toggle ID bit
        push    ecx
        popfd                   ; load into flags
        pushfd                  ; store to see if change is preserved
        pop     ecx             ; ECX opposite bit to EAX if CPUID present
        popfd                   ; restore EFLAGS
        cmp     ecx, eax
        jne     has_cpuid
        mov     si, msg_no_cpuid
        call    print
        stc                     ; no CPUID
        ret

has_cpuid:
        mov     eax, 0x80000000  ; Get Highest Extended Function Supported
        cpuid
        cmp     eax, 0x80000001  ; has Extended Processor Info and Feature Bits?
        jl      bad_cpu
        mov     eax, 0x80000001
        cpuid
        test    edx, FEATURE_BIT_LONG_MODE
        jz      bad_cpu
        clc                     ; All OK
        ret

bad_cpu:
        mov     si, msg_no_long_mode
        call    print
        stc
        ret

msg_no_cpuid:   db      "CPUID not present", 0x0A, 0x0D, 0
msg_no_long_mode: db    "Long mode not supported", 0x0A, 0x0D, 0
