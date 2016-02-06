#ifndef __EFI_H__
#define __EFI_H__

#include <stdint.h>
#include <stddef.h>

typedef void *efi_handle_t;
typedef uint8_t efi_boolean;
// For 64bit platforms
typedef uint64_t efi_uintn;
typedef uint64_t efi_physical_address;

#define EFIERR(a)           (0x8000000000000000 | a)

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


#include <efi/uga.h>
#include <efi/gop.h>
#include <efi/console.h>
#include <efi/api.h>

#endif  // __EFI_H__
