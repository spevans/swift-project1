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
#include <inttypes.h>

typedef int64_t ssize_t;
typedef int64_t off_t;

#define UNIMPLEMENTED(x)  void x() { koops(__func__); }
#define likely(x)      __builtin_expect(!!(x), 1)
#define unlikely(x)    __builtin_expect(!!(x), 0)


void kvsprintf(char *buf, const char *fmt, va_list args) __attribute__ ((format (printf, 2, 0)));
void ksprintf(char *buf, const char *fmt, ...) __attribute__ ((format (printf, 2, 3)));
void kvprintf(const char *fmt, va_list args) __attribute__ ((format (printf, 1, 0)));
void kprintf(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));
void halt();

void koops(const char *fmt, ...) __attribute__ ((format (printf, 1, 2))) __attribute__((noreturn));
void hlt() __attribute__((noreturn));

int memcmp(const void *s1, const void *s2, size_t count);
void *memcpy(void *restrict dest, const void *restrict src, size_t count);
void *memset(void *dest, char c, size_t count);
int strcmp(const char *s1, const char *s2);
char *strcpy(char *restrict dest, const char *restrict src);
size_t strlen(const char *s);

void *malloc(size_t size);
void free(void *ptr);

void print_string(const char *str);
void print_string_len(const char *str, size_t len);
void print_char(const char ch);
void print_nibble(int value);
void print_byte(int value);
void print_word(int value);
void print_dword(unsigned int value);
void print_qword(uint64_t value);
