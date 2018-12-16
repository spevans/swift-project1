/*
 * boot/efi_main.c
 *
 * Created by Simon Evans on 06/02/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * EFI setup for entry to the kernel
 *
 */

#include <efi.h>
#include <klibc.h>


// For passing data back to efi_entry.asm
struct pointer_table {
        unsigned char *image_base;
        void *pml4;
        void *last_page;        // Physical address of last page of BSS
        struct efi_boot_params boot_params;
};

// For alloc_memory() / free_memory()
struct memory_region {
        size_t type;
        size_t req_size;
        void *base;
        size_t pages;
};


// memory types for allocated memory
#define MEM_TYPE_PAGE_MAP       0x80000001
#define MEM_TYPE_BOOT_DATA      0x80000002
#define MEM_TYPE_KERNEL         0x80000003

#define PAGE_PRESENT    1
#define PAGE_READ_WRITE 2
#define PAGE_PHYS_ADDR_MASK 0x0000fffffffff000ULL


void *kernel_elf_header();
void *kernel_elf_end();
uint64_t bss_size();
int uprintf(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));
efi_status_t add_mapping(void *vaddr, void *paddr, size_t page_cnt);
void dump_mapping(void *vaddr);

static efi_system_table_t *sys_table;
static void *image_handle;
static struct pointer_table *ptr_table;
typedef uint64_t pte;


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


