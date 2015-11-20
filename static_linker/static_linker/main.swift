//
//  main.swift
//  static_linker
//
//  Created by Simon Evans on 03/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


// FIXME: remove after debugging
var globalMap: [String:LoadCommandSymTab.Symbol] = [:]
enum LinkerError: ErrorType {
    case UnrecoverableError(reason: String)
}


class binarySection {
    let name: String
    var baseAddress:   UInt64 = 0               // base address of this section
    var startAddress:   UInt64 = 0              // base address of complete binary (--baseAddress argument)
    var currentOffset: UInt64 = 0
    var sectionData    = NSMutableData()
    var symbolInfo:    [String: UInt64] = [:]
    var symbolOrder:   [String] = []
    var relocations:   [(LoadCommandSegmentSection64, FileInfo)] = []


    init(_ name: String) {
        self.name = name
    }


    func printInfo() {
        print("\(name) Symbols:")
        for symbol in symbolOrder {
            let offset: UInt64 = baseAddress + symbolInfo[symbol]!
            print(String(format: "%@: %016X", symbol, offset))
        }
        print("Relocations:")
        for reloc in relocations {
            print("Reloc: \(reloc)")
        }
    }

    func align(addr: UInt64, alignment: UInt64) -> UInt64 {
        if (alignment > 0) {
            let mask = alignment - 1
            return (addr + mask) & ~mask
        }
        return addr
    }

    func addSection(segment: LoadCommandSegment64, section: LoadCommandSegmentSection64, fileInfo: FileInfo) throws -> UInt64 {
        print("Adding section nr \(section.sectionNumber): \(section.segmentName):\(section.sectionName)")

        // Pad section upto next alignment
        let alignSize = UInt64(1 << section.align)
        let padding = Int(align(UInt64(sectionData.length), alignment:alignSize)) - sectionData.length
        if padding > 0 {
            let fillerByte: UInt8 = (name == "__TEXT") ? 0x90 : 0x00
            let filler = Array<UInt8>(count:padding, repeatedValue:UInt8(fillerByte))
            sectionData.appendData(NSData(bytes:filler, length:padding))
        }
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

        // If there is a dynamic symbol table, use that to get a list of the declared symbols contained in the obj/lib
        // otherwise assume all of the symbols are

        func addSymbols(offset offset: Int, count: Int) {
            let lastIdx = offset + count
            for symIdx in offset..<lastIdx {
                let symbol = fileInfo.machOFile.symbolTable.symbols[symIdx]
                if Int(symbol.sectionNumber) == section.sectionNumber && symbol.type != .UNDF {
                    print("\(symIdx): \(symbol.name)")
                    if globalMap[symbol.name] == nil {
                        globalMap[symbol.name] = symbol
                    } else {
                        print("Found \(symbol.name) already in globalMap")
                    }
                    symbolInfo[symbol.name] = (symbol.value - section.addr) + sectionStart
                    symbolOrder.append(symbol.name)
                }
            }
        }

        if fileInfo.machOFile.dySymbolTable != nil {
            // Add in exported symbols
            addSymbols(offset: Int(fileInfo.machOFile.dySymbolTable!.idxExtDefSym),
                count: Int(fileInfo.machOFile.dySymbolTable!.numExtDefSym))

            // Add in local symbols
            addSymbols(offset: Int(fileInfo.machOFile.dySymbolTable!.idxLocalSym),
                count:Int(fileInfo.machOFile.dySymbolTable!.numLocalSym))
        } else {
            addSymbols(offset: 0, count: fileInfo.machOFile.symbolTable.symbols.count)
        }

        let tuple = (section, fileInfo)
        relocations.append(tuple)
        currentOffset = UInt64(sectionData.length)

        return sectionStart
    }


    func symbolMap() -> [String:UInt64] {
        var map: [String:UInt64] = [:]

        for symbol in symbolInfo {
            map[symbol.0] = symbol.1 + baseAddress
        }

        return map
    }


    func relocate(map map: [String:UInt64]) throws {
        for (section, fileInfo) in relocations {
            try relocateSection(map, section, fileInfo)
        }
    }


