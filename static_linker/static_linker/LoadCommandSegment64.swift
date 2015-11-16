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
                for idx in 0..<Int(numSections) {
                    if let section = LoadCommandSegmentSection64(reader:reader, buffer:buffer, sectionNumber:idx+1) {
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
