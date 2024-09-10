        BITS    64
        DEFAULT REL

        ORG     0
        DB      "MZ"            ; PE/COFF Header signature

        OFFSET  0x3c            ; offset to pe_header

        DD      pe_header

;;; offset 64
pe_header:
        ;; https://upload.wikimedia.org/wikipedia/commons/7/70/Portable_Executable_32_bit_Structure_in_SVG.svg
        ;; COFF header
        DB      "PE"                            ; Signature
        DW      0
        DW      0x8664                          ; machine: x86-64
        DW      2                               ; NumberOfSections
        DD      0                               ; TimeDateStamp
        DD      0                               ; PointerToSymbolTable
        DD      0                               ; NumberOfSymbols
        DW      section_table - optional_header ; SizeOfOptionalHeader
        DW      0x206                           ; Characteristics:
                                                ; IMAGE_FILE_EXECUTABLE_IMAGE   0x0002
                                                ; IMAGE_FILE_LINE_NUMS_STRIPPED 0x0004
                                                ; IMAGE_FILE_DEBUG_STRIPPED     0x0200
;;; offset 88 bytes
optional_header:                ; Required for Executables
        DW      0x20b           ; Magic: PE32+
        DB      0x1             ; MajorLinkerVersion
        DB      0x2             ; MinorLinkerVersion
        ;; fixed up by efi_patch
        DD      0x0000          ; SizeOfCode (sum of all code sections)
        ;; fixed up by efi_patch
        DD      0x0000          ; SizeOfInitializedData (sum of all data sections)
        ;; fixed up by efi_patch
        DD      0x0000          ; SizeOfUninitializedData (sum of all bss sections)
        DD      entry_point     ; AddressOfEntryPoint
        DD      entry_point     ; BaseOfCode (beginning of code section)

;;; offset 112 bytes
windows_header:
        DQ      0               ; ImageBase (preferred address)
        DD      0x20            ; SectionAlignment - PAGE_SIZE
        DD      0x20            ; FileAlignment
        DW      0               ; MajorOperatingSystemVersion
        DW      0               ; MinorOperatingSystemVersion
        DW      0               ; MajorImageVersion
        DW      0               ; MinorImageVersion
        DW      0               ; MajorSubsystemVersion
        DW      0               ; MinorSubsystemVersion
        DD      0               ; Win32VersionValue
        ;; fixed up by efi_patch
        DD      0               ; SizeOfImage
        DD      header_end      ; SizeOfHeaders
        DD      0               ; Checksum
        DW      0xA             ; Subsystem (IMAGE_SUBSYSTEM_EFI_APPLICATION)
        DW      0               ; DLL Characteristics
        DQ      0               ; SizeOfStackReserve
        DQ      0               ; SizeOfStackCommit
        DQ      0               ; SizeOfHeapReserve
        DQ      0               ; SizeOfHeapCommit
        DD      0               ; LoaderFlags
        DD      6               ; NumberOfRvaAndSizes

        ;; Data Directory entries (RVA)
        DQ      0               ; ExportTable
        DQ      0               ; ImportTable
        DQ      0               ; ResourceTable
        DQ      0               ; ExceptionTable
        DQ      0               ; CertificationTable
        DD      reloc_space, 0xa ; BaseRelocationTable


section_table:
;;; offset 248 bytes
        ;; .reloc section required by EFI loader
        DB      '.reloc', 0, 0  ; Name
        DD      0xa             ; VirtualSize
        DD      reloc_space     ; VirtualAddress
        DD      0xa             ; SizeOfRawData
        DD      reloc_space     ; PointerToRawData
        DD      0               ; PointerToRelocations
        DD      0               ; PointerToLineNumbers
        DW      0               ; NumberOfRelocations
        DW      0               ; NumberOfLineNumbers
        DD      0x42100040      ; Characteristics
                                ; IMAGE_SCN_CNT_INITIALIZED_DATA
                                ; IMAGE_SCN_ALIGN_1BYTES
                                ; IMAGE_SCN_MEM_DISCARDABLE
                                ; IMAGE_SCN_MEM_READ

;;; offset 288 bytes
        ;; .text (text+rodata+data+bss)
        DB      '.text',0, 0, 0 ; Name
        ;; fixed up by efi_patch
        DD      0x0             ; VirtualSize
        DD      entry_point     ; VirtualAddress
        ;; fixed up by efi_patch
        DD      0x0             ; SizeOfRawData
        DD      entry_point     ; PointerToRawData
        DD      0               ; PointerToRelocations
        DD      0               ; PointerToLineNumbers
        DW      0               ; NumberOfRelocations
        DW      0               ; NumberOfLineNumbers
        DD      0x60500060      ; Characteristics
                                ; IMAGE_SCN_CNT_CODE
                                ; IMAGE_SCN_CNT_INITIALIZED_DATA
                                ; IMAGE_SCN_ALIGN_16BYTES
                                ; IMAGE_SCN_MEM_EXECUTE
                                ; IMAGE_SCN_MEM_READ

header_end:
        ALIGN   32
;;; Add at least 1 reloc entry so the UEFI loader thinks the binary is valid
reloc_space:
        DD reloc_space + 10, 0xa
        DW 0x0


        OFFSET 512         ; End of 'boot' sector
        ;; EFI loader code is appended directly after here
entry_point:
