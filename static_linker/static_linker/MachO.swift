//
//  MachO.swift
//  static_linker
//
//  Created by Simon Evans on 25/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


enum RebaseOpcode: UInt8 {
    static let OPCODE_MASK: UInt8   = 0xF0
    static let IMMEDIATE_MASK: UInt8 = 0x0F

    case REBASE_OPCODE_DONE                               = 0x00
    case REBASE_OPCODE_SET_TYPE_IMM                       = 0x10
    case REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB        = 0x20
    case REBASE_OPCODE_ADD_ADDR_ULEB                      = 0x30
    case REBASE_OPCODE_ADD_ADDR_IMM_SCALED                = 0x40
    case REBASE_OPCODE_DO_REBASE_IMM_TIMES                = 0x50
    case REBASE_OPCODE_DO_REBASE_ULEB_TIMES               = 0x60
    case REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB            = 0x70
    case REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB = 0x80
}

enum RebaseType: UInt8 {
    case NONE       = 0
    case POINTER    = 1
    case ABSOLUTE32 = 2
    case PCREL32    = 3
}

enum BindOpcode: UInt8 {
    static let OPCODE_MASK: UInt8      = 0xF0
    static let IMMEDIATE_MASK: UInt8   = 0x0F
    static let BIND_SPECIAL_DYLIB_SELF                  = 0
    static let BIND_SPECIAL_DYLIB_MAIN_EXECUTABLE       = -1
    static let BIND_SPECIAL_DYLIB_FLAT_LOOKUP           = -2
    static let BIND_SYMBOL_FLAGS_WEAK_IMPORT            = 0x1
    static let BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION    = 0x8


    case BIND_OPCODE_DONE                               = 0x00
    case BIND_OPCODE_SET_DYLIB_ORDINAL_IMM              = 0x10
    case BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB             = 0x20
    case BIND_OPCODE_SET_DYLIB_SPECIAL_IMM              = 0x30
    case BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM      = 0x40
    case BIND_OPCODE_SET_TYPE_IMM                       = 0x50
    case BIND_OPCODE_SET_ADDEND_SLEB                    = 0x60
    case BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB        = 0x70
    case BIND_OPCODE_ADD_ADDR_ULEB                      = 0x80
    case BIND_OPCODE_DO_BIND                            = 0x90
    case BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB              = 0xA0
    case BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED        = 0xB0
    case BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB   = 0xC0
}

enum BindType: UInt8 {
    case NONE       = 0
    case POINTER    = 1
    case ABSOLUTE32 = 2
    case PCREL32    = 3
}
