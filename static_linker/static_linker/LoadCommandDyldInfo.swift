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

            let rebase = MemoryBufferReader(reader, offset: Int(rebaseOffset), size: Int(rebaseSize))
            rebaseInfo(rebase!)

            let bind = MemoryBufferReader(reader, offset: Int(bindOffset), size: Int(rebaseSize))
            bindInfo(bind!, isLazy: false)

            let weakBind = MemoryBufferReader(reader, offset: Int(weakBindOffset), size: Int(weakBindSize))
            bindInfo(weakBind!, isLazy: false)

            let lazyBind = MemoryBufferReader(reader, offset: Int(lazyBindOffset), size: Int(lazyBindSize))
            bindInfo(lazyBind!, isLazy: true)

        } catch {
            return nil
        }
    }

    enum RebaseOpcode: UInt8 {
        static let OPCODE_MASK: UInt8   = 0xF0
        static let IMMEDIATE_MASK: UInt8 = 0x0F

        case DONE                               = 0x00
        case SET_TYPE_IMM                       = 0x10
        case SET_SEGMENT_AND_OFFSET_ULEB        = 0x20
        case ADD_ADDR_ULEB                      = 0x30
        case ADD_ADDR_IMM_SCALED                = 0x40
        case DO_REBASE_IMM_TIMES                = 0x50
        case DO_REBASE_ULEB_TIMES               = 0x60
        case DO_REBASE_ADD_ADDR_ULEB            = 0x70
        case DO_REBASE_ULEB_TIMES_SKIPPING_ULEB = 0x80
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

        case DONE                               = 0x00
        case SET_DYLIB_ORDINAL_IMM              = 0x10
        case SET_DYLIB_ORDINAL_ULEB             = 0x20
        case SET_DYLIB_SPECIAL_IMM              = 0x30
        case SET_SYMBOL_TRAILING_FLAGS_IMM      = 0x40
        case SET_TYPE_IMM                       = 0x50
        case SET_ADDEND_SLEB                    = 0x60
        case SET_SEGMENT_AND_OFFSET_ULEB        = 0x70
        case ADD_ADDR_ULEB                      = 0x80
        case DO_BIND                            = 0x90
        case DO_BIND_ADD_ADDR_ULEB              = 0xA0
        case DO_BIND_ADD_ADDR_IMM_SCALED        = 0xB0
        case DO_BIND_ULEB_TIMES_SKIPPING_ULEB   = 0xC0
    }

    enum BindType: UInt8 {
        case NONE       = 0
        case POINTER    = 1
        case ABSOLUTE32 = 2
        case PCREL32    = 3
    }


    func decodeRebaseOp(instr: UInt8) throws -> (RebaseOpcode, UInt8) {
        if let opcode = RebaseOpcode(rawValue: (instr & RebaseOpcode.OPCODE_MASK)) {
            let immValue = instr & RebaseOpcode.IMMEDIATE_MASK
            return (opcode, immValue)
        } else {
            throw MachOReader.ReadError.InvalidData
        }
    }


    func decodeBindOp(instr: UInt8) throws -> (BindOpcode, UInt8) {
        if let opcode = BindOpcode(rawValue: (instr & BindOpcode.OPCODE_MASK)) {
            let immValue = instr & BindOpcode.IMMEDIATE_MASK
            return (opcode, immValue)
        } else {
            throw MachOReader.ReadError.InvalidData
        }
    }


    func rebaseInfo(r: MemoryBufferReader) {
        //dumpBuffer(r)
        var rebaseType = RebaseType.NONE
        var segmentIndex: Int = 0
        var segmentOffset: UInt64 = 0
        var advanceAmt: UInt64 = 0
        var remainingLoopCount: UInt64 = 0
        let pointerSize: UInt64 = 8

        do {
            repeat {
                let startOffset = r.offset
                let (opcode, immValue) = try decodeRebaseOp(r.read())

                switch (opcode) {
                case .DONE:
                    break

                case .SET_TYPE_IMM:
                    guard let type = RebaseType(rawValue: immValue) else {
                        throw MachOReader.ReadError.InvalidData
                    }
                    rebaseType = type
                    break

                case .SET_SEGMENT_AND_OFFSET_ULEB:
                    segmentIndex = Int(immValue)
                    segmentOffset = try readULEB128(r)
                    break

                case .ADD_ADDR_ULEB:
                    segmentOffset += try readULEB128(r)
                    break

                case .ADD_ADDR_IMM_SCALED:
                    segmentOffset += UInt64(immValue) * pointerSize
                    break

                case .DO_REBASE_IMM_TIMES:
                    advanceAmt = pointerSize
                    remainingLoopCount = UInt64(immValue) - 1
                    break

                case .DO_REBASE_ULEB_TIMES:
                    advanceAmt = pointerSize
                    remainingLoopCount = try readULEB128(r) - 1
                    break

                case .DO_REBASE_ADD_ADDR_ULEB:
                    advanceAmt = try readULEB128(r) + pointerSize
                    remainingLoopCount = 0
                    break

                case .DO_REBASE_ULEB_TIMES_SKIPPING_ULEB:
                    remainingLoopCount = try readULEB128(r) - 1
                    advanceAmt  = try readULEB128(r) + pointerSize
                    break
                }
                let ops = dumpBuffer(r, startOffset, r.offset)
                var str = "\(ops): \(opcode): rebaseType: \(rebaseType) segmentIdx: \(segmentIndex) segmentOff: \(segmentOffset) "
                str += "advance: \(advanceAmt) rlc: \(remainingLoopCount)"
                //print(str)
                if opcode == .DONE {
                    return
                }
            } while true
        } catch {
            print("Read error")
        }
    }


    func bindInfo(r: MemoryBufferReader, isLazy: Bool) {
        //dumpBuffer(r)

        do {
            var done = false
            var ordinal: Int64 = 0
            var flags: UInt8 = 0
            var symbolName = ""
            var bindType = BindType.NONE
            var addend: Int64 = 0
            var segmentIndex: Int = 0
            var segmentOffset: UInt64 = 0
            var advanceAmt: UInt64 = 0
            let pointerSize: UInt64 = 8
            var remainingLoopCount: UInt64 = 0

            while !done {
                let startOffset = r.offset
                let (opcode, immValue) = try decodeBindOp(r.read())

                switch (opcode) {
                case .DONE:
                    if (isLazy) {
                        // DONE opcodes appear between instruction so check end of data stream
                        if r.bytesRemaining > 0 {
                            break
                        }
                    }
                    done = true
                    break

                case .SET_DYLIB_ORDINAL_IMM:
                    ordinal = Int64(immValue)
                    break

                case .SET_DYLIB_ORDINAL_ULEB:
                    ordinal = try Int64(readULEB128(r))
                    break

                case .SET_DYLIB_SPECIAL_IMM:
                    if immValue != 0 {
                        let signExtend = Int8(BindOpcode.OPCODE_MASK | immValue)
                        ordinal = Int64(signExtend)
                    } else {
                        ordinal = 0
                    }
                    break

                case .SET_SYMBOL_TRAILING_FLAGS_IMM:
                    flags = immValue
                    symbolName = try r.scanASCIIZString()
                    // FIXME
                    // if (ImmValue & MachO::BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION)
                    //  return
                    break

                case .SET_TYPE_IMM:
                    guard let type = BindType(rawValue: immValue) else {
                        throw MachOReader.ReadError.InvalidData
                    }
                    bindType = type
                    break

                case .SET_ADDEND_SLEB:
                    if (isLazy) {
                        print("SET_ADDEND_SLEB found in lazy bind")
                        throw MachOReader.ReadError.InvalidData
                    }
                    addend = try readSLEB128(r)
                    break

                case .SET_SEGMENT_AND_OFFSET_ULEB:
                    segmentIndex = Int(immValue)
                    segmentOffset = try readULEB128(r)
                    break

                case .ADD_ADDR_ULEB:
                    segmentOffset += try readULEB128(r)
                    break

                case .DO_BIND:
                    advanceAmt = pointerSize
                    remainingLoopCount = 0
                    break

                case .DO_BIND_ADD_ADDR_ULEB:
                    if (isLazy) {
                        print("DO_BIND_ADD_ADDR_ULEB found in lazy bind")
                        throw MachOReader.ReadError.InvalidData
                    }
                    advanceAmt = try readULEB128(r)
                    advanceAmt += pointerSize
                    remainingLoopCount = 0
                    break

                case .DO_BIND_ADD_ADDR_IMM_SCALED:
                    if (isLazy) {
                        print("DO_BIND_ADD_ADDR_IMM_SCALED found in lazy bind")
                        throw MachOReader.ReadError.InvalidData
                    }
                    advanceAmt = UInt64(immValue) * pointerSize
                    advanceAmt += pointerSize
                    remainingLoopCount = 0
                    break

                case .DO_BIND_ULEB_TIMES_SKIPPING_ULEB:
                    if (isLazy) {
                        print("DO_BIND_ULEB_TIMES_SKIPPING_ULEB found in lazy bind")
                        throw MachOReader.ReadError.InvalidData
                    }
                    remainingLoopCount = try readULEB128(r) - 1
                    advanceAmt = try readULEB128(r) + pointerSize
                    break
                }
                let ops = dumpBuffer(r, startOffset, r.offset)
                var str = "\(ops): \(opcode): bindType: \(bindType) segmentIdx: \(segmentIndex) segmentOff: \(segmentOffset) "
                str += "advance: \(advanceAmt) rlc: \(remainingLoopCount) flags: \(flags) "
                str += "ordinal: \(ordinal) addend: \(addend) symbol: \(symbolName)"
                //print(str)
            }
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
        repeat {
            let byte: UInt8 = try r.read()
            value <<= 7
            value |= UInt64(byte & 0x7f)
        } while (value & 0x80) == 0x80

        return value
    }


    func readSLEB128(r: MemoryBufferReader) throws -> Int64 {
        var value: Int64 = 0
        var shift: Int64 = 0
        var byte: UInt8 = 0

        repeat {
            byte = try r.read()
            value <<= 7
            value |= Int64(byte)
            shift += 7
        } while (value & 0x80) == 0x80

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
