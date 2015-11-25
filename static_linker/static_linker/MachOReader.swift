//
//  MachOReader.swift
//  static_linker
//
//  Created by Simon Evans on 05/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


class MachOReader {
    var file: NSData!
    var header: MachOHeader!
    var loadCommands: [LoadCommand] = []
    var loadCommandSegments: [LoadCommandSegment64] = []
    var loadCommandSections: [LoadCommandSegmentSection64] = []
    var symbolTable: LoadCommandSymTab!
    var dySymbolTable: LoadCommandDySymTab?
    var dyldInfo: LoadCommandDyldInfo?
    var totalSections = 0


    enum MachOMagic: UInt32 {
        case MAGIC_LE    = 0xfeedface
        case MAGIC_BE    = 0xcefaedfe
        case MAGIC_64_LE = 0xfeedfacf
        case MAGIC_64_BE = 0xcffaedfe
    }

    enum CpuType: UInt32 {
        case ANY    = 0xffffffff
        case X86    = 7
        case X86_64 = 0x01000007
    }

    enum CpuSubType: UInt32 {
        case CPU_SUBTYPE_I386_ALL = 3
    }

    enum FileType: UInt32 {
        case OBJECT      = 0x1
        case EXECUTE     = 0x2
        case FVMLIB      = 0x3
        case CORE        = 0x4
        case PRELOAD     = 0x5
        case DYLIB       = 0x6
        case DYLINKER    = 0x7
        case BUNDLE      = 0x8
        case DYLIB_STUB  = 0x9
        case DYSM        = 0xa
        case KEXT_BUNDLE = 0xb
    }

    struct MHFlags : OptionSetType, CustomStringConvertible {
        let rawValue: UInt32

        static let MH_NOUNDEFS                  = MHFlags(rawValue:       0x1)
        static let MH_INCRLINK                  = MHFlags(rawValue:       0x2)
        static let MH_DYLDLINK                  = MHFlags(rawValue:       0x4)
        static let MH_BINDATLOAD                = MHFlags(rawValue:       0x8)
        static let MH_PREBOUND                  = MHFlags(rawValue:      0x10)
        static let MH_SPLIT_SEGS                = MHFlags(rawValue:      0x20)
        static let MH_LAZY_INIT                 = MHFlags(rawValue:      0x40)
        static let MH_TWOLEVEL                  = MHFlags(rawValue:      0x80)
        static let MH_FORCE_FLAT                = MHFlags(rawValue:     0x100)
        static let MH_NOMULTIDEFS               = MHFlags(rawValue:     0x200)
        static let MH_NOFIXPREBINDING           = MHFlags(rawValue:     0x400)
        static let MH_PREBINDABLE               = MHFlags(rawValue:     0x800)
        static let MH_ALLMODSBOUND              = MHFlags(rawValue:    0x1000)
        static let MH_SUBSECTIONS_VIA_SYMBOLS   = MHFlags(rawValue:    0x2000)
        static let MH_CANONICAL                 = MHFlags(rawValue:    0x4000)
        static let MH_WEAK_DEFINES              = MHFlags(rawValue:    0x8000)
        static let MH_BINDS_TO_WEAK             = MHFlags(rawValue:   0x10000)
        static let MH_ALLOW_STACK_EXECUTION     = MHFlags(rawValue:   0x20000)
        static let MH_ROOT_SAFE                 = MHFlags(rawValue:   0x40000)
        static let MH_SETUID_SAFE               = MHFlags(rawValue:   0x80000)
        static let MH_NO_REEXPORTED_DYLIBS      = MHFlags(rawValue:  0x100000)
        static let MH_PIE                       = MHFlags(rawValue:  0x200000)
        static let MH_DEAD_STRIPPABLE_DYLIB     = MHFlags(rawValue:  0x400000)
        static let MH_HAS_TLV_DESCRIPTORS       = MHFlags(rawValue:  0x800000)
        static let MH_NO_HEAP_EXECUTION         = MHFlags(rawValue: 0x1000000)
        static let MH_APP_EXTENSION_SAFE        = MHFlags(rawValue: 0x2000000)

