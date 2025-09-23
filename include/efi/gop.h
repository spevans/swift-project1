#ifndef __EFI_GOP_H__
#define __EFI_GOP_H__

#define EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID    \
        { 0x9042a9de, 0x23dc, 0x4a38, { 0x96, 0xfb, 0x7a, 0xde, 0xd0, 0x80, 0x51, 0x6a }}


struct _efi_graphics_output_protocol;

typedef struct {
        uint32_t red_mask;
        uint32_t green_mask;
        uint32_t blue_mask;
        uint32_t reserved_mask;
} efi_pixel_bitmask_t;

typedef enum {
        pixel_red_green_blue_reserved8_bit_per_color,
        pixel_blue_green_red_reserved8_bit_per_color,
        pixel_bit_mask,
        pixel_blt_only,
        pixel_format_max
} efi_graphics_pixel_format_t;


typedef struct {
        uint32_t version;
        uint32_t horizontal_resolution;
        uint32_t vertical_resolution;
        efi_graphics_pixel_format_t pixel_format;
        efi_pixel_bitmask_t pixel_information;
        uint32_t pixels_per_scan_line;
} efi_graphics_output_mode_information_t;


typedef struct {
        uint32_t max_mode;
        uint32_t mode;
        efi_graphics_output_mode_information_t *info;
        efi_uintn size_of_info;
        efi_physical_address frame_buffer_base;
        efi_uintn frame_buffer_size;
} efi_graphics_output_protocol_mode_t;


typedef struct {
        uint8_t blue;
        uint8_t green;
        uint8_t red;
        uint8_t reserved;
} efi_graphics_output_blt_pixel_t;


typedef union {
        efi_graphics_output_blt_pixel_t pixel;
        uint32_t raw;
} efi_graphics_output_blt_pixel_union;


typedef enum {
        efi_blt_video_fill,
        efi_blt_video_to_blt_buffer,
        efi_blt_buffer_to_video,
        efi_blt_video_to_video,
        efi_graphics_output_blt_operation_max
} efi_graphics_output_blt_operation_t;


typedef efi_status_t
(*efi_graphics_output_protocol_query_mode_t)(struct _efi_graphics_output_protocol *this,
                                             uint32_t mode_number,
                                             efi_uintn *size_of_info,
                                             efi_graphics_output_mode_information_t **info) __attribute__((ms_abi));

typedef efi_status_t
(*efi_graphics_output_protocol_set_mode_t)(struct _efi_graphics_output_protocol *this,
                                           uint32_t mode_number) __attribute__((ms_abi));

typedef efi_status_t
(*efi_graphics_output_protocol_blt_t)(struct _efi_graphics_output_protocol *this,
                                      efi_graphics_output_blt_pixel_t *blt_buffer,
                                      efi_graphics_output_blt_operation_t *blt_op,
                                      efi_uintn source_x,
                                      efi_uintn source_y,
                                      efi_uintn destination_x,
                                      efi_uintn destination_y,
                                      efi_uintn width,
                                      efi_uintn height,
                                      efi_uintn delta) __attribute__((ms_abi));


typedef struct _efi_graphics_output_protocol {
        efi_graphics_output_protocol_query_mode_t query_mode;
        efi_graphics_output_protocol_set_mode_t set_mode;
        efi_graphics_output_protocol_blt_t blt;
        efi_graphics_output_protocol_mode_t *mode;
} efi_graphics_output_protocol_t;

#endif  // __EFI_GOP_H__
