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
extern void _TZFC7Devices3TTY9printCharfVs4Int8T_(const char);

// static SwiftKernel.TTY.printCString (Swift.UnsafePointer<Swift.Int8>) -> ()
extern void _TZFC7Devices3TTY12printCStringfGSPVs4Int8_T_(const char *);

// static SwiftKernel.TTY.printCStringLen (Swift.UnsafePointer<Swift.Int8>, length : Swift.Int) -> ()
extern void _TZFC7Devices3TTY15printCStringLenfTGSPVs4Int8_6lengthSi_T_(const char *, size_t);
