#include <efi.h>
#include <fbcon.h>
#include "../lib/font_8x16.c"


static efi_system_table_t *sys_table;
static void *image_handle;

// Base address that image is loaded at by UEFI firmware, used to offset
// static addreses
static uint64_t image_base;


void __attribute__ ((noinline))
efi_print_string(uint16_t *str)
{
        efi_call2(sys_table->con_out->output_string, (uintptr_t)sys_table->con_out,
                  (uintptr_t)str);
}


void __attribute__ ((noinline))
print_string(char *str)
{
        uint16_t buf[128];
        for (int x = 0; x < 128; x++) {
                buf[x] = 0;
        }
        int j = 0;
        while(*str) {
                char ch = *str++;
                if (ch == '\n') {
                        buf[j++] = (uint16_t)'\r';
                }
                buf[j++] = (uint16_t)ch;
        }
        buf[j++] = (uint16_t)'\0';
        efi_print_string(buf);
}


void  __attribute__ ((noinline))
print_char(char ch)
{
        if (ch == '\n') {
                efi_print_string(L"\r\n");
        } else {
                char buf[4];
                buf[0] = ch;
                buf[1] = '\0';
                buf[2] = '\0';
                buf[3] = '\0';
                efi_print_string((uint16_t *)buf);
        }
}


/* Simple number printing functions that dont invoke *printf */


void __attribute__ ((noinline))
print_nibble(int value)
{
        char *hex = "0123456789ABCDEF";
        print_char(hex[value & 0xf]);
}


void  __attribute__ ((noinline))
print_byte(int value)
{
        print_nibble((value >> 4) & 0xf);
        print_nibble(value & 0xf);
}


void
print_number(uint64_t value)
{
        char *digits = "0123456789";
        char buf[32];
        buf[31] = 0;
        int i = 31;

        do {
                buf[--i] = digits[value % 10];
                value /= 10;
        } while(value > 0);
        print_string(&buf[i]);
}


void
print_word(int value)
{
        print_byte((value >> 8) & 0xff);
        print_byte(value & 0xff);
}


void
print_dword(unsigned int value)
{
        print_word((value >> 16) & 0xffff);
        print_word(value & 0xffff);

}


void
print_qword(uint64_t value)
{
        print_dword((value >> 32) & 0xffffffff);
        print_dword(value & 0xffffffff);
}


void
print_pointer(void *ptr)
{
        print_string("0x");
        print_qword((uintptr_t)ptr);
}


efi_status_t
wait_for_key(efi_input_key_t *key)
{
        efi_status_t status;
        efi_input_key_t dummy;
        if (key == NULL) {
                key = &dummy;
        }
        do {
                status = efi_call2(sys_table->con_in->read_key,
                                   (uintptr_t)sys_table->con_in, (uintptr_t)key);
        } while(status == EFI_NOT_READY);
        return status;
}


void
print_status(char *str, efi_status_t status)
{
        print_string(str);
        print_string(" status = ");
        print_qword(status);
        print_char('\n');
}


efi_status_t
set_text_mode(int on)
{
        efi_guid_t protocol = EFI_CONSOLE_CONTROL_GUID;
        efi_console_control_interface_t *interface;

        efi_status_t status = efi_call3(sys_table->boot_services->locate_protocol,
                                        (uintptr_t)&protocol, (uintptr_t)NULL,
                                        (uintptr_t) &interface);


        print_status("LocateProtocol EFI_CONSOLE_CONTROL_GUID", status);

        if (status != EFI_SUCCESS) {
                return status;
        }

        efi_console_screen_mode_t mode;
        status = efi_call4(interface->get_mode, (uintptr_t)interface,
                           (uintptr_t)&mode, 0, 0);
        print_status("get_mode", status);
        if (status != EFI_SUCCESS) {
                return 0;
        }
        print_string("Setting text mode\n");
        efi_console_screen_mode_t newmode = on ? efi_screen_text : efi_screen_graphics;
        status = efi_call2(interface->set_mode, (uintptr_t)interface, newmode);
        print_status("set_mode", status);

        return status;
}


