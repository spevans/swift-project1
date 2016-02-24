/*
 * include/fbcon.h
 *
 * Created by Simon Evans on 06/02/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Definition for graphical frambuffer and font
 *
 */

#ifndef __FBCON_H__
#define __FBCON_H__

struct frame_buffer {
        void *address;
        uint64_t size;
        uint32_t width;
        uint32_t height;
        uint32_t px_per_scanline;
        uint32_t depth;
        uint8_t red_shift;
        uint8_t red_mask;
        uint8_t green_shift;
        uint8_t green_mask;
        uint8_t blue_shift;
        uint8_t blue_mask;
} __attribute__((packed));

struct font {
        uint8_t width;
        uint8_t height;
        const unsigned char *data;
};

#endif  // __FBCON_H__
