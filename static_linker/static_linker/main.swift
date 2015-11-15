//
//  main.swift
//  static_linker
//
//  Created by Simon Evans on 03/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation



class binarySection {
    let name: String
    var baseAddress:   UInt64 = 0
    var currentOffset: UInt64 = 0
    var sectionData    = NSMutableData()
    var symbolInfo:    [String: UInt64] = [:]
    var symbolOrder:   [String] = []
    var relocations:   [LoadCommandSegmentSection64.Relocation] = []


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


    func addSection(section: LoadCommandSegmentSection64, symbols: [LoadCommandSymTab.Symbol]) {
        if section.align > 1 {
            let diff = sectionData.length % Int(section.align)
            if diff > 0 {
                sectionData.increaseLengthBy(Int(section.align) - diff)
            }
        }

        guard let data = section.sectionData else {
            print("Cant read data")
            exit(EXIT_FAILURE)
        }
        sectionData.appendData(data)
        for symbol in symbols {
            symbolInfo[symbol.name] = (symbol.value - section.addr) //+ currentOffset
            symbolOrder.append(symbol.name)
        }

        guard let relocs = section.relocations else {
            print("Null relocations")
            exit(EXIT_FAILURE)
        }
        relocations.appendContentsOf(relocs)
        currentOffset = UInt64(sectionData.length)
    }


    func symbolMap() -> [String:UInt64] {
        var map: [String:UInt64] = [:]

        for symbol in symbolInfo {
            map[symbol.0] = symbol.1 + baseAddress
        }

        return map
    }


    func relocate(map map: [String:UInt64], symbols: [LoadCommandSymTab.Symbol]) {
        for reloc in relocations {
            let symbolName = symbols[Int(reloc.symbolNum)].name
            var address = map[symbolName]!
            print(String(format: "Updating location %0X length = \(reloc.length) with %016X", reloc.address, address))
            let length = Int(1 << reloc.length)
            let offset = Int(reloc.address)

            if (reloc.PCRelative) {
                // The absolute address needs to be made relative to the symbol being patched
                let pc = (baseAddress + UInt64(offset + length))
                address -= pc
            }
            guard (offset + length) <= sectionData.length else {
                print("Bad offset \(offset + length) > \(sectionData.length)")
                exit(EXIT_FAILURE)
            }
            let relocAddr = UnsafePointer<Void>(sectionData.bytes + offset)

            switch (length) {
            case 1:
                guard address <= UInt64(UInt8.max) else {
                    print("Bad address \(address) for UInt8")
                    exit(EXIT_FAILURE)
                }
                let ptr = UnsafeMutablePointer<UInt8>(relocAddr)
                ptr.memory = UInt8(address)

            case 2:
                guard address <= UInt64(UInt16.max) else {
                    print("Bad address \(address) for UInt16")
                    exit(EXIT_FAILURE)
                }
                let ptr = UnsafeMutablePointer<UInt16>(relocAddr)
                ptr.memory = UInt16(littleEndian: UInt16(address))

            case 4:
                guard address <= UInt64(UInt32.max) else {
                    print("Bad address \(address) for UInt32")
                    exit(EXIT_FAILURE)
                }
                let ptr = UnsafeMutablePointer<UInt32>(relocAddr)
                ptr.memory = UInt32(littleEndian: UInt32(address))

            case 8:
                let ptr = UnsafeMutablePointer<UInt64>(relocAddr)
                ptr.memory = UInt64(littleEndian: address)

            default:
                print("Unknown length \(length)")
                exit(EXIT_FAILURE)
            }
        }
    }
}

extension Dictionary {
    mutating func mergeSymbols<K, V>(dict: [K: V]){
        for (k, v) in dict {
            if (self[k as! Key] != nil) {
                print("\(k) is already defined")
                exit(EXIT_FAILURE)
            } else {
            self.updateValue(v as! Value, forKey: k as! Key)
            }
        }
    }
}


func openOutput(filename: String) -> NSFileHandle {
    if NSFileManager.defaultManager().createFileAtPath(filename, contents: nil, attributes: nil) {
        let output = NSFileHandle(forWritingAtPath: filename)
        if output != nil {
            return output!
        }
    }

    print("Cant open output file: \(filename)")
    exit(EXIT_FAILURE)
}


func writeMapToFile(filename: String, map: [String:UInt64]) {
    let sortedMap = map.sort({ return $0.1 < $1.1 })

    let mapFile = openOutput(filename)
    for (symbol, addr) in sortedMap {
        let str = String(format: "%08X: %@\n", addr, symbol)
        mapFile.writeData(str.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!)
        print(str, terminator:"")
    }
    mapFile.closeFile()
}


func processDylib(srcLib: String, destBinary: String) {
    print("Converting \(srcLib) to \(destBinary)")

    guard let srcLibData = MachOReader(filename: srcLib) else {
        print("Cannot parse \(srcLib)")
        exit(EXIT_FAILURE)
    }

    do {
        for cmd in 0...srcLibData.header!.ncmds-1 {
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
        print("Parse Error")
        exit(EXIT_FAILURE)
    }

    let loadSegment = srcLibData.loadCommandSegment
    let symTab = srcLibData.symbolTable;
    let textSection = binarySection("__TEXT")
    let dataSection = binarySection("__DATA")

    var sectionNum = 1
    for section in loadSegment.sections {
        if section.segmentName == "__TEXT" {
            textSection.addSection(section, symbols: symTab.symbolsInSection(sectionNum))
        } else if section.segmentName == "__DATA" {
            dataSection.addSection(section, symbols: symTab.symbolsInSection(sectionNum))
        } else {
            print("Unknown section: \(section.segmentName)")
            exit(EXIT_FAILURE)
        }
        sectionNum++
    }

    let sectionAlign:UInt64 = 4096 // page size

    textSection.baseAddress = 0x100000
    textSection.printInfo()

    var dataAddr = textSection.baseAddress + textSection.currentOffset
    dataAddr = (dataAddr + sectionAlign-1) & ~(sectionAlign-1)
    dataSection.baseAddress = dataAddr
    dataSection.printInfo()

    // Update symbol locations and relocate
    var map = textSection.symbolMap()
    map.mergeSymbols(dataSection.symbolMap())

    print(map)
    textSection.relocate(map: map, symbols: symTab.symbols)


    let outputFile = openOutput(destBinary)
    outputFile.writeData(textSection.sectionData)
    let dataOffset = dataSection.baseAddress - textSection.baseAddress
    outputFile.seekToFileOffset(dataOffset)
    outputFile.writeData(dataSection.sectionData)
    outputFile.closeFile()
    writeMapToFile("mapfile", map: map)
}


var args = Process.arguments
if (args.count > 2) {
    processDylib(args[1], destBinary:args[2])
} else {
    print("Usage: \(args[0]) srcLib destBinary")
}
