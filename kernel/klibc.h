/*
 * kernel/klibc.h
 *
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Miscellaneous functions mostly string/memory
 *
 */

#include <stddef.h>
#include <stdarg.h>
#include <stdint.h>
#include <limits.h>

typedef int64_t ssize_t;
typedef int64_t off_t;

#define UNIMPLEMENTED(x)  void x() { koops(__func__); }
#define likely(x)      __builtin_expect(!!(x), 1)
#define unlikely(x)    __builtin_expect(!!(x), 0)


void print_string(const char *str);
void print_string_len(const char *str, size_t len);
void kvsprintf(char *buf, const char *fmt, va_list args) __attribute__ ((format (printf, 2, 0)));
void ksprintf(char *buf, const char *fmt, ...) __attribute__ ((format (printf, 2, 3)));
void kvprintf(const char *fmt, va_list args) __attribute__ ((format (printf, 1, 0)));
void kprintf(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));
void halt();

void koops(const char *fmt, ...) __attribute__ ((format (printf, 1, 0))) __attribute__((noreturn));
void hlt() __attribute__((noreturn));

void *malloc(size_t size);
void free(void *ptr);
void *__memcpy(void *dest, const void *src, size_t n);
void *memcpy(void *dest, const void *src, size_t n);
int memcmp(const void *s1, const void *s2, size_t n);
int strcmp(const char *cs, const char *ct);
size_t strlen(const char *s);
size_t d_strlen(const char *s);

void print_nibble(int value);
void print_byte(int value);
void print_word(int value);
void print_dword(unsigned int value);
void print_qword(uint64_t value);
