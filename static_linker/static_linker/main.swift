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


func bindSegments(bindInfos: [RebaseInfo]) throws {
    for bi in bindInfos {
        guard let dyldInfo = bi.machOFile.dyldInfo else {
            continue
        }

        let pointerSize: UInt64 = 8     // pointer size in bytes for X86_64
        var bindType = BindType.NONE
        var segmentIndex: Int = 0
        var segmentOffset: UInt64 = 0
        var addend: Int64 = 0
        var slide: UInt64?
        var section = ""
        var symbolName = ""
        var ordinal = 0
        var weak_import = ""


        func bindAtAddress() throws {
            let seg = bi.segmentMap[segmentIndex]?.section.sectionType.rawValue
            let bindAddress = bi.machOFile.loadCommandSegments[segmentIndex].vmaddr &+ segmentOffset // allow wrap
            print(String(format: "bindAtAddress \(section) bind @ \(seg!) 0x%08X  ", bindAddress), terminator: "")

            switch(bindType) {
            case .POINTER, .ABSOLUTE32:
                // FIXME: do the update
                print(String(format: "%@ %d %@", String(bindType).lowercaseString, addend, symbolName))

            default:
                throw LinkerError.UnrecoverableError(reason: "Bad bindType: \(bindType)")
            }
        }


        func bindCallback(opcode opcode: BindOpcode, immValue: UInt8, uval1: UInt64?, uval2: UInt64?, sval: Int64?,
            symbol:String, opcodeAddr: Int) throws {

                switch opcode {
                case .BIND_OPCODE_DONE:
                    break

                case .BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
                    ordinal = Int(immValue)

                case .BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
                    ordinal = Int(uval1!)

                case .BIND_OPCODE_SET_DYLIB_SPECIAL_IMM:
                    if immValue != 0 {
                        let signExtend = Int8(BindOpcode.OPCODE_MASK | immValue)
                        ordinal = Int(signExtend)
                    } else {
                        ordinal = 0
                    }

                case .BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM:
                    symbolName = symbol
                    if (immValue & UInt8(BindOpcode.BIND_SYMBOL_FLAGS_WEAK_IMPORT)) != 0 {
                        weak_import = "weak"
                    } else {
                        weak_import = ""
                    }


                case .BIND_OPCODE_SET_TYPE_IMM:
                    bindType = BindType(rawValue: immValue)!

                case .BIND_OPCODE_SET_ADDEND_SLEB:
                    addend = sval!

                case .BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                    segmentIndex = Int(immValue)
                    segmentOffset = uval1!

                case .BIND_OPCODE_ADD_ADDR_ULEB:
                    // Allow overflow as wrap
                    segmentOffset = segmentOffset &+ uval1! &+ pointerSize

                case .BIND_OPCODE_DO_BIND:
                    try bindAtAddress()
                    segmentOffset = segmentOffset &+ pointerSize

                case .BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB:
                    try bindAtAddress()
                    // Allow overflow as wrap
                    segmentOffset = segmentOffset &+ uval1! &+ pointerSize

                case .BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
                    try bindAtAddress()
                    let inc = UInt64(immValue) * pointerSize
                    segmentOffset += inc + pointerSize

                case .BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB:
                    try bindAtAddress()
                    let count = uval1!
                    let inc = uval2!
                    for _ in 0..<count {
                        try bindAtAddress()
                        segmentOffset += inc
                    }
                }
        }

        section = "bind"
        try dyldInfo.runBindSection("bind", callback: bindCallback)
        section = "weak"
        try dyldInfo.runBindSection("weak", callback: bindCallback)
        section = "lazy"
        try dyldInfo.runBindSection("lazy", callback: bindCallback)
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
    try bindSegments(rebaseInfos)

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
