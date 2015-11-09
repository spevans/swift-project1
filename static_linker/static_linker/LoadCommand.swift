//
//  LoadCommand.swift
//  static_linker
//
//  Created by Simon Evans on 05/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


class LoadCommand {

    var description: String { return "LoadCommand" }
    let header : LoadCommandHdr
    let reader : MachOReader

    enum LoadCommandID : UInt32 {
        static let LC_REQ_DYLD : UInt32 = 0x80000000

        func isRequiredCommand() -> Bool {
            return ((self.rawValue & LoadCommandID.LC_REQ_DYLD) != 0)
        }

        case SEGMENT                    = 0x1
        case SYMTAB                     = 0x2
        case SYMSEG                     = 0x3
        case THREAD                     = 0x4
        case UNIXTHREAD                 = 0x5
        case LOADFVMLIB                 = 0x6
        case IDFVMLIB                   = 0x7
        case IDENT                      = 0x8
        case FVMFILE                    = 0x9
        case PREPAGE                    = 0xa
        case DYSYMTAB                   = 0xb
        case LOAD_DYLIB                 = 0xc
        case ID_DYLIB                   = 0xd
        case LOAD_DYLINKER              = 0xe
        case ID_DYLINKER                = 0xf
        case PREBOUND_DYLIB             = 0x10
        case ROUTINES                   = 0x11
        case SUB_FRAMEWORK              = 0x12
        case SUB_UMBRELLA               = 0x13
        case SUB_CLIENT                 = 0x14
        case SUB_LIBRARY                = 0x15
        case TWOLEVEL_HINTS             = 0x16
        case PREBIND_CKSUM              = 0x17
        case LOAD_WEAK_DYLIB            = 0x80000018
        case SEGMENT_64                 = 0x19
        case ROUTINES_64                = 0x1a
        case UUID                       = 0x1b
        case RPATH                      = 0x8000001c
        case CODE_SIGNATURE             = 0x1d
        case SEGMENT_SPLIT_INFO         = 0x1e
        case REEXPORT_DYLIB             = 0x8000001f
        case LAZY_LOAD_DYLIB            = 0x20
        case ENCRYPTION_INFO            = 0x21
        case DYLD_INFO                  = 0x22
        case DYLD_INFO_ONLY             = 0x80000022
        case LOAD_UPWARD_DYLIB          = 0x80000023
        case VERSION_MIN_MACOSX         = 0x24
        case VERSION_MIN_IPHONEOS       = 0x25
        case FUNCTION_STARTS            = 0x26
        case DYLD_ENVIRONMENT           = 0x27
        case MAIN                       = 0x80000028
        case DATA_IN_CODE               = 0x29
        case SOURCE_VERSION             = 0x2A
        case DYLIB_CODE_SIGN_DRS        = 0x2B
        case ENCRYPTION_INFO_64         = 0x2C
        case LINKER_OPTION              = 0x2D
        case LINKER_OPTIMIZATION_HINT   = 0x2E
    }

    struct LoadCommandHdr {
        let cmdOffset:  Int
        let cmd:     LoadCommandID
        let cmdSize: UInt32
    }

    enum LoadCommandError : ErrorType {
        case UnsupportedCommand
    }


    init(header: LoadCommandHdr, reader: MachOReader) {
        self.header = header
        self.reader = reader
    }


    func parse() -> LoadCommand? {
        switch(header.cmd) {
        case .SEGMENT_64:           return LoadCommandSegment64(header, reader)
        case .ID_DYLIB:             return LoadCommandIdDylib(header, reader)
        //case .DYLD_INFO_ONLY:
        case .SYMTAB:               return LoadCommandSymTab(header, reader)
        //case .DYSYMTAB:
        case .UUID:                 return LoadCommandUUID(header, reader)
        case .VERSION_MIN_MACOSX:   return LoadCommandMinVersion(header, reader)
        case .SOURCE_VERSION:       return LoadCommandSourceVersion(header, reader)
        case .LOAD_DYLIB:           return LoadCommandLoadDylib(header, reader)
        //case .FUNCTION_STARTS:
        //case .DATA_IN_CODE:
        //case .CODE_SIGNATURE:

        default: return nil
        }
    }
}


