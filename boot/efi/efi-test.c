#include <efi.h>
#include <efilib.h>
#include <stddef.h>

#define GRUB_EFI_CONSOLE_CONTROL_GUID                           \
        { 0xf42f7782, 0x12e, 0x4c12,                            \
          { 0x99, 0x56, 0x49, 0xf9, 0x43, 0x4, 0xf7, 0x21 }     \
        }

#define EFI_UGA_PROTOCOL_GUID                                           \
        { 0x982c298b, 0xf4fa, 0x41cb, { 0xb8, 0x38, 0x77, 0xaa, 0x68, 0x8f, 0xb8, 0x39 }}

#define UGA_IO_PROTOCOL_GUID                                            \
        { 0x61a4d49e, 0x6f68, 0x4f1b, { 0xb9, 0x22, 0xa8, 0x6e, 0xed, 0xb, 0x7, 0xa2 } }

//#define SMBIOS_TABLE_GUID
//        {0xeb9d2d31, 0x2d88, 0x11d3, { 0x9a, 0x16, 0x00, 0x90, 0x27, 0x3f, 0xc1, 0x4d} }



INTERFACE_DECL(_CONSOLE_CONTROL_INTERFACE);

typedef enum {
        EFI_SCREEN_TEXT,
        EFI_SCREEN_GRAPHICS,
        EFI_SCREEN_TEXT_MAX_VALUE
} EFI_CONSOLE_SCREEN_MODE;


typedef
EFI_STATUS
(EFIAPI *EFI_CONSOLE_GET_MODE) (
                                IN struct _CONSOLE_CONTROL_INTERFACE *This,
                                OUT EFI_CONSOLE_SCREEN_MODE *Mode,
                                OUT BOOLEAN *UgaExists,
                                OUT BOOLEAN *StdInLocked
                                );

typedef
EFI_STATUS
(EFIAPI *EFI_CONSOLE_SET_MODE) (
                                IN struct _CONSOLE_CONTROL_INTERFACE *This,
                                IN EFI_CONSOLE_SCREEN_MODE Mode
                                );


typedef struct _CONSOLE_CONTROL_INTERFACE {
        EFI_CONSOLE_GET_MODE GetMode;
        EFI_CONSOLE_SET_MODE SetMode;
} CONSOLE_CONTROL_INTERFACE;


struct _EFI_UGA_DRAW_PROTOCOL;

typedef
EFI_STATUS
(EFIAPI *EFI_UGA_DRAW_PROTOCOL_GET_MODE) (
                                          IN struct _EFI_UGA_DRAW_PROTOCOL *This,
                                          OUT UINT32 *HorizontalResolution,
                                          OUT UINT32 *VerticalResolution,
                                          OUT UINT32 *ColorDepth,
                                          OUT UINT32 *RefreshRate
                                          );


typedef
EFI_STATUS
(EFIAPI *EFI_UGA_DRAW_PROTOCOL_SET_MODE) (
                                          IN struct _EFI_UGA_DRAW_PROTOCOL *This,
                                          IN UINT32 HorizontalResolution,
                                          IN UINT32 VerticalResolution,
                                          IN UINT32 ColorDepth,
                                          IN UINT32 RefreshRate
                                          );


typedef struct {
        UINT8   Blue;
        UINT8   Green;
        UINT8   Red;
        UINT8   Reserved;
} EFI_UGA_PIXEL;

typedef enum {
        EfiUgaVideoFill,
        EfiUgaVideoToBltBuffer,
        EfiUgaBltBufferToVideo,
        EfiUgaVideoToVideo,
        EfiUgaBltMax
} EFI_UGA_BLT_OPERATION;

typedef
EFI_STATUS
(EFIAPI *EFI_UGA_DRAW_PROTOCOL_BLT) (
                                     IN struct _EFI_UGA_DRAW_PROTOCOL *This,
                                     IN OUT EFI_UGA_PIXEL *BltBuffer, OPTIONAL
                                     IN EFI_UGA_BLT_OPERATION BltOperation,
                                     IN UINTN SourceX,
                                     IN UINTN SourceY,
                                     IN UINTN DestinationX,
                                     IN UINTN DestinationY,
                                     IN UINTN Width,
                                     IN UINTN Height,
                                     IN UINTN Delta      OPTIONAL
                                     );


