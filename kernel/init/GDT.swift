/*
 * kernel/init/GDT.swift
 *
 * Created by Simon Evans on 31/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Setup a new GDT in the BSS as the GDT used for booting was
 * in low memory. Long mode doesnt really care about the GDT
 * so the entries are just the bare minimum for code and data
 * and an extra one for the Thread Local Storage stored in FS
 *
 */

private var gdt = theGDT()
private var gdtInfo = dt_info(size: UInt16(strideof(theGDT) - 1), address: &gdt)


// Helper method to construct a GDT entry
private func GDTEntry(base base: UInt64, limit: UInt64, privLevel: UInt, executable: Bool,
    conforming: Bool, readWrite: Bool) -> UInt64 {

        let word0 = limit & 0xffff
        let word1 = base & 0xffff

        var accessByte: UInt64 = 0
        accessByte |= readWrite ? 2 : 0
        accessByte |= conforming ? 4 : 0
        accessByte |= executable ? 8 : 0
        accessByte |= 16    // must be 1
        accessByte |= UInt64((privLevel & 3) << 5)
        accessByte |= 128   // present bit
        accessByte <<= 8
        let word2 = ((base >> 16) & 0xff) | accessByte

        // Granularity = 0 (bytes) Sz = 1 (32bit)
        let flags: UInt64 = executable ? 0x20 : 0
        let word3: UInt64 = 0 | flags
        let entry = word0 | word1 << 16 | word2 << 32 | word3 << 48

        return entry;
}


struct theGDT {
    var nullDescriptor = 0
    var codeSeg = GDTEntry(base: 0, limit: 0, privLevel: 0, executable: true, conforming: false, readWrite: true)
    var dataSeg = GDTEntry(base: 0, limit: 0, privLevel: 0, executable: false, conforming: false, readWrite: true)
    var TLSSeg = GDTEntry(base: 0x1ff8, limit: 0, privLevel: 0, executable: false, conforming: false, readWrite: true)
}


public func setupGDT() {
    print("Initialising GDT:")
    var currentGdtInfo = dt_info(size: 0, address: nil)
    sgdt(&currentGdtInfo)
    String.printf("Current GDTInfo: %p/%u\n", currentGdtInfo.address, currentGdtInfo.size)
    lgdt(&gdtInfo)

    // Below is not really needed except to validate that the setup worked ok
    sgdt(&currentGdtInfo)
    String.printf("New GDTInfo: %p/%u\n", currentGdtInfo.address, currentGdtInfo.size)
    reload_segments()
}