int
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
        struct efi_boot_params *bp = &ptr_table->boot_params;
        uprintf("image_base: %p pagetable: %p\nkernel_addr: %p last_page: %p\n",
                ptr_table->image_base, ptr_table->pml4, bp->kernel_phys_addr,
                ptr_table->last_page);
        struct frame_buffer *fb = &ptr_table->boot_params.fb;
        uprintf("Framebuffer: %dx%d bpp: %d px per line: %d addr:%p size: %lx\n",
                fb->width, fb->height, fb->depth, fb->px_per_scanline,
                fb->address, fb->size);
        uprintf("nr entries: %ld, config table: %p\n", bp->nr_efi_config_entries,
                bp->efi_config_table);
        uprintf("Symbol table @ %p size = 0x%lx\n", bp->symbol_table,
                bp->symbol_table_size);
        uprintf("string table @ %p size = 0x%lx\n", bp->string_table,
                bp->string_table_size);
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
alloc_memory(struct memory_region *region)
{
        size_t pages = (region->req_size + PAGE_MASK) / PAGE_SIZE;
        void *address = 0;
        efi_status_t status = efi_call4(sys_table->boot_services->allocate_pages,
                                        EFI_ALLOCATE_ANY_PAGES, region->type,
                                        pages, (uintptr_t)&address);
        if (status == EFI_SUCCESS) {
                memset(address, 0, pages * PAGE_SIZE);
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


void *
alloc_page()
{
        struct memory_region region = { .type = MEM_TYPE_PAGE_MAP,
                                        .req_size = PAGE_SIZE };
        alloc_memory(&region);

        return region.base;
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
                uprintf("Trying to set mode to: %d, press any key to continue\n",
                        best_mode);
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
                print_status("locate_handle EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID",
                             status);
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


static uint32_t
colour_mask(struct frame_buffer *fb, uint8_t red, uint8_t green, uint8_t blue)
{
        uint32_t colour = (red & fb->red_mask) << fb->red_shift;
        colour |= (green & fb->green_mask) << fb->green_shift;
        colour |= (blue & fb->blue_mask) << fb->blue_shift;

        return colour;
}


static void
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


#ifdef DEBUG
static void
dump_data(void *addr, size_t count)
{

        uint8_t *ptr = (uint8_t *)addr;
        for(size_t i = 0; i < count; i++) {
                if (i % 16 == 0) {
                        if (i > 0) uprintf("\n");
                        uprintf("%p: ", ptr);
                }
                uprintf("%2.2x ", *(ptr++));

        }
        uprint_string("\n");
}
#endif


efi_status_t
exit_boot_services()
{
        uint64_t map_key = 0;
        uint32_t version = 0;
        struct efi_boot_params *bp = &ptr_table->boot_params;

        struct memory_region region = { .type = MEM_TYPE_BOOT_DATA };
        // Call once to find out size of buffer to allocate
        efi_status_t status = efi_call5(sys_table->boot_services->get_memory_map,
                                        (uintptr_t)&region.req_size,
                                        (uintptr_t)bp->memory_map,
                                        (uintptr_t)&map_key,
                                        (uintptr_t)&bp->memory_map_desc_size,
                                        (uintptr_t)&version);
        if (status != EFI_BUFFER_TOO_SMALL) {
                return status;
        }
        /* Add an extra page to the request size as some pages will be allocated
           to map the region into the kernel's space and so we need to take
           account of extra memory allocations that will occur now */
        region.req_size += PAGE_SIZE;

        status = alloc_memory(&region);
        if (status != EFI_SUCCESS) {
                print_status("cant allocate memory:", status);
                return status;
        }
        bp->size = sizeof(struct efi_boot_params);
        bp->memory_map = region.base;
        bp->memory_map_size = region.pages * PAGE_SIZE;

        // Map it just after the kernel BSS +1 page as the ptr_table
        // occupies the page after the bss. Compute the offset from the
        // start of kernel to the last_page + 1
        ptrdiff_t offset = ptr_table->last_page - bp->kernel_phys_addr;
        offset += PAGE_SIZE;
        void *memory_map_vaddr = (void *)KERNEL_VIRTUAL_BASE + offset;
        uprintf("Adding mapping for memory_map, vaddr = %p\n",
                memory_map_vaddr);
        status = add_mapping(memory_map_vaddr, region.base, region.pages);
        bp->nr_efi_config_entries = sys_table->nr_entries;
        bp->efi_config_table = sys_table->config_table;

        status = efi_call5(sys_table->boot_services->get_memory_map,
                           (uintptr_t)&bp->memory_map_size,
                           (uintptr_t)bp->memory_map,
                           (uintptr_t)&map_key,
                           (uintptr_t)&bp->memory_map_desc_size,
                           (uintptr_t)&version);

        if (status != EFI_SUCCESS || bp->memory_map_desc_size == 0) {
                print_status("get_memory_map", status);
                return status;
        }

        // Only enable the following for debugging. The use of the print functions
        // stops ExitBootServices() from working
#if 0
        size_t entries = bp->memory_map_size / bp->memory_map_desc_size;
        uprintf("get_memory_map descriptor_size: %ld map_size %ld map_key %ld\n",
                bp->memory_map_desc_size, bp->memory_map_size,
                map_key);
        uprintf("entries: %ld\n", entries);

        size_t count = 0;
        for(size_t i = 0; i < entries; i++) {
                size_t offset = bp->memory_map_desc_size * i;
                efi_memory_descriptor_t *desc =
                        (efi_memory_descriptor_t *)(bp->memory_map + offset);
                if (desc->number_of_pages == 0) {
                        continue;
                }
                if (desc->type == 3 || desc->type == 4) continue;
                uprintf("%2ld t: %8x p: %16p  n: %6ld a: %#lx\n", i, desc->type,
                        (void *)desc->physical_start,
                        desc->number_of_pages, desc->attribute);

                if (++count > 10) break;
        }
#endif

        // ExitBootServices() must be called immediately after GetMemoryMap()
        // so that nothing can change the map_key
        status = efi_call2(sys_table->boot_services->exit_boot_services,
                           (uintptr_t)image_handle, map_key);
        if (status != EFI_SUCCESS) {
                print_status("exit_boot_services", status);
        }
        // Now update the ptr table with the virtual memory map address
        bp->memory_map = memory_map_vaddr;

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


        return EFI_SUCCESS;
}


void
dump_pte(pte *pte_addr)
{
        uprintf("%p: ", pte_addr);
        uint64_t pte = pte_addr ? *pte_addr : 0;
        size_t idx = 7;
        do {
                uprintf("%2.2lx ", (pte >> (idx * 8)) & 0xff);
        } while(idx-- > 0);
        uprint_string("\n");
}


// Allocate memory for the kernel and BSS. This ensures the kernel starts
// on a page boundary
efi_status_t
relocate_kernel()
{
        uprintf("Kernel image @ %p - %p BSS size: %#lx\n", kernel_elf_header(),
                kernel_elf_end(), bss_size());

        uint64_t kernel_sz = kernel_elf_end() - kernel_elf_header();
        struct elf_file kernel_image = {
                .file_data = kernel_elf_header(),
                .file_len = kernel_sz
        };

        efi_status_t status = elf_init_file(&kernel_image);
        uprintf("elf_init_file: %lu\n", status);
        if (status != EFI_SUCCESS) {
                print_status("Read elf header: ", status);
                return status;
        }
        // Find the size of all of the program load sections.
        // For now, assume they are contiguous and in ascending
        // load address order and there are no unneccessary gaps
        // between sections.

        struct elf_file *ki = &kernel_image;
        Elf64_Ehdr *elf_hdr = ki->elf_hdr;
        Elf64_Phdr *first = elf_program_header(ki, 0);
        Elf64_Phdr *last = elf_program_header(ki, elf_hdr->e_phnum - 1);
        size_t total_sz = (last->p_vaddr - first->p_vaddr) + last->p_memsz;
        total_sz = (total_sz + PAGE_MASK) & ~PAGE_MASK;
        // FIXME - Add an extra page at the end of the BSS for the
        // entry stub and boot params data. This is only needed becasue
        // BSS is cleared in kernel/init/main.asm over writing the boot params
        total_sz += PAGE_SIZE;
        uprintf("Size of kernel and bss: %ld\n", total_sz);

        size_t symbol_size = ki->symbol_table->sh_size
                + ki->string_table->sh_size;
        uprintf("symbol_size: %lx\n", symbol_size);

        // Compute the vaddr where the symbol table will reside
        Elf64_Addr symtab_vaddr = first->p_vaddr + total_sz;
        Elf64_Addr strtab_vaddr = symtab_vaddr + ki->symbol_table->sh_size;
        size_t symbol_offset = total_sz;
        total_sz += (symbol_size + PAGE_MASK) & ~PAGE_MASK;
        total_sz += PAGE_SIZE;
        uprintf("Size of kernel+bss+symbols %lx\n", total_sz);

        struct memory_region region = {
                .req_size = total_sz,
                .type = MEM_TYPE_KERNEL
        };

        status = alloc_memory(&region);
        if (status != EFI_SUCCESS) {
                print_status("alloc_memory: ", status);
                return status;
        }
        uprintf("Allocated %ld pages\n", region.pages);
        /* Copy the kernel into the allocated memory. The BSS is cleared
         * by the kernel startup. This could be replaced with a decompressor
         * for a compressed kernel etc
         */

        for (size_t idx = 0; idx < elf_hdr->e_phnum; idx++) {
                Elf64_Phdr *pheader = elf_program_header(ki, idx);
                uintptr_t offset = pheader->p_vaddr - first->p_vaddr;
                void *kdest = region.base + offset;
                void *ksrc =  elf_program_data(ki, pheader);
                size_t sz = pheader->p_filesz;
                uprintf("Copying %lx bytes of kernel @ offset = %lx image from %p -> %p\n",
                        sz, offset, ksrc, kdest);
                memcpy(kdest, ksrc, sz);
        }

        // Copy over the symbol table, sh string table and string table
        uprintf("symbol table @ %lx [%lx], len = %lx\n", ki->symbol_table->sh_offset,
                symtab_vaddr, ki->symbol_table->sh_size);
        uprintf("string table @ %lx [%lx], len = %lx\n", ki->string_table->sh_offset,
                strtab_vaddr, ki->string_table->sh_size);

        memcpy(region.base + symbol_offset,
               kernel_elf_header() + ki->symbol_table->sh_offset,
               ki->symbol_table->sh_size);
        memcpy(region.base + symbol_offset + ki->symbol_table->sh_size,
               kernel_elf_header() + ki->string_table->sh_offset,
               ki->string_table->sh_size);

#if 0
        // Dump symbols
        char *sym = region.base + symbol_offset + ki->symbol_table->sh_size;
        size_t offset = 0;
        size_t count = 0;
        while (offset <  ki->string_table->sh_size) {
                char * str = sym  + offset;
                size_t len = strlen(str);
                uprintf("%lu\t%lu\t%s\t%lu\n", count, offset, str, len);
                offset += len + 1;
                count++;
                if (count > 10) {
                        break;
                }
        }
#endif

        void *kdest = region.base + symbol_offset + ki->symbol_table->sh_size;
        void *ksrc = kernel_elf_header() + ki->string_table->sh_offset;
        size_t strsz = ki->string_table->sh_size;
        uprintf("Copying %lx bytes of string table from %p -> %p\n",
                strsz, ksrc, kdest);

        struct efi_boot_params *bp = &ptr_table->boot_params;
        bp->kernel_phys_addr = region.base;
        bp->symbol_table = (void *)symtab_vaddr;
        bp->symbol_table_size = ki->symbol_table->sh_size;
        bp->string_table = (void *)strtab_vaddr;
        bp->string_table_size = ki->string_table->sh_size;
        ptr_table->last_page = region.base + (region.pages - 1) * PAGE_SIZE;
        uprint_string("Kernel copied into place\n");
        print_memory_region(&region);

        return EFI_SUCCESS;
}


static const uint64_t entries_per_page = 512;
static const uint64_t entries_per_page_mask = entries_per_page - 1;

static size_t
pml4_index(void *vaddr)
{
        return ((uintptr_t)vaddr >> 39) & entries_per_page_mask;
}


static size_t
pdp_index(void *vaddr)
{
        return ((uintptr_t)vaddr >> 30) & entries_per_page_mask;
}


static size_t
pd_index(void *vaddr)
{
        return ((uintptr_t)vaddr >> 21) & entries_per_page_mask;
}


static size_t
pt_index(void *vaddr)
{
        return ((uintptr_t)vaddr >> 12) & entries_per_page_mask;
}


static pte *
get_page_at_index(pte *pd, size_t idx)
{
        if ((pd[idx] & PAGE_PRESENT) == 0) {
                // no page present
                pte *new_page = alloc_page();
                if (new_page == NULL) {
                        return NULL;
                }
                pte entry = (uintptr_t)new_page;
                pd[idx] = entry | PAGE_READ_WRITE | PAGE_PRESENT;
        }
        return (pte *)(pd[idx] & PAGE_PHYS_ADDR_MASK);
}


pte *
read_entry(pte *dir, int idx)
{
        pte entry = dir[idx];
        entry &= PAGE_PHYS_ADDR_MASK;
        return (pte *)entry;
}

void
dump_mapping(void *vaddr)
{
         size_t idx0 = pml4_index(vaddr);
         size_t idx1 = pdp_index(vaddr);
         size_t idx2 = pd_index(vaddr);
         size_t idx3 = pt_index(vaddr);
         pte *addr = ptr_table->pml4;
         uprintf("pml4 = %p : %p => %ld/%ld/%ld/%ld [%lx/%lx/%lx/%lx]\n", addr,
                 vaddr, idx0, idx1, idx2, idx3,
                 idx0 << 3, idx1 << 3, idx2 << 3, idx3 << 3);

         dump_pte(addr + idx0);
         pte *pdp_page = read_entry(addr, idx0);
         dump_pte(pdp_page + idx1);
         pte *pd_page = read_entry(pdp_page, idx1);
         dump_pte(pd_page + idx2);
         pte *pt_page = read_entry(pd_page, idx2);
         dump_pte(pt_page + idx3);
}


// Add 4K page read/write no other settings
efi_status_t
add_mapping(void *vaddr, void *paddr, size_t page_cnt)
{
        uprintf("Mapping %p => %p pages: %ld\n", vaddr, paddr, page_cnt);

        for (size_t i = 0; i < page_cnt; i++) {

                size_t idx0 = pml4_index(vaddr);
                size_t idx1 = pdp_index(vaddr);
                size_t idx2 = pd_index(vaddr);
                size_t idx3 = pt_index(vaddr);
                pte *pdp_page = get_page_at_index(ptr_table->pml4, idx0);
                if (pdp_page == NULL) {
                        return EFI_OUT_OF_RESOURCES;
                }
                pte *pd_page = get_page_at_index(pdp_page, idx1);
                if (pd_page == NULL) {
                        return EFI_OUT_OF_RESOURCES;
                }
                pte *pt_page = get_page_at_index(pd_page, idx2);
                if (pt_page == NULL) {
                        return EFI_OUT_OF_RESOURCES;
                }

                if (pt_page[idx3] & PAGE_PRESENT) {
                        uprintf("Page already mapped @ %p => %p\n", vaddr, paddr);
                        return EFI_INVALID_PARAMETER;
                } else {
                        pte entry = (uintptr_t)paddr;
                        pt_page[idx3] = entry | PAGE_READ_WRITE | PAGE_PRESENT;
                }
                vaddr += PAGE_SIZE;
                paddr += PAGE_SIZE;
        }
        uprintf("Last mapping @ %p => %p\n", vaddr - PAGE_SIZE, paddr - PAGE_SIZE);

        return EFI_SUCCESS;
}


/*
 * Setup page tables to cover the new kernel (mapped at its correct location)
 * and a mapping for the frame buffer and any tables that will be passed as
 * boot data to the kernel. Note that a mapping for all of physical memory is
 * not setup just the frame buffer and boot tables will be added @
 * PHYSICAL_MEM_BASE + real address. Use 4K pages for all mappings as kernel
 * may not have been relocated to a 2MB aligned region
 */
efi_status_t
setup_page_tables()
{
        void *root = alloc_page();
        if (root == NULL) {
                return EFI_OUT_OF_RESOURCES;
        }
        ptr_table->pml4 = root;
        uprintf("pml4 @ %p\n", root);
        struct efi_boot_params *bp = &ptr_table->boot_params;
        ptrdiff_t kernel_pages = (ptr_table->last_page - bp->kernel_phys_addr) / PAGE_SIZE;
        kernel_pages++;

        efi_status_t status = add_mapping((void *)KERNEL_VIRTUAL_BASE,
                                          bp->kernel_phys_addr, kernel_pages);
        if (status != EFI_SUCCESS) {
                return status;
        }
#ifdef DEBUG
        dump_mapping((void *)KERNEL_VIRTUAL_BASE);
#endif
        // Add identity mapping for last page of BSS as this is where the stub that
        // transitions to the kernel's virtual address loads the page tables
        add_mapping(ptr_table->last_page, ptr_table->last_page, 1);

        // Map framebuffer @ 128GB + base address
        // FIXME: Should really be an IO mapping
        struct frame_buffer *fb = &ptr_table->boot_params.fb;
        add_mapping((void *)(PHYSICAL_MEM_BASE + fb->address), fb->address,
                    (fb->size + PAGE_MASK) / PAGE_SIZE);

#ifdef ENABLE_TLS
        // Map the first 4K of the kernel @ 0x1000, this is the config area
        // including the TLS which needs to be in the first 4GB.
        add_mapping((void *)(TLS_END_ADDR & ~PAGE_MASK), bp->kernel_phys_addr,
                    1);
#endif


        // Map the first 4GB of RAM into the 128GB mapping. 4GB should
        // cover all of the memory used in loading the kernel and also
        // any page maps setup in this EFI loader so they can be read
        // by page.swift:virtualToPhys(address:base:)
        // TODO: Convert to using 2MB pages and stop double mapping with
        // the framebuffer above.
        add_mapping((void *)PHYSICAL_MEM_BASE, (void *)0, 1048576);

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

        efi_status_t status;
        if ((status = relocate_kernel()) != EFI_SUCCESS) {
                goto error;
        }


        struct frame_buffer *fb = &ptr_table->boot_params.fb;
        if ((status = setup_frame_buffer(fb)) != EFI_SUCCESS) {
                goto error;
        }

        if ((status = setup_page_tables()) != EFI_SUCCESS) {
                goto error;
        }
        print_ptr_table();
#ifdef DEBUG
        uprintf("nr_entries: %ld, config_table: %p\n", sys_table->nr_entries,
                 sys_table->config_table);
        for (size_t i = 0; i < sys_table->nr_entries; i++) {
                efi_config_table_t *table = sys_table->config_table + i;
                uprintf("%lu: %p\t", i, table->vendor_table);
                dump_data(&table->vendor_guid, sizeof(efi_guid_t));
        }
#endif
        if (exit_boot_services() != EFI_SUCCESS) {
                goto error;
        }

        return EFI_SUCCESS;

 error:
        uprint_string("EFI Initialisation failed, Press any key to exit\n");
        wait_for_key(NULL);

        return status;
}