efi_status_t
locate_handle(efi_locate_search_type type, efi_guid_t *guid, void *search_key,
              uint64_t *nr_handles, efi_handle_t *handles)
{
        return efi_call5(sys_table->boot_services->locate_handle,
                         type, (uintptr_t)guid, (uintptr_t)search_key,
                         (uintptr_t)nr_handles, (uintptr_t)handles);
}


void
convert_mask(uint32_t mask_in, uint8_t *shift, uint8_t *mask)
{
        switch(mask_in) {
        case 0xff000000:
                *shift = 24;
                *mask = 0xff;
                break;

        case 0x00ff0000:
                *shift = 16;
                *mask = 0xff;
                break;

        case 0x0000ff00:
                *shift = 8;
                *mask = 0xff;
                break;

        case 0x000000ff:
                *shift = 0;
                *mask = 0xff;
                break;

        default:
                *shift = 0;
                *mask = 0;
        }
}


void
gop_bytes_pp(efi_graphics_output_mode_information_t *info, struct frame_buffer *fb)
{
        switch(info->pixel_format) {
        case pixel_blue_green_red_reserved8_bit_per_color:
                fb->depth = 32;
                fb->red_shift = 16;
                fb->red_mask = 0xff;
                fb->green_shift = 8 ;
                fb->green_mask = 0xff;
                fb->blue_shift = 0;
                fb->blue_mask = 0xff;
                break;

        case pixel_red_green_blue_reserved8_bit_per_color:
                fb->depth = 32;
                fb->red_shift = 24;
                fb->red_mask = 0xff;
                fb->green_shift = 16;
                fb->green_mask = 0xff;
                fb->blue_shift = 8;
                fb->blue_mask = 0xff;
                break;

        case pixel_bit_mask:
                fb->depth = 24;
                convert_mask(info->pixel_information.red_mask,
                             &fb->red_shift, &fb->red_mask);
                convert_mask(info->pixel_information.green_mask,
                             &fb->green_shift, &fb->green_mask);
                convert_mask(info->pixel_information.blue_mask,
                             &fb->blue_shift, &fb->blue_mask);
                break;

        case pixel_blt_only:
        default:
                fb->depth = 0;
                fb->red_shift = 0;
                fb->red_mask = 0x0;
                fb->green_shift = 0;
                fb->green_mask = 0x0;
                fb->blue_shift = 0;
                fb->blue_mask = 0x0;
                break;
        }
}


void
show_gop_mode(uint32_t mode, efi_graphics_output_mode_information_t *info)
{
        print_number(mode);
        print_string(": ");
        print_number(info->horizontal_resolution);
        print_string("x");
        print_number(info->vertical_resolution);
        print_char(' ');

        switch(info->pixel_format) {
        case pixel_red_green_blue_reserved8_bit_per_color:
                print_string("RGBR");
                break;

        case pixel_blue_green_red_reserved8_bit_per_color:
                print_string("BGRR");
                break;

        case pixel_bit_mask:
                print_string("R: ");
                print_dword(info->pixel_information.red_mask);
                print_string(" G: ");
                print_dword(info->pixel_information.green_mask);
                print_string(" B: ");
                print_dword(info->pixel_information.blue_mask);
                print_string(" X: ");
                print_dword(info->pixel_information.reserved_mask);
                break;

        case pixel_blt_only:
                print_string("(blt only)");
                break;

        default:
                print_string("(Invalid pixel format)");
                break;
        }
        print_string(" pitch: ");
        print_number(info->pixels_per_scan_line);
        print_char('\n');
}


