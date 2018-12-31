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
#include <bits/confname.h>
#include <elf.h>

#pragma GCC diagnostic ignored "-Wunused-parameter"


extern void (*__init_array_start [])(void);
extern void (*__init_array_end [])(void);
extern Elf64_Rela __rela_iplt_start[];
extern Elf64_Rela __rela_iplt_end[];


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


void
_klibc_random(void *buffer, size_t count)
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


void
abort()
{
        koops("abort() called");
}


char *
strerror(int errno)
{
        return "fatal error";
}


// Used when libswiftCore is compiled with debugging
int
isdigit(int c)
{
        return (c >= '0' && c <='9');
}


char *
getenv(const char *name)
{
        return NULL;
}


// Unicode (libicu)
UNIMPLEMENTED(u_strToLower_55)
UNIMPLEMENTED(u_strToUpper_55)
UNIMPLEMENTED(ucol_closeElements_55)
UNIMPLEMENTED(ucol_next_55)
UNIMPLEMENTED(ucol_openElements_55)
UNIMPLEMENTED(ucol_open_55)
UNIMPLEMENTED(ucol_setAttribute_55)
UNIMPLEMENTED(ucol_strcollIter_55)
UNIMPLEMENTED(ucol_strcoll_55)
UNIMPLEMENTED(uiter_setString_55)
UNIMPLEMENTED(uiter_setUTF8_55)
UNIMPLEMENTED(ubrk_close_55)
UNIMPLEMENTED(ubrk_open_55)
UNIMPLEMENTED(ubrk_preceding_55)
UNIMPLEMENTED(ubrk_following_55)
UNIMPLEMENTED(ubrk_setText_55)
UNIMPLEMENTED(unorm2_getNFCInstance_55)
UNIMPLEMENTED(unorm2_spanQuickCheckYes_55)
UNIMPLEMENTED(u_isdefined_55)
UNIMPLEMENTED(unorm2_hasBoundaryBefore_55)
UNIMPLEMENTED(unorm2_normalize_55)
UNIMPLEMENTED(u_hasBinaryProperty_55)

UNIMPLEMENTED(u_charAge_60)
UNIMPLEMENTED(u_charName_60)
UNIMPLEMENTED(u_hasBinaryProperty_60)
UNIMPLEMENTED(u_isdefined_60)
UNIMPLEMENTED(u_getIntPropertyValue_60)
UNIMPLEMENTED(u_strToLower_60)
UNIMPLEMENTED(u_strToTitle_60)
UNIMPLEMENTED(u_strToUpper_60)
UNIMPLEMENTED(ubrk_close_60)
UNIMPLEMENTED(ubrk_following_60)
UNIMPLEMENTED(ubrk_open_60)
UNIMPLEMENTED(ubrk_preceding_60)
UNIMPLEMENTED(ubrk_setText_60)
UNIMPLEMENTED(ubrk_setUText_60)
UNIMPLEMENTED(ucol_closeElements_60)
UNIMPLEMENTED(ucol_next_60)
UNIMPLEMENTED(ucol_openElements_60)
UNIMPLEMENTED(ucol_open_60)
UNIMPLEMENTED(ucol_setAttribute_60)
UNIMPLEMENTED(ucol_strcollIter_60)
UNIMPLEMENTED(ucol_strcoll_60)
UNIMPLEMENTED(uiter_setString_60)
UNIMPLEMENTED(uiter_setUTF8_60)
UNIMPLEMENTED(unorm2_getNFCInstance_60)
UNIMPLEMENTED(unorm2_hasBoundaryBefore_60)
UNIMPLEMENTED(unorm2_normalize_60)
UNIMPLEMENTED(unorm2_spanQuickCheckYes_60)
UNIMPLEMENTED(utext_openUChars_60)
UNIMPLEMENTED(utext_openUTF8_60)
