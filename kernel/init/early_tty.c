/*
 * kernel/init/early_tty.c
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Simple functions to print characters and strings until the
 * Swift TTY driver is initialised
 *
 */

#include "klibc.h"
#include "swift.h"


void early_print_char(const char c);
static void early_print_string(const char *text);
static void early_print_string_len(const char *text, size_t len);

// Initialise the function pointers, later updated to point to TTY.swift
void (*print_char)(const char) = early_print_char;
void (*print_string)(const char *) = early_print_string;
void (*print_string_len)(const char *, size_t) = early_print_string_len;

// Base address of PC screen RAM
static char *const screen = (char *)0xB8000;
// Motorola 6845 CRT Controller registers
static const uint16_t crt_idx_reg = 0x3D4;
static const uint16_t crt_data_reg = 0x3D5;
static const uint8_t cursor_msb = 0xE;
static const uint8_t cursor_lsb = 0xF;

static void
get_cursor(int *x, int *y)
{
        uint16_t address;

        outb(crt_idx_reg, cursor_msb);
        address = inb(crt_data_reg) << 8;
        outb(crt_idx_reg, cursor_lsb);
        address |= inb(crt_data_reg);
        *x = address % 80;
        *y = address / 80;
}


static void
set_cursor(int x, int y)
{
        uint16_t address = (y * 80) + x;
        outb(crt_idx_reg, cursor_msb);
        outb(crt_data_reg, address >> 8);
        outb(crt_idx_reg, cursor_lsb);
        outb(crt_data_reg, address & 0xff);
}


void
early_print_char(const char c)
{
        int cursor_x, cursor_y;
        get_cursor(&cursor_x, &cursor_y);

        if (c == '\n') {
                cursor_x = 0;
                cursor_y++;
        } else if(c == '\t') {
                int new_x = (cursor_x + 8) & ~7;
                char *cursor_char = (screen + (cursor_y * 80 * 2) + (cursor_x * 2));
                memsetw(cursor_char, 0x0720, new_x - cursor_x);
                cursor_x = new_x;
        } else {
                char *cursor_char = (screen + (cursor_y * 80 * 2) + (cursor_x * 2));
                *cursor_char = c;
                *(cursor_char + 1) = 0x07;
                cursor_x++;
        }

        if (cursor_x >= 80) {
                cursor_x = 0;
                cursor_y++;
        }

        if(cursor_y >= 25) {
                memcpy(screen, screen + 160, 24 * 160);
                memsetw(screen + (24 * 160), 0x0720, 160);
                cursor_y--;
        }
        set_cursor(cursor_x, cursor_y);
}


static void
early_print_string_len(const char *text, size_t len)
{
        while(len--) {
                print_char(*text++);
        }
}


static void
early_print_string(const char *text)
{
        while(*text) {
                print_char(*text++);
        }
}


/*
 * Point the print functions to the swift ones in TTY.swift -
 * Called by TTY.initTTY() once swift has initialised
 */
void
set_print_functions_to_swift()
{
        print_char = &_TZFC11SwiftKernel3TTY9printCharfVs4Int8T_;
        print_string = &_TZFC11SwiftKernel3TTY12printCStringfGSPVs4Int8_T_;
        print_string_len = &_TZFC11SwiftKernel3TTY15printCStringLenfTGSPVs4Int8_6lengthSi_T_;
}


/* Simple number printing functions that dont invoke *printf */

void print_nibble(int value)
{
        static char *hex = "0123456789ABCDEF";
        print_char(hex[value & 0xf]);
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
