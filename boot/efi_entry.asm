;;; boot/efi_entry.asm
;;;
;;; Created by Simon Evans on 06/02/2016.
;;; Copyright © 2016 Simon Evans. All rights reserved.
;;;
;;; Entry point from the UEFI firmware. Calls boot/efi_main.c
;;; to setup the page tables and framebuffer then setups CR3
;;; and enters kernel at its correct virtual address


        SECTION .text
        BITS 64
        DEFAULT REL

        extern efi_main
        extern _binary_output_kernel_elf_start
        extern _binary_output_kernel_elf_end

        global efi_entry
        global kernel_elf_header
        global kernel_elf_end
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

        ;; rax holds return status, 0 == EFI_SUCCESS so can process else
        ;; return to UEFI. ExitBootServices() will have beed called
        ;; if everything was setup ok
        test    rax, rax
        jz      enter_kernel
        add     rsp, 0x8
        ret                     ; return to UEFI

enter_kernel:
        ;; copy the entry_stub into the last page as that
        ;; page is mapped in both the identity mapping under
        ;; UEFI's CR3 and in the kernel's virtual address space
        ;; under the new CR3
        cli
        lea     rsi, [entry_stub]
        mov     rdi, [pointer_table.last_page]
        mov     rbx, rdi
        lea     rcx, [stub_end]
        sub     rcx, rsi
        rep     movsb
        jmp     rbx             ; entry_stub copied into last_page

kernel_elf_header:
        lea     rax, [_binary_output_kernel_elf_start]
        ret

kernel_elf_end:
        lea     rax, [_binary_output_kernel_elf_end]
        ret

bss_size:
        mov     rax, [_bss_size]
        ret

;;; Helper functions for efi_main.c

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

;;; All code below must be relative since it needs to work where it is
;;; loaded by UEFI and also when it has been copied to the last BSS page
;;; of the mapped in kernel. Everything between entry_stop and stub_end
;;; is copied
        ALIGN   16
entry_stub:
        mov     rax, [pointer_table.pml4]
        mov     cr3, rax
        ;; Only kernel is mapped in now, no UEFI services
        ;; reload IDT/GDT since the kernel startup will load selector 0x18
        ;; into FS so GDT needs to be valid. This IDT/GDT is only temporary

        lea     rax, [GDT]
        mov     [GDT.address], rax
        lgdt    [GDT.pointer]
        lidt    [IDT.pointer]
        ;; temporary stack to allow a far jmp, just needs to entries
        ;; overwrite the earlier code. RSP will be reset after entry
        ;; to the kernel
        lea     rsp, [entry_stub + 16]


        ;; fake a jmp  dword CODE_SEG:KERNEL_ENTRY which isnt allowed
        ;; directly in long mode
        push    qword CODE_SEG
        push    qword KERNEL_ENTRY

        ;; Make RDI -> Virtual address of framebuffer info in the kernel's
        ;; virtual address space
        mov     r8, KERNEL_VIRTUAL_BASE
        lea     rdi, [framebuffer]
        mov     rsi, [pointer_table.kernel_addr]
        sub     rdi, rsi
        add     rdi, r8         ; Convert address to kernel's virtual mapping
        mov     edx, edi
        shr     rdi, 32
        mov     ecx, edi        ; ECX:EDX => framebuffer info
        lea     rsi, [pointer_table.efi_boot_params]
        sub     rsi, [pointer_table.kernel_addr] ; RSI => efi_boot_params
        add     rsi, r8
        mov     rdi, rsi
        shr     rdi, 32         ; EDI:ESI => boot params
        db      0x48
        retf


IDT:
        ALIGN 4
.pointer:
        ;; NULL IDT: 0 base, 0 length
        dw      0               ; 16bit length
        dq      0               ; 32bit base address

GDT:
        dq      0x0000000000000000 ; Null descriptor
        ;; Code descriptor, base=0, limit=0 Present, Ring 0, RO/EX Longmode
        dq      0x00209A0000000000
        ;; Data descriptor, base=0, limit=0 Present, Ring 0, RW Longmode
        dq      0x0000920000000000
        dq      0x0000000000000000 ; Null descriptor


.pointer:
        dw      ($ - GDT) - 1   ; 16bit length -1
.address:
        dq      0               ; 64bit base address

        ALIGN   8

;;; These values are setup by efi_main.c - this layout must match
;;; struct efi_boot_params in include/mm.h
pointer_table:
        .image_base     DQ      0
        .pml4:          DQ      0x12345678
        .last_page:     DQ      0
.efi_boot_params:       DQ      "EFI"
        .size           DQ      0
        .kernel_addr:   DQ      0xDEADBEEF
        .mem_map        DQ      0
        .mem_map_sz:    DQ      0
        .mem_map_desc_sz:DQ     0
framebuffer:
        .address:       DQ      0
        .size:          DQ      0
        .width:         DD      0
        .height:        DD      0
        .px_per_line:   DD      0
        .depth:         DD      0
        .colour_info:   DB      0, 0, 0, 0, 0, 0
efi_config_table:
        .nr_cfg_entries:DQ      0
        .config_table:  DQ      0
symbol_table:
        .address:       DQ      0
        .size:          DQ      0
string_table:
        .address:       DQ      0
        .size:          DQ      0

        ALIGN   8
stub_end:
