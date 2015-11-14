//
//  LoadCommandSegment64.swift
//  static_linker
//
//  Created by Simon Evans on 07/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


class LoadCommandSegment64 : LoadCommand {
    var segname : String      = ""
    var vmaddr : UInt64       = 0
    var vmsize : UInt64       = 0
    var fileOffset : UInt64   = 0
    var fileSize : UInt64     = 0
    var maxProtection         = VMProtection.VM_PROT_NONE
    var initialProtection     = VMProtection.VM_PROT_NONE
    var numSections : UInt32  = 0
    var flags : UInt32        = 0
    var sections : [LoadCommandSegmentSection64] = []


    struct VMProtection : OptionSetType, CustomStringConvertible {
        let rawValue : UInt32

        static let VM_PROT_NONE         = VMProtection(rawValue: 0x00)
        static let VM_PROT_READ         = VMProtection(rawValue: 0x01)
        static let VM_PROT_WRITE        = VMProtection(rawValue: 0x02)
        static let VM_PROT_EXECUTE      = VMProtection(rawValue: 0x04)
        static let VM_PROT_NO_CHANGE    = VMProtection(rawValue: 0x08)
        static let VM_PROT_COPY         = VMProtection(rawValue: 0x10)
        static let VM_PROT_IS_MASK      = VMProtection(rawValue: 0x40)

        static let VM_PROT_DEFAULT = [VM_PROT_READ, VM_PROT_WRITE]
        static let VM_PROT_ALL = [VM_PROT_READ, VM_PROT_WRITE, VM_PROT_EXECUTE]
        private static let VALID_FIELDS = [VM_PROT_NONE, VM_PROT_READ, VM_PROT_WRITE, VM_PROT_EXECUTE,
                                           VM_PROT_NO_CHANGE, VM_PROT_COPY, VM_PROT_IS_MASK]

        var description: String { return String(rawValue, radix: 16) }
    }


    struct SegmentFlags : OptionSetType, CustomStringConvertible {
        let rawValue : UInt32

        static let SG_HIGHVM    = SegmentFlags(rawValue: 0x1)
        static let SG_FVMLIB    = SegmentFlags(rawValue: 0x2)
        static let SG_NORELOC   = SegmentFlags(rawValue: 0x4)
        static let SG_PROTECTED_VERSION_1 = SegmentFlags(rawValue: 0x8)

        var description: String { return String(rawValue, radix: 16) }
    }


    init?(_ header: LoadCommandHdr, _ reader: MachOReader) {
        super.init(header: header, reader: reader)

        do {
            guard let buffer = MemoryBufferReader(reader, offset: header.cmdOffset + 8, size: Int(header.cmdSize)-8) else {
                return nil
            }
            segname = try buffer.readASCIIZString(maxSize: 16)
            vmaddr = try buffer.read()
            vmsize = try buffer.read()
            fileOffset = try buffer.read()
            fileSize = try buffer.read()
            maxProtection = try VMProtection(rawValue: buffer.read())
            initialProtection = try VMProtection(rawValue: buffer.read())
            numSections = try buffer.read()
            flags = try buffer.read()

            sections.reserveCapacity(Int(numSections))
            if (numSections > 0) {
                for _ in 0...Int(numSections)-1 {
                    if let section = LoadCommandSegmentSection64(buffer) {
                        sections.append(section)

                    } else {
                        print("Error processing section")
                        return nil
                    }
                }
            }
        } catch {
            print("Error processing segment")
            return nil
        }
    }


    override var description: String {
        var str = String(format: "LoadCommandSegment64: %@", segname)
        str += String(format: " addr: %016X", vmaddr)
        str += String(format: " vmsize: %016X", vmsize)
        str += String(format: " offset: %016X", fileOffset)
        str += String(format: " size: %016X sections: %d ", fileSize, numSections)
        str += "maxProt: \(maxProtection.description) initialProt: \(initialProtection.description) flags: \(flags)"
        if sections.count > 0 {
            str += "\nsections:\n"
            for section in sections {
                str += section.description + "\n"
            }
        }

        return str
    }
}


class LoadCommandSegmentSection64 {
    var sectionName : String    = ""
    var segmentName : String    = ""
    var addr : UInt64           = 0
    var size : UInt64           = 0
    var fileOffset : UInt32     = 0
    var align : UInt32          = 0
    var relocOffset : UInt32    = 0
    var numberOfRelocs : UInt32 = 0
    var flags : UInt32          = 0
    var sectionType : SectionType = .S_REGULAR
    var attributes : SectionAttribute = SectionAttribute(rawValue: 0)
    var reserved1 : UInt32      = 0
    var reserved2 : UInt32      = 0
    var reserved3 : UInt32      = 0


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


    init?(_ reader: MemoryBufferReader) {
        do {
            func parseFlags(value: UInt32) throws -> (SectionType, SectionAttribute) {
                guard let sType = SectionType(rawValue: UInt8(value & 0xFF)) else {
                    print("Bad section flags")
                    throw MachOReader.ReadError.InvalidData
                }
                let sAttr = SectionAttribute(rawValue: UInt32(value >> 8))

                return (sType, sAttr)
            }

            sectionName = try reader.readASCIIZString(maxSize: 16)
            segmentName = try reader.readASCIIZString(maxSize: 16)
            addr = try reader.read()
            size = try reader.read()
            fileOffset = try reader.read()
            align = try reader.read()
            relocOffset = try reader.read()
            numberOfRelocs = try reader.read()
            flags = try reader.read()
            (sectionType, attributes) = try parseFlags(flags)
            reserved1 = try reader.read()
            reserved2 = try reader.read()
            reserved3 = try reader.read()
        } catch {
            print("Error reading from buffer")
            return nil
        }
    }


    var description: String {
        return String(format: "%@: %@ addr: %016X size: %016X fileOffset: %08X type: \(sectionType)",
            segmentName, sectionName, addr, size, fileOffset)
    }
}
