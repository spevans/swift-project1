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


enum GateType: UInt32 {
    // Ignore the 16bit types
    case TASK_GATE = 5
    case TSS_DESCRIPTOR = 9
    case INTR_GATE = 14
    case TRAP_GATE = 15
}


// Helper method to construct an IDT entry
private func IDTEntry(function: (@escaping @convention(c) () -> Void),
    selector: UInt16 = UInt16(CODE_SELECTOR), gateType: GateType,
    dpl: UInt32 = 0, ist: UInt32 = 0) -> idt_entry {

    precondition(dpl < 4)
    precondition(ist < 8)
    let address = unsafeBitCast(function, to: UInt64.self)

    return idt_entry(
        addr_lo: UInt16(truncatingIfNeeded: address & 0xffff),
        selector: selector,
        ist: ist,
        zero0: 0,
        type: gateType.rawValue,
        zero1: 0,
        dpl: dpl,
        present: 1,
        addr_mid: UInt16(truncatingIfNeeded: (address >> 16) & 0xffff),
        addr_hi: UInt32(truncatingIfNeeded: address >> 32),
        reserved: 0);
}


func setupIDT() {
    print("IDT: Initialising..")

    func printIDT(_ msg: String, _ idt: dt_info) {
        print("IDT:", msg, terminator: "")
        printf(": Info: %p/%u\n", UInt(bitPattern: idt.base), idt.limit)
    }

    var currentIdtInfo = dt_info()
    sidt(&currentIdtInfo)
    printIDT("Current", currentIdtInfo)

    idt.0 = IDTEntry(function: divide_by_zero_stub, gateType: .TRAP_GATE)
    idt.1 = IDTEntry(function: debug_exception_stub, gateType: .TRAP_GATE)
    idt.2 = IDTEntry(function: nmi_stub, gateType: .TRAP_GATE)
    idt.3 = IDTEntry(function: single_step_stub, gateType: .TRAP_GATE)
    idt.4 = IDTEntry(function: overflow_stub, gateType: .TRAP_GATE)
    idt.5 = IDTEntry(function: bounds_stub, gateType: .TRAP_GATE)
    idt.6 = IDTEntry(function: invalid_opcode_stub, gateType: .TRAP_GATE)
    idt.7 = IDTEntry(function: unused_stub, gateType: .TRAP_GATE)
    idt.8 = IDTEntry(function: double_fault_stub, gateType: .TRAP_GATE, ist: 1)
    idt.9 = IDTEntry(function: unused_stub, gateType: .TRAP_GATE)
    idt.10 = IDTEntry(function: invalid_tss_stub, gateType: .TRAP_GATE)
    idt.11 = IDTEntry(function: seg_not_present_stub, gateType: .TRAP_GATE)
    idt.12 = IDTEntry(function: stack_fault_stub, gateType: .TRAP_GATE, ist: 1)
    idt.13 = IDTEntry(function: gpf_stub, gateType: .TRAP_GATE, ist: 1)
    idt.14 = IDTEntry(function: page_fault_stub, gateType: .TRAP_GATE)
    idt.15 = IDTEntry(function: unused_stub, gateType: .TRAP_GATE)
    idt.16 = IDTEntry(function: fpu_fault_stub, gateType: .TRAP_GATE)
    idt.17 = IDTEntry(function: alignment_exception_stub, gateType: .TRAP_GATE)
    idt.18 = IDTEntry(function: mce_stub, gateType: .TRAP_GATE)
    idt.19 = IDTEntry(function: simd_exception_stub, gateType: .TRAP_GATE)

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

    idt.32 = IDTEntry(function: irq00_stub, gateType: .INTR_GATE)
    idt.33 = IDTEntry(function: irq01_stub, gateType: .INTR_GATE)
    idt.34 = IDTEntry(function: irq02_stub, gateType: .INTR_GATE)
    idt.35 = IDTEntry(function: irq03_stub, gateType: .INTR_GATE)
    idt.36 = IDTEntry(function: irq04_stub, gateType: .INTR_GATE)
    idt.37 = IDTEntry(function: irq05_stub, gateType: .INTR_GATE)
    idt.38 = IDTEntry(function: irq06_stub, gateType: .INTR_GATE)
    idt.39 = IDTEntry(function: irq07_stub, gateType: .INTR_GATE)
    idt.40 = IDTEntry(function: irq08_stub, gateType: .INTR_GATE)
    idt.41 = IDTEntry(function: irq09_stub, gateType: .INTR_GATE)
    idt.42 = IDTEntry(function: irq10_stub, gateType: .INTR_GATE)
    idt.43 = IDTEntry(function: irq11_stub, gateType: .INTR_GATE)
    idt.44 = IDTEntry(function: irq12_stub, gateType: .INTR_GATE)
    idt.45 = IDTEntry(function: irq13_stub, gateType: .INTR_GATE)
    idt.46 = IDTEntry(function: irq14_stub, gateType: .INTR_GATE)
    idt.47 = IDTEntry(function: irq15_stub, gateType: .INTR_GATE)

    idt.48 = IDTEntry(function: apic_int0_stub, gateType: .INTR_GATE)
    idt.49 = IDTEntry(function: apic_int1_stub, gateType: .INTR_GATE)
    idt.50 = IDTEntry(function: apic_int2_stub, gateType: .INTR_GATE)
    idt.51 = IDTEntry(function: apic_int3_stub, gateType: .INTR_GATE)
    idt.52 = IDTEntry(function: apic_int4_stub, gateType: .INTR_GATE)
    idt.53 = IDTEntry(function: apic_int5_stub, gateType: .INTR_GATE)
    idt.54 = IDTEntry(function: apic_int6_stub, gateType: .INTR_GATE)

    // Below is not needed except to validate that the setup worked ok
    // and test some exceptions
    sidt(&currentIdtInfo)
    printIDT("New", currentIdtInfo)
    print("IDT: Testing Breakpoint:")
    test_breakpoint()
}

func currentIDT() -> dt_info {
    var idt = dt_info()
    sidt(&idt)
    return idt
}
