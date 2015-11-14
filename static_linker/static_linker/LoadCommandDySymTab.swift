//
//  LoadCommandDySymTab.swift
//  static_linker
//
//  Created by Simon Evans on 11/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


class LoadCommandDySymTab : LoadCommand {
    var idxLocalSym: UInt32      = 0
    var numLocalSym: UInt32      = 0
    var idxExtDefSym: UInt32     = 0
    var numExtDefSym: UInt32     = 0
    var idxUndefSym: UInt32      = 0
    var numUndefSym: UInt32      = 0
    var TOCOff: UInt32           = 0
    var numModTabEntries: UInt32 = 0
    var extRefSymOff: UInt32     = 0
    var numExtRefSym: UInt32     = 0
    var indirectSymOff: UInt32   = 0
    var numIndirectSym: UInt32   = 0
    var extRelocOff: UInt32      = 0
    var numExtReloc: UInt32        = 0
    var localRelocOff: UInt32    = 0
    var numLocalReloc: UInt32    = 0


    init?(_ header: LoadCommandHdr, _ reader: MachOReader) {
        super.init(header: header, reader: reader)

        do {
            guard let buffer = MemoryBufferReader(reader, offset: header.cmdOffset + 8, size: Int(header.cmdSize)-8) else {
                return nil
            }
            idxLocalSym = try buffer.read()
            numLocalSym = try buffer.read()
            idxExtDefSym = try buffer.read()
            numExtDefSym = try buffer.read()
            idxUndefSym = try buffer.read()
            numUndefSym = try buffer.read()
            TOCOff = try buffer.read()
            numModTabEntries = try buffer.read()
            extRefSymOff = try buffer.read()
            numExtRefSym = try buffer.read()
            indirectSymOff = try buffer.read()
            numIndirectSym = try buffer.read()
            extRelocOff = try buffer.read()
            numExtReloc = try buffer.read()
            localRelocOff = try buffer.read()
            numLocalReloc = try buffer.read()

            let syms = buffer.subBuffer(buffer.offset + Int(idxExtDefSym), size: Int(numExtDefSym))
            //showSyms(syms)
        } catch {
            return nil
        }
    }


    func showSyms(syms: UnsafeBufferPointer<UInt8>) {
        var str = ""
        for idx in 0..<syms.count {
            let ch = CUnsignedChar(syms[idx])
            str += String(format: "%02X ", ch)
        }
        print(str)
    }


    override var description: String {
        var str = "localSym: \(idxLocalSym)/\(numLocalSym) extDefSym: \(idxExtDefSym)/\(numExtDefSym) "
        str += "undefSym: \(idxUndefSym)/\(numUndefSym) TOCoff: \(TOCOff) numEntries: \(numModTabEntries) "
        str += "extRefSym: \(extRefSymOff)/\(numExtRefSym) indirectSym: \(indirectSymOff)/\(numIndirectSym) "
        str += "extReloc: \(extRelocOff)/\(numExtReloc) localReloc: \(localRelocOff)/\(numLocalReloc)"
        return str
    }
}
