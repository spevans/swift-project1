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

    init?(_ header: LoadCommandHdr, _ reader: MachOReader) {
        super.init(header: header, reader: reader)

        do {
            guard let buffer = MemoryBufferReader(reader, offset: header.cmdOffset + 8, size: Int(header.cmdSize)-8) else {
                return nil
            }
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

            let bind = MemoryBufferReader(reader, offset: Int(bindOffset), size: Int(rebaseSize))
            bindInfo(bind!, isLazy: false, sectionType: "bind")

            let weakBind = MemoryBufferReader(reader, offset: Int(weakBindOffset), size: Int(weakBindSize))
            bindInfo(weakBind!, isLazy: false, sectionType: "weak")

            let lazyBind = MemoryBufferReader(reader, offset: Int(lazyBindOffset), size: Int(lazyBindSize))
            bindInfo(lazyBind!, isLazy: true, sectionType: "lazy")


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


    typealias rebaseCallback = (RebaseOpcode, UInt8, UInt64?, UInt64?, Int) throws -> ()


    func showRebaseOpcodes() throws {
        let pointerSize: UInt64 = 8
        var rebaseType = RebaseType.NONE
        var segmentIndex: Int = 0
        var segmentOffset: UInt64 = 0


        func rebaseCallback(opcode opcode: RebaseOpcode, immValue: UInt8, val1: UInt64?, val2: UInt64?,
            opcodeAddr: Int) throws {

            switch (opcode) {
            case .REBASE_OPCODE_DONE:
                print(String(format: "0x%04X \(opcode)()", opcodeAddr))

            case .REBASE_OPCODE_SET_TYPE_IMM:
                rebaseType = RebaseType(rawValue: immValue)!
                print(String(format: "0x%04X \(opcode)(%d)", opcodeAddr, rebaseType.rawValue))

            case .REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                print(String(format: "0x%04X \(opcode)(%d, 0x%08X)", opcodeAddr, Int(immValue), val1!))

            case .REBASE_OPCODE_ADD_ADDR_ULEB:
                print(String(format: "0x%04X \(opcode)(0x%02X)", opcodeAddr, val1!))

            case .REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
                let val = UInt64(immValue) * pointerSize
                print(String(format: "0x%04X \(opcode)(0x%X)", opcodeAddr, val))

            case .REBASE_OPCODE_DO_REBASE_IMM_TIMES:
                print(String(format: "0x%04X \(opcode)(%d)", opcodeAddr, immValue))

            case .REBASE_OPCODE_DO_REBASE_ULEB_TIMES:
                print(String(format: "0x%04X \(opcode)(%d)", opcodeAddr, val1!))

            case .REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB:
                let advanceAmt = val1! + pointerSize
                print(String(format: "0x%04X \(opcode)(%d)", opcodeAddr, advanceAmt))

            case .REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB:
                print(String(format: "0x%04X \(opcode)(%d, %d)", opcodeAddr, val1!, val2!))
            }
        }

        try runRebase(rebaseCallback)
    }


    func runRebase(callback: rebaseCallback) throws {
        let rebase = MemoryBufferReader(reader, offset: Int(rebaseOffset), size: Int(rebaseSize))
        try rebaseInfo(rebase!, callback: callback)
    }


    func rebaseInfo(r: MemoryBufferReader, callback: rebaseCallback) throws {
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
                val1 = try readULEB128(r)

            case .REBASE_OPCODE_ADD_ADDR_ULEB:
                val1 = try readULEB128(r)

            case .REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
                break

            case .REBASE_OPCODE_DO_REBASE_IMM_TIMES:
                break

            case .REBASE_OPCODE_DO_REBASE_ULEB_TIMES:
                val1 = try readULEB128(r)

            case .REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB:
                val1 = try readULEB128(r)

            case .REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB:
                val1 = try readULEB128(r)
                val2 = try readULEB128(r)
            }
            try callback(opcode, immValue, val1, val2, opcodeAddr)

            if opcode == .REBASE_OPCODE_DONE {
                return
            }
        } while true
    }


    func bindInfo(r: MemoryBufferReader, isLazy: Bool, sectionType: String) {
        //dumpBuffer(r)

        do {
            var done = false
            var ordinal: Int64 = 0
            var flags: UInt8 = 0
            var symbolName = ""
            var addend: Int64 = 0
            var segmentIndex: Int = 0
            var segmentOffset: UInt64 = 0
            var advanceAmt: UInt64 = 0
            let pointerSize: UInt64 = 8
            var remainingLoopCount: UInt64 = 0
            let startOffset = r.offset

            while !done {

                let opcodeAddr = r.offset - startOffset
                let (opcode, immValue) = try decodeBindOp(r.read())
                print(String(format: "\(sectionType): 0x%04X \(opcode)", opcodeAddr), terminator: "")

                switch (opcode) {
                case .BIND_OPCODE_DONE:
                    print("")
                    if (isLazy) {
                        // DONE opcodes appear between instruction so check end of data stream
                        if r.bytesRemaining > 0 {
                            break
                        }
                    }
                    done = true

                case .BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
                    ordinal = Int64(immValue)
                    print(String(format: "(%d)", ordinal))

                case .BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
                    ordinal = try Int64(readULEB128(r))
                    print(String(format: "(%d)", ordinal))

                case .BIND_OPCODE_SET_DYLIB_SPECIAL_IMM:
                    if immValue != 0 {
                        let signExtend = Int8(BindOpcode.OPCODE_MASK | immValue)
                        ordinal = Int64(signExtend)
                    } else {
                        ordinal = 0
                    }
                    print(String(format: "(%d)", ordinal))

                case .BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM:
                    flags = immValue
                    symbolName = try r.scanASCIIZString()
                    // FIXME:
                    // if (ImmValue & MachO::BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION)
                    //  return
                    print(String(format: "(0x%02X, %@)", flags, symbolName))

                case .BIND_OPCODE_SET_TYPE_IMM:
                    guard let type = BindType(rawValue: immValue) else {
                        throw MachOReader.ReadError.InvalidData(reason: "Invalud BindType")
                    }
                    //bindType = type
                    print(String(format: "(%d)", type.rawValue))

                case .BIND_OPCODE_SET_ADDEND_SLEB:
                    if (isLazy) {
                        throw MachOReader.ReadError.InvalidData(reason: "SET_ADDEND_SLEB found in lazy bind")
                    }
                    addend = try readSLEB128(r)
                    print(String(format: "(%lld)", addend))

                case .BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                    segmentIndex = Int(immValue)
                    segmentOffset = try readULEB128(r)
                    print(String(format: "(0x%02X, 0x%08llX)", segmentIndex, segmentOffset))

                case .BIND_OPCODE_ADD_ADDR_ULEB:
                    let val = try readULEB128(r)
                    segmentOffset = val
                    print(String(format: "(0x%08X)", val))

                case .BIND_OPCODE_DO_BIND:
                    advanceAmt = pointerSize
                    remainingLoopCount = 0
                    print("()")

                case .BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB:
                    if (isLazy) {
                        throw MachOReader.ReadError.InvalidData(reason: "DO_BIND_ADD_ADDR_ULEB found in lazy bind")
                    }
                    advanceAmt = try readULEB128(r)
                    //advanceAmt = (advanceAmt &+ pointerSize)
                    print(String(format: "(0x%08X)", advanceAmt))

                case .BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
                    if (isLazy) {
                        throw MachOReader.ReadError.InvalidData(reason: "DO_BIND_ADD_ADDR_IMM_SCALED found in lazy bind")
                    }
                    advanceAmt = UInt64(immValue) * pointerSize
                    advanceAmt += pointerSize
                    remainingLoopCount = 0
                    print(String(format: "(0x%08X)", advanceAmt))

                case .BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB:
                    if (isLazy) {
                        throw MachOReader.ReadError.InvalidData(reason: "DO_BIND_ULEB_TIMES_SKIPPING_ULEB found in lazy bind")
                    }
                    remainingLoopCount = try readULEB128(r)
                    advanceAmt = try readULEB128(r)
                    print(String(format: "(%d, 0x%08X)", remainingLoopCount, advanceAmt))
                }
                //let ops = "" //dumpBuffer(r, startOffset, r.offset)
                //var str = "\(ops): \(opcode): bindType: \(bindType) segmentIdx: \(segmentIndex) segmentOff: \(segmentOffset) "
                //str += "advance: \(advanceAmt) rlc: \(remainingLoopCount) flags: \(flags) "
                //str += "ordinal: \(ordinal) addend: \(addend) symbol: \(symbolName)"
                //print(str)
            }
        } catch MachOReader.ReadError.InvalidData(let reason) {
            print("Read error: \(reason)")
        } catch {
            print("Read error")
        }
    }


    func dumpBuffer(r: MemoryBufferReader) {
        var str = "0000: "

        if (r.buffer.count > 0) {
            for idx in 0..<r.buffer.count {
                if (idx > 0) && (idx % 32) == 0 {
                    print(str)
                    str = String(format: "%04X: ", idx)
                }

                let data: UInt8 = try! r.read()
                str += String(format: " %02X", data)
            }
            if !str.isEmpty {
                print(str)
            }
        }

        r.offset = 0
    }


    func dumpBuffer(r: MemoryBufferReader, _ startOffset: Int, _ endOffset: Int) -> String {
        var str = ""
        let saved = r.offset
        let count = endOffset - startOffset

        r.offset = startOffset
        for _ in 0..<count {
            let data: UInt8 = try! r.read()
            str += String(format: "%02X ", data)
        }
        r.offset = saved
        return str
    }


    func readULEB128(r: MemoryBufferReader) throws -> UInt64 {
        var value: UInt64 = 0
        var shift: UInt64 = 0
        var byte: UInt8 = 0

        repeat {
            byte = try r.read()
            value |= (UInt64(byte & 0x7f) << shift)
            shift += 7
        } while (byte & 0x80) == 0x80

        return value
    }


    func readSLEB128(r: MemoryBufferReader) throws -> Int64 {
        var value: Int64 = 0
        var shift: Int64 = 0
        var byte: UInt8 = 0

        repeat {
            byte = try r.read()
            value |= (Int64(byte & 0x7f) << shift)
            shift += 7
        } while (byte & 0x80) == 0x80

        if (Int(shift) < sizeof(Int64)) && (byte & 0x40) == 0x40 {
            // sign bit set so sign extend
            value |= -(1 << shift)
        }

        return value
    }


    override var description: String {
        var str =  String(format: "LoadCommandDyldInfo: rebase: %08X/%08X  bind: %08X/%08X  weakBind: %08X/%08X",
            rebaseOffset, rebaseSize, bindOffset, bindSize, weakBindOffset, weakBindSize)
        str += String(format: " lazyBind: %08X/%08X export: %08X/%08X",
            lazyBindOffset, lazyBindSize, exportOffset, exportSize)

        return str
    }
}
