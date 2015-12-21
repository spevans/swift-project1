/*
 * kernel/early_tty.c
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Simple functions to print characters and strings until the
 * Swift TTY driver is initialised
 *
 */

#include "klibc.h"
#include "swift.h"


static void early_print_char(const char c);
static void early_print_string(const char *text);
static void early_print_string_len(const char *text, size_t len);

// Initialise the function pointers, later updated to point to TTY.swift
void (*print_char)(const char) = early_print_char;
void (*print_string)(const char *) = early_print_string;
void (*print_string_len)(const char *, size_t) = early_print_string_len;

// Base address of PC screen RAM
static char *const screen = (char *)0xB8000;


static void
early_print_char(const char c)
{
        static int cursor_x, cursor_y;
        char *cursor_char = (screen + (cursor_y * 80 * 2) + (cursor_x * 2));

        if((c == '\n') || (cursor_x >= 80)) {
                cursor_x = 0;
                if(++cursor_y >= 25) {
                        memcpy(screen, screen + 160, 24 * 160);
                        memsetw(screen + (24 * 160), 0x0720, 160);
                        cursor_y--;
                }
                cursor_char = (screen + (cursor_y * 80 * 2)
                               + (cursor_x * 2));
                if(c == '\n') {
                        return;
                }
        }
        else if(c == '\t') {
                int new_x = (cursor_x + 8) & ~7;
                memsetw(cursor_char, 0x0720, new_x - cursor_x);
                cursor_x = new_x;
                cursor_char = (screen + (cursor_y * 80 * 2)
                               + (cursor_x * 2));
                return;
        }
        *cursor_char++ = c;
        *cursor_char++ = 0x07;
        cursor_x++;
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