        var description: String { return String(format: "%08X", self.rawValue) }
    }

    struct MachOHeader {
        let magic:      MachOMagic
        let cpuType:    CpuType
        let cpuSubType: CpuSubType
        let fileType:   FileType
        let ncmds:      UInt32
        let sizeOfCmds: UInt32
        let flags:      MHFlags
        let reserved:   UInt32

        // Sizeof doesnt work correctly when some elements are enum
        static func size() -> Int { return 8 * sizeof(UInt32) }

        func dump() {
            print("magic:\t\t\(self.magic)")
            print("cpuType:\t\(self.cpuType)")
            print("cpuSubType:\t\(self.cpuSubType)")
            print("fileType:\t\(self.fileType)")
            print("ncmds:\t\t\(self.ncmds)")
            print("sizeOfCmds:\t\(self.sizeOfCmds)")
            print("flags:\t\t\(self.flags)")
        }
    }

    enum ReadError : ErrorType {
        case InvalidHeader
        case InvalidOffset
        case InvalidData(reason: String)
    }


    init?(filename: String) {
        do {
            file = try NSData(contentsOfFile: filename, options: .DataReadingMapped)
            guard file.length > MachOHeader.size() else {
                print("Header is too short \(file.length) shoud be at least \(MachOHeader.size())")
                return nil
            }
            header = try readHeader()

            for cmd in 0..<header!.ncmds {
                if let lcHdr : LoadCommand.LoadCommandHdr = try getLoadCommand(cmd) {
                    if let loadCmd = LoadCommand(header: lcHdr, reader: self).parse() {
                        loadCommands.append(loadCmd)
                        switch loadCmd {
                        case is LoadCommandSegment64:
                            loadCommandSegments.append(loadCmd as! LoadCommandSegment64)

                        case is LoadCommandSymTab:
                            guard symbolTable == nil else {
                                print("2nd symbolTable found!")
                                return nil
                            }
                            symbolTable = loadCmd as! LoadCommandSymTab

                        case is LoadCommandDySymTab:
                            guard dySymbolTable == nil else {
                                print("2nd DySymbolTable found!")
                                return nil
                            }
                            dySymbolTable = loadCmd as? LoadCommandDySymTab

                        case is LoadCommandDyldInfo:
                            guard dyldInfo == nil else {
                                print("2nd Dyldinfo found!")
                                return nil
                            }
                            dyldInfo = loadCmd as? LoadCommandDyldInfo

                        default: break
                        }
                    } else {
                        return nil
                    }
                } else {
                    print("Cannot read load command header: \(cmd)")
                    return nil
                }
            }
        } catch {
            return nil
        }
    }


    func readHeader() throws -> MachOHeader {
        do {
            return MachOHeader(
                magic:      try readEnum(0),
                cpuType:    try readEnum(4),
                cpuSubType: try readEnum(8),
                fileType:   try readEnum(12),
                ncmds:      try readBytes(16),
                sizeOfCmds: try readBytes(20),
                flags:      try readEnum(24),
                reserved:   0)
        } catch {
            print("Bad magic")
            throw ReadError.InvalidHeader
        }
    }


    func readBytes<T>(offset: Int) throws -> T {
        //print("Reading \(sizeof(T)) bytes at offset \(offset)")
        guard offset >= 0 && (sizeof(T) + offset) < file.length else {
            print("Offset \(offset) is out of range for file")
            throw ReadError.InvalidOffset
        }
        return UnsafePointer<T>(file.bytes + offset).memory
    }


    func readArray<T>(offset: Int, count: Int) throws -> UnsafeBufferPointer<T> {
        //print("reading array of ", sizeof(T), "bytes for \(count) elements")
        guard count > 0 && offset > 0 else {
            throw ReadError.InvalidOffset
        }
        guard (sizeof(T) * count) + offset < file.length else {
            print("Offset \(offset) is out of range for file")
            throw ReadError.InvalidOffset
        }

        return UnsafeBufferPointer<T>(start: UnsafePointer<T>(file.bytes + offset), count: count)
    }