efi_status_t
show_gop_info(efi_graphics_output_protocol_t *gop,
              efi_graphics_output_mode_information_t *mode_info)
{
        print_string("MaxMode: ");
        print_number(gop->mode->max_mode);
        print_string(" Mode: ");
        print_number(gop->mode->mode);
        print_string(" fb addr: ");
        print_qword(gop->mode->frame_buffer_base);
        print_string(" fb size: ");
        print_qword(gop->mode->frame_buffer_size);

        efi_graphics_output_mode_information_t best_mode_info;
        uint32_t best_mode = gop->mode->mode;
        uint32_t best_width = 0;
        uint32_t mode;
        for(mode = 0; mode < gop->mode->max_mode; mode++) {
                efi_uintn size_of_info;
                efi_graphics_output_mode_information_t *info;
                efi_status_t status = efi_call4(gop->query_mode, (uintptr_t)gop,
                                                mode, (uintptr_t)&size_of_info,
                                                (uintptr_t)&info);
                if (status != EFI_SUCCESS) {
                        print_status("QueryMode", status);
                        return status;
                }
                if (mode == gop->mode->mode && mode_info != NULL) {
                        *mode_info = *info;
                }

                if (info->horizontal_resolution > best_width) {
                        best_mode = mode;
                        best_width = info->horizontal_resolution;
                        best_mode_info = *info;
                }
                show_gop_mode(mode, info);
        }
        efi_status_t status = EFI_SUCCESS;
        if (best_mode != gop->mode->mode) {
                print_string("Trying to set mode to ");
                print_number(best_mode);
                print_char('\n');
                wait_for_key(NULL);
                status = efi_call2(gop->set_mode, (uintptr_t)gop, best_mode);
                if (status != EFI_SUCCESS) {
                        print_status("Cant set best GOP mode", status);
                } else {
                        if (mode_info != NULL) {
                                *mode_info = best_mode_info;
                        }
                }
        }

        return status;
}


efi_status_t
find_gop(struct frame_buffer *fb)
{
        efi_handle_t handles[64];
        uint64_t buffer_sz = sizeof(handles);
        efi_guid_t guid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;

        print_string("looking for GOP\n");
        efi_status_t status = locate_handle(efi_by_protocol, &guid, NULL,
                                            &buffer_sz, handles);
        if (status != EFI_SUCCESS) {
                print_status("locate_handle EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID", status);
                print_string("Cant find GOP graphics\n");
                return status;
        }

        int handlecnt = buffer_sz / sizeof(efi_handle_t);
        print_string("Found ");
        print_dword(handlecnt);
        print_string(" GOP handles\n");

        efi_graphics_output_protocol_t *first_gop = NULL;
        efi_graphics_output_mode_information_t current_info;
        for (int i = 0; i < handlecnt; i++) {
                efi_graphics_output_protocol_t *gop;
                status = efi_call3(sys_table->boot_services->handle_protocol,
                                   (uintptr_t)handles[i], (uintptr_t)&guid,
                                   (uintptr_t)&gop);
                if (status != EFI_SUCCESS) {
                        print_status("handle_procotol", status);
                        continue;
                }
                print_string("handle: ");
                print_pointer(handles[i]);
                print_string(" interface: ");
                print_pointer(gop);
                print_char('\n');

                if (i==0) {
                        first_gop = gop;
                        if (show_gop_info(gop, &current_info) == EFI_SUCCESS) {
                                break;
                        }
                } else {
                        show_gop_info(gop, NULL);
                }
        }


        fb->address = (void *)first_gop->mode->frame_buffer_base;
        fb->size = first_gop->mode->frame_buffer_size;
        fb->width = current_info.horizontal_resolution;
        fb->height = current_info.vertical_resolution;
        gop_bytes_pp(&current_info, fb);
        fb->px_per_scanline = current_info.pixels_per_scan_line;

        return EFI_SUCCESS;
}


