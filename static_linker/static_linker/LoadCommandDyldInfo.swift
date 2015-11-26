//
//  LoadCommandDyldInfo.swift
//  static_linker
//
//  Created by Simon Evans on 10/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


class LoadCommandDyldInfo: LoadCommand {
    var rebaseOffset: UInt32   = 0
    var rebaseSize: UInt32     = 0
    var bindOffset: UInt32     = 0
    var bindSize: UInt32       = 0
    var weakBindOffset: UInt32 = 0
    var weakBindSize: UInt32   = 0
    var lazyBindOffset: UInt32 = 0
    var lazyBindSize: UInt32   = 0
    var exportOffset: UInt32   = 0
    var exportSize: UInt32     = 0
    var opcodeCounter = 0

    override var description: String {
        var str =  String(format: "LoadCommandDyldInfo: rebase: %08X/%08X  bind: %08X/%08X  weakBind: %08X/%08X",
            rebaseOffset, rebaseSize, bindOffset, bindSize, weakBindOffset, weakBindSize)
        str += String(format: " lazyBind: %08X/%08X export: %08X/%08X",
            lazyBindOffset, lazyBindSize, exportOffset, exportSize)

        return str
    }

    typealias rebaseCallback = (RebaseOpcode, UInt8, UInt64?, UInt64?, Int) throws -> ()
    typealias bindCallback = (BindOpcode, UInt8, UInt64?, UInt64?, Int64?, String, Int) throws -> ()


    init?(_ header: LoadCommandHdr, _ reader: MachOReader) {
        super.init(header: header, reader: reader)

        do {
            guard let buffer = MemoryBufferReader(reader, offset: header.cmdOffset + 8, size: Int(header.cmdSize)-8) else {
                return nil
            }
            // FIXME: validate the offsets and size
            rebaseOffset = try buffer.read()
            rebaseSize = try buffer.read()
            bindOffset = try buffer.read()
            bindSize = try buffer.read()
            weakBindOffset = try buffer.read()
            weakBindSize = try buffer.read()
            lazyBindOffset = try buffer.read()
            lazyBindSize = try buffer.read()
            exportOffset = try buffer.read()
            exportSize = try buffer.read()

            try showRebaseOpcodes()
            try showBindOpcodes()
        } catch {
            return nil
        }
    }


    func decodeRebaseOp(instr: UInt8) throws -> (RebaseOpcode, UInt8) {
        if let opcode = RebaseOpcode(rawValue: (instr & RebaseOpcode.OPCODE_MASK)) {
            let immValue = instr & RebaseOpcode.IMMEDIATE_MASK
            return (opcode, immValue)
        } else {
            throw MachOReader.ReadError.InvalidData(reason: "Cant read Rebase Opcode")
        }
    }


    func decodeBindOp(instr: UInt8) throws -> (BindOpcode, UInt8) {
        if let opcode = BindOpcode(rawValue: (instr & BindOpcode.OPCODE_MASK)) {
            let immValue = instr & BindOpcode.IMMEDIATE_MASK
            return (opcode, immValue)
        } else {
            throw MachOReader.ReadError.InvalidData(reason: "Invalid Bind Opcode")
        }
    }


    func showRebaseOpcodes() throws {
        let pointerSize: UInt64 = 8


        func rebaseCallback(opcode opcode: RebaseOpcode, immValue: UInt8, val1: UInt64?, val2: UInt64?,
            opcodeAddr: Int) throws {

            print(String(format: "0x%04X \(opcode)", opcodeAddr), terminator:"")
            switch opcode {
            case .REBASE_OPCODE_DONE:
                print("\(opcode)()")

            case .REBASE_OPCODE_SET_TYPE_IMM:
                let rebaseType = RebaseType(rawValue: immValue)!
                print("\(opcode)(\(rebaseType.rawValue))")

            case .REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                print(String(format: "(%d, 0x%08X)", Int(immValue), val1!))

            case .REBASE_OPCODE_ADD_ADDR_ULEB:
                print(String(format: "(0x%02X)", val1!))

            case .REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
                let val = UInt64(immValue) * pointerSize
                print(String(format: "(0x%X)", val))

            case .REBASE_OPCODE_DO_REBASE_IMM_TIMES:
                print("(\(immValue))")

            case .REBASE_OPCODE_DO_REBASE_ULEB_TIMES:
                print("(\(val1!))")

            case .REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB:
                let advanceAmt = val1! + pointerSize
                print("(\(advanceAmt))")

            case .REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB:
                print("(\(val1!),\(val2!))")
            }
        }

        try runRebase(rebaseCallback)
    }


    func showBindOpcodes() throws {
        let pointerSize: UInt64 = 8
        var section = ""

        func bindCallback(opcode opcode: BindOpcode, immValue: UInt8, uval1: UInt64?, uval2: UInt64?, sval: Int64?,
            symbol:String, opcodeAddr: Int) throws {

                print(String(format: "\(section) 0x%04X \(opcode)", opcodeAddr), terminator:"")
                switch opcode {
                case .BIND_OPCODE_DONE:
                    print("")

                case .BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
                    print("(\(immValue))")

                case .BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
                    print("(\(uval1!))")

                case .BIND_OPCODE_SET_DYLIB_SPECIAL_IMM:
                    var ordinal: Int8 = 0
                    if immValue != 0 {
                        let signExtend = Int8(BindOpcode.OPCODE_MASK | immValue)
                        ordinal = Int8(signExtend)
                    }
                    print("(\(ordinal))")

                case .BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM:
                    print(String(format: "(0x%02X, %@)", immValue, symbol))

                case .BIND_OPCODE_SET_TYPE_IMM:
                    let bindType = BindType(rawValue: immValue)!
                    print("(\(bindType.rawValue))")

                case .BIND_OPCODE_SET_ADDEND_SLEB:
                    print("(\(sval!))")

                case .BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                    print(String(format: "(0x%02X, 0x%08X)", immValue, uval1!))

                case .BIND_OPCODE_ADD_ADDR_ULEB:
                    print(String(format: "(0x%08X)", uval1!))

                case .BIND_OPCODE_DO_BIND:
                    print("()")

                case .BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB:
                    print(String(format: "(0x%08X)", uval1!))

                case .BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
                    let val = UInt64(immValue) * pointerSize
                    print(String(format: "(0x%08X)", val + pointerSize))

                case .BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB:
                    print(String(format: "(%d, 0x%08X)", uval1!, uval2!))
                }
        }

        section = "bind"
        try runBindSection("bind", callback: bindCallback)
        section = "weak"
        try runBindSection("weak", callback: bindCallback)
        section = "lazy"
        try runBindSection("lazy", callback: bindCallback)
    }


