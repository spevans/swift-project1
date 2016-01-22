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
private var gdtInfo = dt_info(limit: UInt16(strideof(theGDT) - 1), address: &gdt)


// Helper method to construct a GDT entry
private func GDTEntry(base base: UInt32, privLevel: UInt, executable: Bool,
    conforming: Bool, readWrite: Bool) -> UInt64 {

        let loWord = (base << 16) & 0xffff0000   // limit is ignored so set to 0

        var accessByte: UInt32 = 0
        accessByte |= readWrite ? 1 << 9 : 0
        accessByte |= conforming ? 1 << 10 : 0
        accessByte |= executable ? 1 << 11 : 0
        accessByte |= 1 << 12    // must be 1    // code/data segment
        accessByte |= UInt32((privLevel & 3) << 13)
        accessByte |= 1 << 15   // present bit

        var hiWord = ((base >> 16) & 0xff) | accessByte

        // Granularity = 0 (bytes) Sz = 1 (32bit)
        hiWord |= executable ? 1 << 21 : 0
        hiWord |= (base & 0xff000000)

        let entry = UInt64(hiWord) << 32 | UInt64(loWord)
        kprintf("entry = %p\n", entry)
        return entry;
}


private struct theGDT {
    var nullDescriptor = 0
    var codeSeg = GDTEntry(base: 0, privLevel: 0, executable: true, conforming: false, readWrite: true)
    var dataSeg = GDTEntry(base: 0, privLevel: 0, executable: false, conforming: false, readWrite: true)
    var TLSSeg = GDTEntry(base: UInt32(initial_tls_end_addr), privLevel: 0, executable: false, conforming: false, readWrite: true)
}


public func setupGDT() {
    kprint("Initialising GDT:")
    let tlsPtr = UnsafeMutablePointer<UInt>(bitPattern: initial_tls_end_addr)
    tlsPtr.memory = initial_tls_end_addr

    var currentGdtInfo = dt_info(limit: 0, address: nil)
    sgdt(&currentGdtInfo)
    kprintf("Current GDTInfo: %p/%u\n", currentGdtInfo.address, currentGdtInfo.limit)
    lgdt(&gdtInfo)

    // Below is not really needed except to validate that the setup worked ok
    sgdt(&currentGdtInfo)
    kprintf("New GDTInfo: %p/%u\n", currentGdtInfo.address, currentGdtInfo.limit)
    reload_segments()
}
