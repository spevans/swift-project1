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

let CODE_SEG: UInt16 = 0x8
let TSS_SEG: UInt16 = 0x20

typealias GDTEntry = UInt64
private var gdt = theGDT()
private var gdtInfo = dt_info(
    limit: UInt16(MemoryLayout<theGDT>.size - 1),
    base: &gdt
)


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


private func mkTSS(base: UnsafeRawPointer, limit: UInt32, privLevel: UInt)
    -> gdt_system_entry {

    precondition(limit < (1 << 20))
    precondition(privLevel < 4)

    let _base = BitArray64(UInt(bitPattern: base))
    let _limit = BitArray32(limit)
    var entry = gdt_system_entry()
    entry.limit00_15 = UInt16(_limit[0...15])
    entry.limit16_19 = _limit[16...19]

    entry.base00_15 = UInt16(_base[0...15])
    entry.base16_23 = UInt32(_base[16...23])
    entry.base24_31 = UInt8(_base[24...31])
    entry.base32_63 = UInt32(_base[32...63])

    entry.type = UInt32(GateType.TSS_DESCRIPTOR.rawValue)
    entry.dpl = UInt32(privLevel)
    entry.present = 1
    entry.available = 0
    entry.granularity = 0 // Bytes
    entry.zero0 = 0
    entry.zero1 = 0
    entry.reserved = 0

    return entry
}


private var taskStateSegment = task_state_segment(
    reserved0: 0,
    rsp0: 0,
    rsp1: 0,
    rsp2: 0,
    reserved1: 0,
    ist1: UInt64(_ist1_stack_top_addr),
    ist2: 0,
    ist3: 0,
    ist4: 0,
    ist5: 0,
    ist6: 0,
    ist7: 0,
    reserved2: 0,
    reserved3: 0,
    io_map_addr: 0
)


private struct theGDT {
    // 0x0
    let nullDescriptor: GDTEntry = 0

    // 0x8
    let codeSeg = mkGDTEntry(privLevel: 0, executable: true,
        conforming: false, readWrite: true)

    // 0x10
    let dataSeg = mkGDTEntry(privLevel: 0, executable: false,
        conforming: false, readWrite: true)

    // 0x18
    let TLSSeg = mkGDTEntry(base: UInt(bitPattern: initial_tls_end_addr),
        privLevel: 0, executable: false, conforming: false, readWrite: true)

    // 0x20
    let tssSeg = mkTSS(base: &taskStateSegment,
        limit: UInt32(MemoryLayout<task_state_segment>.size - 1), privLevel: 0)
}


func setupGDT() {
    print("GDT: Initialising..")
    // The TLS points back to itself so set the address
    //let tlsPtr = initial_tls_end_addr.bindMemory(to: UInt.self, capacity: 1)
    //tlsPtr.pointee = UInt(bitPattern: initial_tls_end_addr)

    func printGDT(_ msg: String, _ gdt: dt_info) {
        print("GDT:", msg, terminator: "")
        printf(": Info: %p/%u\n", UInt(bitPattern: gdt.base), gdt.limit)
    }

    var currentGdtInfo = dt_info(limit: 0, base: nil)
    sgdt(&currentGdtInfo)
    printGDT("Current", currentGdtInfo)
    lgdt(&gdtInfo)
    print("Loading task register")
    ltr(TSS_SEG)
    print("TSS loaded")

    // Below is not really needed except to validate that the setup worked ok
    sgdt(&currentGdtInfo)
    printGDT("New", currentGdtInfo)
    reload_segments()
}
