/*
 * kernel/klibc.h
 *
 * Created by Simon Evans on 12/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Miscellaneous functions mostly string/memory
 *
 */

#ifndef __KLIBC_H__
#define __KLIBC_H__

#include <stddef.h>
#include <stdarg.h>
#include <stdint.h>
#include <limits.h>
#include <inttypes.h>
#include "x86funcs.h"
#include "mm.h"


typedef int64_t ssize_t;
typedef int64_t off_t;

#define UNIMPLEMENTED(x)  void x() { koops("UNIMPLEMENTED: %s", __func__); }
#define likely(x)      __builtin_expect(!!(x), 1)
#define unlikely(x)    __builtin_expect(!!(x), 0)

#ifdef DEBUG
#define debugf(...) bprintf(__VA_ARGS__)
#else
#define debugf(...) do {} while(0)
#endif


// kprintf
int kvsnprintf(char *buf, size_t size, const char *fmt, va_list args) __attribute__ ((format (printf, 3, 0)));
int kvlprintf(const char *fmt, size_t len, va_list args);
int kvprintf(const char *fmt, va_list args) __attribute__ ((format (printf, 1, 0)));
int kprintf(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));
// bochs printf
int bprintf(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));
void bochs_print_string(const char *str, size_t len);


// klibc
void koops(const char *fmt, ...) __attribute__ ((format (printf, 1, 2))) __attribute__((noreturn));
void dump_registers(struct exception_regs *registers);
int memcmp(const void *s1, const void *s2, size_t count);
void *memcpy(void *dest, const void *src, size_t count);
void *memset(void * dest, int c, size_t count);
void *memsetw(void *dest, uint16_t w, size_t count);
char *stpcpy(char *dest, const char *src);
int strcmp(const char *s1, const char *s2);
char *strcpy(char *dest, const char *src);
size_t strlen(const char *s);


// early_tty.c
typedef uint16_t text_coord;

extern void (*print_char)(const char ch);
extern void (*print_string)(const char *str);
extern void (*print_string_len)(const char *str, size_t len);

void set_print_functions_to_swift();
void early_print_string(const char *text);
void early_print_string_len(const char *text, size_t len);
void kprint_byte(uint8_t value);
void kprint_word(uint16_t value);
void kprint_dword(uint32_t value);
void kprint_qword(uint64_t value);

// early_tty interface for TTY.EarlyTTY driver
extern void (*etty_print_char)(text_coord x, text_coord y, const unsigned char ch);
extern void (*etty_clear_screen)();
extern void (*etty_scroll_up)();
text_coord etty_chars_per_line();
text_coord etty_total_lines();
text_coord etty_get_cursor_x();
text_coord etty_get_cursor_y();
void etty_set_cursor_x(text_coord x);
void etty_set_cursor_y(text_coord y);


// entry.asm
unsigned int read_int_nest_count();

#endif  // __KLIBC_H__
