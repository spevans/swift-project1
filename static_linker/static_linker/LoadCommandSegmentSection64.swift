//
//  LoadCommandSegmentSection64.swift
//  static_linker
//
//  Created by Simon Evans on 15/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


class LoadCommandSegmentSection64 {
    let reader: MachOReader
    let sectionNumber: Int
    var sectionName : String    = ""
    var segmentName : String    = ""
    var addr : UInt64           = 0
    var size : UInt64           = 0
    var fileOffset : UInt32     = 0
    var align : UInt32          = 0     // log2 of alignment
    var relocOffset : UInt32    = 0
    var numberOfRelocs : UInt32 = 0
    var flags : UInt32          = 0
    var sectionType : SectionType = .S_REGULAR
    var attributes : SectionAttribute = SectionAttribute(rawValue: 0)
    var reserved1 : UInt32      = 0
    var reserved2 : UInt32      = 0
    var reserved3 : UInt32      = 0
    lazy var relocations: [Relocation]? = try? self.parseRelocations()


    // Lower 8 bits of flags field
    enum SectionType : UInt8 {
        case S_REGULAR                      = 0x0   /* regular section */
        case S_ZEROFILL                     = 0x1   /* zero fill on demand section */
        case S_CSTRING_LITERALS             = 0x2   /* section with only literal C strings*/
        case S_4BYTE_LITERALS               = 0x3   /* section with only 4 byte literals */
        case S_8BYTE_LITERALS               = 0x4   /* section with only 8 byte literals */
        case S_LITERAL_POINTERS             = 0x5   /* section with only pointers to literals */
        case S_NON_LAZY_SYMBOL_POINTERS     = 0x6   /* section with only non-lazy symbol pointers */
        case S_LAZY_SYMBOL_POINTERS         = 0x7   /* section with only lazy symbol pointers */
        case S_SYMBOL_STUBS                 = 0x8   /* section with only symbol stubs, byte size of stub in reserved2 field */
        case S_MOD_INIT_FUNC_POINTERS       = 0x9   /* section with only function pointers for initialization */
        case S_MOD_TERM_FUNC_POINTERS       = 0xa   /* section with only function pointers for termination */
        case S_COALESCED                    = 0xb   /* section contains symbols that are to be coalesced */
        case S_GB_ZEROFILL                  = 0xc   /* zero fill on demand section (that can be larger than 4GB) */
        case S_INTERPOSING                  = 0xd   /* section with only pairs of function pointers for interposing */
        case S_16BYTE_LITERALS              = 0xe   /* section with only 16 byte literals */
        case S_DTRACE_DOF                   = 0xf   /* section contains DTrace Object Format */
        case S_LAZY_DYLIB_SYMBOL_POINTERS   = 0x10  /* section with only lazy symbol pointers to lazy loaded dylibs */
        case S_THREAD_LOCAL_REGULAR         = 0x11  /* template of initial values for TLVs */
        case S_THREAD_LOCAL_ZEROFILL        = 0x12  /* template of initial values for TLVs */
        case S_THREAD_LOCAL_VARIABLES       = 0x13  /* TLV descriptors */
        case S_THREAD_LOCAL_VARIABLE_POINTERS       = 0x14  /* pointers to TLV descriptors */
        case S_THREAD_LOCAL_INIT_FUNCTION_POINTERS  = 0x15  /* functions to call to initialize TLV values */
    }

    struct SectionAttribute : OptionSetType, CustomStringConvertible {
        let rawValue: UInt32

        static let SECTION_ATTRIBUTES_USR       = SectionAttribute(rawValue: 0xff000000)
        static let S_ATTR_PURE_INSTRUCTIONS     = SectionAttribute(rawValue: 0x80000000)
        static let S_ATTR_NO_TOC                = SectionAttribute(rawValue: 0x40000000)
        static let S_ATTR_STRIP_STATIC_SYMS     = SectionAttribute(rawValue: 0x20000000)
        static let S_ATTR_NO_DEAD_STRIP         = SectionAttribute(rawValue: 0x10000000)
        static let S_ATTR_LIVE_SUPPORT          = SectionAttribute(rawValue: 0x08000000)
        static let S_ATTR_SELF_MODIFYING_CODE   = SectionAttribute(rawValue: 0x04000000)
        static let S_ATTR_DEBUG                 = SectionAttribute(rawValue: 0x02000000)
        static let SECTION_ATTRIBUTES_SYS       = SectionAttribute(rawValue: 0x00ffff00)
        static let S_ATTR_SOME_INSTRUCTIONS     = SectionAttribute(rawValue: 0x00000400)
        static let S_ATTR_EXT_RELOC             = SectionAttribute(rawValue: 0x00000200)
        static let S_ATTR_LOC_RELOC             = SectionAttribute(rawValue: 0x00000100)

        var description: String { return String(format: "%08X", self.rawValue) }
    }


