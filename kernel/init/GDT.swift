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

let CODE_SEG: UInt16 = 8

typealias GDTEntry = UInt64
private var gdt = theGDT()
private var gdtInfo = dt_info(limit: UInt16(MemoryLayout<theGDT>.size - 1), base: &gdt)


// Helper method to construct a GDT entry, base is ignored by the CPU
// for most selectors so default it
private func mkGDTEntry(base: UInt = 0, privLevel: UInt, executable: Bool,
    conforming: Bool, readWrite: Bool) -> GDTEntry {

    assert(base < UInt(UInt32.max))
    let base32 = UInt32(base)
    let loWord = (base32 << 16) & 0xffff0000   // limit is ignored so set to 0

    var accessByte: UInt32 = 0
    accessByte |= readWrite ? 1 << 9 : 0
    accessByte |= conforming ? 1 << 10 : 0
    accessByte |= executable ? 1 << 11 : 0
    accessByte |= 1 << 12    // must be 1    // code/data segment
    accessByte |= UInt32((privLevel & 3) << 13)
    accessByte |= 1 << 15   // present bit

    var hiWord = ((base32 >> 16) & 0xff) | accessByte

    // Granularity = 0 (bytes) Sz = 1 (32bit)
    hiWord |= executable ? 1 << 21 : 0
    hiWord |= (base32 & 0xff000000)

    let entry = UInt64(hiWord) << 32 | UInt64(loWord)

    return entry;
}


private struct theGDT {
    let nullDescriptor: GDTEntry = 0
    var codeSeg = mkGDTEntry(privLevel: 0, executable: true,
        conforming: false, readWrite: true)
    var dataSeg = mkGDTEntry(privLevel: 0, executable: false,
        conforming: false, readWrite: true)
    var TLSSeg = mkGDTEntry(base: UInt(bitPattern: initial_tls_end_addr),
        privLevel: 0, executable: false, conforming: false, readWrite: true)
}


func setupGDT() {
    print("Initialising GDT:")
    // The TLS points back to itself so set the address
    let tlsPtr = initial_tls_end_addr.bindMemory(to: UInt.self, capacity: 1)
    tlsPtr.pointee = UInt(bitPattern: initial_tls_end_addr)

    func printGDT(_ msg: String, _ gdt: dt_info) {
        print(msg, terminator: "")
        printf(" GDTInfo: %p/%u\n", UInt(bitPattern: gdt.base), gdt.limit)
    }

    var currentGdtInfo = dt_info(limit: 0, base: nil)
    sgdt(&currentGdtInfo)
    printGDT("Current", currentGdtInfo)
    lgdt(&gdtInfo)

    // Below is not really needed except to validate that the setup worked ok
    sgdt(&currentGdtInfo)
    printGDT("New", currentGdtInfo)
    reload_segments()
}
