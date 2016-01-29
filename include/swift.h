/*
 * kernel/swift.h
 *
 * Created by Simon Evans on 16/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Declarations of Swift functions callable from C
 *
 */

// Swift versions of the print functions

// static SwiftKernel.TTY.printChar (Swift.Int8) -> ()
extern void tty_print_char(const char ch);

// static SwiftKernel.TTY.printCString (Swift.UnsafePointer<Swift.Int8>) -> ()
extern void tty_print_cstring(const char *str);

// static SwiftKernel.TTY.printCStringLen (Swift.UnsafePointer<Swift.Int8>, length : Swift.Int) -> ()
extern void tty_print_cstring_len(const char *str, size_t len);