    func relocateSection(map: [String:UInt64], _ section: LoadCommandSegmentSection64, _ fileInfo: FileInfo) throws {

        guard let relocs = section.relocations else {
            throw LinkerError.UnrecoverableError(reason: "Null relocations")
        }

        for reloc in relocs {
            switch reloc.type {
            case .X86_64_RELOC_BRANCH, .X86_64_RELOC_SIGNED:
                guard reloc.PCRelative == true else {
                    throw LinkerError.UnrecoverableError(reason: "reloc is not PCRelative")
                }

            case .X86_64_RELOC_UNSIGNED:
                break

            case .X86_64_RELOC_SIGNED_4:
                break

            default:
                throw LinkerError.UnrecoverableError(reason: "Unsupported reloc type: \(reloc.type)")
            }

            var address: Int64 = 0              // The value to be patched into memory
            var symAddr: UInt64 = 0             // The address of the symbol or section that is the target
            let length = Int(1 << reloc.length) // Number of bytes to modify

            // Offset into the bytes of this segment that will updated
            let offset = Int(reloc.address) + Int(fileInfo.sectionBaseAddrs[section.sectionNumber]!)
            let pc = (baseAddress + UInt64(offset + length))

            print(reloc)
            if reloc.extern {
                // Target is a symbol
                let symbols = fileInfo.machOFile.symbolTable.symbols
                let symbolName: String? = reloc.extern ? symbols[Int(reloc.symbolNum)].name : nil
                guard let addr = map[symbolName!] else {
                    throw LinkerError.UnrecoverableError(reason: "Undefined symbol: \(symbolName!)")
                }
                print(symbolName!)
                symAddr = addr
                if (reloc.PCRelative) {
                    address = Int64(symAddr) - Int64(pc)
                } else {
                    throw LinkerError.UnrecoverableError(reason: "PCRelative == false not allowed")
                }
            } else {
                // Target is in another section
                let section = Int(reloc.symbolNum)

                // Where the section was originally supposed to go
                let oldAddr = fileInfo.machOFile.loadCommandSections[section-1].addr
                if (reloc.type == .X86_64_RELOC_UNSIGNED) {
                    symAddr = fileInfo.sectionBaseAddrs[section]! + startAddress
                    address = Int64(symAddr - oldAddr)
                } else {
                    address = Int64(fileInfo.offsetInSegment[section]!) - Int64(oldAddr)
                }
            }

            // The absolute address needs to be made relative to the symbol being patched

            //print(String(format:"pc: %08X relocAddr: %08X symAddr: %08X baseAddr: %08X address: %08X offset: %08X length: %d  ",
             //   pc, reloc.address, symAddr, baseAddress, address, offset, length), terminator:"" )

            //print(String(format: "Updating location %0X length = \(reloc.length) with %016X", reloc.address, address))
            //print(String(format: "symAddr: %08X offset: %d/%04X length: %d", symAddr, offset, offset,length))

            guard (offset + length) <= sectionData.length else {
                throw LinkerError.UnrecoverableError(reason: "Bad offset \(offset + length) > \(sectionData.length)")
            }

            // Pointer to the bytes in the data to actually update
            let relocAddr = UnsafePointer<Void>(sectionData.bytes + offset)

            // The address to patch may not contain 0 it main contain an offset that needs to be added to the address
            let addend: Int8 = (reloc.type == .X86_64_RELOC_UNSIGNED) ? 0 :  UnsafePointer<Int8>(relocAddr).memory
            //print("Addend at location: \(addend)")

            switch (length) {
            case 1:
                guard address <= Int64(Int8.max) else {
                    throw LinkerError.UnrecoverableError(reason: "Bad address \(address) for Int8")
                }
                let ptr = UnsafeMutablePointer<Int8>(relocAddr)
                ptr.memory = Int8(address) + addend

            case 2:
                guard address <= Int64(Int16.max) else {
                    throw LinkerError.UnrecoverableError(reason: "Bad address \(address) for Int16")
                }
                let ptr = UnsafeMutablePointer<Int16>(relocAddr)
                ptr.memory = Int16(littleEndian: Int16(address)) + Int16(addend)

            case 4:
                guard address <= Int64(Int32.max) else {
                    throw LinkerError.UnrecoverableError(reason: "Bad address \(address) for Int32")
                }
                let ptr = UnsafeMutablePointer<Int32>(relocAddr)
                ptr.memory = Int32(littleEndian: Int32(address)) + Int32(addend)

            case 8:
                if (reloc.type == .X86_64_RELOC_UNSIGNED) {
                    let ptr = UnsafeMutablePointer<UInt64>(relocAddr)
                    ptr.memory += UInt64(littleEndian: UInt64(bitPattern: address))
                } else {
                    let ptr = UnsafeMutablePointer<Int64>(relocAddr)
                    ptr.memory = Int64(littleEndian: address) + Int64(addend)
                }

            default:
                throw LinkerError.UnrecoverableError(reason: "Invalid symbol relocation length \(length)")
            }
        }
    }
}

