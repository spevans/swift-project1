/*
 * include/mm.h
 *
 * Created by Simon Evans on 18/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Miscellaneous definitions for memory management
 *
 */

#ifndef __MM_H__
#define __MM_H__

#define PHYSICAL_MEM_BASE       0x2000000000UL

#define PAGE_SIZE 4096UL
#define PAGE_MASK 4095UL
#define PAGE_SHIFT 12UL

#endif  // __MM_H__
