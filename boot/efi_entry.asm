        SECTION .text
        BITS 64
        DEFAULT REL

        extern efi_main
        extern _binary_output_kernel_bin_start
        extern _binary_output_kernel_bin_end

        global efi_entry
        global kernel_bin_start
        global kernel_bin_end
        global bss_size
        global efi_call2
        global efi_call3
        global efi_call4
        global efi_call5
        global memcpy
        global memset

efi_entry:
        jmp start
        ALIGN   8

;;; Following values are fixedup by efi_patch
_bss_size:      DQ      0x0     ; Kernel BSS size in bytes


start:
        sub     rsp, 0x8        ; ELF requires alignment to 16bytes
        mov     rdi, rcx
        mov     rsi, rdx
        lea     rdx, [pointer_table]
        lea     rcx, [efi_entry]
        mov     [rdx], rcx
        call    efi_main
        xor     rax, rax
        add     rsp, 0x8
        ret


kernel_bin_start:
        lea     rax, [_binary_output_kernel_bin_start]
        ret

kernel_bin_end:
        lea     rax, [_binary_output_kernel_bin_end]
        ret

bss_size:
        mov     rax, [_bss_size]
        ret

;;; MS Windows ABI calling convention, arguments to UEFI need to be in
;;; RCX, RDX, R8, R9
;;; Need to reserve space on stack for 4register +8 to keep aligned
;;; to 16bytes
;;; efi_status_t efi_call2(void *func, void *this, void *data);
;;; RDI: Func to call RSI: *This RDX: Data1
efi_call2:
        sub     rsp, 0x28
        mov     rcx, rsi
        call    rdi
        add     rsp, 0x28
        ret

;;; efi_status_t efi_call3(void *func, void *this, void *data1, void *data2);
;;; RDI: func to call RSI: *This, RDX: data1, RCX: data2
;;; rcx, rdx, r8
efi_call3:
        sub     rsp, 0x28
        mov     r8, rcx
        mov     rcx, rsi
        call    rdi
        add     rsp, 0x28
        ret


;;; rdi, rsi, rdx, rcx, r8,
;;;      rcx, rdx, r8,  r9
efi_call4:
        sub     rsp, 0x28
        mov     r9, r8
        mov     r8, rcx
        mov     rcx, rsi
        call    rdi
        add     rsp, 0x28
        ret


;;; rdi, rsi, rdx, rcx, r8, r9
;;;      rcx, rdx, r8,  r9, sp[0]
efi_call5:
        sub     rsp, 0x28
        mov     [rsp+32], r9
        mov     r9, r8
        mov     r8, rcx
        mov     rcx, rsi
        call    rdi
        add     rsp, 0x28
        ret


;;; void *memcpy(void *dest, const void *src, size_t n)
;;; RDI: dest, RSI: src, RDX: count, returns dest
memcpy:
        mov     rcx, rdx
        mov     rax, rdi
        test    rdx, rdx
        jz      .exit
        shr     rcx, 3
        rep     movsq
        and     rdx, 7
        mov     rcx, rdx
        rep     movsb
.exit:
        ret

;;; void *memset(void *dest, char c, size_t count)
;;; RDI: dest: RSI: c RDX: count
memset:
        mov     rax, rdi
        mov     al, sil
        mov     rcx, rdx
        rep     stosb
        ret


pointer_table:
.image_base     DQ      0
.pagetable:     DQ      0x12345678
.kernel_addr:   DQ      0xDEADBEEF
.last_page:     DQ      0
