#include <stddef.h>
#include <stdarg.h>


void print_string(const char *str);
void kvsprintf(char *buf, const char *fmt, va_list args) __attribute__ ((format (printf, 2, 0)));
void ksprintf(char *buf, const char *fmt, ...) __attribute__ ((format (printf, 2, 3)));
void kvprintf(const char *fmt, va_list args) __attribute__ ((format (printf, 1, 0)));
void kprintf(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));
void halt();

void print_and_halt(const char *str) __attribute__((noreturn));
void koops(const char *str) __attribute__((noreturn));
void hlt() __attribute__((noreturn));

void *malloc(size_t size);
void free(void *ptr);
void *__memcpy(void *dest, const void *src, size_t n);
int strcmp(const char *cs, const char *ct);
size_t strlen(const char *s);
