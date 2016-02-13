#include <efi.h>
#include <fbcon.h>
#include <klibc.h>
#include "../lib/font_8x16.c"


// For passing data back to efi_entry.asm
struct pointer_table {
        unsigned char *image_base;
        void *pml4;
        void *kernel_addr;
        void *last_page;
};

// For allocate_memory() / free_memory()
struct memory_region {
        size_t type;
        size_t req_size;
        void *base;
        size_t pages;
};


// memory types for allocated memory
#define MEM_TYPE_PAGE_MAP       0x80000000
#define MEM_TYPE_BOOT_DATA      0x80000001
#define MEM_TYPE_KERNEL         0x80000002

void *kernel_bin_start();
void *kernel_bin_end();
uint64_t bss_size();
static int uprintf(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));

static efi_system_table_t *sys_table;
static void *image_handle;
static struct pointer_table *ptr_table;


void __attribute__ ((noinline))
efi_print_string(uint16_t *str)
{
        efi_call2(sys_table->con_out->output_string, (uintptr_t)sys_table->con_out,
                  (uintptr_t)str);
}


void __attribute__ ((noinline))
uprint_string(char *str)
{
        uint16_t buf[1024];
        for (int x = 0; x < 1024; x++) {
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


void
early_print_char(char ch)
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


static int
uprintf(const char *fmt, ...)
{
        char buf[512];
        va_list args;
        va_start(args, fmt);
        int len = kvsnprintf(buf, 512, fmt, args);
        uprint_string(buf);

        return len;
}


// Needed for kprintf
size_t
strlen(const char *s)
{
        size_t d0;
        size_t res;
        asm volatile("cld\n\t"
                     "repne\n\t"
                     "scasb"
                     : "=c" (res), "=&D" (d0)
                     : "1" (s), "a" (0), "0" (0xffffffffffffffffu)
                     : "memory");
        return ~res - 1;
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
print_ptr_table()
{
        uprintf("image_base: %p pagetable: %p\nkernel_addr: %p last_page: %p\n",
                ptr_table->image_base, ptr_table->pml4, ptr_table->kernel_addr,
                ptr_table->last_page);
}


void
print_memory_region(struct memory_region *region)
{
        uprintf("Base: %p req_size: %ld pages: %ld type: %#lx\n",
                region->base, region->req_size, region->pages, region->type);
}


void
print_status(char *str, efi_status_t status)
{
        uprintf("%s status: %ld %s\n", str, efi_err_num(status),
                efi_is_error(status) ? "[error]" : "");
}


efi_status_t
allocate_memory(struct memory_region *region)
{
        size_t pages = (region->req_size + PAGE_SIZE - 1) / PAGE_SIZE;
        void *address = 0;
        efi_status_t status = efi_call4(sys_table->boot_services->allocate_pages,
                                        EFI_ALLOCATE_ANY_PAGES, region->type,
                                        pages, (uintptr_t)&address);
        if (status == EFI_SUCCESS) {
                region->base = address;
                region->pages = pages;
        } else {
                region->base = NULL;
                region->pages = 0;
                uprintf("Cant allocate %ld bytes\n", region->req_size);
        }

        return status;
}


efi_status_t
free_memory(struct memory_region *region)
{
        efi_status_t status = efi_call2(sys_table->boot_services->free_pages,
                                        region->pages, (uintptr_t)&region->base);
        if (status == EFI_SUCCESS) {
                region->base = NULL;
                region->pages = 0;
        }

        return status;
}



efi_status_t
set_text_mode(int on)
{
        efi_guid_t protocol = EFI_CONSOLE_CONTROL_GUID;
        efi_console_control_interface_t *interface;

        efi_status_t status = efi_call3(sys_table->boot_services->locate_protocol,
                                        (uintptr_t)&protocol, (uintptr_t)NULL,
                                        (uintptr_t) &interface);


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
        uprint_string("Setting text mode\n");
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
        uprintf("%d: %dx%d ", mode, info->horizontal_resolution,
                info->vertical_resolution);

        switch(info->pixel_format) {
        case pixel_red_green_blue_reserved8_bit_per_color:
                uprint_string("RGBR");
                break;

        case pixel_blue_green_red_reserved8_bit_per_color:
                uprint_string("BGRR");
                break;

        case pixel_bit_mask:
                uprintf("R:%8.8x G:%8.8x B:%8.8x X:%8.8x ",
                        info->pixel_information.red_mask,
                        info->pixel_information.green_mask,
                        info->pixel_information.blue_mask,
                        info->pixel_information.reserved_mask);
                break;

        case pixel_blt_only:
                uprint_string("(blt only)");
                break;

        default:
                uprint_string("(Invalid pixel format)");
                break;
        }
        uprintf(" pitch: %d\n", info->pixels_per_scan_line);
}


efi_status_t
show_gop_info(efi_graphics_output_protocol_t *gop,
              efi_graphics_output_mode_information_t *mode_info)
{
        uprintf("MaxMode: %d Mode: %d fb addr: %#lx fb size: %#lx\n",
                gop->mode->max_mode, gop->mode->mode,
                gop->mode->frame_buffer_base,
                gop->mode->frame_buffer_size);

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
                uprintf("Trying to set mode to: %d\n", best_mode);
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

        efi_status_t status = locate_handle(efi_by_protocol, &guid, NULL,
                                            &buffer_sz, handles);
        if (status != EFI_SUCCESS) {
                print_status("locate_handle EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID", status);
                uprint_string("Cant find GOP graphics\n");
                return status;
        }

        int handlecnt = buffer_sz / sizeof(efi_handle_t);
        uprintf("Found %d GOP handles\n", handlecnt);

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
        efi_status_t status = locate_handle(efi_by_protocol, &guid, NULL,
                                            &buffer_sz, handles);
        if (status != EFI_SUCCESS) {
                print_status("locate_handle EFI_UGA_PROTOCOL_GUID", status);
                uprint_string("Cant find GOP graphics\n");
                return status;
        }
        int handlecnt = buffer_sz / sizeof(efi_handle_t);
        uprintf("Found %d UGA handles\n", handlecnt);

        for (int i = 0; i < handlecnt; i++) {
                efi_uga_draw_protocol_t *uga;
                status = efi_call3(sys_table->boot_services->handle_protocol,
                                   (uintptr_t)handles[i], (uintptr_t)&guid,
                                   (uintptr_t)&uga);
                if (status != EFI_SUCCESS) {
                        print_status("handle_procotol ", status);
                        continue;
                }
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
        return (uint64_t)ptr_table->image_base + font->data;
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
show_memory_map()
{
        char *memory_map = NULL;
        uint64_t map_key = 0;
        uint64_t descriptor_size = 0;
        uint32_t version = 0;

        struct memory_region region = { .type = MEM_TYPE_BOOT_DATA };
        // Call once to find out size of buffer to allocate
        efi_status_t status = efi_call5(sys_table->boot_services->get_memory_map,
                                        (uintptr_t)&region.req_size,
                                        (uintptr_t)memory_map, (uintptr_t)&map_key,
                                        (uintptr_t)&descriptor_size,
                                        (uintptr_t)&version);
        if (status != EFI_BUFFER_TOO_SMALL) {
                return status;
        }

        status = allocate_memory(&region);
        if (status != EFI_SUCCESS) {
                print_status("cant allocate memory:", status);
                return status;
        }
        memory_map = region.base;

        uint64_t map_size = region.pages * PAGE_SIZE;
        map_key = 0;
        descriptor_size = 0;
        version = 0;

        status = efi_call5(sys_table->boot_services->get_memory_map,
                           (uintptr_t)&map_size, (uintptr_t)memory_map,
                           (uintptr_t)&map_key, (uintptr_t)&descriptor_size,
                           (uintptr_t)&version);

        if (status != EFI_SUCCESS || descriptor_size == 0) {
                print_status("get_memory_map", status);
                return status;
        }

        uprintf("get_memory_map descriptor_size: %ld map_size %ld map_ley %ld\n",
                descriptor_size, map_size, map_key);

        size_t entries = map_size / descriptor_size;
        uprintf("entries: %ld\n", entries);

        size_t count = 0;
        for(size_t i = 0; i < entries; i++) {
                size_t offset = descriptor_size * i;
                efi_memory_descriptor_t *desc = (efi_memory_descriptor_t *)(memory_map+offset);
                if (desc->physical_start == 0 && desc->virtual_start == 0 && desc->type == 0
                    && desc-> number_of_pages == 0) {
                        continue;
                }
                if (desc->type > 4) continue;

                uprintf("%2ld t: %d p: %p v: %p n: %ld a: %#lx\n", i, desc->type,
                        (void *)desc->physical_start, (void *)desc->virtual_start,
                        desc->number_of_pages, desc->attribute);

                if (++count > 10) break;
        }

        free_memory(&region);

        return status;
}


efi_status_t
setup_frame_buffer(struct frame_buffer *fb)
{
        if (find_gop(fb) != EFI_SUCCESS) {
                if (find_uga(fb) != EFI_SUCCESS) {
                        uprint_string("Cant find framebuffer information\n");
                        return EFI_NOT_FOUND;
                }
        }
        uprintf("Framebuffer: %dx%d bpp: %d px per line: %d addr:%p size: %lx\n",
                fb->width, fb->height, fb->depth, fb->px_per_scanline,
                fb->address, fb->size);

        for(uint32_t x = 0; x < fb->width; x++) {
                plot_pixel(fb, x, 0, 0xff, 0, 0);
                plot_pixel(fb, x, fb->height-1, 0, 0, 0xff);
        }

        for(uint32_t y = 0; y < fb->height; y++) {
                plot_pixel(fb, 0, y, 0, 0xff, 0);
                plot_pixel(fb, fb->width-1, y, 0xff, 0xff, 0xff);
        }

        unsigned char ch = 0;
        uint32_t max_x, max_y;
        console_size(fb, &font8x16, &max_x, &max_y);
        uprintf("Console size: %dx%d\n", max_x, max_y);

        const struct font *font = &font8x16;
        uprintf("font size: %dx%d font->data:%p fontdata_8x16:%p\n", font->width, font->height,
                font_data(font), fontdata_8x16);

        set_text_colour(0x002fff12); // rgb
        for(int y = 0; y < 16; y++) {
                for (int x = 0; x < 16; x++) {
                        print_fb_char(fb, x, y, ch);
                        ch++;
                        ch &= 0xff;
                }
        }

        return EFI_SUCCESS;
}


// Allocate memory for the kernel and BSS. This ensures the kernel starts
// on a page boundary
efi_status_t
relocate_kernel()
{
        uprintf("Kernel image @ %p - %p BSS size: %#lx\n", kernel_bin_start(),
                kernel_bin_end(), bss_size());

        uint64_t kernel_sz = kernel_bin_end() - kernel_bin_start();
        uint64_t total_sz = kernel_sz + bss_size();
        uprintf("Size of kernel and bss: %ld\n", total_sz);
        struct memory_region region = { .req_size = total_sz,
                                        .type = MEM_TYPE_KERNEL };
        efi_status_t status = allocate_memory(&region);
        if (status != EFI_SUCCESS) {
                print_status("allocate_memory: ", status);
                return status;
        }
        uprintf("Allocated %ld pages\n", region.pages);
        /* Copy the kernel into the allocated memory. The BSS is cleared
         * by the kernel startup. This could be replaced with a decompressor
         * for a compressed kernel etc
         */
        memcpy(region.base, kernel_bin_start(), kernel_sz);
        ptr_table->kernel_addr = region.base;
        ptr_table->last_page = region.base + (region.pages - 1) * PAGE_SIZE;
        uprint_string("Kernel copied into place, press any key\n");
        print_memory_region(&region);
        wait_for_key(NULL);

        return EFI_SUCCESS;
}


efi_status_t
efi_main(void *handle, efi_system_table_t *_sys_table,
         struct pointer_table *ptrs)
{
        image_handle = handle;
        sys_table = _sys_table;
        ptr_table = ptrs;
        print_ptr_table();

        set_text_mode(1);
        uprint_string("Vendor: ");
        efi_print_string(sys_table->fw_vendor);
        uprintf(" rev: %d.%d\n", sys_table->fw_revision >> 16,
                sys_table->fw_revision & 0xff);

        if (relocate_kernel() != EFI_SUCCESS) {
                goto error;
        }

        print_ptr_table();
        struct frame_buffer fb = { .address = 0 };
        if (setup_frame_buffer(&fb) != EFI_SUCCESS) {
                goto error;
        }

        if (show_memory_map() != EFI_SUCCESS) {
                goto error;
        }

 error:
        uprint_string("Press any key to exit\n");
        efi_input_key_t key;
        wait_for_key(&key);

        return  EFI_SUCCESS;
}