typedef struct _EFI_UGA_DRAW_PROTOCOL {
        EFI_UGA_DRAW_PROTOCOL_GET_MODE GetMode;
        EFI_UGA_DRAW_PROTOCOL_SET_MODE SetMode;
        EFI_UGA_DRAW_PROTOCOL_BLT Blt;
} EFI_UGA_DRAW_PROTOCOL;



struct frame_buffer {
        UINTN width;
        UINTN height;
        UINTN depth;
        UINTN line_width;
        UINT64 fb;
};


struct font {
        uint8_t width;
        uint8_t height;
        const unsigned char *data;
};

#include "font_8x16.c"

void stop() {
        asm volatile("cli; hlt; ");
}

static inline uint64_t
getCR0()
{
        uint64_t res;
        asm volatile ("mov %%cr0, %0" : "=r" (res) : : );
        return res;
}

static inline uint64_t
getCR3()
{
        uint64_t res;
        asm volatile ("mov %%cr3, %0" : "=r" (res) : : );
        return res;
}

static inline uint64_t
get_cs()
{
        uint64_t res;
        asm volatile ("mov %%cs, %0" : "=r" (res) : : );
        return res;
}


static inline uint64_t
get_ds()
{
        uint64_t res;
        asm volatile ("mov %%ds, %0" : "=r" (res) : : );
        return res;
}


static inline uint64_t
get_es()
{
        uint64_t res;
        asm volatile ("mov %%es, %0" : "=r" (res) : : );
        return res;
}


static inline uint64_t
get_fs()
{
        uint64_t res;
        asm volatile ("mov %%fs, %0" : "=r" (res) : : );
        return res;
}


static inline uint64_t
get_gs()
{
        uint64_t res;
        asm volatile ("mov %%gs, %0" : "=r" (res) : : );
        return res;
}

static inline uint64_t
get_ss()
{
        uint64_t res;
        asm volatile ("mov %%ss, %0" : "=r" (res) : : );
        return res;
}


static inline uint64_t
get_rip()
{
        uint64_t res;
        asm volatile ("call 1f; 1: pop %0" : "=r" (res) : : "memory" );
        return res;
}


int set_text_mode(int on)
{
        EFI_GUID Protocol = GRUB_EFI_CONSOLE_CONTROL_GUID;
        CONSOLE_CONTROL_INTERFACE *interface;
        EFI_STATUS status = uefi_call_wrapper(ST->BootServices->LocateProtocol, 3, &Protocol, NULL, &interface);
        Print(L"LocateProtocol status = %d\r\n", status);
        if (status != EFI_SUCCESS) return 1;

        EFI_CONSOLE_SCREEN_MODE mode;
        status = uefi_call_wrapper(interface->GetMode, 4, interface, &mode, 0, 0);
        Print(L"GetMode status = %d\r\n", status);
        if (status != EFI_SUCCESS) return 0;

        EFI_CONSOLE_SCREEN_MODE newmode = on ? EFI_SCREEN_TEXT : EFI_SCREEN_GRAPHICS;
        status = uefi_call_wrapper(interface->SetMode, 2, interface, newmode);

        return status == EFI_SUCCESS;
}


EFI_STATUS
EFIAPI
wait_for_key(EFI_INPUT_KEY *key)
{
        EFI_STATUS status;
        do {
                status = uefi_call_wrapper(ST->ConIn->ReadKeyStroke, 2, ST->ConIn, &key);
        } while(status == EFI_NOT_READY);
        return status;
}