    func runRebase(callback: rebaseCallback) throws {
        let rebase = MemoryBufferReader(reader, offset: Int(rebaseOffset), size: Int(rebaseSize))
        try rebaseInfo(rebase!, callback: callback)
    }


    private func rebaseInfo(r: MemoryBufferReader, callback: rebaseCallback) throws {
        let startOffset = r.offset

        repeat {
            let opcodeAddr = r.offset - startOffset
            let (opcode, immValue) = try decodeRebaseOp(r.read())
            var val1: UInt64? = nil
            var val2: UInt64? = nil

            switch (opcode) {
            case .REBASE_OPCODE_DONE:
                break

            case .REBASE_OPCODE_SET_TYPE_IMM:
                if RebaseType(rawValue: immValue) == nil {
                    throw MachOReader.ReadError.InvalidData(reason: "Invalid RebaseType")
                }

            case .REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                val1 = try r.readULEB128()

            case .REBASE_OPCODE_ADD_ADDR_ULEB:
                val1 = try r.readULEB128()

            case .REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
                break

            case .REBASE_OPCODE_DO_REBASE_IMM_TIMES:
                break

            case .REBASE_OPCODE_DO_REBASE_ULEB_TIMES:
                val1 = try r.readULEB128()

            case .REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB:
                val1 = try r.readULEB128()

            case .REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB:
                val1 = try r.readULEB128()
                val2 = try r.readULEB128()
            }
            try callback(opcode, immValue, val1, val2, opcodeAddr)

            if opcode == .REBASE_OPCODE_DONE {
                return
            }
        } while true
    }


    func runBindSection(section: String, callback: bindCallback) throws {
        switch(section) {
        case "bind":
            let bind = MemoryBufferReader(reader, offset: Int(bindOffset), size: Int(rebaseSize))
            try bindInfo(bind!, isLazy: false, callback: callback)

        case "lazy":
            let lazyBind = MemoryBufferReader(reader, offset: Int(lazyBindOffset), size: Int(lazyBindSize))
            try bindInfo(lazyBind!, isLazy: true, callback: callback)

        case "weak":
            let weakBind = MemoryBufferReader(reader, offset: Int(weakBindOffset), size: Int(weakBindSize))
            try bindInfo(weakBind!, isLazy: false, callback: callback)

        default:
            print("Bad section '\(section)'")
        }
    }


    private func bindInfo(r: MemoryBufferReader, isLazy: Bool, callback: bindCallback) throws {

        var done = false
        var symbolName = ""
        let startOffset = r.offset

        while !done {
            let opcodeAddr = r.offset - startOffset
            let (opcode, immValue) = try decodeBindOp(r.read())
            var uval1: UInt64? = nil
            var uval2: UInt64? = nil
            var sval: Int64? = nil

            switch (opcode) {
            case .BIND_OPCODE_DONE:
                if (isLazy) {
                    // DONE opcodes appear between instruction so check end of data stream
                    if r.bytesRemaining > 0 {
                        break
                    }
                }
                done = true

            case .BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
                break

            case .BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
                uval1 = try r.readULEB128()

            case .BIND_OPCODE_SET_DYLIB_SPECIAL_IMM:
                break

            case .BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM:
                symbolName = try r.scanASCIIZString()
                // FIXME:
                // if (ImmValue & MachO::BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION)
                //  return

            case .BIND_OPCODE_SET_TYPE_IMM:
                if BindType(rawValue: immValue) == nil {
                    throw MachOReader.ReadError.InvalidData(reason: "Invalud BindType")
                }

            case .BIND_OPCODE_SET_ADDEND_SLEB:
                if (isLazy) {
                    throw MachOReader.ReadError.InvalidData(reason: "SET_ADDEND_SLEB found in lazy bind")
                }
                sval = try r.readSLEB128()

            case .BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                uval1 = try r.readULEB128()

            case .BIND_OPCODE_ADD_ADDR_ULEB:
                uval1 = try r.readULEB128()

            case .BIND_OPCODE_DO_BIND:
                break

            case .BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB:
                if (isLazy) {
                    throw MachOReader.ReadError.InvalidData(reason: "DO_BIND_ADD_ADDR_ULEB found in lazy bind")
                }
                uval1 = try r.readULEB128()

            case .BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
                if (isLazy) {
                    throw MachOReader.ReadError.InvalidData(reason: "DO_BIND_ADD_ADDR_IMM_SCALED found in lazy bind")
                }

            case .BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB:
                if (isLazy) {
                    throw MachOReader.ReadError.InvalidData(reason: "DO_BIND_ULEB_TIMES_SKIPPING_ULEB found in lazy bind")
                }
                uval1 = try r.readULEB128()
                uval2 = try r.readULEB128()
            }
            try callback(opcode, immValue, uval1, uval2, sval, symbolName, opcodeAddr)
        }
    }
}
