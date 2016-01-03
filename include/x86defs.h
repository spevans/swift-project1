/*
 * include/x86defs.h
 *
 * Created by Simon Evans on 03/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Header file for x86 specific data structures
 *
 */

#ifndef __X86_DEFS_H__
#define __X86_DEFS_H__

// Descriptor table info used for both GDT and IDT
struct dt_info {
        uint16_t size;
        void *address;
} __attribute__((packed));


#endif  // __X86_DEFS_H__