void
show_gop_mode(UINT32 mode, EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *info)
{
        Print(L"%d: Ver: %d hres: %d vres: %d: ", mode,
              info->Version, info->HorizontalResolution, info->VerticalResolution,
              info->PixelFormat, info->PixelInformation, info->PixelsPerScanLine);

        switch(info->PixelFormat) {
        case PixelRedGreenBlueReserved8BitPerColor:
                Print(L"RGBR");
                break;
        case PixelBlueGreenRedReserved8BitPerColor:
                Print(L"BGRR");
                break;
        case PixelBitMask:
                Print(L"R:%08x G:%08x B:%08x X:%08x",
                      info->PixelInformation.RedMask,
                      info->PixelInformation.GreenMask,
                      info->PixelInformation.BlueMask,
                      info->PixelInformation.ReservedMask);
                break;
        case PixelBltOnly:
                Print(L"(blt only)");
                break;
        default:
                Print(L"(Invalid pixel format)");
                break;
        }
        Print(L" pitch %d\r\n", info->PixelsPerScanLine);
}


void
show_gop_info(EFI_GRAPHICS_OUTPUT_PROTOCOL *gop, EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *current_info)
{
        Print(L"MaxMode: %d Mode: %d fb addr: %lx fb size: %lx\r\n",
              gop->Mode->MaxMode, gop->Mode->Mode,
              gop->Mode->FrameBufferBase, gop->Mode->FrameBufferSize);

        UINT32 mode;
        for(mode = 0; mode < gop->Mode->MaxMode; mode++) {
                UINTN size_of_info;
                EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *info;
                EFI_STATUS status = uefi_call_wrapper(gop->QueryMode, 4, gop, mode,
                                                      &size_of_info, &info);
                if (status != EFI_SUCCESS) {
                        Print(L"QueryMode returned %lx\r\n", status);
                        return;
                }
                if (mode == gop->Mode->Mode && current_info != NULL) {
                        *current_info = *info;
                }
                //show_gop_mode(mode, info);
        }
}



EFI_STATUS
EFIAPI
find_gop(struct frame_buffer *fb)
{
        EFI_HANDLE handles[64];
        UINTN buffer_sz = sizeof(handles);
        EFI_GUID guid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;

        EFI_STATUS status = uefi_call_wrapper(ST->BootServices->LocateHandle, 5,
                                              ByProtocol, &guid, NULL, &buffer_sz, handles);
        //Print(L"LocateHandle: status = %lx buffer_sz=%ld\r\n", status, buffer_sz);
        if (status != EFI_SUCCESS) {
                Print(L"Cant find GOP graphics\r\n");
                return status;
        }

        int handlecnt = buffer_sz / sizeof(EFI_HANDLE);
        Print(L"Found %d GOP handles\r\n", handlecnt);
        int i;
        EFI_GRAPHICS_OUTPUT_PROTOCOL *first_gop = NULL;
        EFI_GRAPHICS_OUTPUT_MODE_INFORMATION current_info;
        for (i = 0; i < handlecnt; i++) {
                EFI_GRAPHICS_OUTPUT_PROTOCOL *gop;
                status = uefi_call_wrapper(ST->BootServices->HandleProtocol, 3,
                                           handles[i], &guid, &gop);
                if (status != EFI_SUCCESS) {
                        Print(L"HandleProcotol status = %lx\r\n", status);
                        continue;
                }
                Print(L"handle: %lx interface: %lx\r\n", handles[i], gop);

                if (i==0) {
                        first_gop = gop;
                        show_gop_info(gop, &current_info);
                } else {
                        show_gop_info(gop, NULL);
                }
        }

        show_gop_mode(-1, &current_info);
        uint32_t *screen = (uint32_t *)first_gop->Mode->FrameBufferBase;
        if (current_info.PixelFormat == PixelRedGreenBlueReserved8BitPerColor
            || current_info.PixelFormat == PixelBlueGreenRedReserved8BitPerColor) {
                int x,y;
                uint32_t color = 0x01010100;
                for (y = 0; y < 100; y++) {
                        for (x = 0; x < current_info.HorizontalResolution; x++) {
                                int pixel = y * current_info.HorizontalResolution + x;
                                screen[pixel] = color;
                        }
                        color += 0x01010100;
                }
        }

        fb->fb = first_gop->Mode->FrameBufferBase;
        fb->width = current_info.HorizontalResolution;
        fb->height = current_info.VerticalResolution;
        fb->depth = 4;
        fb->line_width = current_info.PixelsPerScanLine;

        return EFI_SUCCESS;
}


