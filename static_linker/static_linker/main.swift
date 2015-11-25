//
//  main.swift
//  static_linker
//
//  Created by Simon Evans on 03/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


enum LinkerError: ErrorType {
    case UnrecoverableError(reason: String)
}

enum Section: String {
    case TEXT = "__TEXT"
    case DATA = "__DATA"
    case BSS  = "__BSS"
    case GOT  = "__GOT"

    func startSymbol() -> String { return rawValue.lowercaseString + "_start" }
    func endSymbol()   -> String { return rawValue.lowercaseString + "_end" }
}

struct SymbolInfo {
    let name: String
    let section: Section
    var address: UInt64 = 0 // Initially offset in the section until final address is determined
    let isLocal: Bool
    var GOTAddress: UInt64? // nil if doesnt need an entry, else 0 until GOT address is determined
    var bssSize: Int?
}


struct GlobalOffsetTable {
    let symbols: Set<String>
    let size: Int
    let buffer: UnsafeMutableBufferPointer<UInt64>
    var address: UInt64
}


class FileInfo {
    let machOFile: MachOReader
    var sectionBaseAddrs: [Int:UInt64] = [:]
    var offsetInSegment: [Int:UInt64] = [:]

    init(file: MachOReader) {
        self.machOFile = file
    }


    private func checkUndefinedSymbolsExist() throws -> Bool {
        // Check all of the undefined symbols are available
        var haveUndefined = false
        if machOFile.dySymbolTable != nil {
            let offset = Int(machOFile.dySymbolTable!.idxUndefSym)
            let lastIdx = offset + Int(machOFile.dySymbolTable!.numUndefSym)
            for symIdx in offset..<lastIdx {
                let symbol = machOFile.symbolTable.symbols[symIdx]
                guard symbol.type == .UNDF else {
                    throw LinkerError.UnrecoverableError(reason: "\(symbol.name) is in undef list but not marked as UNDF")
                }
                if symbol.name != "dyld_stub_binder" && globalMap[symbol.name] == nil {
                    haveUndefined = true
                    //throw LinkerError.UnrecoverableError(reason: "\(symbol.name) is not defined")
                    print("\(symbol.name) is not defined")
                }
            }
        }

        return haveUndefined
    }
}


var globalMap: [String:SymbolInfo] = [:]
var bssSymbols: [String:Int] = [:]


class BinarySection {
    let sectionType:   Section
    var baseAddress:   UInt64 = 0               // base address of this section
    var startAddress:  UInt64 = 0               // base address of complete binary (--baseAddress argument)
    var currentOffset: UInt64 = 0
    var sectionData    = NSMutableData()
    var relocations:   [(LoadCommandSegmentSection64, FileInfo)] = []


    init(_ type: Section) {
        sectionType = type
    }


    func align(addr: UInt64, alignment: UInt64) -> UInt64 {
        if (alignment > 0) {
            let mask = alignment - 1
            return (addr + mask) & ~mask
        }
        return addr
    }


    // alignment is log2 eg 0=>1, 1=>2 etc
    private func expandSectionToAlignment(alignment: Int) {
        let alignSize = UInt64(1 << alignment)
        let padding = Int(align(UInt64(sectionData.length), alignment:alignSize)) - sectionData.length
        if padding > 0 {
            let fillerByte: UInt8 = (sectionType == .TEXT) ? 0x90 : 0x00
            let filler = Array<UInt8>(count:padding, repeatedValue:UInt8(fillerByte))
            sectionData.appendData(NSData(bytes:filler, length:padding))
        }
    }

    /***
    func ptrToSpace<T>(addr: UInt64, count: Int) throws -> UnsafeMutableBufferPointer<T> {
        guard count > 0 && UInt64(sectionData.length) >= (addr + UInt64(count*(sizeof(T)))) else {
            throw LinkerError.UnrecoverableError(reason: "address/count is out of bounds")
        }
        let ptr = UnsafeMutablePointer<T>(sectionData.bytes + Int(addr))
        return UnsafeMutableBufferPointer<T>(start: ptr, count: count)
    }***/