extension Dictionary {
    mutating func mergeSymbols<K, V>(dict: [K: V]) throws {
        for (k, v) in dict {
            if (self[k as! Key] != nil) {
                //throw LinkerError.UnrecoverableError(reason: "\(k) is already defined")
            } else {
                self.updateValue(v as! Value, forKey: k as! Key)
            }
        }
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


func writeMapToFile(filename: String, textMap: [String:UInt64], dataMap: [String:UInt64], bssMap: [String:UInt64],
    textAddr: UInt64, dataAddr: UInt64, bssAddr: UInt64) throws {

        let mapFile = try openOutput(filename)

        func writeSection(name:String, _ map: [String:UInt64], _ baseAddr: UInt64) {
            mapFile.writeString(String(format: "%@ section baseAddress: %08X\n\n", name, baseAddr))
            for (symbol, addr) in map.sort({ return $0.1 < $1.1 }) {
                mapFile.writeString(String(format: "%08X [%10d]: %@\n", addr, addr, symbol))
            }
        }

        writeSection(".text", textMap, textAddr)
        mapFile.writeString("\n\n")
        writeSection(".data", dataMap, dataAddr)
        mapFile.writeString("\n\n")
        writeSection(".bss", bssMap, bssAddr)
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


class FileInfo {
    let machOFile: MachOReader
    var sectionBaseAddrs: [Int:UInt64] = [:]
    var offsetInSegment: [Int:UInt64] = [:]

    init(file: MachOReader) {
        self.machOFile = file
    }
}

var bssSymbols: [String:LoadCommandSymTab.Symbol] = [:]

func findBssSymbols(symbols: [LoadCommandSymTab.Symbol]) throws {
    for symbol in symbols {
        print(symbol)
        if (symbol.sectionNumber == 0) && (symbol.type == .UNDF) && symbol.value > 0 {
            if let sym = bssSymbols[symbol.name] {
                if sym.value != symbol.value {
                    let reason = "Found \(symbol.name) in bss list but it has size \(sym.value) and not \(symbol.value)"
                    throw LinkerError.UnrecoverableError(reason:reason)
                }
            } else {
                bssSymbols[symbol.name] = symbol
            }
        }
    }
}


func processSourceFile(args: [String:AnyObject]) throws {
    let sources = args["sources"] as! [String]
    let destBinary = args["--output"] as! String
    let textSection = binarySection("__TEXT")
    let dataSection = binarySection("__DATA")

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
        }

        for idx in 0..<srcLibData.loadCommands.count {
            print("\(idx): \(srcLibData.loadCommands[idx].description)")
        }

        // These two vars track the offset that sections are copied to, this allows that difference
        // between where a section's addr says it should go and where it ends up (relative to the start of the
        // object file not the start of the total output
        var textAddress: UInt64?
        var dataAddress: UInt64?

        try findBssSymbols(srcLibData.symbolTable.symbols)
        for loadSegment in srcLibData.loadCommandSegments {
            print(loadSegment)
            let fileInfo = FileInfo(file: srcLibData) //symbolTable: srcLibData.symbolTable, dySymbolTable: srcLibData.dySymbolTable)
            for section in loadSegment.sections {
                if section.segmentName == "__TEXT" {
                    var curaddr = textSection.currentOffset
                    let sectionStart = try textSection.addSection(loadSegment, section: section, fileInfo: fileInfo)
                    if textAddress == nil {
                        textAddress = sectionStart
                        curaddr = sectionStart
                    }
                    fileInfo.sectionBaseAddrs[section.sectionNumber] = sectionStart
                    fileInfo.offsetInSegment[section.sectionNumber] = curaddr - textAddress!
                } else if section.segmentName == "__DATA" {
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

    var dataAddr = textSection.baseAddress + textSection.currentOffset
    dataAddr = (dataAddr + sectionAlign-1) & ~(sectionAlign-1)
    dataSection.baseAddress = dataAddr

    // Update symbol locations and relocate
    let textMap = textSection.symbolMap()
    let dataMap = dataSection.symbolMap()
    var map = textMap
    try map.mergeSymbols(dataMap)

    // Put the BSS after the data section and align to 8 bytes
    let dataEnd = dataSection.baseAddress + dataSection.currentOffset
    let bssBaseAddr: UInt64 = (dataEnd + 7) & ~7
    let bssFileOffset = bssBaseAddr - dataEnd

    // Create bss from BSS symbols
    print("BSS symbols: \(bssSymbols)")

    var bssMap: [String:UInt64] = [:]
    var bssOffset: UInt64 = 0
    for symbol in bssSymbols {
        bssMap[symbol.0] = bssBaseAddr + bssOffset
        bssOffset += UInt64(symbol.1.value)
    }
    try map.mergeSymbols(bssMap)


    // Find all of the symbols refernced in the BSS and allocate them an address
    //print(map)
    try textSection.relocate(map: map)
    try dataSection.relocate(map: map)


    let outputFile = try openOutput(destBinary)
    outputFile.writeData(textSection.sectionData)
    let dataOffset = dataSection.baseAddress - textSection.baseAddress
    outputFile.seekToFileOffset(dataOffset)
    outputFile.writeData(dataSection.sectionData)

    print("bssFileOffset = \(bssFileOffset)")
    let bssFileSz = bssOffset
    print("bssFileSz = \(bssFileSz)")
    let bss = NSMutableData()
    bss.increaseLengthBy(Int(bssFileOffset + bssFileSz + 100))
    outputFile.writeData(bss)


    outputFile.closeFile()
    if let mapfile = args["--mapfile"] as? String {
        try writeMapToFile(mapfile, textMap: textMap, dataMap: dataMap, bssMap: bssMap,
            textAddr: textSection.baseAddress, dataAddr: dataSection.baseAddress, bssAddr: bssBaseAddr)
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