void
show_uga_info(EFI_UGA_DRAW_PROTOCOL *uga)
{
        UINT32 hres, vres, depth, refresh;
        EFI_STATUS status = uefi_call_wrapper(uga->GetMode, 5, uga,
                                              &hres, &vres, &depth, &refresh);
        if (status != EFI_SUCCESS) {
                Print(L"GetMode  returned %lx\r\n", status);
                return;
        }

        Print(L"hres: %d vres: %d depth: %d\r\n", hres, vres, depth, refresh);
}


EFI_STATUS
EFIAPI
find_uga(struct frame_buffer *fb)
{
        EFI_HANDLE handles[64];
        UINTN buffer_sz = sizeof(handles);
        EFI_GUID guid =  EFI_UGA_PROTOCOL_GUID;

        EFI_STATUS status = uefi_call_wrapper(ST->BootServices->LocateHandle, 5,
                                              ByProtocol, &guid, NULL, &buffer_sz, handles);
        //Print(L"LocateHandle: status = %lx buffer_sz=%ld\r\n", status, buffer_sz);
        if (status != EFI_SUCCESS) {
                Print(L"Cant find UGA graphics\r\n");
                return status;
        }

        int handlecnt = buffer_sz / sizeof(EFI_HANDLE);
        Print(L"Found %d UGA handles\r\n", handlecnt);

        int i;
        //EFI_GRAPHICS_OUTPUT_MODE_INFORMATION current_info;
        for (i = 0; i < handlecnt; i++) {
                EFI_UGA_DRAW_PROTOCOL *uga;
                status = uefi_call_wrapper(ST->BootServices->HandleProtocol, 3,
                                           handles[i], &guid, &uga);
                if (status != EFI_SUCCESS) {
                        Print(L"HandleProcotol status = %lx\r\n", status);
                        continue;
                }
                Print(L"handle: %lx interface: %lx\r\n", handles[i], uga);

                UINT32 hres, vres, depth, refresh;
                EFI_STATUS status = uefi_call_wrapper(uga->GetMode, 5, uga,
                                                      &hres, &vres, &depth, &refresh);
                if (status == EFI_SUCCESS) {
                        fb->width = hres;
                        fb->height = vres;
                        fb->depth = depth;
                        fb->fb = 0xC0000000;
                        fb->line_width = 2048;
                        return EFI_SUCCESS;
                } else {
                        Print(L"GetMode  returned %lx\r\n", status);
                }

        }

        return EFI_NOT_FOUND;
}


int static inline
convert_font_line(struct font *font, const unsigned char *data, uint32_t *buf)
{
        unsigned int offset = 0;
        for(int i = font->width-1; i >= 0; i--) {
                int bit = data[0] & (1 << i);
                buf[offset++] = bit ? 0x00ffffff : 0x00000000;
        }
        return offset;
}


void static inline
console_size(struct frame_buffer *fb, struct font *font, int *max_x, int *max_y)
{
        *max_x = fb->width / font->width;
        *max_y = fb->height / font->height;
}


void static inline
print_char(struct frame_buffer *fb, unsigned int x, unsigned int y, unsigned char ch)
{
        struct font *font = &font8x16;
        int max_x, max_y;
        console_size(fb, font, &max_x, &max_y);
        if (x >= max_x || y >= max_y) {
                return;
        }

        int bytes_per_char = ((font->width + 7) / 8) * font->height;
        const unsigned char *char_data = font->data + (bytes_per_char * ch);
        uint32_t *screen = (uint32_t *)fb->fb;
        unsigned int pixel = (y * font->height) * fb->line_width + (x * font->width);
        for(int line = 0; line < font->height; line++) {
                uint32_t buf[16];
                int px = convert_font_line(font, char_data, buf);
                for(size_t p = 0; p < px; p++) {
                        screen[pixel + p] = buf[p];
                }
                pixel += fb->line_width;
                char_data += ((font->width + 7) / 8);
        }
}


void static inline
plot_pixel(struct frame_buffer *fb, int x, int y)
{
        UINT32 *screen = (UINT32 *)(fb->fb);
        int pixel = y * fb->line_width + x;
        screen[pixel] = 0x00ffffff;
}

