/*
 * klibc/misc.c
 *
 * Created by Simon Evans on 21/05/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Fake libc calls used by Linux/ELF libswiftCore
 *
 */

#include "klibc.h"

#define _UNISTD_H   // Avoid including all of unistd.h
#include <elf.h>

#pragma GCC diagnostic ignored "-Wunused-parameter"


extern void (*__init_array_start [])(void);
extern void (*__init_array_end [])(void);
extern Elf64_Rela __rela_iplt_start[];
extern Elf64_Rela __rela_iplt_end[];


uint64_t _cacheReadTest(uint8_t * _Nullable p, uint64_t count, uint8_t * _Nullable result) {
        uint8_t byte = 0;
        uint64_t start = rdtsc();
        for (size_t i = 0; i < count; i++) {
                byte += p[i];
        }
        uint64_t diff = rdtsc() - start;
        if (result) { *result = byte; };
        return diff;
}


uint64_t _cacheWriteTest(uint8_t * _Nullable p, uint64_t count, uint8_t data) {
        uint64_t start = rdtsc();
        for (size_t i = 0; i < count; i++) {
                p[i] = data;
        }
        uint64_t diff = rdtsc() - start;
        return diff;
}


void
klibc_start()
{
        // Call the static constructors held in the .init_array
        const size_t count = __init_array_end - __init_array_start;
        for (size_t idx = 0; idx < count; idx++) {
                void (*func)(void) = __init_array_start[idx];
                func();
        }

        // Setup relocations in the .rela.iplt array
        const size_t relocs = __rela_iplt_end - __rela_iplt_start;
        for (size_t idx = 0; idx < relocs; idx++) {
                Elf64_Rela *reloc = &__rela_iplt_start[idx];
                if (ELF64_R_TYPE(reloc->r_info) != R_X86_64_IRELATIVE) {
                        kprintf("Bad reloc type: %ld\n",
                                ELF64_R_TYPE(reloc->r_info));
                } else {
                        Elf64_Addr (*func)(void) = (void *)reloc->r_addend;
                        Elf64_Addr addr = func();
                        Elf64_Addr *const reloc_addr = (void *)reloc->r_offset;
                        *reloc_addr = addr;
                }
        }
}

// FIXME: This is not random!!!
void
arc4random_buf(void *buffer, size_t count)
{
        char *p = buffer;
        for (size_t i = 0; i < count; i++) {
                p[i] = (char)i;
        }
}

void
__assert_fail(const char *err, const char *file,
               unsigned int line, const char *function)
{
        koops("assert:%s:%s:%d:%s\n", file, function, line, err);
        hlt();
}

void _swift_stdlib_reportFatalErrorInFile(
    const unsigned char *prefix, int prefixLength,
    const unsigned char *message, int messageLength,
    const unsigned char *file, int fileLength,
    uint32_t line,
    uint32_t flags
) {
  kprintf("%s:%u: %s%s%s\n",
      file,
      line,
      prefix,
      (messageLength > 0 ? ": " : ""),
      message);
}

void
abort()
{
        koops("abort() called");
}