    func reserveSpace<T>(count: Int, align: Int) -> (UInt64, UnsafeMutableBufferPointer<T>) {
        let size = count * sizeof(T)
        let space = NSMutableData()
        space.increaseLengthBy(size)
        expandSectionToAlignment(align)

        let addr = UInt64(sectionData.length)
        sectionData.appendData(space)
        currentOffset = UInt64(sectionData.length)

        let ptr = UnsafeMutablePointer<T>(sectionData.bytes + Int(addr))
        let buffer = UnsafeMutableBufferPointer<T>(start: ptr, count: count)

        return (addr, buffer)
    }


    private func addSymbols(fileInfo: FileInfo, pc: UInt64, sectionNumber: Int, sectionAddr: UInt64,
        offset: Int, count: Int) throws {
        let dupes = Set(["__ZL11unreachablePKc", "__ZN5swiftL11STDLIB_NAMEE", "__ZN5swiftL20MANGLING_MODULE_OBJCE", "__ZN5swiftL17MANGLING_MODULE_CE", "GCC_except_table2"])
        let lastIdx = offset + count
        for symIdx in offset..<lastIdx {
            let symbol = fileInfo.machOFile.symbolTable.symbols[symIdx]
            if Int(symbol.sectionNumber) == sectionNumber && symbol.type != .UNDF {
                if globalMap[symbol.name] == nil {
                    let address = (symbol.value - sectionAddr) + pc
                    globalMap[symbol.name] = SymbolInfo(name: symbol.name, section: sectionType,
                        address: address, isLocal: symbol.privateExternalBit, GOTAddress: nil, bssSize: nil)
                } else {
                    if !dupes.contains(symbol.name) {
                        throw LinkerError.UnrecoverableError(reason: "Found \(symbol.name) already in globalMap")
                    }
                }
            }
        }
    }


    func addSegment(segment: LoadCommandSegment64, fileInfo: FileInfo) throws -> (UInt64, UInt64) {
        print("Adding segment nr \(segment.segnumber): \(segment.segname)")
        expandSectionToAlignment(Int(segment.sections[0].align))
        let dataStart = UInt64(sectionData.length)

        // FIXME: currently doesnt check if zerofills are only at the end
        for section in segment.sections {
            guard let data = section.sectionData else {
                throw LinkerError.UnrecoverableError(reason: "Cant read data")
            }
            sectionData.appendData(data)

            // If there is a dynamic symbol table, use that to get a list of the declared symbols contained in the obj/lib
            if fileInfo.machOFile.dySymbolTable != nil {
                // Add in exported symbols
                try addSymbols(fileInfo, pc: dataStart, sectionNumber: section.sectionNumber, sectionAddr: section.addr,
                    offset: Int(fileInfo.machOFile.dySymbolTable!.idxExtDefSym),
                    count: Int(fileInfo.machOFile.dySymbolTable!.numExtDefSym))

                // Add in local symbols
                try addSymbols(fileInfo, pc: dataStart, sectionNumber: section.sectionNumber, sectionAddr: section.addr,
                    offset: Int(fileInfo.machOFile.dySymbolTable!.idxLocalSym),
                    count:Int(fileInfo.machOFile.dySymbolTable!.numLocalSym))
            }
        }
        let dataSize = UInt64(sectionData.length) - dataStart



        return (dataStart, dataSize)
    }


    func addSection(segment: LoadCommandSegment64, section: LoadCommandSegmentSection64, fileInfo: FileInfo) throws -> UInt64 {
        print("Adding section nr \(section.sectionNumber): \(section.segmentName):\(section.sectionName)")

        // Pad section upto next alignment
        expandSectionToAlignment(Int(section.align))
        let sectionStart = UInt64(sectionData.length)   // the current 'program counter' for this section

        if (section.sectionType == .S_ZEROFILL) {
            print("Adding \(section.size) bytes of zerofill")
            sectionData.increaseLengthBy(Int(section.size))
        } else {
            guard let data = section.sectionData else {
                throw LinkerError.UnrecoverableError(reason: "Cant read data")
            }
            sectionData.appendData(data)
        }

        try addSymbols(fileInfo, pc: sectionStart, sectionNumber: section.sectionNumber, sectionAddr: section.addr,
            offset: 0, count: fileInfo.machOFile.symbolTable.symbols.count)

        let tuple = (section, fileInfo)
        relocations.append(tuple)
        currentOffset = UInt64(sectionData.length)

        return sectionStart
    }


