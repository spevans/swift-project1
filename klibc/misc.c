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
__assert_fail(const char *err, const char *file,
               unsigned int line, const char *function)
{
        koops("assert:%s:%s:%d:%s\n", file, function, line, err);
        hlt();
}


void
__stack_chk_fail()
{
        koops("stack check fail !");
}


void
abort()
{
        koops("abort() called");
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
