/*
 * klibc/early_tty.c
 *
 * Created by Simon Evans on 26/12/2015.
 * Copyright © 2015 - 2017 Simon Evans. All rights reserved.
 *
 * Simple functions to print characters and strings until the
 * Swift TTY driver is initialised.
 *
 */

#include "klibc.h"
#include "swift.h"
#include "mm.h"
#include "fbcon.h"
#include "../lib/font_8x16.c"


void early_print_char(const char c);
void early_print_string(const char *text);
void early_print_string_len(const char *text, size_t len);
void framebuffer_test(struct frame_buffer *fb);
static void set_text_colour(uint32_t colour);

void (*etty_print_char)(text_coord x, text_coord y, const unsigned char ch);
void (*etty_clear_screen)();
void (*etty_scroll_up)();

static void text_mode_print_char(text_coord x, text_coord y, const unsigned char ch);
static void text_mode_clear_screen();
static void text_mode_scroll_up();
static void fb_print_char(text_coord x, text_coord y, const unsigned char ch);
static void fb_clear_screen();
static void fb_scroll_up();
static void get_hw_cursor(text_coord *x, text_coord *y);


// Base address of PC text screen or framebuffer memory
static uint8_t *screen_buffer;
// Motorola 6845 CRT Controller registers
static const uint16_t crt_idx_reg = 0x3D4;
static const uint16_t crt_data_reg = 0x3D5;
static const uint8_t cursor_msb = 0xE;
static const uint8_t cursor_lsb = 0xF;

static text_coord text_width = 80;
static text_coord text_height = 25;
static text_coord cursor_x = 0;
static text_coord cursor_y = 0;
static int text_mode = 1;
static struct frame_buffer frame_buffer;
static const struct font *font;
static uint32_t text_colour = 0x00ffffff;
static uint8_t text_red = 0xff, text_green = 0xff, text_blue = 0xff;
static void serial_init();


void
init_early_tty(struct frame_buffer *fb)
{
        serial_init();
        if (fb == NULL) {
                text_mode = 1;
                text_width = 80;
                text_height = 25;
                screen_buffer = (uint8_t *)(PHYSICAL_MEM_BASE + 0xB8000);
                etty_print_char = text_mode_print_char;
                etty_clear_screen = text_mode_clear_screen;
                etty_scroll_up = text_mode_scroll_up;
                kprintf("Using text mode: ");
        } else {
                // Get the current cursor position from the boot setup
                get_hw_cursor(&cursor_x, &cursor_y);
                text_mode = 0;
                frame_buffer = *fb;
                font = &font8x16;
                text_width = fb->width / font->width;
                text_height = fb->height / font->height;
                screen_buffer = (uint8_t *)(PHYSICAL_MEM_BASE
                                            + frame_buffer.address);
                etty_print_char = fb_print_char;
                etty_clear_screen = fb_clear_screen;
                etty_scroll_up = fb_scroll_up;
                set_text_colour(0x00ffffff); // rgb
                //framebuffer_test(fb);
                kprintf("Using framebuffer mode: ");
        }
        etty_clear_screen();
        kprintf("Console size: %ux%u\n", text_width, text_height);
}

const uint16_t COM1_BASE = 0x3f8;

static int
serial_xmit_empty()
{
        return inb(COM1_BASE + 5) & 0x20;
}

void
serial_print_char(const char c)
{
        static const char hexchars[] = "0123456789abcdef";
        if (c  < 0 || c > 127 || (c >= 0 && c <= 31 && c != '\n' && c != '\t')) {
                unsigned char idx = (unsigned char)c;
                serial_print_char('\\');
                serial_print_char('x');
                serial_print_char(hexchars[(idx >> 4) & 0xf]);
                serial_print_char(hexchars[(idx >> 0) & 0xf]);
                return;
        }
        int tries = 64;
        while (!serial_xmit_empty() && tries--);
        if (tries > 0) {
                outb(COM1_BASE, c);
        }
}


