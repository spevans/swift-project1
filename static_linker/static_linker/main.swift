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


class binarySection {
    let name: String
    var baseAddress:   UInt64 = 0
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


    func addSection(section: LoadCommandSegmentSection64, fileInfo: FileInfo) throws -> UInt64 {
        if section.align > 1 {
            let diff = sectionData.length % Int(section.align)
            if diff > 0 {
                let fillerByte: UInt8 = (name == "__TEXT") ? 0x90 : 0x00
                let length = Int(section.align) - diff
                let filler = Array<UInt8>(count:length, repeatedValue:UInt8(fillerByte))
                sectionData.appendData(NSData(bytes:filler, length:length))
            }
        }
        let sectionStart = UInt64(sectionData.length)

        guard let data = section.sectionData else {
            throw LinkerError.UnrecoverableError(reason: "Cant read data")
        }
        sectionData.appendData(data)
        for symbol in fileInfo.symbolTable.symbols {
            if Int(symbol.sectionNumber) == section.sectionNumber {
                symbolInfo[symbol.name] = (symbol.value - section.addr) + sectionStart
                symbolOrder.append(symbol.name)
            }
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
            var address: Int64 = 0              // The value to be patched into memory
            var symAddr: UInt64 = 0             // The address of the symbol or section that is the target
            let length = Int(1 << reloc.length) // Number of bytes to modify
            print(reloc)
            if reloc.extern {
                // Target is a symbol
                let symbols = fileInfo.symbolTable.symbols
                let symbolName: String? = reloc.extern ? symbols[Int(reloc.symbolNum)].name : nil
                guard let addr = map[symbolName!] else {
                    throw LinkerError.UnrecoverableError(reason: "Undefined symbol: \(symbolName!)")
                }
                symAddr = addr
            } else {
                // Target is in another section
                symAddr = 0 //fileInfo.sectionBaseAddrs[Int(reloc.symbolNum)]! + baseAddress
                if (reloc.PCRelative) {
                    // Other sections in the same segment are contiguous and if the reloc is pc relative then
                    // there shouldnt be anything to relocate for now (may change if sections dont end up being
                    // contiguous)
                    continue
                }
            }

            // Offset into the bytes of this segment that will updated
            let offset = Int(reloc.address) + Int(fileInfo.sectionBaseAddrs[section.sectionNumber]!)
            if (reloc.PCRelative) {
                // The absolute address needs to be made relative to the symbol being patched
                let pc = (baseAddress + UInt64(offset + length))
                address = Int64(symAddr) - Int64(pc)
                print(String(format:"pc: %08X symAddr: %08X baseAddr: %08X address: %08X",
                    pc, symAddr, baseAddress, address))
            }
            //print(String(format: "Updating location %0X length = \(reloc.length) with %016X", reloc.address, address))
            print(String(format: "symAddr: %08X offset: %d/%04X length: %d", symAddr, offset, offset,length))

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
                ptr.memory += Int8(address)

            case 2:
                guard address <= Int64(Int16.max) else {
                    throw LinkerError.UnrecoverableError(reason: "Bad address \(address) for Int16")
                }
                let ptr = UnsafeMutablePointer<Int16>(relocAddr)
                ptr.memory += Int16(littleEndian: Int16(address))

            case 4:
                guard address <= Int64(Int32.max) else {
                    throw LinkerError.UnrecoverableError(reason: "Bad address \(address) for Int32")
                }
                let ptr = UnsafeMutablePointer<Int32>(relocAddr)
                ptr.memory += Int32(littleEndian: Int32(address))

            case 8:
                let ptr = UnsafeMutablePointer<Int64>(relocAddr)
                ptr.memory += Int64(littleEndian: address)

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
                throw LinkerError.UnrecoverableError(reason: "\(k) is already defined")
            } else {
                self.updateValue(v as! Value, forKey: k as! Key)
            }
        }
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


func writeMapToFile(filename: String, map: [String:UInt64]) throws {
    let sortedMap = map.sort({ return $0.1 < $1.1 })

    let mapFile = try openOutput(filename)
    for (symbol, addr) in sortedMap {
        let str = String(format: "%08X: %@\n", addr, symbol)
        mapFile.writeData(str.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
        print(str, terminator:"")
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


class FileInfo {
    let symbolTable: LoadCommandSymTab
    var sectionBaseAddrs: [Int:UInt64] = [:]

    init(symbolTable: LoadCommandSymTab) {
        self.symbolTable = symbolTable
    }
}


func processDylib(args: [String:AnyObject]) throws {
    let sources = args["sources"] as! [String]
    let destBinary = args["--output"] as! String
    let textSection = binarySection("__TEXT")
    let dataSection = binarySection("__DATA")

    for source in sources {
        guard let srcLibData = MachOReader(filename: source) else {
            throw LinkerError.UnrecoverableError(reason: "Cannot parse \(source)")
        }

        do {
            for cmd in 0..<srcLibData.header!.ncmds {
                if let lcHdr : LoadCommand.LoadCommandHdr = try srcLibData.getLoadCommand(cmd) {
                    if let loadCmd = LoadCommand(header: lcHdr, reader: srcLibData).parse() {
                        print("Cmd: \(cmd) loadCmd:", loadCmd.description)
                    } else {
                        print("Cmd: \(cmd): \(lcHdr)")
                    }
                } else {
                    print("Cannot read load command header: \(cmd)")
                }
            }
        } catch {
            throw LinkerError.UnrecoverableError(reason: "Parse Error")
        }

        let loadSegment = srcLibData.loadCommandSegment

        let fileInfo = FileInfo(symbolTable: srcLibData.symbolTable)
        for section in loadSegment.sections {
            if section.segmentName == "__TEXT" {
                let sectionStart = try textSection.addSection(section, fileInfo: fileInfo)
                fileInfo.sectionBaseAddrs[section.sectionNumber] = sectionStart
            } else if section.segmentName == "__DATA" {
                let sectionStart = try dataSection.addSection(section, fileInfo: fileInfo)
                fileInfo.sectionBaseAddrs[section.sectionNumber] = sectionStart
            } else {
                //throw LinkerError.UnrecoverableError(reason: "Unknown section: \(section.segmentName)")
                print("Skipping section: \(section.segmentName)");
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
    }

    var dataAddr = textSection.baseAddress + textSection.currentOffset
    dataAddr = (dataAddr + sectionAlign-1) & ~(sectionAlign-1)
    dataSection.baseAddress = dataAddr

    // Update symbol locations and relocate
    var map = textSection.symbolMap()
    try map.mergeSymbols(dataSection.symbolMap())

    print(map)
    try textSection.relocate(map: map)
    try dataSection.relocate(map: map)


    let outputFile = try openOutput(destBinary)
    outputFile.writeData(textSection.sectionData)
    let dataOffset = dataSection.baseAddress - textSection.baseAddress
    outputFile.seekToFileOffset(dataOffset)
    outputFile.writeData(dataSection.sectionData)
    outputFile.closeFile()
    if let mapfile = args["--mapfile"] as? String {
        try writeMapToFile(mapfile, map: map)
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
    try processDylib(parseArgs())
} catch LinkerError.UnrecoverableError(let reason) {
    print("Error processing arguments: \(reason)")
    exit(EXIT_FAILURE)
}