EFI_STATUS
EFIAPI
efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
        InitializeLib(ImageHandle, SystemTable);
        ST = SystemTable;

        EFI_STATUS status = set_text_mode(1);
        Print(L"SetMode status = %d\r\n", status);

        /* Find SIMPLE_TEXT_OUTPUT_PROTOCOL */
        SIMPLE_TEXT_OUTPUT_INTERFACE *output;
        EFI_GUID text_protocol = SIMPLE_TEXT_OUTPUT_PROTOCOL;
        status = uefi_call_wrapper(ST->BootServices->LocateProtocol, 3,
                                   &text_protocol, NULL, &output);
        Print(L"SIMPLE_TEXT_OUTPUT_PROTOCOL: %lx/%X\r\n", status, output);
        if (status == EFI_SUCCESS) {
                status = uefi_call_wrapper(output->OutputString, 2,
                                           output, L"Using protocol\r\n");
        } else {
                output = NULL;
        }

        Print(SystemTable->FirmwareVendor);
        Print(L"\r\n");

#if 0
        Print(L"ST = %lx ConOut = %lx OutputString = %lx\r\n",
              ST, ST->ConOut, ST->ConOut->OutputString);


        Print(L"CR0: %lx CR3: %lx\r\n", getCR0(), getCR3());
        Print(L"CS: %x DS: %x ES: %x FS: %x GS: %x SS: %x\r\n",
              get_cs(), get_ds(), get_es(), get_fs(), get_gs(), get_ss());
        Print(L"RIP: %lx\r\n", get_rip());
#endif

        struct frame_buffer fb = { 0 };
        if (find_gop(&fb) != EFI_SUCCESS) {
                if (find_uga(&fb) != EFI_SUCCESS) {
                        Print(L"Cant find framebuffer information\n");
                        return EFI_SUCCESS;
                }
        }
        Print(L"Framebuffer: width: %d height: %d depth: %d line_width: %d addr: %lx\r\n",
              fb.width, fb.height, fb.depth, fb.line_width, fb.fb);

        for(int x = 0; x < fb.width; x++) {
                plot_pixel(&fb, x, 0);
                plot_pixel(&fb, x, fb.height-1);
        }

        for(int y = 0; y < fb.height; y++) {
                plot_pixel(&fb, 0, y);
                plot_pixel(&fb, fb.width-1, y);
        }

        unsigned char ch = 0;
        int max_x, max_y;
        console_size(&fb, &font8x16, &max_x, &max_y);
        Print(L"Console size: %d x %d\r\n", max_x, max_y);
        for(int y = 0; y < 16; y++) {
                for (int x = 0; x < 16; x++) {
                        print_char(&fb, x, y, ch);
                        ch++;
                        ch &= 0xff;
                }
        }

#if 0
        EFI_MEMORY_DESCRIPTOR memory_map[1024];
        UINTN map_size = sizeof(memory_map);
        UINTN map_key = 0;
        UINTN desc_size = 0;
        UINT32 desc_version = 0;

        Print(L"map_size = %ld\r\n", map_size);
        status = uefi_call_wrapper(ST->BootServices->GetMemoryMap, 5, &map_size,
                                   memory_map, &map_key, &desc_size,
                                   &desc_version);

        Print(L"get_mem_map: status = %lx\r\n", status);
        if (status == EFI_SUCCESS) {
                Print(L"get_mem_map: map_size: %ld, map_key: %lx, desc_size: %ld, desc_version: %ld\r\n",
                      map_size, map_key, desc_size, desc_version);
        }
        status = uefi_call_wrapper(ST->BootServices->GetMemoryMap, 5, &map_size,
                                   memory_map, &map_key, &desc_size,
                                   &desc_version);


        Print(L"Press any key to ExitBootServices()\r\n");
        EFI_INPUT_KEY key;
        wait_for_key(&key);

        status = uefi_call_wrapper(ST->BootServices->ExitBootServices, 2,
                                   ImageHandle, map_key);
        if (status != EFI_SUCCESS) {
                Print(L"exit_boot_services: status = %lx\r\n", status);
        }
#endif
        stop();
        return EFI_SUCCESS;
}
