/*
 * kernel/traps/IDT.swift
 *
 * Created by Simon Evans on 01/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Setup a new IDT in the BSS as the IDT used for booting was in
 * memory that will be reclaimed. This mostly adds static entries
 * into the idt declared in kernel/init/bss.c and could probably
 * be done more easily in entry.asm without having to export the
 * exceptio stub addresses to Swift but its mostly an exercise in
 * manipulating C structs and arrays with the storage declared
 * in a .c file
 *
 */


// FIXME when strideof can be used with arrays
private let idtSize = NR_INTERRUPTS * MemoryLayout<idt_entry>.size
private var idtInfo = dt_info(limit: UInt16(idtSize - 1), base: &idt)


enum GateType: UInt8 {
    // Ignore the 16bit types
    case TASK_GATE = 5
    case INTR_GATE = 14
    case TRAP_GATE = 15
}

// Helper method to construct an IDT entry
private func IDTEntry(address: UInt, selector: UInt16 = CODE_SEG, gateType: GateType, dpl: UInt8 = 0) -> idt_entry {

    let level = (dpl & 3) << 5
    let flags: UInt8 = 128 | level | gateType.rawValue  // 128 = Present Bit set

    return idt_entry(
        addr_lo: UInt16(truncatingBitPattern: address & 0xffff),
        selector: selector,
        unused: 0,
        flags: flags,
        addr_mid: UInt16(truncatingBitPattern: (address >> 16) & 0xffff),
        addr_hi: UInt32(truncatingBitPattern: address >> 32),
        reserved: 0);
}


func setupIDT() {
    print("Initialising IDT:")
    irqController.disableAllIRQs()

    func printIDT(_ msg: String, _ idt: dt_info) {
        print(msg, terminator: "")
        printf(" IDTInfo: %p/%u\n", UInt(bitPattern: idt.base), idt.limit)
    }

    var currentIdtInfo = dt_info(limit: 0, base: nil)
    sidt(&currentIdtInfo)
    printIDT("Current", currentIdtInfo)

    idt.0 = IDTEntry(address: divide_by_zero_stub_addr(), gateType: .TRAP_GATE)
    idt.1 = IDTEntry(address: debug_exception_stub_addr(), gateType: .TRAP_GATE)
    idt.2 = IDTEntry(address: nmi_stub_addr(), gateType: .TRAP_GATE)
    idt.3 = IDTEntry(address: single_step_stub_addr(), gateType: .TRAP_GATE)
    idt.4 = IDTEntry(address: overflow_stub_addr(), gateType: .TRAP_GATE)
    idt.5 = IDTEntry(address: bounds_stub_addr(), gateType: .TRAP_GATE)
    idt.6 = IDTEntry(address: invalid_opcode_stub_addr(), gateType: .TRAP_GATE)
    idt.7 = IDTEntry(address: unused_stub_addr(), gateType: .TRAP_GATE)
    idt.8 = IDTEntry(address: double_fault_stub_addr(), gateType: .TRAP_GATE)
    idt.9 = IDTEntry(address: unused_stub_addr(), gateType: .TRAP_GATE)
    idt.10 = IDTEntry(address: invalid_tss_stub_addr(), gateType: .TRAP_GATE)
    idt.11 = IDTEntry(address: seg_not_present_stub_addr(), gateType: .TRAP_GATE)
    idt.12 = IDTEntry(address: stack_fault_stub_addr(), gateType: .TRAP_GATE)
    idt.13 = IDTEntry(address: gpf_stub_addr(), gateType: .TRAP_GATE)
    idt.14 = IDTEntry(address: page_fault_stub_addr(), gateType: .TRAP_GATE)
    idt.15 = IDTEntry(address: unused_stub_addr(), gateType: .TRAP_GATE)
    idt.16 = IDTEntry(address: fpu_fault_stub_addr(), gateType: .TRAP_GATE)
    idt.17 = IDTEntry(address: alignment_exception_stub_addr(), gateType: .TRAP_GATE)
    idt.18 = IDTEntry(address: mce_stub_addr(), gateType: .TRAP_GATE)
    idt.19 = IDTEntry(address: simd_exception_stub_addr(), gateType: .TRAP_GATE)

    trap_dispatch_table.0 = divideByZeroException
    trap_dispatch_table.1 = debugException
    trap_dispatch_table.2 = nonMaskableInterrupt
    trap_dispatch_table.3 = singleStepBreakpoint
    trap_dispatch_table.4 = overflowException
    trap_dispatch_table.5 = boundsException
    trap_dispatch_table.6 = invalidOpcodeException
    trap_dispatch_table.7 = unhandledException   // 387 not present
    trap_dispatch_table.8 = doubleFault
    trap_dispatch_table.9 = unhandledException   // 387 Coprocessor overrun
    trap_dispatch_table.10 = invalidTSSException
    trap_dispatch_table.11 = segmentNotPresentException
    trap_dispatch_table.12 = stackFault
    trap_dispatch_table.13 = generalProtectionFault
    trap_dispatch_table.14 = pageFault
    trap_dispatch_table.15 = unhandledException  // reserved
    trap_dispatch_table.16 = fpuFault
    trap_dispatch_table.17 = alignmentCheckException
    trap_dispatch_table.18 = machineCheckException
    trap_dispatch_table.19 = simdException
    lidt(&idtInfo)

    idt.32 = IDTEntry(address: irq00_stub_addr(), gateType: .INTR_GATE)
    idt.33 = IDTEntry(address: irq01_stub_addr(), gateType: .INTR_GATE)
    idt.34 = IDTEntry(address: irq02_stub_addr(), gateType: .INTR_GATE)
    idt.35 = IDTEntry(address: irq03_stub_addr(), gateType: .INTR_GATE)
    idt.36 = IDTEntry(address: irq04_stub_addr(), gateType: .INTR_GATE)
    idt.37 = IDTEntry(address: irq05_stub_addr(), gateType: .INTR_GATE)
    idt.38 = IDTEntry(address: irq06_stub_addr(), gateType: .INTR_GATE)
    idt.39 = IDTEntry(address: irq07_stub_addr(), gateType: .INTR_GATE)
    idt.40 = IDTEntry(address: irq08_stub_addr(), gateType: .INTR_GATE)
    idt.41 = IDTEntry(address: irq09_stub_addr(), gateType: .INTR_GATE)
    idt.42 = IDTEntry(address: irq10_stub_addr(), gateType: .INTR_GATE)
    idt.43 = IDTEntry(address: irq11_stub_addr(), gateType: .INTR_GATE)
    idt.44 = IDTEntry(address: irq12_stub_addr(), gateType: .INTR_GATE)
    idt.45 = IDTEntry(address: irq13_stub_addr(), gateType: .INTR_GATE)
    idt.46 = IDTEntry(address: irq14_stub_addr(), gateType: .INTR_GATE)
    idt.47 = IDTEntry(address: irq15_stub_addr(), gateType: .INTR_GATE)

    initIRQs()

    // Below is not needed except to validate that the setup worked ok and test some exceptions
    sidt(&currentIdtInfo)
    printIDT("New", currentIdtInfo)
    print("Testing Breakpoint:")
    test_breakpoint()
    // Test Null page read fault
    //let p = UnsafePointer<UInt8>(bitPattern: 0x123)
    //print("Null: \(p.memory)")
}