    // Look through all of the relocations and find any symbols that are via the GOT and so may need a GOT entry
    func findGOTSymbols() throws -> Set<String> {
        var result: Set<String> = []

        for (section, fileInfo) in relocations {
            guard let relocs = section.relocations else {
                throw LinkerError.UnrecoverableError(reason: "Null relocations")
            }
            let symbols = fileInfo.machOFile.symbolTable.symbols

            for reloc in relocs {
                if reloc.type == .X86_64_RELOC_GOT || reloc.type == .X86_64_RELOC_GOT_LOAD {
                    guard reloc.extern else {
                        throw LinkerError.UnrecoverableError(reason: "Found GOT relocation that is not external")
                    }
                    guard let symbolName: String! = symbols[Int(reloc.symbolNum)].name else {
                        throw LinkerError.UnrecoverableError(reason: "Missing symbol")
                    }
                    result.insert(symbolName)
                }
            }
        }

        return result
    }


    func relocate() throws {
        for (section, fileInfo) in relocations {
            try relocateSection(section, fileInfo)
        }
    }


    private func patchAddress(offset offset: Int, length: Int, address: Int64, absolute: Bool) throws {
        guard (offset + length) <= sectionData.length else {
            throw LinkerError.UnrecoverableError(reason: "Bad offset \(offset + length) > \(sectionData.length)")
        }
        // Pointer to the bytes in the data to actually update
        let relocAddr = UnsafePointer<Void>(sectionData.bytes + offset)

        switch (length) {
        case 1:
            guard address <= Int64(Int8.max) else {
                throw LinkerError.UnrecoverableError(reason: "Bad address \(address) for Int8")
            }
            let ptr = UnsafeMutablePointer<Int8>(relocAddr)
            guard absolute == false || ptr.memory == 0 else {
                throw LinkerError.UnrecoverableError(reason: "Addend found in absolute patch")
            }
            ptr.memory += Int8(address)


        case 2:
            guard address <= Int64(Int16.max) else {
                throw LinkerError.UnrecoverableError(reason: "Bad address \(address) for Int16")
            }
            let ptr = UnsafeMutablePointer<Int16>(relocAddr)
            guard absolute == false || ptr.memory == 0 else {
                throw LinkerError.UnrecoverableError(reason: "Addend found in absolute patch")
            }
            ptr.memory += Int16(littleEndian: Int16(address))


        case 4:
            guard address <= Int64(Int32.max) else {
                throw LinkerError.UnrecoverableError(reason: "Bad address \(address) for Int32")
            }
            let ptr = UnsafeMutablePointer<Int32>(relocAddr)
            guard absolute == false || ptr.memory == 0 else {
                throw LinkerError.UnrecoverableError(reason: "Addend found in absolute patch")
            }
            ptr.memory += Int32(littleEndian: Int32(address))


        case 8:
            let ptr = UnsafeMutablePointer<Int64>(relocAddr)
            guard absolute == false || ptr.memory == 0 else {
                throw LinkerError.UnrecoverableError(reason: "Addend found in absolute patch")
            }
            ptr.memory += Int64(littleEndian: address)


        default:
            throw LinkerError.UnrecoverableError(reason: "Invalid symbol relocation length \(length)")
        }
    }


