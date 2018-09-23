/*
 * kernel/mm/symbols.swift
 *
 * Created by Simon Evans on 13/01/2018.
 * Copyright © 2018 Simon Evans. All rights reserved.
 *
 * Symbol lookup
 */


private var _symbolTablePtr: UnsafePointer<Elf64_Sym>? = nil
private var _symbolCount = 0
private var _stringTablePtr: UnsafePointer<CChar>? = nil
private var _stringTableSize = 0


func symbolLookupInit(bootParams: BootParams) {
    // Check if already initialised
    guard _symbolTablePtr == nil else {
        return
    }

    guard
        let symbolTablePtr = bootParams.symbolTablePtr,
        let stringTablePtr = bootParams.stringTablePtr else {
        return
    }

    _symbolCount = Int(bootParams.symbolTableSize) / MemoryLayout<Elf64_Sym>.stride

    guard _symbolCount > 0 else {
        print("Empty symbol table")
        return
    }

    guard bootParams.stringTableSize > 0 else {
        print("Empty string table")
        return
    }

    let p = UnsafeMutablePointer<Elf64_Sym>(mutating: symbolTablePtr)
    var symbols = UnsafeMutableBufferPointer(start: p,
                                             count: _symbolCount)
    symbols.sort {
        $0.st_value < $1.st_value
    }
    // TODO: Remap the memory as RO now it has been sorted
    _symbolTablePtr = symbolTablePtr
    _stringTablePtr = stringTablePtr
    _stringTableSize = Int(bootParams.stringTableSize)
}


func showSymbolAt(addr: VirtualAddress) {
    if let sym = lookupSymbolBy(addr: addr) {
        print("Found symbol:", sym)
        let name = symbolName(sym.st_name)
        print("Name:", name ?? "name not found")
    } else {
        printf("Cant find symbol for address %p\n", addr)
    }
}


func showSymbols() {
    print("Dumping \(_symbolCount) symbols")
    guard _symbolCount > 0 else {
        return
    }
    guard let ptr = _symbolTablePtr else {
        return
    }
    var count = 0
    for symIdx in 0..<_symbolCount {
        let symbolPtr = ptr.advanced(by: symIdx)
        let symbol = symbolPtr.pointee
        printf("%016lx: %08x: ", symbol.st_value, symbol.st_size)
        print(symbolName(symbol.st_name) ?? "unknown")

        count = count + 1
        if count > 100 { return }
    }
}


@_cdecl("dladdr")
public func dladdr(addr: UnsafeRawPointer, info: UnsafeMutablePointer<Dl_info>) -> Int32 {
    let vaddr = VirtualAddress(addr.address)
    guard vaddr >= _kernel_start_addr || vaddr <= _kernel_end_addr else {
        return 0
    }
    info.pointee.dli_fname = nil
    info.pointee.dli_fbase = UnsafeMutableRawPointer(mutating: _kernel_start)

    if let symbol = lookupSymbolBy(addr: vaddr) {
        info.pointee.dli_sname = symbolNameCPtr(symbol.st_name)
        info.pointee.dli_saddr = UnsafeMutableRawPointer(bitPattern: UInt(symbol.st_value))
    } else {
        info.pointee.dli_sname = nil
        info.pointee.dli_saddr = nil
    }
    return 1
}


func lookupSymbolBy(addr: VirtualAddress) -> Elf64_Sym? {
    guard let ptr = _symbolTablePtr else {
        return nil
    }
    // TODO: Use a binary search as the array is sorted
    for symIdx in 0..<_symbolCount {
        let symPtr = ptr.advanced(by: Int(symIdx))
        if addr >= symPtr.pointee.st_value &&
            addr <= symPtr.pointee.st_value + symPtr.pointee.st_size {
            return symPtr.pointee
        }
    }
    return nil
}


private func symbolNameCPtr(_ idx: UInt32) -> UnsafePointer<CChar>? {
    guard idx < _stringTableSize else {
        return nil
    }
    guard let ptr = _stringTablePtr else {
        return nil
    }

    return ptr.advanced(by: Int(idx))
}


private func symbolName(_ idx: UInt32) -> String? {
    guard idx < _stringTableSize else {
        return nil
    }
    guard let ptr = _stringTablePtr else {
        return nil
    }

    var result = ""
    var offset = Int(idx)
    while (UInt64(offset) < _stringTableSize) {
        let ch = ptr.advanced(by: offset).pointee
        if ch == 0 {
            break
        }
        result.append(Character(UnicodeScalar(UInt8(ch))))
        offset = offset + 1
    }
    return result
}

