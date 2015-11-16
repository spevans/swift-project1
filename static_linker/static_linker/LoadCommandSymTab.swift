//
//  LoadCommandSymTab.swift
//  static_linker
//
//  Created by Simon Evans on 06/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


class LoadCommandSymTab : LoadCommand {
    var symbols : [Symbol] = []

    // File format of a symbol
    private struct nlist64 {
        var strIdx  : UInt32
        var type    : UInt8
        var section : UInt8
        var desc    : UInt16
        var value   : UInt64
    }

    // type field in the file format is a UInt8 packed 3:1:3:1 N_STAB:N_PEXT:N_TYPE:N_EXT
    enum SymbolType : UInt8 {
        case UNDF   = 0x0       /* undefined, n_sect == NO_SECT */
        case ABS    = 0x2       /* absolute, n_sect == NO_SECT */
        case SECT   = 0xe       /* defined in section number n_sect */
        case PBUD   = 0xc       /* prebound undefined (defined in a dylib) */
        case INDR   = 0xa       /* indirect */

        init?(type: UInt8) {
            let TYPE_MASK : UInt8 = 0xe
            self.init(rawValue: UInt8(type & TYPE_MASK))
        }
    }

    struct Symbol {
        let name : String
        // Next 3 fields expanded from type in file format
        let type                : SymbolType
        let privateExternalBit  : Bool
        let externalBit         : Bool
        let sectionNumber       : UInt8
        let value               : UInt64  // Value or stab offset

        var description : String {
            return "Type: \(type) Section: \(sectionNumber) Value: \(value) : \(name)"
        }


        init?(name: String, type: UInt8, section: UInt8, value: UInt64) {
            let PRIVATE_EXTERNAL_BIT_MASK : UInt8 = 0x10
            let EXTERNAL_BIT_MASK : UInt8 = 0x1

            guard let stype = SymbolType(type: type) else {
                return nil
            }
            self.type = stype
            self.name = name
            self.privateExternalBit = (type & PRIVATE_EXTERNAL_BIT_MASK) == PRIVATE_EXTERNAL_BIT_MASK
            self.externalBit = (type & EXTERNAL_BIT_MASK) == EXTERNAL_BIT_MASK
            self.sectionNumber = section
            self.value = value
        }
    }


    init?(_ header: LoadCommandHdr, _ reader: MachOReader) {
        super.init(header: header, reader: reader)

        do {
            let buffer : UnsafeBufferPointer<UInt32> = try reader.readArray(header.cmdOffset + 8, count: 4)
            let symOffset = Int(buffer[0])
            let numberSyms = Int(buffer[1])
            let strOffset = Int(buffer[2])
            let strSize = Int(buffer[3])
            let symbolBuffer : UnsafeBufferPointer<nlist64> = try reader.readArray(symOffset, count: numberSyms)

            symbols.reserveCapacity(numberSyms)
            if numberSyms > 1 {
                for idx in 0...numberSyms-1 {
                    let symbol = symbolBuffer[Int(idx)]
                    let sym = Symbol(
                        name: try reader.readASCIIZString(strOffset + Int(symbol.strIdx), strSize - strOffset)!,
                        type: symbol.type,
                        section: symbol.section,
                        value: symbol.value
                    )
                    if (sym == nil) {
                        return nil
                    }
                    symbols.append(sym!)
                }
            }
        } catch {
            return nil
        }
    }

/***
    func symbolsInSection(section: Int) -> [Symbol] {
        var result: [Symbol] = []
        for symbol in symbols {
            if Int(symbol.sectionNumber) == section {
                result.append(symbol)
            }
        }

        return result
    }
***/

    override var description: String {
        return "LoadCommandSymTab symbol count: \(symbols.count)"
    }
}