efi_status_t
find_uga(struct frame_buffer *fb)
{
        efi_handle_t handles[64];
        uint64_t buffer_sz = sizeof(handles);
        efi_guid_t guid = EFI_UGA_PROTOCOL_GUID;
        print_string("looking for UGA\n");
        efi_status_t status = locate_handle(efi_by_protocol, &guid, NULL,
                                            &buffer_sz, handles);
        if (status != EFI_SUCCESS) {
                print_status("locate_handle EFI_UGA_PROTOCOL_GUID", status);
                print_string("Cant find GOP graphics\n");
                return status;
        }
        int handlecnt = buffer_sz / sizeof(efi_handle_t);
        print_string("Found ");
        print_number(handlecnt);
        print_string(" UGA handles\n");

        for (int i = 0; i < handlecnt; i++) {
                efi_uga_draw_protocol_t *uga;
                status = efi_call3(sys_table->boot_services->handle_protocol,
                                   (uintptr_t)handles[i], (uintptr_t)&guid,
                                   (uintptr_t)&uga);
                if (status != EFI_SUCCESS) {
                        print_status("handle_procotol ", status);
                        continue;
                }
                print_string("handle: ");
                print_pointer(handles[i]);
                print_string(" interface: ");
                print_pointer(uga);
                print_char('\n');

                uint32_t hres, vres, depth, refresh;
                status = efi_call5(uga->get_mode, (uintptr_t)uga, (uintptr_t)&hres,
                                   (uintptr_t)&vres, (uintptr_t)&depth,
                                   (uintptr_t)&refresh);
                if (status == EFI_SUCCESS) {
                        fb->width = hres;
                        fb->height = vres;

                        // UGA is 32bpp XRGB
                        fb->depth = depth;
                        fb->red_shift = 16;
                        fb->red_mask = 0xff;
                        fb->green_shift = 8;
                        fb->green_mask = 0xff;
                        fb->blue_shift = 0;
                        fb->blue_mask = 0xff;

                        // Hardcoding for Macbook for now
                        fb->address = (void *)0xC0000000;
                        fb->px_per_scanline = 2048;
                        fb->size = hres * vres * 2048;

                        return EFI_SUCCESS;
                } else {
                        print_status("get_mode", status);
                }
        }

        return EFI_NOT_FOUND;
}


static inline void
split_rgb(uint32_t colour, uint8_t *red, uint8_t *green, uint8_t *blue)
{
        *blue = colour & 0xff;
        *green = (colour >> 8) & 0xff;
        *red = (colour >> 16) & 0xff;
}


static uint32_t text_colour = 0x00ffffff;
static uint8_t text_red = 0xff, text_green = 0xff, text_blue = 0xff;
static void set_text_colour(uint32_t colour)
{
        text_colour = colour;
        split_rgb(colour, &text_red, &text_green, &text_blue);
}


uint32_t
colour_mask(struct frame_buffer *fb, uint8_t red, uint8_t green, uint8_t blue)
{
        uint32_t colour = (red & fb->red_mask) << fb->red_shift;
        colour |= (green & fb->green_mask) << fb->green_shift;
        colour |= (blue & fb->blue_mask) << fb->blue_shift;

        return colour;
}


static inline int
convert_font_line(struct frame_buffer *fb, const struct font *font,
                  const unsigned char *data, uint8_t *buf)
{
        unsigned int offset = 0;
        uint32_t mask = colour_mask(fb, text_red, text_green, text_blue);
        for(int i = font->width-1; i >= 0; i--) {
                int bit = data[0] & (1 << i);
                for(uint32_t i = 0; i < (fb->depth/8); i++) {
                        buf[offset++] = bit ? (mask >> (i*8)) : 0;
                }
        }

        return offset;
}


static inline void
console_size(struct frame_buffer *fb, const struct font *font,
             uint32_t *max_x, uint32_t *max_y)
{
        *max_x = fb->width / font->width;
        *max_y = fb->height / font->height;
}


static const unsigned char *
font_data(const struct font *font)
{
        // font->data is compiled in for binary @ 0 so add image offset
        return image_base + font->data;
}


