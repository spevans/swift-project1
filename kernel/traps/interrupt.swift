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


typealias IRQHandler = (Int) -> ()

private(set) var localAPIC: APIC?

protocol InterruptController {
    func enableIRQ(_ irqSetting: IRQSetting)
    func disableIRQ(_ irqSetting: IRQSetting)
    func disableAllIRQs()
    func ackIRQ(_ irq: Int)
    func printStatus()
}


public final class InterruptManager {

    fileprivate let irqController: InterruptController
    fileprivate var irqHandlers: [IRQHandler] = Array(repeating: InterruptManager.unexpectedInterrupt, count: NR_IRQS)


    init(acpiTables: ACPI) {

        func initAPIC() -> InterruptController? {
            if let madtEntries = acpiTables.madt?.madtEntries {
                return APIC(madtEntries: madtEntries)
            } else {
                return nil
            }
        }

        func initPIC() -> InterruptController? {
            if acpiTables.madt?.hasCompatDual8259 == false {
                return nil
            } else {
                return PIC8259()
            }
        }

        guard let controller = initAPIC() ?? initPIC() else {
            fatalError("Cannot initialise IRQ controller")
        }
        irqController = controller

        localAPIC = controller as? APIC
        print("localAPIC:", localAPIC as Any)

        print("kernel: Using \(irqController.self) as interrupt controller")
        irqController.disableAllIRQs()
    }


    func enableGpicMode() {
        // Set _PIC mode to APIC (1)
        do {
            try ACPI.invoke(method: "\\_PIC", AMLDataObject.integer(1))
            print("ACPI: _PIC mode set to APIC")
        } catch AMLError.invalidMethod {
            // ignore, _PIC is optional
        } catch {
            fatalError("Cant set ACPI mode: \(error)")
        }
    }

    func enableIRQs() {
        print("INT: Enabling IRQs")
        sti()
    }


    func setIrqHandler(_ irqSetting: IRQSetting, handler: @escaping IRQHandler) {
        // FIXME, deal with shared interrupts
        irqHandlers[irqSetting.irq] = handler
        irqController.enableIRQ(irqSetting)
    }


    func removeIrqHandler(_ irqSetting: IRQSetting) {
        irqController.disableIRQ(irqSetting)
        irqHandlers[irqSetting.irq] = InterruptManager.unexpectedInterrupt
    }


    // The following functions all run inside an IRQ so cannot call malloc().
    // The irqHandler does everything except save/restore the registers and
    // the IRET. The IRQ number is passed on the stack in the ExceptionRegisters
    // (include/x86defs.h:excpetion_regs) as the error_code.
    static private func unexpectedInterrupt(irq: Int) {
        printf("unexpected interrupt: %d\n")
    }
}


// Called from entry.asm:_irq_handlers
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
    interruptManager.irqHandlers[irq](irq)
    // EOI
    interruptManager.irqController.ackIRQ(irq)
}