void
serial_print_string(const char *str)
{
        while(*str) {
                serial_print_char(*str);
                str++;
        }
}


static void
serial_init()
{
        outb(COM1_BASE + 1, 0x00);    // Disable all interrupts
        outb(COM1_BASE + 3, 0x80);    // Enable DLAB (set baud rate divisor)
        outb(COM1_BASE + 0, 0x03);    // Set divisor to 3 (lo byte) 38400 baud
        outb(COM1_BASE + 1, 0x00);    //                  (hi byte)
        outb(COM1_BASE + 3, 0x03);    // 8 bits, no parity, one stop bit
        outb(COM1_BASE + 2, 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
        serial_print_string("COM1 Initialised\n");
}

text_coord
etty_chars_per_line()
{
        return text_width;
}


text_coord
etty_total_lines()
{
        return text_height;
}


text_coord
etty_get_cursor_x()
{
        return cursor_x;
}


text_coord
etty_get_cursor_y()
{
        return cursor_y;
}


void
etty_set_cursor_x(text_coord x)
{
        if (x < text_width) {
                cursor_x = x;
        }
}


void
etty_set_cursor_y(text_coord y)
{
        if (y < text_height) {
                cursor_y = y;
        }
}


// If cursor is outside of screen, set to bottom right
static void
fix_cursor(text_coord *x, text_coord *y)
{
        if (*x >= text_width) *x = text_width - 1;
        if (*y >= text_height) *y = text_height - 1;
}


static void
get_hw_cursor(text_coord *x, text_coord *y)
{
        // FIXME: need save_flags() / cli
        outb(crt_idx_reg, cursor_msb);
        uint16_t address = inb(crt_data_reg) << 8;
        outb(crt_idx_reg, cursor_lsb);
        address |= inb(crt_data_reg);
        *x = address % 80;
        *y = address / 80;
        fix_cursor(x, y);
}


static void
set_hw_cursor(text_coord x, text_coord y)
{
        fix_cursor(&x, &y);
        uint16_t address = (y * 80) + x;
        outb(crt_idx_reg, cursor_msb);
        outb(crt_data_reg, address >> 8);
        outb(crt_idx_reg, cursor_lsb);
        outb(crt_data_reg, address & 0xff);
}


static void
text_mode_print_char(text_coord x, text_coord y, const unsigned char ch)
{
        if (x >= text_width || y >= text_height) {
                return;
        }
        unsigned char *cursor_char = screen_buffer + (2 *  (y * text_width + x));
        *cursor_char = ch;
        *(cursor_char + 1) = 0x07;
}


static void
text_mode_clear_screen()
{
        memsetw(screen_buffer, 0x0720, text_width * text_height);
}


static void
text_mode_scroll_up()
{
        unsigned int bytes_per_line = text_width * 2;
        memcpy(screen_buffer, screen_buffer + bytes_per_line,
               (text_height-1) * bytes_per_line);
        memsetw(screen_buffer + ((text_height-1) * bytes_per_line), 0x0720,
                text_width);
}


// Frambuffer functions

static uint32_t
colour_mask(uint8_t red, uint8_t green, uint8_t blue)
{
        uint32_t colour = (red & frame_buffer.red_mask) << frame_buffer.red_shift;
        colour |= (green & frame_buffer.green_mask) << frame_buffer.green_shift;
        colour |= (blue & frame_buffer.blue_mask) << frame_buffer.blue_shift;

        return colour;
}


static int
convert_font_line(const unsigned char *data, uint8_t *buf)
{
        unsigned int offset = 0;
        uint32_t mask = colour_mask(text_red, text_green, text_blue);
        for(int i = font->width-1; i >= 0; i--) {
                int bit = data[0] & (1 << i);
                uint32_t db = frame_buffer.depth / 8;
                for(uint32_t i = 0; i < db; i++) {
                        buf[offset++] = bit ? (mask >> (i*8)) : 0;
                }
        }

        return offset;
}


// Colour is RGB with B in LSB
static void
set_text_colour(uint32_t colour)
{
        text_blue = colour & 0xff;
        text_green = (colour >> 8) & 0xff;
        text_red = (colour >> 16) & 0xff;
        text_colour = colour;
}


static void
fb_print_char(text_coord x, text_coord y, const unsigned char ch)
{
        if (x >= text_width || y >= text_height) {
                return;
        }

        int bytes_per_char = ((font->width + 7) / 8) * font->height;
        const unsigned char *char_data = font->data + (bytes_per_char * ch);


        unsigned int pixel = (y * font->height) * frame_buffer.px_per_scanline
                + (x * font->width);
        int db = (frame_buffer.depth / 8);
        pixel *= db;
        for(int line = 0; line < font->height; line++) {
                uint8_t buf[128];
                int px = convert_font_line(char_data, buf);
                for(int p = 0; p < px; p++) {
                        screen_buffer[pixel + p] = buf[p];
                }
                pixel += (frame_buffer.px_per_scanline * db);
                char_data += ((font->width + 7) / 8);
        }
}


static void
fb_clear_screen()
{
        size_t size = frame_buffer.px_per_scanline * (frame_buffer.depth / 8);
        size *= frame_buffer.height;
        memset(screen_buffer, 0, size);
}


static void
fb_scroll_up()
{
        //unsigned int bytes_per_line = text_width * 2;
        unsigned int text_line = frame_buffer.px_per_scanline * (frame_buffer.depth / 8);
        text_line *= font->height;
        memcpy(screen_buffer, screen_buffer + text_line,
               text_line * (text_height - 1));
        memset(screen_buffer + (text_line * (text_height - 1)), 0, text_line);
}


void
framebuffer_test(struct frame_buffer *fb)
{
        kprintf("Frambuffer info fb = %p ", fb);
        kprintf("font size: %dx%d font->data:%p fontdata_8x16:%p\n",
                font->width, font->height, font->data, fontdata_8x16);
        kprintf("Framebuffer: %dx%d bpp: %d px per line: %d addr:%p size: %lx\n",
                fb->width, fb->height, fb->depth, fb->px_per_scanline,
                fb->address, fb->size);
        kprintf("Red shift:   %2d Red mask:   %x\n", fb->red_shift, fb->red_mask);
        kprintf("Green shift: %2d Green mask: %x\n", fb->green_shift, fb->green_mask);
        kprintf("Blue shift:  %2d Blue mask:  %x\n", fb->blue_shift, fb->blue_mask);
        unsigned char ch = 0;
        for(int y = 7; y < 23; y++) {
                for (int x = 0; x < 16; x++) {
                        fb_print_char(x, y, ch);
                        ch++;
                        ch &= 0xff;
                }
        }
        cursor_x = 0;
        cursor_y = 25;
}


void
early_print_char(const char c)
{
        serial_print_char(c);
        if (c == '\n') {
                cursor_x = 0;
                cursor_y++;
        } else if(c == '\t') {
                int new_x = (cursor_x + 8) & ~7;
                cursor_x = new_x;
        } else {
                etty_print_char(cursor_x, cursor_y, c);
                cursor_x++;
        }

        if (cursor_x >= text_width) {
                cursor_x = 0;
                cursor_y++;
        }

        if(cursor_y >= text_height) {
                etty_scroll_up();
                cursor_y--;
        }

        if (text_mode) {
                set_hw_cursor(cursor_x, cursor_y);
        }
}


void
early_print_string_len(const char *text, size_t len)
{
        while(len--) {
                early_print_char(*text++);
        }
}


void
early_print_string(const char *text)
{
        while(*text) {
                early_print_char(*text++);
        }
}


void
kprint(const char *string)
{
        while(*string) {
                early_print_char(*string);
                string++;
        }
}
