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
    #kprint("IDT: Initialising..")

    var currentIdtInfo = dt_info()
    sidt(&currentIdtInfo)
    #kprintf("IDT: Current: Info: %p/%u\n", UInt(bitPattern: currentIdtInfo.base), currentIdtInfo.limit)

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

    // 24 IRQ / GSI interrupts connected to IO-APICs
    idt.32 = IDTEntry(function: irq0_stub, gateType: .INTR_GATE)
    idt.33 = IDTEntry(function: irq1_stub, gateType: .INTR_GATE)
    idt.34 = IDTEntry(function: irq2_stub, gateType: .INTR_GATE)
    idt.35 = IDTEntry(function: irq3_stub, gateType: .INTR_GATE)
    idt.36 = IDTEntry(function: irq4_stub, gateType: .INTR_GATE)
    idt.37 = IDTEntry(function: irq5_stub, gateType: .INTR_GATE)
    idt.38 = IDTEntry(function: irq6_stub, gateType: .INTR_GATE)
    idt.39 = IDTEntry(function: irq7_stub, gateType: .INTR_GATE)
    idt.40 = IDTEntry(function: irq8_stub, gateType: .INTR_GATE)
    idt.41 = IDTEntry(function: irq9_stub, gateType: .INTR_GATE)
    idt.42 = IDTEntry(function: irq10_stub, gateType: .INTR_GATE)
    idt.43 = IDTEntry(function: irq11_stub, gateType: .INTR_GATE)
    idt.44 = IDTEntry(function: irq12_stub, gateType: .INTR_GATE)
    idt.45 = IDTEntry(function: irq13_stub, gateType: .INTR_GATE)
    idt.46 = IDTEntry(function: irq14_stub, gateType: .INTR_GATE)
    idt.47 = IDTEntry(function: irq15_stub, gateType: .INTR_GATE)
    idt.48 = IDTEntry(function: irq16_stub, gateType: .INTR_GATE)
    idt.49 = IDTEntry(function: irq17_stub, gateType: .INTR_GATE)
    idt.50 = IDTEntry(function: irq18_stub, gateType: .INTR_GATE)
    idt.51 = IDTEntry(function: irq19_stub, gateType: .INTR_GATE)
    idt.52 = IDTEntry(function: irq20_stub, gateType: .INTR_GATE)
    idt.53 = IDTEntry(function: irq21_stub, gateType: .INTR_GATE)
    idt.54 = IDTEntry(function: irq22_stub, gateType: .INTR_GATE)
    idt.55 = IDTEntry(function: irq23_stub, gateType: .INTR_GATE)

    idt.64 = IDTEntry(function: irq24_stub, gateType: .INTR_GATE)
    idt.65 = IDTEntry(function: irq25_stub, gateType: .INTR_GATE)
    idt.66 = IDTEntry(function: irq26_stub, gateType: .INTR_GATE)
    idt.67 = IDTEntry(function: irq27_stub, gateType: .INTR_GATE)
    idt.68 = IDTEntry(function: irq28_stub, gateType: .INTR_GATE)
    idt.69 = IDTEntry(function: irq29_stub, gateType: .INTR_GATE)
    idt.70 = IDTEntry(function: irq30_stub, gateType: .INTR_GATE)
    idt.71 = IDTEntry(function: irq31_stub, gateType: .INTR_GATE)
    idt.72 = IDTEntry(function: irq32_stub, gateType: .INTR_GATE)
    idt.73 = IDTEntry(function: irq33_stub, gateType: .INTR_GATE)
    idt.74 = IDTEntry(function: irq34_stub, gateType: .INTR_GATE)
    idt.75 = IDTEntry(function: irq35_stub, gateType: .INTR_GATE)
    idt.76 = IDTEntry(function: irq36_stub, gateType: .INTR_GATE)
    idt.77 = IDTEntry(function: irq37_stub, gateType: .INTR_GATE)
    idt.78 = IDTEntry(function: irq38_stub, gateType: .INTR_GATE)
    idt.79 = IDTEntry(function: irq39_stub, gateType: .INTR_GATE)
    idt.80 = IDTEntry(function: irq40_stub, gateType: .INTR_GATE)
    idt.81 = IDTEntry(function: irq41_stub, gateType: .INTR_GATE)
    idt.82 = IDTEntry(function: irq42_stub, gateType: .INTR_GATE)
    idt.83 = IDTEntry(function: irq43_stub, gateType: .INTR_GATE)
    idt.84 = IDTEntry(function: irq44_stub, gateType: .INTR_GATE)
    idt.85 = IDTEntry(function: irq45_stub, gateType: .INTR_GATE)
    idt.86 = IDTEntry(function: irq46_stub, gateType: .INTR_GATE)
    idt.87 = IDTEntry(function: irq47_stub, gateType: .INTR_GATE)
    idt.88 = IDTEntry(function: irq48_stub, gateType: .INTR_GATE)
    idt.89 = IDTEntry(function: irq49_stub, gateType: .INTR_GATE)
    idt.90 = IDTEntry(function: irq50_stub, gateType: .INTR_GATE)
    idt.91 = IDTEntry(function: irq51_stub, gateType: .INTR_GATE)
    idt.92 = IDTEntry(function: irq52_stub, gateType: .INTR_GATE)
    idt.93 = IDTEntry(function: irq53_stub, gateType: .INTR_GATE)
    idt.94 = IDTEntry(function: irq54_stub, gateType: .INTR_GATE)
    idt.95 = IDTEntry(function: irq55_stub, gateType: .INTR_GATE)
    idt.96 = IDTEntry(function: irq56_stub, gateType: .INTR_GATE)
    idt.97 = IDTEntry(function: irq57_stub, gateType: .INTR_GATE)
    idt.98 = IDTEntry(function: irq58_stub, gateType: .INTR_GATE)
    idt.99 = IDTEntry(function: irq59_stub, gateType: .INTR_GATE)
    idt.100 = IDTEntry(function: irq60_stub, gateType: .INTR_GATE)
    idt.101 = IDTEntry(function: irq61_stub, gateType: .INTR_GATE)
    idt.102 = IDTEntry(function: irq62_stub, gateType: .INTR_GATE)
    idt.103 = IDTEntry(function: irq63_stub, gateType: .INTR_GATE)
    idt.104 = IDTEntry(function: irq64_stub, gateType: .INTR_GATE)
    idt.105 = IDTEntry(function: irq65_stub, gateType: .INTR_GATE)
    idt.106 = IDTEntry(function: irq66_stub, gateType: .INTR_GATE)
    idt.107 = IDTEntry(function: irq67_stub, gateType: .INTR_GATE)
    idt.108 = IDTEntry(function: irq68_stub, gateType: .INTR_GATE)
    idt.109 = IDTEntry(function: irq69_stub, gateType: .INTR_GATE)
    idt.110 = IDTEntry(function: irq70_stub, gateType: .INTR_GATE)
    idt.111 = IDTEntry(function: irq71_stub, gateType: .INTR_GATE)
    idt.112 = IDTEntry(function: irq72_stub, gateType: .INTR_GATE)
    idt.113 = IDTEntry(function: irq73_stub, gateType: .INTR_GATE)
    idt.114 = IDTEntry(function: irq74_stub, gateType: .INTR_GATE)
    idt.115 = IDTEntry(function: irq75_stub, gateType: .INTR_GATE)
    idt.116 = IDTEntry(function: irq76_stub, gateType: .INTR_GATE)
    idt.117 = IDTEntry(function: irq77_stub, gateType: .INTR_GATE)
    idt.118 = IDTEntry(function: irq78_stub, gateType: .INTR_GATE)
    idt.119 = IDTEntry(function: irq79_stub, gateType: .INTR_GATE)
    idt.120 = IDTEntry(function: irq80_stub, gateType: .INTR_GATE)
    idt.121 = IDTEntry(function: irq81_stub, gateType: .INTR_GATE)
    idt.122 = IDTEntry(function: irq82_stub, gateType: .INTR_GATE)
    idt.123 = IDTEntry(function: irq83_stub, gateType: .INTR_GATE)
    idt.124 = IDTEntry(function: irq84_stub, gateType: .INTR_GATE)
    idt.125 = IDTEntry(function: irq85_stub, gateType: .INTR_GATE)
    idt.126 = IDTEntry(function: irq86_stub, gateType: .INTR_GATE)
    idt.127 = IDTEntry(function: irq87_stub, gateType: .INTR_GATE)

    // Local APIC interrupts
    idt.240 = IDTEntry(function: apic_int0_stub, gateType: .INTR_GATE)
    idt.241 = IDTEntry(function: apic_int1_stub, gateType: .INTR_GATE)
    idt.242 = IDTEntry(function: apic_int2_stub, gateType: .INTR_GATE)
    idt.243 = IDTEntry(function: apic_int3_stub, gateType: .INTR_GATE)
    idt.244 = IDTEntry(function: apic_int4_stub, gateType: .INTR_GATE)
    idt.245 = IDTEntry(function: apic_int5_stub, gateType: .INTR_GATE)
    idt.246 = IDTEntry(function: apic_int6_stub, gateType: .INTR_GATE)

    // Below is not needed except to validate that the setup worked ok
    // and test some exceptions
    sidt(&currentIdtInfo)
    #kprintf("IDT: New: Info: %p/%u\n", UInt(bitPattern: currentIdtInfo.base), currentIdtInfo.limit)
    #kprint("IDT: Testing Breakpoint:")
    test_breakpoint()
}

func currentIDT() -> dt_info {
    var idt = dt_info()
    sidt(&idt)
    return idt
}
