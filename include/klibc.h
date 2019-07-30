/*
 * kernel/klibc.h
 *
 * Created by Simon Evans on 12/12/2015.
 * Copyright © 2015 - 2018 Simon Evans. All rights reserved.
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
#include "efi.h"


typedef int64_t ssize_t;
typedef int64_t off_t;

#define UNIMPLEMENTED(x)  void x() { koops("UNIMPLEMENTED: %s", __func__); }
#define likely(x)      __builtin_expect(!!(x), 1)
#define unlikely(x)    __builtin_expect(!!(x), 0)

#if DEBUG
#define debugf(...) do {                                            \
        serial_printf("debug: %p: ", __builtin_return_address(0));  \
        serial_printf(__VA_ARGS__);                                 \
} while(0)

#else
#define debugf(...) do {} while(0)
#endif


// kprintf
int kvsnprintf(char * _Nonnull buf, size_t size, const char * _Nonnull fmt, va_list args) __attribute__ ((format (printf, 3, 0)));
int kvlprintf(const char * _Nonnull fmt, size_t len, va_list args);
int kvprintf(const char * _Nonnull fmt, va_list args) __attribute__ ((format (printf, 1, 0)));
int kprintf(const char * _Nonnull fmt, ...) __attribute__ ((format (printf, 1, 2)));
int kprintf1arg(const char * _Nonnull fmt, long l1);
int kprintf2args(const char * _Nonnull fmt, long l1, long l2);
int kprintf3args(const char * _Nonnull fmt, long l1, long l2, long l3);

// bochs printf
int bprintf(const char * _Nonnull fmt, ...) __attribute__ ((format (printf, 1, 2)));
void bochs_print_string(const char * _Nonnull str, size_t len);
int serial_printf(const char * _Nonnull fmt, ...) __attribute__ ((format (printf, 1, 2)));


// klibc
void abort(void);
void debugger_hook(void);
void koops(const char * _Nonnull fmt, ...) __attribute__ ((format (printf, 1, 2))) __attribute__((noreturn));
void dump_registers(struct exception_regs * _Nonnull registers);
void stack_trace(uintptr_t rsp, uintptr_t rbp);
int memcmp(const void * _Nonnull s1, const void * _Nonnull s2, size_t count);
void * _Nonnull memcpy(void * _Nonnull dest, const void * _Nonnull src, size_t count);
void * _Nonnull memset(void * _Nonnull dest, int c, size_t count);
void * _Nonnull memsetw(void * _Nonnull dest, uint16_t w, size_t count);
int strcmp(const char * _Nonnull s1, const char * _Nonnull s2);
char * _Nonnull strcpy(char * _Nonnull dest, const char * _Nonnull src);
size_t strlen(const char * _Nonnull s);

// early_tty.c
typedef uint16_t text_coord;
void kprint(const char * _Nonnull string);
void serial_print_char(const char ch);
void early_print_char(const char c);
void early_print_string(const char * _Nonnull text);
void early_print_string_len(const char * _Nonnull text, size_t len);

// early_tty interface for TTY.EarlyTTY driver
extern void (* _Nonnull etty_print_char)(text_coord x, text_coord y, const unsigned char ch);
extern void (* _Nonnull etty_clear_screen)(void);
extern void (* _Nonnull etty_scroll_up)(void);
text_coord etty_chars_per_line(void);
text_coord etty_total_lines(void);
text_coord etty_get_cursor_x(void);
text_coord etty_get_cursor_y(void);
void etty_set_cursor_x(text_coord x);
void etty_set_cursor_y(text_coord y);


// kernel/traps/entry.asm
unsigned int read_int_nest_count(void);
void run_first_task(void);
void set_interrupt_manager(const void * _Nonnull im);

#endif  // __KLIBC_H__
