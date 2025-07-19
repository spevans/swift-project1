/*
 *  I915Blitter.swift
 *  Kernel
 *
 *  Created by Simon Evans on 26/07/2025.
 *
 *  2D Blitter commands
 */

typealias RGBA32 = UInt32

extension I915 {


    func xy_color_blt(x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16, colour: RGBA32) {
        guard x1 <= x2, y1 <= y2 else {
            #kprintf("Invalid coordinates: (%u, %u) -> (%u, %u)\n", x1, y1, x2, y2)
            return
        }
        guard Int(x2) <= width, Int(y2) <= height else {
            #kprintf("Cordinates out of bounds (%u, %u)\n", x2, y2)
            return
        }

        let x1y1 = UInt32(x1) | (UInt32(y1) << 16)
        let x2y2 = UInt32(x2) | (UInt32(y2) << 16)
        let commands: InlineArray = [
            UInt32(0x5430_0804),
            0x03f0_0800,
            x1y1,
            x2y2,
            0,
            colour,
        ]
        writeToRingBuffer(commands.span)
    }

    func xy_setup_blt(bgColour: RGBA32, fgColour: RGBA32) {
        let x1y1 = UInt32(0)
        let x2y2 = UInt32(1279) | (UInt32(799) << 16)

        let commands: InlineArray = [
            0x4070_0806,
            0x43cc_0800,
            x1y1,
            x2y2,
            0,
            bgColour,
            fgColour,
            0
        ]
        writeToRingBuffer(commands.span)
    }

    func xy_text_blt(x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16, sourceAddress: UInt32) {
        guard x1 <= x2, y1 <= y2 else {
            #kprintf("Invalid coordinates: (%u, %u) -> (%u, %u)\n", x1, y1, x2, y2)
            return
        }
        guard Int(x2) <= width, Int(y2) <= height else {
            #kprintf("Cordinates out of bounds (%u, %u)\n", x2, y2)
            return
        }

        let x1y1 = UInt32(x1) | (UInt32(y1) << 16)
        let x2y2 = UInt32(x2) | (UInt32(y2) << 16)
        let commands: InlineArray = [
            (0x2 << 29) | BlitterCommands.XY_TEXT_BLT.rawValue << 22 | (1 << 11) | 2,
            x1y1,
            x2y2,
            sourceAddress,
        ]
        writeToRingBuffer(commands.span)
    }

    func xy_text_immediate_blt(x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16, characterData: UnsafeBufferPointer<UInt8> ) {
        guard x1 <= x2, y1 <= y2 else {
            #kprintf("Invalid coordinates: (%u, %u) -> (%u, %u)\n", x1, y1, x2, y2)
            return
        }
        guard Int(x2) <= width, Int(y2) <= height else {
            #kprintf("Cordinates out of bounds (%u, %u)\n", x2, y2)
            return
        }

        let dWordCount = UInt32(characterData.count + 3) / 4

        let x1y1 = UInt32(x1) | (UInt32(y1) << 16)
        let x2y2 = UInt32(x2) | (UInt32(y2) << 16)

        var commands: [UInt32] = [
            0x4c40_0800 | (dWordCount + 1),
            x1y1,
            x2y2,
        ]
        var count = 0
        var dword: UInt32 = 0
        for value in characterData {
            dword |= UInt32(value) << (8 * count)
            count += 1
            if count == 4 {
                commands.append(dword)
                count = 0
                dword = 0
            }
        }
        if !commands.count.isMultiple(of: 2) {
            commands.append(0)
        }
        writeToRingBuffer(commands.span)
    }


    func xy_src_copy_blt(x1: UInt16, y1: UInt16, x2: UInt16, y2: UInt16, sourceX1: UInt16, sourceY1: UInt16) {
        guard x1 <= x2, y1 <= y2 else {
            #kprintf("Invalid coordinates: (%u, %u) -> (%u, %u)\n", x1, y1, x2, y2)
            return
        }
        guard Int(x2) <= width, Int(y2) <= height else {
            #kprintf("Cordinates out of bounds (%u, %u)\n", x2, y2)
            return
        }

        let x1y1 = UInt32(x1) | (UInt32(y1) << 16)
        let x2y2 = UInt32(x2) | (UInt32(y2) << 16)

        let srcx1y1 = UInt32(sourceX1) | (UInt32(sourceY1) << 16)
        let commands: InlineArray = [
            0x54f0_8806,
            0x03cc_0800,    // clipping disabled
            x1y1,
            x2y2,
            0,              // Destination base address
            srcx1y1,
            0x800,
            0,
        ]
        writeToRingBuffer(commands.span)
    }

    private enum BlitterCommands: UInt32 {
        case XY_SETUP_BLT = 0x1
        case XY_SETUP_CLIP_BLT = 0x3
        case XY_SETUP_MONO_PATTERN_SL_BLT = 0x11
        case XY_PIXEL_BLT = 0x24
        case XY_SCANLINE_BLT = 0x25
        case XY_TEXT_BLT = 0x26
        case XY_TEXT_IMMEDIATE_BLT = 0x31
        case COLOR_BLT = 0x40
        case SRC_COPY_BLT = 0x43
        case XY_COLOR_BLT = 0x50
        case XY_PAT_BLT = 0x51
        case XY_MONO_PAT_BLT = 0x52
        case XY_SRC_COPY_BLT_1 = 0x53
        case XY_MONO_SRC_COPY_BLT = 0x54
        case XY_FULL_BLT = 0x55
        case XY_FULL_MONO_SRC_BLT = 0x56
        case XY_FULL_MONO_PATTERN_BLT = 0x57
        case XY_FULL_MONO_PATTERN_MONO_SRC_BLT = 0x58
        case XY_MONO_PAT_FIXED_BLT = 0x59
        case XY_MONO_SRC_COPY_IMMEDIATE_BLT = 0x71
        case XY_PAT_BLT_IMMEDIATE = 0x72
        case XY_SRC_COPY_CHROMA_BLT = 0x73
        case XY_FULL_IMMEDIATE_PATTERN_BLT = 0x74
        case XY_FULL_MONO_SRC_IMMEDIATE_PATTERN_BLT = 0x75
        case XY_PAT_CHROMA_BLT = 0x76
        case XY_PAT_CHROMA_BLT_IMMEDIATE = 0x77
    }
}