void
print_fb_char(struct frame_buffer *fb, uint32_t x, uint32_t y, unsigned char ch)
{
        const struct font *font = &font8x16;
        int bytes_per_char = ((font->width + 7) / 8) * font->height;

        uint32_t max_x, max_y;
        console_size(fb, font, &max_x, &max_y);
        if (x >= max_x || y >= max_y) {
                return;
        }

        const unsigned char *char_data = font_data(font) + (bytes_per_char * ch);

        uint8_t *screen = (uint8_t *)fb->address;
        unsigned int pixel = (y * font->height) * fb->px_per_scanline + (x * font->width);
        pixel *= (fb->depth/8);
        for(int line = 0; line < font->height; line++) {
                uint8_t buf[128];
                int px = convert_font_line(fb, font, char_data, buf);
                for(int p = 0; p < px; p++) {
                        screen[pixel + p] = buf[p];
                }
                pixel += (fb->px_per_scanline * (fb->depth/8));
                char_data += ((font->width + 7) / 8);
        }
}


void static inline
plot_pixel(struct frame_buffer *fb, uint32_t x, uint32_t y,
           uint8_t red, uint8_t blue, uint8_t green)
{
        if (x > fb->width || y > fb->height) {
                return;
        }

        uint8_t *screen = (uint8_t *)(fb->address);
        uint32_t pixel = y * fb->px_per_scanline + x;
        pixel *= (fb->depth/8);
        uint32_t colour = colour_mask(fb, red, green, blue);
        for (uint32_t i = 0; i < (fb->depth/8); i++) {
                screen[pixel + i] = (uint8_t)(colour >> (i * 8));
        }
}


efi_status_t
efi_main(void *handle, efi_system_table_t *_sys_table, void *base)
{
        image_handle = handle;
        sys_table = _sys_table;
        image_base = (uintptr_t)base;

        set_text_mode(1);
        print_string("Vendor: ");
        efi_print_string(sys_table->fw_vendor);
        print_string(" rev: ");
        print_number(sys_table->fw_revision >> 16);
        print_string(".");
        print_number(sys_table->fw_revision & 0xff);
        print_char('\n');
        print_string("Image base: ");
        print_pointer(base);
        struct frame_buffer fb = { .address = 0 };

        if (find_gop(&fb) != EFI_SUCCESS) {
                if (find_uga(&fb) != EFI_SUCCESS) {
                        print_string("Cant find framebuffer information\n");
                        goto exit;
                }
        }
        print_string("Framebuffer: ");
        print_number(fb.width);
        print_string("x");
        print_number(fb.height);
        print_string(" bpp: ");
        print_number(fb.depth);
        print_string(" px per line: ");
        print_number(fb.px_per_scanline);
        print_string(" address: ");
        print_pointer(fb.address);
        print_string(" size: ");
        print_qword(fb.size);
        print_char('\n');

        for(uint32_t x = 0; x < fb.width; x++) {
                plot_pixel(&fb, x, 0, 0xff, 0, 0);
                plot_pixel(&fb, x, fb.height-1, 0, 0, 0xff);
        }

        for(uint32_t y = 0; y < fb.height; y++) {
                plot_pixel(&fb, 0, y, 0, 0xff, 0);
                plot_pixel(&fb, fb.width-1, y, 0xff, 0xff, 0xff);
        }

        unsigned char ch = 0;
        uint32_t max_x, max_y;
        console_size(&fb, &font8x16, &max_x, &max_y);
        print_string("Console size: ");
        print_number(max_x);
        print_string("x");
        print_number(max_y);
        print_char('\n');

        const struct font *font = &font8x16;
        print_string("font size: ");
        print_number(font->width);
        print_string("x");
        print_number(font->height);
        print_string(" font->data: ");
        print_pointer((void *)font_data(font));
        print_string(" fontdata_8x16: ");
        print_pointer((void *)fontdata_8x16);
        print_char('\n');

        set_text_colour(0x002fff12); // rgb
        for(int y = 0; y < 16; y++) {
                for (int x = 0; x < 16; x++) {
                        print_fb_char(&fb, x, y, ch);
                        ch++;
                        ch &= 0xff;
                }
        }
 exit:
        print_string("Press any key to exit\n");
        efi_input_key_t key;
        wait_for_key(&key);

        return EFI_SUCCESS;
}