    func relocateSection(section: LoadCommandSegmentSection64, _ fileInfo: FileInfo) throws {

        guard let relocs = section.relocations else {
            throw LinkerError.UnrecoverableError(reason: "Null relocations")
        }

        if relocs.count == 0 {
            return
        }
        for reloc in relocs {
            // Offset into the bytes of this segment that will updated
            let offset = Int(reloc.address) + Int(fileInfo.sectionBaseAddrs[section.sectionNumber]!)
            let length = Int(1 << reloc.length) // Number of bytes to modify
            let pc = (baseAddress + UInt64(offset + length))
            var address: Int64 = 0              // The value to be patched into memory


            func externalSymbol() throws -> SymbolInfo {
                guard reloc.extern else {
                    throw LinkerError.UnrecoverableError(reason: "Not an external reloc")
                }
                let symbols = fileInfo.machOFile.symbolTable.symbols
                let symbolName: String? = reloc.extern ? symbols[Int(reloc.symbolNum)].name : nil
                guard let symbol = globalMap[symbolName!] else {
                    throw LinkerError.UnrecoverableError(reason: "Undefined symbol: \(symbolName!)")
                }
                return symbol
            }


            switch reloc.type {
            case .X86_64_RELOC_BRANCH, .X86_64_RELOC_SIGNED:
                guard reloc.PCRelative == true else {
                    throw LinkerError.UnrecoverableError(reason: "reloc is not PCRelative")
                }

                if reloc.extern {
                    // Target is a symbol
                    guard reloc.PCRelative else {
                        throw LinkerError.UnrecoverableError(reason: "PCRelative == false not allowed")
                    }

                    let symbol = try externalSymbol()
                    address = Int64(symbol.address) - Int64(pc)
                } else {
                    // Target is in another section
                    let section = Int(reloc.symbolNum)

                    // Where the section was originally supposed to go
                    let oldAddr = fileInfo.machOFile.loadCommandSections[section-1].addr
                    address = Int64(fileInfo.offsetInSegment[section]!) - Int64(oldAddr)
                }
                try patchAddress(offset: offset, length: length, address: address, absolute: false)


            case .X86_64_RELOC_UNSIGNED:
                guard reloc.PCRelative == false else {
                    throw LinkerError.UnrecoverableError(reason: "PCRelative == true not allowed")
                }
                guard reloc.length == 2 || reloc.length == 3 else {
                    throw LinkerError.UnrecoverableError(reason: "Bad reloc length \(reloc.length) for RELOC_UNSIGNED")
                }
                if (reloc.extern) {
                    let symbol = try externalSymbol()
                    address = Int64(symbol.address)

                } else {
                    // Target is in another section
                    let section = Int(reloc.symbolNum)

                    // Where the section was originally supposed to go
                    let oldAddr = fileInfo.machOFile.loadCommandSections[section-1].addr
                    let symAddr = fileInfo.sectionBaseAddrs[section]! + startAddress
                    address = Int64(symAddr - oldAddr)
                }
                try patchAddress(offset: offset, length: length, address: address, absolute: false)


            case .X86_64_RELOC_GOT, .X86_64_RELOC_GOT_LOAD:
                guard reloc.PCRelative else {
                    throw LinkerError.UnrecoverableError(reason: "PCRelative == false not allowed")
                }
                guard reloc.length == 2 else {
                    throw LinkerError.UnrecoverableError(reason: "Bad reloc length \(reloc.length) for GOT reloc")
                }

                let symbol = try externalSymbol()
                guard let saddr = symbol.GOTAddress else {
                    throw LinkerError.UnrecoverableError(reason: "\(symbol.name) does not have a GOT address")
                }
                let address = Int64(saddr) - Int64(pc) // make PC relative
                try patchAddress(offset: offset, length: length, address: address, absolute: true)

            default:
                throw LinkerError.UnrecoverableError(reason: "Unsupported reloc type: \(reloc.type)")
            }
        }
    }
}


class RebaseInfo {
    struct SegmentMapInfo {
        let section: BinarySection
        let offset: UInt64          // The offset into the sectionData that the segment was stored
        let dataSize: UInt64        // The number of bytes of the segment's data that was stored (excludes ZEROFILL etc)
    }

    let machOFile: MachOReader
    var segmentMap: [Int:SegmentMapInfo] = [:]


    init(file: MachOReader) {
        machOFile = file
    }


    func addSegment(segment: Int, section: BinarySection, offset: UInt64, dataSize: UInt64) {
        segmentMap[segment] = SegmentMapInfo(section: section, offset: offset, dataSize: dataSize)
    }
}


