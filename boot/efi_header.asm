        BITS    64
        DEFAULT REL

        ORG     0
        DB      "MZ"            ; PE/COFF Header signature

times 0x3c - ($ - $$)   db 0
        DD      pe_header       ; offset to pe_header

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

optional_header:                ; Required for Executables
        DW      0x20b           ; Magic: PE32+
        DB      0x1             ; MajorLinkerVersion
        DB      0x2             ; MinorLinkerVersion
        DD      0x3000          ; SizeOfCode (sum of all code sections)
        DD      0x000           ; SizeOfInitializedData (sum of all data sections)
        DD      0x000           ; SizeOfUninitializedData (sum of all bss sections)
        DD      0x1000          ; AddressOfEntryPoint
        DD      0x1000          ; BaseOfCode (beginning of code section)

windows_header:
        DQ      0               ; ImageBase (preferred address)
        DD      4096            ; SectionAlignment
        DD      0x200           ; FileAlignment
        DW      0               ; MajorOperatingSystemVersion
        DW      0               ; MinorOperatingSystemVersion
        DW      0               ; MajorImageVersion
        DW      0               ; MinorImageVersion
        DW      0               ; MajorSubsystemVersion
        DW      0               ; MinorSubsystemVersion
        DD      0               ; Win32VersionValue
        DD      0x4000          ; SizeOfImage
        DD      0x200           ; SizeOfHeaders
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

        ;; .text (text+rodata+data)
        DB      '.text',0, 0, 0 ; Name
        DD      0x3000          ; VirtualSize
        DD      0x1000          ; VirtualAddress
        DD      0x3000          ; SizeOfRawData
        DD      0x1000          ; PointerToRawData
        DD      0               ; PointerToRelocations
        DD      0               ; PointerToLineNumbers
        DW      0               ; NumberOfRelocations
        DW      0               ; NumberOfLineNumbers
        DD      0x40500020      ; Characteristics
                                ; IMAGE_SCN_CNT_CODE
                                ; IMAGE_SCN_ALIGN_16BYTES
                                ; IMAGE_SCN_MEM_EXECUTE
                                ; IMAGE_SCN_MEM_READ



times 0x200 - ($ - $$)   db 0   ; End of 'boot' sector

;;; Add at least 1 reloc entry so the UEFI loader thinks the binary is valid
reloc_space:
        DD reloc_space + 10, 0xa
        DW 0x0

times 0x1000 - ($ - $$) db 0    ; Pad to PAGE_SIZE
