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

public private(set) var localAPIC: APIC?

protocol InterruptController {
    func enableIRQ(_ irq: Int)
    func disableIRQ(_ irq: Int)
    func disableAllIRQs()
    func ackIRQ(_ irq: Int)
    func printStatus()
}


public class InterruptManager {

    fileprivate var irqController: InterruptController!

    fileprivate var irqHandlers: [IRQHandler] =
        Array(repeating: InterruptManager.unexpectedInterrupt, count: NR_IRQS)

    fileprivate var queuedIrqHandlers: [IRQHandler] =
        Array(repeating: InterruptManager.unexpectedInterrupt, count: NR_IRQS)

    // Circular queue of IRQs
    fileprivate var irqQueue = CircularBuffer<Int>(item: 0, capacity: 128)


    init() {
        irqQueue.clear()
        guard let controller: InterruptController = APIC() ?? PIC8259() else {
            fatalError("Cannot initialise IRQ controller")
        }
        localAPIC = controller as? APIC
        print("localAPIC:", localAPIC as Any)

        irqController = controller
        print("kernel: Using \(irqController.self) as interrupt controller")
        // In a PIC8259/IOAPIC dual system, need to disable IRQs in both controllers
        //if let pic = PIC8259() {
        //    pic.disableAllIRQs()
        //}
        irqController.disableAllIRQs()
    }


    func enableIRQs() {
        print("INT: Enabling IRQs")
        sti()
    }


    func setIrqHandler(_ irq: Int, handler: @escaping IRQHandler) {
        irqHandlers[irq] = handler
        irqController.enableIRQ(irq)
    }


    func removeIrqHandler(_ irq: Int) {
        irqController.disableIRQ(irq)
        irqHandlers[irq] = InterruptManager.unexpectedInterrupt
    }


    func setQueuedIrqHandler(_ irq: Int, handler: @escaping IRQHandler) {
        queuedIrqHandlers[irq] = handler
        setIrqHandler(irq, handler: queueIrq)
    }


    func queuedIRQsTask() {
        while let irq = irqQueue.remove() {
            queuedIrqHandlers[irq](irq)
        }
    }


    /* The following functions all run inside an IRQ so cannot call
    * malloc() etc and so cant use [CVarArgs] so no printf() functions.
    * irqHandler does everything except save/restore the registers and
    * the IRET. The IRQ number is passed on the stack in the ExceptionRegisters
    * (include/x86defs.h:excpetion_regs) as the error_code.
    * This interrupt handler currently suffers from overrun as it is too slow.
    * because the code is currently compiled without optimisation due to SR-1318.
    * The kprint_* functions are used because they do not take var args and print
    * to the screen using the early_tty.c print routines.
    */


    static private func unexpectedInterrupt(irq: Int) {
        kprint("unexpected interrupt: ")
        kprint_byte(UInt8(truncatingBitPattern: irq))
        kprint("\n")
    }


    private func queueIrq(irq: Int) {
        kprint_word(UInt16(irq))
        if irqQueue.add(irq) == false {
            kprint("Irq queue full\n")
        }
    }
}


// Called from entry.asm:_irq_handlers
@_silgen_name("irqHandler")
public func irqHandler(registers: ExceptionRegisters,
    interruptManager: inout InterruptManager) {

    let irq = Int(registers.pointee.error_code)
    guard irq < NR_IRQS else {
        kprint("\nInvalid interrupt: ")
        kprint_word(UInt16(irq))
        kprint("\n")
        return
    }
    let c = read_int_nest_count()
    if c > 1 {
        kprint("int_nest_count: ")
        kprint_dword(c)
        kprint("\n")
    }
    interruptManager.irqHandlers[irq](irq)
    // EOI
    interruptManager.irqController.ackIRQ(irq)
}
