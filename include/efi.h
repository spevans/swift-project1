#ifndef __EFI_H__
#define __EFI_H__

#include <stdint.h>
#include <stddef.h>
#include <elf.h>
#include "fbcon.h"


typedef void *efi_handle_t;
typedef uint8_t efi_boolean;
// For 64bit platforms
typedef uint64_t efi_uintn;
typedef uint64_t efi_physical_address;
typedef uint64_t efi_virtual_address;

int uprintf(const char * _Nonnull fmt, ...) __attribute__ ((format (printf, 1, 2)));

#define EFIERR(a)           (0x8000000000000000 | a)
static inline int
efi_is_error(uint64_t err) {
        return err & 0x8000000000000000;
}

static inline uint64_t
efi_err_num(uint64_t err) {
        return err & 0x8000000000000000-1;
}


typedef enum {
        EFI_SUCCESS             = 0,
        EFI_LOAD_ERROR          = EFIERR(1),
        EFI_INVALID_PARAMETER   = EFIERR(2),
        EFI_UNSUPPORTED         = EFIERR(3),
        EFI_BAD_BUFFER_SIZE     = EFIERR(4),
        EFI_BUFFER_TOO_SMALL    = EFIERR(5),
        EFI_NOT_READY           = EFIERR(6),
        EFI_DEVICE_ERROR        = EFIERR(7),
        EFI_WRITE_PROTECTED     = EFIERR(8),
        EFI_OUT_OF_RESOURCES    = EFIERR(9),
        EFI_VOLUME_CORRUPTED    = EFIERR(10),
        EFI_VOLUME_FULL         = EFIERR(11),
        EFI_NO_MEDIA            = EFIERR(12),
        EFI_MEDIA_CHANGED       = EFIERR(13),
        EFI_NOT_FOUND           = EFIERR(14),
        EFI_ACCESS_DENIED       = EFIERR(15),
        EFI_NO_RESPONSE         = EFIERR(16),
        EFI_NO_MAPPING          = EFIERR(17),
        EFI_TIMEOUT             = EFIERR(18),
        EFI_NOT_STARTED         = EFIERR(19),
        EFI_ALREADY_STARTED     = EFIERR(20),
        EFI_ABORTED             = EFIERR(21),
        EFI_ICMP_ERROR          = EFIERR(22),
        EFI_TFTP_ERROR          = EFIERR(23),
        EFI_PROTOCOL_ERROR      = EFIERR(24),
        EFI_INCOMPATIBLE_VERSION = EFIERR(25),
        EFI_SECURITY_VIOLATION  = EFIERR(26),
        EFI_CRC_ERROR           = EFIERR(27),
        EFI_END_OF_MEDIA        = EFIERR(28),
        EFI_END_OF_FILE         = EFIERR(31),
        EFI_INVALID_LANGUAGE    = EFIERR(32),
        EFI_COMPROMISED_DATA    = EFIERR(33),
} efi_status_t;


typedef struct {
        uint64_t signature;
        uint32_t revision;
        uint32_t header_size;
        uint32_t crc32;
        uint32_t reserved;
} efi_table_header_t;


typedef struct {
        uint32_t data1;
        uint16_t data2;
        uint16_t data3;
        uint8_t data4[8];
} efi_guid_t;


typedef enum {
        efi_all_handles,
        efi_by_register_notify,
        efi_by_protocol
} efi_locate_search_type;


typedef enum {
        EFI_ALLOCATE_ANY_PAGES,
        EFI_ALLOCATE_MAX_ADDRESS,
        EFI_ALLOCATE_ADDRESS,
        EFI_MAX_ALLOCATE_TYPE
} efi_allocate_type;


typedef enum {
        EFI_RESERVED_MEMORY_TYPE,
        EFI_LOADER_CODE,
        EFI_LOADER_DATA,
        EFI_BOOT_SERVICES_CODE,
        EFI_BOOT_SERVICES_DATA,
        EFI_RUNTIME_SERVICES_CODE,
        EFI_RUNTIME_SERVICES_DATA,
        EFI_CONVENTIONAL_MEMORY,
        EFI_UNUSABLE_MEMORY,
        EFI_ACPI_RECLAIM_MEMORY,
        EFI_ACPI_MEMORY_NVS,
        EFI_MEMORY_MAPPED_IO,
        EFI_MEMORY_MAPPED_IO_PORT_SPACE,
        EFI_PAL_CODE,
        EFI_PERSISTENT_MEMORY,
        EFI_MAX_MEMORY_TYPE
} efi_memory_type;


typedef enum {
        EFI_MEMORY_UC = 1ULL << 0,
        EFI_MEMORY_WC = 1ULL << 1,
        EFI_MEMORY_WT = 1ULL << 2,
        EFI_MEMORY_WB = 1ULL << 3,
        EFI_MEMORY_UCE = 1ULL << 4,
        EFI_MEMORY_WP = 1ULL << 12,
        EFI_MEMORY_RP = 1ULL << 13,
        EFI_MEMORY_XP = 1ULL << 14,
        EFI_MEMORY_NV = 1ULL << 15,
        EFI_MEMORY_MORE_RELIABLE = 1ULL << 16,
        EFI_MEMORY_RO = 1ULL << 17,
        EFI_MEMORY_RUNTIME = 1ULL << 63,
} efi_memory_attribute;


typedef struct {
        uint32_t type;
        efi_physical_address physical_start;
        efi_virtual_address virtual_start;
        uint64_t number_of_pages;
        uint64_t attribute;
} efi_memory_descriptor_t;


#include "efi/uga.h"
#include "efi/gop.h"
#include "efi/console.h"
#include "efi/api.h"

struct efi_boot_params {
        char signature[8];      // ASCIIZ string 'EFI'
        size_t size;            // Size of entire table including embedded data and signature
        void * _Nonnull kernel_phys_addr;
        void * _Nonnull memory_map;
        uint64_t memory_map_size;
        uint64_t memory_map_desc_size;
        struct frame_buffer fb;
        uint64_t nr_efi_config_entries;
        const efi_config_table_t * _Nonnull efi_config_table;
        const Elf64_Sym * _Nonnull symbol_table;
        uint64_t symbol_table_size;
        const char * _Nonnull string_table;
        uint64_t string_table_size;
}  __attribute__((packed));

// ELF functions used for the ELF kernel.

struct elf_file {
        void * _Nonnull file_data; // mmap()'d input ELF file
        size_t file_len;
        Elf64_Ehdr * _Nonnull elf_hdr;
        Elf64_Shdr * _Nonnull section_headers;
        Elf64_Phdr * _Nonnull program_headers;
        Elf64_Shdr * _Nonnull sh_string_table;
        Elf64_Shdr * _Nullable string_table;
        Elf64_Shdr * _Nullable symbol_table;
};

efi_status_t elf_init_file(struct elf_file * _Nonnull kernel_image);
Elf64_Phdr * _Nullable elf_program_header(struct elf_file * _Nonnull file, size_t idx);
void * _Nonnull elf_program_data(struct elf_file * _Nonnull file, Elf64_Phdr * _Nonnull header);
Elf64_Shdr * _Nullable elf_section_header(struct elf_file * _Nonnull file, size_t idx);

#endif  // __EFI_H__
