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
int kvsnprintf(char * _Nonnull buf, size_t size, const char * _Nonnull fmt, va_list args) __attribute__ ((format (printf, 3, 0)));
int kvlprintf(const char * _Nonnull fmt, size_t len, va_list args);
int kvprintf(const char * _Nonnull fmt, va_list args) __attribute__ ((format (printf, 1, 0)));
int kprintf(const char * _Nonnull fmt, ...) __attribute__ ((format (printf, 1, 2)));
// bochs printf
int bprintf(const char * _Nonnull fmt, ...) __attribute__ ((format (printf, 1, 2)));
void bochs_print_string(const char * _Nonnull str, size_t len);


// klibc
void koops(const char * _Nonnull fmt, ...) __attribute__ ((format (printf, 1, 2))) __attribute__((noreturn));
void dump_registers(struct exception_regs * _Nonnull registers);
int memcmp(const void * _Nonnull s1, const void * _Nonnull s2, size_t count);
void * _Nonnull memcpy(void * _Nonnull dest, const void * _Nonnull src, size_t count);
void * _Nonnull memset(void * _Nonnull dest, int c, size_t count);
void * _Nonnull memsetw(void * _Nonnull dest, uint16_t w, size_t count);
char * _Nonnull stpcpy(char * _Nonnull dest, const char * _Nonnull src);
int strcmp(const char * _Nonnull s1, const char * _Nonnull s2);
char * _Nonnull strcpy(char * _Nonnull dest, const char * _Nonnull src);
size_t strlen(const char * _Nonnull s);


// early_tty.c
typedef uint16_t text_coord;

extern void (* _Nonnull print_char)(const char ch);
extern void (* _Nonnull print_string)(const char * _Nonnull str);
extern void (* _Nonnull print_string_len)(const char * _Nonnull str,
                                          size_t len);

void com1_print_char(const char ch);
void set_print_functions_to_swift();
void early_print_char(const char c);
void early_print_string(const char * _Nonnull text);
void early_print_string_len(const char * _Nonnull text, size_t len);
void kprint_byte(uint8_t value);
void kprint_word(uint16_t value);
void kprint_dword(uint32_t value);
void kprint_qword(uint64_t value);

// early_tty interface for TTY.EarlyTTY driver
extern void (* _Nonnull etty_print_char)(text_coord x, text_coord y, const unsigned char ch);
extern void (* _Nonnull etty_clear_screen)();
extern void (* _Nonnull etty_scroll_up)();
text_coord etty_chars_per_line();
text_coord etty_total_lines();
text_coord etty_get_cursor_x();
text_coord etty_get_cursor_y();
void etty_set_cursor_x(text_coord x);
void etty_set_cursor_y(text_coord y);


// entry.asm
unsigned int read_int_nest_count();

#endif  // __KLIBC_H__
