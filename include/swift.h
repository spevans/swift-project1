/*
 * kernel/swift.h
 *
 * Created by Simon Evans on 16/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Declarations of Swift functions callable from C
 *
 */

#ifndef __SWIFT_H__
#define __SWIFT_H__

#include <stddef.h>


// Swift versions of the print functions

// static SwiftKernel.TTY.printChar (Swift.Int8) -> ()
extern void tty_print_char(const char ch);

// static SwiftKernel.TTY.printCString (Swift.UnsafePointer<Swift.Int8>) -> ()
extern void tty_print_cstring(const char * _Nonnull str);

// static SwiftKernel.TTY.printCStringLen (Swift.UnsafePointer<Swift.Int8>, length : Swift.Int) -> ()
extern void tty_print_cstring_len(const char * _Nonnull str, size_t len);

// Used by dladdr() implemented in kernel/mm/symbols.swift
typedef struct {
    const char * _Nullable dli_fname;        /* File name of defining object.  */
    void * _Nullable dli_fbase;              /* Load address of that object.  */
    const char * _Nullable dli_sname;        /* Name of nearest symbol.  */
    void * _Nullable dli_saddr;              /* Exact value of nearest symbol.  */
} Dl_info;
extern int dladdr(const void * _Nullable addr, Dl_info * _Nonnull info);

#endif  // __SWIFT_H__