    enum RelocationType: UInt8 {
        case X86_64_RELOC_UNSIGNED      = 0 // for absolute addresses
        case X86_64_RELOC_SIGNED        = 1 // for signed 32-bit displacement
        case X86_64_RELOC_BRANCH        = 2 // a CALL/JMP instruction with 32-bit displacement
        case X86_64_RELOC_GOT_LOAD      = 3 // a MOVQ load of a GOT entry
        case X86_64_RELOC_GOT           = 4 // other GOT references
        case X86_64_RELOC_SUBTRACTOR    = 5 // must be followed by a X86_64_RELOC_UNSIGNED
        case X86_64_RELOC_SIGNED_1      = 6 // for signed 32-bit displacement with a -1 addend
        case X86_64_RELOC_SIGNED_2      = 7 // for signed 32-bit displacement with a -2 addend
        case X86_64_RELOC_SIGNED_4      = 8 // for signed 32-bit displacement with a -4 addend
        case X86_64_RELOC_TLV           = 9 // for thread local variables
    }


    struct Relocation {
        let address: UInt32
        let symbolNum: UInt32
        let PCRelative: Bool
        let length: UInt8
        let extern: Bool
        let type: RelocationType

        var description: String {
            return String(format: "addr: %08X num: %d PCRel: %d len: %d extern: %d type: \(type)",
                address, symbolNum, PCRelative, length, extern)
        }


        init?(address: UInt32, data: UInt32) {
            let SYMBOL_MASK: UInt32 = 0x00FFFFFF
            let PCREL_MASK: UInt32  = 0x01000000
            let LENGTH_MASK: UInt32 = 0x06000000
            let EXTERN_MASK: UInt32 = 0x08000000
            let TYPE_MASK: UInt32   = 0xF0000000

            self.address = address
            self.symbolNum = UInt32(data & SYMBOL_MASK)
            self.PCRelative = (data & PCREL_MASK) == PCREL_MASK
            self.length = UInt8((data & LENGTH_MASK) >> 25)
            self.extern = (data & EXTERN_MASK) == EXTERN_MASK

            guard let type = RelocationType(rawValue: UInt8((data & TYPE_MASK) >> 28)) else {
                return nil
            }
            self.type = type
        }
    }


    init?(reader: MachOReader, buffer: MemoryBufferReader, sectionNumber: Int) {
        self.reader = reader
        self.sectionNumber = sectionNumber
        do {
            func parseFlags(value: UInt32) throws -> (SectionType, SectionAttribute) {
                guard let sType = SectionType(rawValue: UInt8(value & 0xFF)) else {
                    throw MachOReader.ReadError.InvalidData(reason: "Bad section flags")
                }
                let sAttr = SectionAttribute(rawValue: UInt32(value & 0xFFFFFF00))

                return (sType, sAttr)
            }

            sectionName = try buffer.readASCIIZString(maxSize: 16)
            segmentName = try buffer.readASCIIZString(maxSize: 16)
            addr = try buffer.read()
            size = try buffer.read()
            fileOffset = try buffer.read()
            align = try buffer.read()
            relocOffset = try buffer.read()
            numberOfRelocs = try buffer.read()
            flags = try buffer.read()
            (sectionType, attributes) = try parseFlags(flags)
            reserved1 = try buffer.read()
            reserved2 = try buffer.read()
            reserved3 = try buffer.read()
            do {
                try self.parseRelocations()
            } catch {
            }
        } catch MachOReader.ReadError.InvalidData(let reason) {
            print("Error reading from buffer: \(reason)")
            return nil
        } catch {
            print("Non InvalidData error")
            return nil
        }
    }


    func parseRelocations() throws -> [Relocation] {
        var result: [Relocation] = []

        if numberOfRelocs == 0 {
            return result
        }

        guard let relocBuffer = MemoryBufferReader(reader, offset: Int(relocOffset), size: Int(numberOfRelocs) * 8) else {
            throw MachOReader.ReadError.InvalidOffset
        }

        result.reserveCapacity(Int(numberOfRelocs))
        for _ in 0..<Int(numberOfRelocs) {
            let addr: UInt32 = try relocBuffer.read()
            let data: UInt32 = try relocBuffer.read()
            guard let reloc = Relocation(address: addr, data: data) else {
                throw MachOReader.ReadError.InvalidData(reason: "Bad relocation info")
            }
            result.append(reloc)
        }

        return result
    }


    func symbolName(idx: Int) -> String {
        return reader.symbolTable.symbols[idx].name
    }


    var description: String {
        return String(format: "%@: %02d %@ addr: %016X size: %016X fileOffset: %08X type: \(sectionType) align: %02X relocs: %d/%08X attr: \(attributes)",
            segmentName, sectionNumber, sectionName, addr, size, fileOffset, align, numberOfRelocs, relocOffset)
    }

    lazy var sectionData: NSData? = {
        return try? self.reader.dataBuffer(offset: Int(self.fileOffset), size: Int(self.size))
    }()
}
