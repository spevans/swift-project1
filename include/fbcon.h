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

#include <stdint.h>


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
} __attribute__((packed));


struct standard_timing {
        uint8_t horizontal_pixels; // Horizontal resolution in pixels
        uint8_t aspect_ratio_refresh;    // Vertical resolution in lines
} __attribute__((packed));

struct detailed_timing {
        uint16_t pixel_clock;                  // Pixel clock in MHz
        uint8_t horizontal_pixels;             // Horizontal resolution in pixels
        uint8_t horizontal_blanking;
        uint8_t h_pixels_blanking_msb;
        uint8_t vertical_active_lines;                // Vertical resolution in lines
        uint8_t vertical_blanking_lines;
        uint8_t v_lines_msb;
        uint8_t horizontal_sync_offset;         // Horizontal sync offset
        uint8_t horizontal_sync_pulse_width;    // Horizontal sync pulse width
        uint8_t verital_syn_pulse_width;
        uint8_t horizontal_sync_msbs;
        uint8_t horizontal_size_mm;           
        uint8_t vertical_size_mm;
        uint8_t horiz_vertical_size_msbs;
        uint8_t horizontal_border_pixels;                          // Flags (e.g., interlaced, sync polarity)
        uint8_t vertical_border_lines;
        uint8_t features_bitmap;             // Additional descriptor data
} __attribute__((packed));

struct edid_data {
        uint64_t header;                        // EDID header 00_ff_ff_ff_ff_ff_ff_00
        uint16_t manufacturer_id;               // Manufacturer ID (2 bytes)
        uint16_t product_code;                  // Product code
        uint32_t serial_number;                 // Serial number
        uint8_t manufacture_week;               // Week of manufacture
        uint8_t manufacture_year;               // Year of manufacture
        uint8_t version;                        // EDID version
        uint8_t revision;                       // EDID revision
        uint8_t video_input_bitmap;             // Video input parameters bitmap
        uint8_t horizontal_screen_size;         // Size in centimeters or landscape aspect ratio
        uint8_t vertical_screen_size;           // Size in centimeters or portrait aspect ratio
        uint8_t display_gamma;
        uint8_t supported_features_bitmap;
        uint8_t color_characteristics[10];      // Color characteristics
        uint8_t established_timings[3];         // Established timing
        struct standard_timing standard_timings[8];   // Standard timings
        
        struct detailed_timing detailed_timings[4];    // Detailed timing descriptors
        uint8_t extension_flag;                 // Extension flag
        uint8_t checksum;                       // Checksum
} __attribute__((packed));


#endif  // __FBCON_H__
