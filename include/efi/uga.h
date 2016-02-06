#ifndef __EFI_UGA_H__
#define __EFI_UGA_H__

#define EFI_UGA_PROTOCOL_GUID           \
        { 0x982c298b, 0xf4fa, 0x41cb, { 0xb8, 0x38, 0x77, 0xaa, 0x68, 0x8f, 0xb8, 0x39 }}

#define EFI_UGA_IO_PROTOCOL_GUID        \
        { 0x61a4d49e, 0x6f68, 0x4f1b, { 0xb9, 0x22, 0xa8, 0x6e, 0xed, 0xb, 0x7, 0xa2 }}


struct _efi_uga_draw_protocol;

typedef efi_status_t
(*efi_uga_draw_protocol_get_mode_t)(struct _efi_uga_draw_protocol *this,
                                    uint32_t *horizontal_resolution,
                                    uint32_t *vertical_resolution,
                                    uint32_t *color_depth,
                                    uint32_t *refresh_rate);

typedef efi_status_t
(*efi_uga_draw_protocol_set_mode_t)(struct _efi_uga_draw_protocol *this,
                                    uint32_t horizontal_resolution,
                                    uint32_t vertical_resolution,
                                    uint32_t color_depth,
                                    uint32_t refresh_rate);

typedef struct {
        uint8_t blue;
        uint8_t green;
        uint8_t red;
        uint8_t reserved;
} efi_uga_pixel_t;


typedef enum {
        efi_uga_video_fill,
        efi_uga_video_to_blt_buffer,
        efi_uga_blt_buffer_to_video,
        efi_uga_video_to_video,
        efi_uga_blt_max
} efi_uga_blt_operation_t;

typedef efi_status_t
(*efi_uga_draw_protocol_blt_t) (struct _efi_uga_draw_protocol *this,
                                efi_uga_pixel_t *blt_buffer,
                                efi_uga_blt_operation_t blt_operation,
                                efi_uintn source_x,
                                efi_uintn source_y,
                                efi_uintn destination_X,
                                efi_uintn destination_y,
                                efi_uintn width,
                                efi_uintn height,
                                efi_uintn delta);


typedef struct _efi_uga_draw_protocol {
        efi_uga_draw_protocol_get_mode_t get_mode;
        efi_uga_draw_protocol_set_mode_t SetMode;
        efi_uga_draw_protocol_blt_t Blt;
} efi_uga_draw_protocol_t;

#endif  // __EFI_UGA_H__
