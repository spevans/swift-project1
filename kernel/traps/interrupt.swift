/*
 * kernel/traps/interrupt.swift
 *
 * Created by Simon Evans on 26/02/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Handing of IRQs including using a queue to service interrupts
 * outside of the IRQ handler for situations where the handler may
 * need to do more work etc
 */


// IRQHandler returns `true` if the interrupt was handled, `false`
// otherwise. This if for when shared interrupts are used.
typealias IRQHandler = () -> Bool

private(set) var localAPIC: APIC!

protocol InterruptController {
    func enableIRQ(_ irqSetting: IRQSetting)
    func disableIRQ(_ irqSetting: IRQSetting)
    func disableAllIRQs()
    func ackIRQ(_ irq: Int)
    func printStatus()
}


public final class InterruptManager {

    fileprivate var irqHandlers: [IRQHandler?] = Array(repeating: nil, count: NR_IRQS)
    private let ioapics: [IOAPIC]
    private let overrideEntries: [MADT.InterruptSourceOverrideTable]


    init(acpiTables: ACPI) {

        guard let madtEntries = acpiTables.madt?.madtEntries else {
            fatalError("Cant find MADT Table")
        }
        localAPIC = APIC(madtEntries: madtEntries)

        // Find the IO-APICS and interrupt overrides
        var _ioapics: [IOAPIC] = []
        var _overrideEntries: [MADT.InterruptSourceOverrideTable] = []

        madtEntries.forEach {
            if let entry = $0 as? MADT.IOApicTable {
                let baseAddress = PhysAddress(RawAddress(entry.ioApicAddress))
                let ioapic = IOAPIC(ioApicId: entry.ioApicID, baseAddress: baseAddress,
                                    gsiBase: entry.globalSystemInterruptBase)
                _ioapics.append(ioapic)
            } else if let entry = $0 as? MADT.InterruptSourceOverrideTable {
                _overrideEntries.append(entry)
            }
        }
        ioapics = _ioapics
        overrideEntries = _overrideEntries

        guard _ioapics.count > 0 else {
            fatalError("Cant find any IO-APICs in the ACPI: MADT tables")
        }

        print("INT-MAN: Have \(ioapics.count) IO-APICs")
        localAPIC.disableAllIRQs()
    }


    func enableGpicMode() {
        // Set _PIC mode to APIC (1)
        do {
            try ACPI.invoke(method: "\\_PIC", AMLDataObject.integer(1))
            print("INT-MAN: _PIC mode set to APIC")
        } catch AMLError.invalidMethod {
            // ignore, _PIC is optional
        } catch {
            fatalError("INT-MAN: Cant set ACPI mode: \(error)")
        }
    }

    func enableIRQs() {
        print("INT-MAN: Enabling IRQs")
        sti()
    }


    private func overrideEntryFor(irq: Int) -> MADT.InterruptSourceOverrideTable? {
        for entry in overrideEntries {
            if entry.sourceIRQ == UInt8(irq) {
                return entry
            }
        }
        return nil
    }


    // IRQs might require remapping. The resultant value can be used as a GSI.
    // If the interrupt pin is already a GSI then no remapping is required.
    private func remapIrqIfNeeded(_ irqSetting: IRQSetting) -> IRQSetting {
        let newIrqSetting: IRQSetting
        if irqSetting.isIRQ, let entry = overrideEntryFor(irq: irqSetting.irq) {
            newIrqSetting = entry.irqSetting
            guard newIrqSetting.isGSI else {
                fatalError("INT-MAN: Remapped \(irqSetting) to \(newIrqSetting) but it is not a GSI")
            }
            print("INT-MAN: Remap IRQ:", irqSetting, "overriden to:", newIrqSetting)
        } else {
            newIrqSetting = irqSetting
        }

        guard newIrqSetting.irq < NR_IRQS else {
            fatalError("INT-MAN: setIrqHandler: Invalid IRQ \(newIrqSetting.irq) > \(NR_IRQS)")
        }
        return newIrqSetting
    }


    private func ioapicForIrq(_ irqSetting: IRQSetting) -> IOAPIC? {
        print("INT-MAN: looking for ioapic for IRQ", irqSetting)
        if let ioapic = ioapics.first(where: { $0.canHandleIrq(irqSetting) }) {
            return ioapic
        }
        print("INT-MAN: cant find an IOAPIC!")
        return nil
    }


    func enableIRQ(_ irqSetting: IRQSetting) {
        let actualIrq = remapIrqIfNeeded(irqSetting)
        if let ioapic = ioapicForIrq(actualIrq) {
            // Global System Interrupts are mapped into the IDT starting at entry 32
            let vector = UInt8(irqSetting.irq) + 0x20
            ioapic.enableIRQ(actualIrq, vector: vector)
        }
    }

    func disableIRQ(_ irqSetting: IRQSetting) {
        let actualIrq = remapIrqIfNeeded(irqSetting)
        if let ioapic = ioapicForIrq(actualIrq) {
            ioapic.disableIRQ(actualIrq)
        }
    }

    func ackIRQ(_ irq: Int) {
        localAPIC.ackIRQ(irq)
    }

    func setIrqHandler(_ irqSetting: IRQSetting, handler: @escaping IRQHandler) {
        // FIXME, deal with shared interrupts
        print("INT-MAN: Setting IRQ handler for \(irqSetting.irq)")
        irqHandlers[irqSetting.irq] = handler
        enableIRQ(irqSetting)
    }

    func removeIrqHandler(_ irqSetting: IRQSetting) {
        disableIRQ(irqSetting)
        irqHandlers[irqSetting.irq] = nil
    }
}


// Called from entry.asm:_irq_handlers
// The following function runs inside an IRQ so cannot call malloc().
// The irqHandler does everything except save/restore the registers and
// the IRET. The IRQ number is passed on the stack in the ExceptionRegisters
// (include/x86defs.h:excpetion_regs) as the error_code.
@_silgen_name("irqHandler")
public func irqHandler(registers: ExceptionRegisters,
    interruptManager: inout InterruptManager) {

    let irq = Int(registers.pointee.error_code)
    guard irq >= 0 && irq < NR_IRQS else {
        printf("\nInvalid interrupt: %x\n", UInt(irq))
        return
    }
    let c = read_int_nest_count()
    if c > 1 {
        printf("\nint_nest_count: %d\n", c)
    }
    if let handler = interruptManager.irqHandlers[irq] {
        _ = handler()
    } else {
        printf("INT-MAN: Unexpected interrupt: %d\n", irq)
    }
    // EOI
    interruptManager.ackIRQ(irq)
}
