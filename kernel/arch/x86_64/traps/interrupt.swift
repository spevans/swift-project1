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


protocol InterruptController {
    func enableIRQ(_ irqSetting: IRQSetting)
    func disableIRQ(_ irqSetting: IRQSetting)
    func disableAllIRQs()
    func ackIRQ(_ irq: Int)
    func printStatus()
}


final class InterruptHandler: Equatable, Hashable, CustomStringConvertible {
    let description: String
    let handler: IRQHandler

    init(name: String, handler: @escaping IRQHandler) {
        self.description = name
        self.handler = handler
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    static func ==(lhs: InterruptHandler, rhs: InterruptHandler) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

fileprivate var irqHandlers: InlineArray<256, (IRQSetting, Set<InterruptHandler>)?> = .init(repeating: nil)

public struct InterruptManager: ~Copyable {

    private(set) var localAPIC = APIC()
    private var ioapics: [IOAPIC] = []
    private var overrideEntries: [MADT.InterruptSourceOverrideTable] = []


    init() {
    }

    mutating func setup(with acpiTables: ACPI) {

        guard let madtEntries = acpiTables.madt?.madtEntries else {
            fatalError("Cant find MADT Table")
        }
        guard localAPIC.setup(with: madtEntries) else {
            fatalError("Cannot setup ACPI")
        }

        // Find the IO-APICS and interrupt overrides
        var _ioapics: [IOAPIC] = []
        var _overrideEntries: [MADT.InterruptSourceOverrideTable] = []

        madtEntries.forEach {
            //#kprint("INT-MAN: MADT entry:", $0)
            switch $0 {
                case let .ioApic(entry):
                    let baseAddress = PhysAddress(RawAddress(entry.ioApicAddress))
                    let ioapic = IOAPIC(ioApicId: entry.ioApicID, baseAddress: baseAddress,
                                        gsiBase: entry.globalSystemInterruptBase)
                    _ioapics.append(ioapic)
                case let .interruptSourceOverride(entry):
                    _overrideEntries.append(entry)
                default: break
            }
        }
        ioapics = _ioapics
        overrideEntries = _overrideEntries

        guard _ioapics.count > 0 else {
            fatalError("Cant find any IO-APICs in the ACPI: MADT tables")
        }

        #kprint("INT-MAN: Have \(ioapics.count) IO-APICs")
        localAPIC.disableAllIRQs()
    }


    func enableGpicMode() {
        // Set _PIC mode to APIC (1)
        do {
            try ACPI.invoke(method: "\\_PIC", AMLTermArg(1))
            #kprint("INT-MAN: _PIC mode set to APIC")
        } catch AMLError.invalidMethod {
            #kprint("INT-MAN: Cannot set _PIC to APIC: no such method")
            // ignore, _PIC is optional
        } catch {
            fatalError("INT-MAN: Cant set ACPI mode: \(error)")
        }
    }

    func enableIRQs() {
        #kprint("INT-MAN: Enabling IRQs")
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
            #kprint("INT-MAN: Remap IRQ:", irqSetting, "overriden to:", newIrqSetting)
        } else {
            newIrqSetting = irqSetting
        }

        guard newIrqSetting.irq < NR_IRQS else {
            fatalError("INT-MAN: setIrqHandler: Invalid IRQ \(newIrqSetting.irq) > \(NR_IRQS)")
        }
        return newIrqSetting
    }


    private func ioapicForIrq(_ irqSetting: IRQSetting) -> IOAPIC? {
        #kprint("INT-MAN: looking for ioapic for IRQ", irqSetting)
        if let ioapic = ioapics.first(where: { $0.canHandleIrq(irqSetting) }) {
            return ioapic
        }
        #kprint("INT-MAN: cant find an IOAPIC!")
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

    mutating func setIrqHandler(_ handler: InterruptHandler, forInterrupt interrupt: IRQSetting) {
        let irq = interrupt.irq
        #kprintf("INT-MAN: Setting IRQ handler for IRQ%d\n", irq)

        var enableIrq = false
        if let irqHandler = irqHandlers[irq] {
            let currentInterrupt = irqHandler.0
            var handlers = irqHandler.1
            if currentInterrupt.shared {
                guard currentInterrupt == interrupt else {
                    fatalError("INT-MAN: IRQ handler for \(irq) is for shared interrupts but trying to add an mismatching interrupt \(interrupt) != \(currentInterrupt)")
                }
                enableIrq = handlers.count == 0
                guard !handlers.contains(handler) else {
                    fatalError("SharedInterrupt already contains \(handler)")
                }
                handlers.insert(handler)
                irqHandlers[irq] = (currentInterrupt, handlers)
            } else {
                if interrupt.shared {
                    fatalError("INT-MAN: IRQ handler for \(irq) is set for unshared but trying to add a shared handler")
                } else {
                    fatalError("INT-MAN: IRQ handler for \(irq) is already set")
                }
            }
        } else {
            irqHandlers[irq] = (interrupt, [handler])
            if interrupt.shared {
                #kprint("Adding shared handler")
            } else {
                #kprint("Adding unshared handler")
            }
            enableIrq = true
        }
        if enableIrq {
            enableIRQ(interrupt)
        }
    }


    mutating func removeIrqHandler(_ handler: InterruptHandler, forInterrupt interrupt: IRQSetting) {

        var disableIrq = false
        guard let irqHandler = irqHandlers[interrupt.irq] else {
            fatalError("INT-MAN: No interrupt handler to remove for IRQ\(interrupt.irq) \(handler)")
        }

        let currentInterrupt = irqHandler.0
        var handlers = irqHandler.1

        if currentInterrupt.shared {
            if interrupt == currentInterrupt {
                guard handlers.remove(handler) != nil else {
                    fatalError("SharedInterrupt does not contain \(handler)")
                }
                disableIrq = handlers.count == 0
                irqHandlers[interrupt.irq] = (currentInterrupt, handlers)
            }
        } else {
                guard currentInterrupt == interrupt else {
                    fatalError("Cannot remove mismatching interupt \(currentInterrupt) != \(interrupt)")
                }
                irqHandlers[interrupt.irq] = nil
                disableIrq = true
        }
        if disableIrq {
            disableIRQ(interrupt)
        }
    }
}


// Called from entry.asm:_irq_handlers
// The following function runs inside an IRQ so cannot call malloc().
// The irqHandler does everything except save/restore the registers and
// the IRET. The IRQ number is passed on the stack in the ExceptionRegisters
// (include/x86defs.h:exception_regs) as the error_code.
@_silgen_name("irqHandler")
public func irqHandler(registers: ExceptionRegisters,
                       interruptManager: borrowing InterruptManager) {

    let irq = Int(truncatingIfNeeded: registers.pointee.error_code)
    guard irq >= 0 && irq < NR_IRQS else {
        #kprintf("\nInvalid interrupt: %d\n", irq)
        return
    }
    let c = read_int_nest_count()
    if c > 1 {
        #kprintf("\nint_nest_count: %d\n", c)
    }
    if let irqHandler = irqHandlers[irq] {
        let interruptHandlers = irqHandler.1
        var acked = false
        for interruptHandler in interruptHandlers {
            let ack = interruptHandler.handler()
            acked = acked || ack
        }
        if !acked {
            #kprintf("\nShared IRQ:%d no handler ACKed\n", irq)
        }
    } else {
        #kprintf("INT-MAN: Unexpected interrupt: %d\n", irq)
    }
    // EOI
    interruptManager.ackIRQ(irq)
}
