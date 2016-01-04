/*
 * kernel/klibc.h
 *
 * Created by Simon Evans on 12/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Miscellaneous functions mostly string/memory
 *
 */

#include <stddef.h>
#include <stdarg.h>
#include <stdint.h>
#include <limits.h>
#include <inttypes.h>
#include "x86funcs.h"


typedef int64_t ssize_t;
typedef int64_t off_t;

#define UNIMPLEMENTED(x)  void x() { koops(__func__); }
#define likely(x)      __builtin_expect(!!(x), 1)
#define unlikely(x)    __builtin_expect(!!(x), 0)


// kprintf

int kvsprintf(char *buf, const char *fmt, va_list args) __attribute__ ((format (printf, 2, 0)));
int ksprintf(char *buf, const char *fmt, ...) __attribute__ ((format (printf, 2, 3)));
int kvprintf(const char *fmt, va_list args) __attribute__ ((format (printf, 1, 0)));
int kprintf(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));


#ifdef DEBUG
#define debugf(...) kprintf(__VA_ARGS__)
#else
#define debugf(...) do {} while(0)
#endif


// klibc

void koops(const char *fmt, ...) __attribute__ ((format (printf, 1, 2))) __attribute__((noreturn));

int memcmp(const void *s1, const void *s2, size_t count);
void *memcpy(void *dest, const void *src, size_t count);
void *memset(void *dest, char c, size_t count);
void *memsetw(void *dest, uint16_t w, size_t count);
char *stpcpy(char *dest, const char *src);
int strcmp(const char *s1, const char *s2);
char *strcpy(char *dest, const char *src);
size_t strlen(const char *s);


// tty

extern void (*print_char)(const char ch);
extern void (*print_string)(const char *str);
extern void (*print_string_len)(const char *str, size_t len);

void print_nibble(int value);
void print_byte(int value);
void print_word(int value);
void print_dword(unsigned int value);
void print_qword(uint64_t value);


// mm

#define PAGE_SIZE 4096
#define PAGE_SHIFT 12
#define PAGE_MASK (PAGE_SIZE-1)

void *alloc_pages(size_t count);
void free_pages(void *pages, size_t count);
void *malloc(size_t size);
void free(void *ptr);