extension NSFileHandle {
    func writeString(string: String) {
        self.writeData(string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
    }
}


func openOutput(filename: String) throws -> NSFileHandle {
    if NSFileManager.defaultManager().createFileAtPath(filename, contents: nil, attributes: nil) {
        let output = NSFileHandle(forWritingAtPath: filename)
        if output != nil {
            return output!
        }
    }

    throw LinkerError.UnrecoverableError(reason: "Cant open output file: \(filename)")
}


func writeMapToFile(filename: String, textAddr: UInt64, dataAddr: UInt64, bssAddr: UInt64) throws {
    let mapFile = try openOutput(filename)
    let sortedSymbols = globalMap.keys.sort({ return globalMap[$0]!.address < globalMap[$1]!.address })

    func writeSection(name:String, _ section: Section, _ baseAddr: UInt64) {
        mapFile.writeString(String(format: "%@ section baseAddress: %08X\n\n", name, baseAddr))
        for name in sortedSymbols {
            let symbol = globalMap[name]!
            if symbol.section == section {
                let addr = symbol.address
                mapFile.writeString(String(format: "%08X [%10d]:%@: %@\n", addr, addr, symbol.isLocal ? "L" : "G",
                    symbol.name))
            }
        }
    }

    writeSection(".text", Section.TEXT, textAddr)
    mapFile.writeString("\n\n")
    writeSection(".data", Section.DATA, dataAddr)
    mapFile.writeString("\n\n")
    writeSection(".bss", Section.BSS, bssAddr)

    mapFile.writeString(String(format: "\nGlobal Offset Table:\n"))
    for name in sortedSymbols {
        let symbol = globalMap[name]!
        if let gAddr = symbol.GOTAddress {
            mapFile.writeString(String(format: "[GOT = %08X]: %08X  %@\n", gAddr, symbol.address, name))
        }
    }

    mapFile.closeFile()
}


func parseNumber(number: String) -> UInt64? {
    let strs = number.componentsSeparatedByString("0x")

    if strs.count == 2 {
        return UInt64(strs[1], radix: 16)
    } else {
        return UInt64(strs[0], radix: 10)
    }
}


// Look through all of the symbols to find the ones which are BSS and store them along with their
// size (which is that symbol.value).
func findBssSymbols(symbols: [LoadCommandSymTab.Symbol]) throws {
    for symbol in symbols {
        if (symbol.sectionNumber == 0) && (symbol.type == .UNDF) && symbol.value > 0 {
            let size = Int(symbol.value)
            if let curSize = bssSymbols[symbol.name] {
                if curSize < size {
                    // Store the largest value for a BSS symbol as this will be its allocated size
                    bssSymbols[symbol.name] = size
                }
            } else {
                bssSymbols[symbol.name] = size
            }
        }
    }
}


func rebaseSegments(rebaseInfos: [RebaseInfo]) throws {
    for ri in rebaseInfos {
        guard let dyldInfo = ri.machOFile.dyldInfo else {
            continue
        }

        let pointerSize: UInt64 = 8     // pointer size in bytes for X86_64
        var rebaseType = RebaseType.NONE
        var segmentIndex: Int = 0
        var segmentOffset: UInt64 = 0
        var slide: UInt64?


        func rebaseAtAddress() throws {
            let seg = ri.segmentMap[segmentIndex]?.section.sectionType.rawValue
            let rebaseAddress = ri.machOFile.loadCommandSegments[segmentIndex].vmaddr + segmentOffset
            print(String(format: "Rebase @ \(seg!) 0x%08X  ", rebaseAddress), terminator: "")

            switch(rebaseType) {
            case .POINTER, .ABSOLUTE32:
                // FIXME: do the update
                print(String(rebaseType).lowercaseString)

            default:
                throw LinkerError.UnrecoverableError(reason: "Bad rebaseType: \(rebaseType)")
            }
        }


        func rebaseCallback(opcode opcode: RebaseOpcode, immValue: UInt8, val1: UInt64?, val2: UInt64?, opcodeAddr: Int) throws {

                switch (opcode) {
                case .REBASE_OPCODE_DONE:
                    print("Rebase finished")
                    return

                case .REBASE_OPCODE_SET_TYPE_IMM:
                    rebaseType = RebaseType(rawValue: immValue)!

                case .REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                    segmentIndex = Int(immValue)
                    segmentOffset = val1!
                    // Calculate the displacement of where the section is v where it preferred to be (vmaddr)
                    let originalAddr = ri.machOFile.loadCommandSegments[segmentIndex].vmaddr
                    let actualAddr = ri.segmentMap[segmentIndex]!.section.baseAddress
                    slide = actualAddr - originalAddr

                case .REBASE_OPCODE_ADD_ADDR_ULEB:
                    segmentOffset += val1!

                case .REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
                    segmentOffset += UInt64(immValue) * pointerSize

                case .REBASE_OPCODE_DO_REBASE_IMM_TIMES:
                    let count = Int(immValue)
                    let inc = pointerSize
                    for _ in 0..<count {
                        try rebaseAtAddress()
                        segmentOffset += inc
                    }

                case .REBASE_OPCODE_DO_REBASE_ULEB_TIMES:
                    let count = val1!
                    let inc = pointerSize
                    for _ in 0..<count {
                        try rebaseAtAddress()
                        segmentOffset += inc
                    }

                case .REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB:
                    let inc = val1! + pointerSize
                    try rebaseAtAddress()
                    segmentOffset += inc

                case .REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB:
                    let count = val1!
                    let skip = val2!
                    let inc = skip + pointerSize
                    for _ in 0..<count {
                        try rebaseAtAddress()
                        segmentOffset += inc
                    }
                }
        }

        try dyldInfo.runRebase(rebaseCallback)
    }
}


func processSourceFile(args: [String:AnyObject]) throws {
    let sources = args["sources"] as! [String]
    let destBinary = args["--output"] as! String
    let textSection = BinarySection(Section.TEXT)
    let dataSection = BinarySection(Section.DATA)
    var fileInfos: [FileInfo] = []
    var rebaseInfos: [RebaseInfo] = []

    for source in sources {
        print("Processing \(source)")
        guard let srcLibData = MachOReader(filename: source) else {
            throw LinkerError.UnrecoverableError(reason: "Cannot parse \(source)")
        }

        guard srcLibData.loadCommandSegments.count > 0 else {
            throw LinkerError.UnrecoverableError(reason: "No load command segments found")
        }

        if (srcLibData.header.fileType == MachOReader.FileType.OBJECT) {
            guard srcLibData.loadCommandSegments.count == 1 else {
                throw LinkerError.UnrecoverableError(reason: "OBJECT file has >1 segments")
            }

            guard srcLibData.loadCommandSegments[0].vmaddr == 0 else {
                throw LinkerError.UnrecoverableError(reason: "OBJECT file has vmaddr set!")
            }

            let name = srcLibData.loadCommandSegments[0].segname
            guard name == "" else {
                throw LinkerError.UnrecoverableError(reason: "OBJECT file has segment named \(name)")
            }
        } else if (srcLibData.header.fileType == MachOReader.FileType.DYLIB) {

        } else {
            throw LinkerError.UnrecoverableError(reason: "Cant process source file of type \(srcLibData.header.fileType)")
        }


        for idx in 0..<srcLibData.loadCommands.count {
            print("\(idx): \(srcLibData.loadCommands[idx].description)")
        }

        // These two vars track the offset that sections are copied to, this allows that difference
        // between where a section's addr says it should go and where it ends up (relative to the start of the
        // object file not the start of the total output
        var textAddress: UInt64?
        var dataAddress: UInt64?
        let fileInfo = FileInfo(file: srcLibData)
        fileInfos.append(fileInfo)
        let rebaseInfo = RebaseInfo(file: srcLibData)
        rebaseInfos.append(rebaseInfo)

        try findBssSymbols(srcLibData.symbolTable.symbols)
        for loadSegment in srcLibData.loadCommandSegments {
            print(loadSegment)

            if (loadSegment.segname == Section.TEXT.rawValue) {
                let (start, size) = try textSection.addSegment(loadSegment, fileInfo: fileInfo)
                rebaseInfo.addSegment(loadSegment.segnumber, section: textSection, offset: start, dataSize: size)
            } else if (loadSegment.segname == Section.DATA.rawValue) {
                let (start, size) = try dataSection.addSegment(loadSegment, fileInfo: fileInfo)
                rebaseInfo.addSegment(loadSegment.segnumber, section: dataSection, offset: start, dataSize: size)
            } else if (loadSegment.segname == "") {
                for section in loadSegment.sections {
                    if section.segmentName == Section.TEXT.rawValue {
                        var curaddr = textSection.currentOffset
                        let sectionStart = try textSection.addSection(loadSegment, section: section, fileInfo: fileInfo)
                        if textAddress == nil {
                            textAddress = sectionStart
                            curaddr = sectionStart
                        }
                        fileInfo.sectionBaseAddrs[section.sectionNumber] = sectionStart
                        fileInfo.offsetInSegment[section.sectionNumber] = curaddr - textAddress!
                    } else if section.segmentName == Section.DATA.rawValue {
                        var curaddr = dataSection.currentOffset
                        let sectionStart = try dataSection.addSection(loadSegment, section: section, fileInfo: fileInfo)
                        if dataAddress == nil {
                            dataAddress = sectionStart
                            curaddr = sectionStart
                        }
                        fileInfo.sectionBaseAddrs[section.sectionNumber] = sectionStart
                        fileInfo.offsetInSegment[section.sectionNumber] = curaddr - dataAddress!
                    } else {
                        print("Skipping section: \(section.segmentName)");
                    }
                }
            } else {
                print("Skipping segment: \(loadSegment.segname)")
            }
        }
    }


    let sectionAlign:UInt64 = 4096 // page size
    if let baseAddr = args["--baseAddress"] as? String {
        guard let addr = parseNumber(baseAddr) else {
            throw LinkerError.UnrecoverableError(reason: "Bad baseAddress \(baseAddr)")
        }
        print(String(format: "Base address = %016X", addr))
        textSection.baseAddress = addr
        textSection.startAddress = addr
        dataSection.startAddress = addr
    }

    // Add the GOT at the end of the text section if one is required
    let GOT = try computeGOTSize(textSection, dataSection)

    var dataAddr = textSection.baseAddress + textSection.currentOffset
    dataAddr = (dataAddr + sectionAlign-1) & ~(sectionAlign-1)
    dataSection.baseAddress = dataAddr

    // Now that the text and data section base addresses have been set, update the symbols in these sections
    // to have their final address
    for symbol in globalMap.keys {
        if (globalMap[symbol]!.section == .TEXT) {
            globalMap[symbol]!.address += textSection.baseAddress
        } else if (globalMap[symbol]!.section == .DATA) {
            globalMap[symbol]!.address += dataSection.baseAddress
        }
    }

    try rebaseSegments(rebaseInfos)

    let (bssBaseAddr, bssSize) = createBSS(dataSection)
    addSectionSymbols(textSection, dataSection, bssBaseAddr: bssBaseAddr, bssEndAddr: bssBaseAddr + bssSize, GOT: GOT)
    addGOTSymbols(GOT)

    for fi in fileInfos {
        try fi.checkUndefinedSymbolsExist()
    }

    try textSection.relocate()
    try dataSection.relocate()

    let outputFile = try openOutput(destBinary)
    outputFile.writeData(textSection.sectionData)
    let dataOffset = dataSection.baseAddress - textSection.baseAddress
    outputFile.seekToFileOffset(dataOffset)
    outputFile.writeData(dataSection.sectionData)
    outputFile.closeFile()

    if let mapfile = args["--mapfile"] as? String {
        try writeMapToFile(mapfile, textAddr: textSection.baseAddress, dataAddr: dataSection.baseAddress,
            bssAddr: bssBaseAddr)
    }
}


func computeGOTSize(textSection: BinarySection, _ dataSection: BinarySection) throws -> GlobalOffsetTable {
    let sectionSymbols = Set([
        Section.TEXT.startSymbol(), Section.TEXT.endSymbol(),
        Section.DATA.startSymbol(), Section.DATA.endSymbol(),
        Section.GOT.startSymbol(), Section.GOT.endSymbol(),
        Section.BSS.startSymbol(), Section.BSS.endSymbol()
    ])
    let GOTSymbols = try textSection.findGOTSymbols().union(dataSection.findGOTSymbols()).union(sectionSymbols)

    let GOTSize = GOTSymbols.count * sizeof(UInt64)      // 8 byte pointer per entry

    // If there are GOT symbols create a GOT and add to the end of the text section
    // GOTBase / GOTAddr are initialised so they can be updated in a tuple return
    // Probably needs fixin
    var GOTBase: UnsafeMutableBufferPointer<UInt64> = UnsafeMutableBufferPointer<UInt64>(start: nil, count: 0)
    var GOTAddr: UInt64 = 0
    if (GOTSize > 0) {
        let count = GOTSymbols.count
        (GOTAddr, GOTBase) = textSection.reserveSpace(count, align:3)
        GOTAddr += textSection.startAddress
    }

    return GlobalOffsetTable(symbols: GOTSymbols, size: GOTSize, buffer: GOTBase, address: GOTAddr)
}


func createBSS(dataSection: BinarySection) -> (UInt64, UInt64) {

    // Put the BSS after the data section and align to 8 bytes
    let dataEnd = dataSection.baseAddress + dataSection.currentOffset
    let bssBaseAddr: UInt64 = (dataEnd + 7) & ~7

    // Create bss from BSS symbols
    var bssOffset: UInt64 = 0
    for symbol in bssSymbols {
        let gsym = SymbolInfo(name: symbol.0, section: Section.BSS, address: bssBaseAddr + bssOffset, isLocal: false,
            GOTAddress: nil, bssSize: Int(symbol.1.value))
        globalMap[symbol.0] = gsym
        bssOffset += UInt64(symbol.1.value)
    }

    return (bssBaseAddr, bssOffset)
}


func addSectionSymbols(textSection: BinarySection, _ dataSection: BinarySection, bssBaseAddr: UInt64, bssEndAddr: UInt64,
    GOT: GlobalOffsetTable) {

    var symbol = textSection.sectionType.startSymbol()
    globalMap[symbol] = SymbolInfo(name: symbol, section: Section.TEXT,
        address: textSection.baseAddress, isLocal: false, GOTAddress: nil, bssSize: nil)

    symbol = textSection.sectionType.endSymbol()
    globalMap[symbol] = SymbolInfo(name: symbol, section: Section.TEXT,
        address: textSection.baseAddress + textSection.currentOffset, isLocal: false, GOTAddress: nil, bssSize: nil)

    symbol = dataSection.sectionType.startSymbol()
    globalMap[symbol] = SymbolInfo(name: symbol, section: Section.DATA,
        address: dataSection.baseAddress, isLocal: false, GOTAddress: nil, bssSize: nil)

    symbol = dataSection.sectionType.endSymbol()
    globalMap[symbol] = SymbolInfo(name: symbol, section: Section.DATA,
        address: dataSection.baseAddress + dataSection.currentOffset, isLocal: false, GOTAddress: nil, bssSize: nil)

    symbol = Section.BSS.startSymbol()
    globalMap[symbol] = SymbolInfo(name: symbol, section: Section.BSS,
        address: bssBaseAddr, isLocal: false, GOTAddress: nil, bssSize: nil)

    symbol = Section.BSS.endSymbol()
    globalMap[symbol] = SymbolInfo(name: symbol, section: Section.BSS,
        address: bssEndAddr, isLocal: false, GOTAddress: nil, bssSize: nil)

    if GOT.address > 0 {
        symbol = Section.GOT.startSymbol()
        globalMap[symbol] = SymbolInfo(name: symbol, section: Section.TEXT,
            address: GOT.address, isLocal: false, GOTAddress: nil, bssSize: nil)

        symbol = Section.GOT.endSymbol()
        globalMap[symbol] = SymbolInfo(name: symbol, section: Section.TEXT,
            address: GOT.address + UInt64(GOT.size), isLocal: false, GOTAddress: nil, bssSize: nil)
    }
}


func addGOTSymbols(GOT: GlobalOffsetTable) {
    if (GOT.size > 0) {
        var GOTEntry = 0
        let sortedKeys = globalMap.keys.sort({ return globalMap[$0]!.address < globalMap[$1]!.address })
        for symbol in sortedKeys {
            if (GOT.symbols.contains(symbol)) {
                globalMap[symbol]!.GOTAddress = GOT.address + (8 * UInt64(GOTEntry))
                GOT.buffer[GOTEntry] = globalMap[symbol]!.address
                GOTEntry++
            }
        }
    }
}


func parseArgs() throws -> [String:AnyObject] {
    let validOptions:Set = ["--baseAddress", "--mapfile", "--output"]

    var options: [String:AnyObject] = [:]
    var sources: [String] = []
    var args = Process.arguments
    args.removeAtIndex(0)

    for arg in args {
        if arg.hasPrefix("--") {
            let option = arg.componentsSeparatedByString("=")
            guard option.count == 2 && validOptions.contains(option[0]) else {
                throw LinkerError.UnrecoverableError(reason: "Bad option: \(arg)")
            }
            guard (option[1] != "") else {
                throw LinkerError.UnrecoverableError(reason: "Bad value for option: \(arg)")
            }
            options[option[0]] = option[1]
        } else {
            sources.append(arg)
        }
    }

    guard sources.count > 0 else {
        throw LinkerError.UnrecoverableError(reason: "No source files specified!")
    }
    options["sources"] = sources

    guard options["--output"] != nil else {
        throw LinkerError.UnrecoverableError(reason: "No output file specified")
    }

    return options
}


do {
    try processSourceFile(parseArgs())
} catch LinkerError.UnrecoverableError(let reason) {
    print("Error processing arguments: \(reason)")
    exit(EXIT_FAILURE)
}
