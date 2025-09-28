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


void init_serial();
const uint16_t COM1_BASE = 0x3f8;
static int serial_initialised = 0;

static int
serial_xmit_empty()
{
        return inb(COM1_BASE + 5) & 0x20;
}

void
serial_print_char(const char c)
{
        static const char hexchars[] = "0123456789abcdef";
        init_serial();
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


void
init_serial()
{
    if (serial_initialised) { return; }
        outb(COM1_BASE + 1, 0x00);    // Disable all interrupts
        outb(COM1_BASE + 3, 0x80);    // Enable DLAB (set baud rate divisor)
        outb(COM1_BASE + 0, 0x03);    // Set divisor to 3 (lo byte) 38400 baud
        outb(COM1_BASE + 1, 0x00);    //                  (hi byte)
        outb(COM1_BASE + 3, 0x03);    // 8 bits, no parity, one stop bit
        outb(COM1_BASE + 2, 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
        serial_initialised = 1;
        serial_print_string("COM1 Initialised\n");
}