class LoadCommandUUID : LoadCommand {
    final var uuid : String!


    init?(_ header: LoadCommandHdr, _ reader: MachOReader) {
        super.init(header: header, reader: reader)

        do {
            let offset = header.cmdOffset + 8
            let buffer : UnsafeBufferPointer<UInt8> = try reader.readArray(offset, count: 16)
            var str = String(format: "%02X%02X%02X%02X-", buffer[0], buffer[1], buffer[2], buffer[3])
            str += String(format: "%02X%02X-%02X%02X-", buffer[4], buffer[5], buffer[6], buffer[7])
            str += String(format: "%02X%02X%02X%02X%02X%02X%02X%02X", buffer[8], buffer[9], buffer[10],
                buffer[11], buffer[12], buffer[13], buffer[14], buffer[15])
            uuid = str
        } catch {
            return nil
        }
    }


    override var description: String {
        return "LoadCommandUUID: uuid = " + uuid
    }
}


class LoadCommandMinVersion : LoadCommand {
    final var version : String!
    final var sdk : String!


    init?(_ header: LoadCommandHdr, _ reader: MachOReader) {
        super.init(header: header, reader: reader)

        func readVersion(offset: Int) -> String {
            if let buffer : UInt32 = try? reader.readBytes(offset) {
                return String(format: "%d.%d.%d",
                    UInt16(truncatingBitPattern: buffer >> 16),
                    UInt8(truncatingBitPattern: buffer >> 8),
                    UInt8(truncatingBitPattern: buffer))
            } else {
                return ""
            }
        }

        version = readVersion(header.cmdOffset + 8)
        sdk = readVersion(header.cmdOffset + 12)
    }


    override var description: String {
        return "LoadCommandMinVersion version: \(version) sdk: \(sdk)"
    }
}


class LoadCommandSourceVersion : LoadCommand {
    final var version : String!


    init?(_ header: LoadCommandHdr, _ reader: MachOReader) {
        super.init(header: header, reader: reader)

        if let buffer : UInt64 = try? reader.readBytes(header.cmdOffset + 8) {
            version = String(format: "%d.%d.%d.%d.%d",
                UInt32(truncatingBitPattern: buffer >> 40) & 0xffffff,
                UInt16(truncatingBitPattern: buffer >> 30) & 0x3ff,
                UInt16(truncatingBitPattern: buffer >> 20) & 0x3ff,
                UInt16(truncatingBitPattern: buffer >> 10) & 0x3ff,
                UInt16(truncatingBitPattern: buffer >> 00) & 0x3ff)
        } else {
            return nil
        }
    }


    override var description: String {
        return "LoadCommandSourceVersion version: \(version)"
    }
}


class LoadCommandIdDylib : LoadCommand {
    final var dylib : String!
    final var timestamp : NSDate!
    final var currentVersion : UInt32!
    final var compatibilityVersion : UInt32!


    init?(_ header: LoadCommandHdr, _ reader: MachOReader) {
        super.init(header: header, reader: reader)

        do {
            let buffer : UnsafeBufferPointer<UInt32> = try reader.readArray(header.cmdOffset + 8, count: 4)
            let strOffset = Int(buffer[0])
            dylib = try reader.readASCIIZString(header.cmdOffset + Int(strOffset),
                                                header.cmdOffset + Int(header.cmdSize))!
            timestamp = NSDate(timeIntervalSince1970: Double(buffer[1]))
            currentVersion = buffer[2]
            compatibilityVersion = buffer[3]
        } catch {
            return nil
        }
    }


    override var description: String {
        var str = "LoadCommandIdDylib lib: \(dylib), timestamp: \(timestamp) "
        str += "version: \(currentVersion) compat: \(compatibilityVersion)"

        return str
    }
}


class LoadCommandLoadDylib : LoadCommandIdDylib {
    override var description: String {
        var str = "LoadCommandLoadDylib lib: \(dylib), timestamp: \(timestamp) "
        str += "version: \(currentVersion) compat: \(compatibilityVersion)"

        return str
    }
}
