/*
 * kernel/init/early_tty.c
 *
 * Created by Simon Evans on 26/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Simple functions to print characters and strings until the
 * Swift TTY driver is initialised
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

// Initialise the function pointers, later updated to point to TTY.swift
void (*print_char)(const char) = early_print_char;
void (*print_string)(const char *) = early_print_string;
void (*print_string_len)(const char *, size_t) = early_print_string_len;

// Base address of PC screen RAM
static char *const screen = (char *)(PHYSICAL_MEM_BASE + 0xB8000);
// Motorola 6845 CRT Controller registers
static const uint16_t crt_idx_reg = 0x3D4;
static const uint16_t crt_data_reg = 0x3D5;
static const uint8_t cursor_msb = 0xE;
static const uint8_t cursor_lsb = 0xF;

static unsigned int text_width = 80;
static unsigned int text_height = 25;
static unsigned int cursor_x = 0;
static unsigned int cursor_y = 0;
static int text_mode = 1;
static struct frame_buffer frame_buffer;
static const struct font *font;
static uint32_t text_colour = 0x00ffffff;
static uint8_t text_red = 0xff, text_green = 0xff, text_blue = 0xff;


void
init_early_tty(struct frame_buffer *fb)
{
        if (fb == NULL) {
                text_mode = 1;
                text_width = 80;
                text_height = 25;
                kprintf("Using text mode: ");
        } else {
                text_mode = 0;
                frame_buffer = *fb;
                font = &font8x16;
                text_width = fb->width / font->width;
                text_height = fb->height / font->height;
                set_text_colour(0x00ffffff); // rgb
                //framebuffer_test(fb);
                kprintf("Using framebuffer mode: ");
        }
        kprintf("Console size: %dx%d\n", text_width, text_height);
}


static void
fix_cursor(unsigned int *x, unsigned int *y)
{
        if (*x >= text_width) *x = text_width - 1;
        if (*y >= text_height) *y =text_height - 1;
}


static void
get_hw_cursor(unsigned int *x, unsigned int *y)
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
set_hw_cursor(unsigned int x, unsigned int y)
{
        fix_cursor(&x, &y);
        uint16_t address = (y * 80) + x;
        outb(crt_idx_reg, cursor_msb);
        outb(crt_data_reg, address >> 8);
        outb(crt_idx_reg, cursor_lsb);
        outb(crt_data_reg, address & 0xff);
}


static void
text_mode_print_char(const char ch)
{
        char *cursor_char = (screen + (cursor_y * text_width * 2) + (cursor_x * 2));
        *cursor_char = ch;
        *(cursor_char + 1) = 0x07;
}


static void
text_mode_scroll_up()
{
        unsigned int bytes_per_line = text_width * 2;
        memcpy(screen, screen + bytes_per_line, (text_height-1) * bytes_per_line);
        memsetw(screen + ((text_height-1) * bytes_per_line), 0x0720,
                bytes_per_line);
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
fb_print_char(unsigned char ch)
{
        int bytes_per_char = ((font->width + 7) / 8) * font->height;
        const unsigned char *char_data = font->data + (bytes_per_char * ch);
        uint8_t *screen = (uint8_t *)(PHYSICAL_MEM_BASE + frame_buffer.address);

        unsigned int pixel = (cursor_y * font->height) * frame_buffer.px_per_scanline
                + (cursor_x * font->width);
        int db = (frame_buffer.depth / 8);
        pixel *= db;
        for(int line = 0; line < font->height; line++) {
                uint8_t buf[128];
                int px = convert_font_line(char_data, buf);
                for(int p = 0; p < px; p++) {
                        screen[pixel + p] = buf[p];
                }
                pixel += (frame_buffer.px_per_scanline * db);
                char_data += ((font->width + 7) / 8);
        }
}


static void
fb_scroll_up()
{
        //unsigned int bytes_per_line = text_width * 2;
        unsigned int text_line = frame_buffer.px_per_scanline * (frame_buffer.depth / 8);
        text_line *= font->height;
        uint8_t *screen = (uint8_t *)(PHYSICAL_MEM_BASE + frame_buffer.address);

        memcpy(screen, screen + text_line, text_line * (text_height - 1));
        memset(screen + (text_line * (text_height - 1)), 0, text_line);
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
                        cursor_x = x;
                        cursor_y = y;
                        fb_print_char(ch);
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
        if (text_mode) {
                get_hw_cursor(&cursor_x, &cursor_y);
        }

        if (c == '\n') {
                cursor_x = 0;
                cursor_y++;
        } else if(c == '\t') {
                int new_x = (cursor_x + 8) & ~7;
                //char *cursor_char = (screen + (cursor_y * 80 * 2) + (cursor_x * 2));
                //memsetw(cursor_char, 0x0720, new_x - cursor_x);
                cursor_x = new_x;
        } else {
                if (text_mode) {
                        text_mode_print_char(c);
                } else {
                        fb_print_char(c);
                }
                cursor_x++;
        }

        if (cursor_x >= text_width) {
                cursor_x = 0;
                cursor_y++;
        }

        if(cursor_y >= text_height) {
                if (text_mode) {
                        text_mode_scroll_up();
                } else {
                        fb_scroll_up();
                }
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


/*
 * Point the print functions to the swift ones in TTY.swift -
 * Called by TTY.initTTY() once swift has initialised
 */
void
set_print_functions_to_swift()
{
        print_char = tty_print_char;
        print_string = tty_print_cstring;
        print_string_len = tty_print_cstring_len;
}


/* Simple number printing functions that dont invoke *printf */

void print_nibble(int value)
{
        static char *hex = "0123456789ABCDEF";
        early_print_char(hex[value & 0xf]);
}


void print_byte(int value)
{
        print_nibble((value >> 4) & 0xf);
        print_nibble(value & 0xf);
}


void print_word(int value)
{
        print_byte((value >> 8) & 0xff);
        print_byte(value & 0xff);
}


void print_dword(unsigned int value)
{
        print_word((value >> 16) & 0xffff);
        print_word(value & 0xffff);

}


void print_qword(uint64_t value)
{
        print_dword((value >> 32) & 0xffffffff);
        print_dword(value & 0xffffffff);
}


void print_pointer(void *ptr)
{
        print_string("0x");
        print_qword((uintptr_t)ptr);
}
