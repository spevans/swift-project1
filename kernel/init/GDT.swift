/*
 * kernel/init/GDT.swift
 *
 * Created by Simon Evans on 31/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Routines to add entries into the GDT. The table space is declared in
 * main.asm. Currently only a TSS is added so that an interrupt stack
 * can be set.
 */

typealias GDTEntry = UInt64

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



func setupGDT() {
    func printGDT(_ msg: String, _ gdt: dt_info) {
        print("GDT:", msg, terminator: "")
        printf(": Info: %#x/%u\n", UInt(bitPattern: gdt.base), gdt.limit)
    }

    func asRawPointer(_ x: UnsafeRawPointer) -> UnsafeRawPointer {
        return x
    }

    var currentGdtInfo = dt_info(limit: 0, base: nil)
    sgdt(&currentGdtInfo)
    printGDT("Current", currentGdtInfo)

    // Set IST1 in the TSS
    let tssPtr = UnsafeMutableRawPointer(mutating: asRawPointer(&task_state_segment))
    let tss = tssPtr.bindMemory(to: task_state_segment.self, capacity: 1)
    tss.pointee.ist1 = UInt64(_ist1_stack_top_addr)

    let gdtPtr = UnsafeMutableRawPointer(currentGdtInfo.base)!
    let tssSeg = gdtPtr.advanced(by: Int(TSS_SELECTOR))
        .bindMemory(to: gdt_system_entry.self, capacity: 1)
    tssSeg.pointee = mkTSS(base: &task_state_segment,    // defined in main.asm
        limit: UInt32(MemoryLayout<task_state_segment>.size - 1), privLevel: 0)

    print("Loading task register")
    ltr(UInt16(TSS_SELECTOR))
    print("TSS loaded")
}

func currentGDT() -> dt_info {
    var gdt = dt_info()
    sgdt(&gdt)
    return gdt
}