    func memoryReadBuffer<T>(offset: Int, size: Int) throws -> UnsafePointer<T> {
        guard size > 0 && offset > 0 && (offset + size) < file.length else {
            throw ReadError.InvalidOffset
        }

        return UnsafePointer<T>(file.bytes + offset)
    }


    func dataBuffer(offset offset: Int, size: Int) throws -> NSData {
        guard size > 0 && offset >= 0 && (offset + size) < file.length else {
            throw ReadError.InvalidOffset
        }

        return NSData(bytes: file.bytes + offset, length: size)
    }


    func readEnum<T : RawRepresentable>(offset: Int) throws -> T {
        if let result : T = try T(rawValue: readBytes(offset)) {
            return result
        }
        throw ReadError.InvalidData(reason: "Cant read ENUM")
    }


    func readASCIIZString(offset: Int, _ maxLength: Int) throws -> String? {
        guard (offset + maxLength) < file.length else {
            throw ReadError.InvalidOffset
        }
        let ptr = UnsafePointer<CChar>(file.bytes + offset)

        return String(CString: ptr, encoding: NSASCIIStringEncoding)
    }


    func getLoadCommand(index: UInt32) throws -> LoadCommand.LoadCommandHdr {
        if (index >= header.ncmds) {
            throw ReadError.InvalidOffset
        }
        var offset = MachOHeader.size()
        var hdr: LoadCommand.LoadCommandHdr?
        for _ in 0...index {
            hdr = LoadCommand.LoadCommandHdr(
                cmdOffset:  offset,
                cmd:     try readEnum(offset),
                cmdSize: try readBytes(offset + sizeof(UInt32))
            )
            offset += Int(hdr!.cmdSize)
        }

        return hdr!
    }
}


class MemoryBufferReader {
    var ptr: UnsafePointer<UInt8> = nil
    var buffer: UnsafeBufferPointer<UInt8> = UnsafeBufferPointer<UInt8>(start: nil, count: 0)
    var offset: Int = 0
    var bytesRemaining: Int { return (buffer.count - offset) }

    init?(_ reader: MachOReader, offset: Int, size: Int) {
        do {
            ptr = try reader.memoryReadBuffer(offset, size: size)
            buffer = UnsafeBufferPointer<UInt8>(start: ptr, count: size)
        } catch {
            return nil
        }
    }

    func subBuffer(offset: Int, size: Int) -> UnsafeBufferPointer<UInt8> {
        return UnsafeBufferPointer<UInt8>(start: ptr + offset, count: size)
    }


    func readASCIIZString(maxSize maxSize: Int) throws -> String {
        guard maxSize > 0 else {
            throw MachOReader.ReadError.InvalidOffset
        }

        guard bytesRemaining > 0 else {
            throw MachOReader.ReadError.InvalidOffset
        }

        guard bytesRemaining >= maxSize else {
            throw MachOReader.ReadError.InvalidOffset
        }

        var newString : [CChar] = []
        newString.reserveCapacity(maxSize + 1)
        for _ in 0...maxSize-1 {
            newString.append(CChar(buffer[offset++]))
        }
        newString.append(0) // Terminating nul
        if let result = String(CString: newString, encoding: NSASCIIStringEncoding) {
            return result
        } else {
            throw MachOReader.ReadError.InvalidData(reason: "Invalid string")
        }
    }


    // read from the current offset until the first nul byte is found
    func scanASCIIZString() throws -> String {
        var str : [CChar] = []
        var ch : CChar
        repeat {
            ch = try read()
            str.append(ch)
        }
        while ch != 0
        if let result = String(CString: str, encoding: NSASCIIStringEncoding) {
            return result
        } else {
            throw MachOReader.ReadError.InvalidData(reason: "Invalid string")
        }
    }


    func read<T>() throws -> T {
        guard bytesRemaining > 0 else {
            throw MachOReader.ReadError.InvalidOffset
        }

        guard bytesRemaining >= sizeof(T) else {
            throw MachOReader.ReadError.InvalidOffset
        }
        let resultPtr : UnsafePointer<T> = UnsafePointer(ptr + offset)
        let result = resultPtr.memory
        offset += sizeof(T)

        return result
    }
}
