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

protocol InterruptController {
    func enableIRQ(_ irq: Int)
    func disableIRQ(_ irq: Int)
    func disableAllIRQs()
    func ackIRQ(_ irq: Int)
    func printStatus()
}


let irqController = PIC8259.sharedInstance
private var irqHandlers: [IRQHandler] = Array(repeating: unexpectedInterrupt,
    count: NR_IRQS)

private var queuedIrqHandlers: [IRQHandler] = Array(repeating: unexpectedInterrupt,
    count: NR_IRQS)

// Circular queue of IRQs
private let irqQueueSize = 128
private var irqQueue: [Int] = Array(repeating: 0, count: irqQueueSize)
private var irqQIn = 0
private var irqQOut = 0


func initIRQs() {
    irqQueue.reserveCapacity(irqQueueSize)
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
    irqHandlers[irq] = unexpectedInterrupt
}


func setQueuedIrqHandler(_ irq: Int, handler: @escaping IRQHandler) {
    queuedIrqHandlers[irq] = handler
    setIrqHandler(irq, handler: queueIrq)
}


func queuedIRQsTask() {
    while (irqQOut != irqQIn) {
        irqQOut = (irqQOut + 1) & (irqQueueSize - 1)
        let irq = irqQueue[irqQOut]
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

// Called from entry.asm:_irq_handlers
@_silgen_name("irqHandler")
public func irqHandler(registers: ExceptionRegisters) {
    let irq = Int(registers.pointee.error_code)
    let c = read_int_nest_count()
    if c > 1 {
        kprint("int_nest_count: ")
        kprint_dword(c)
        kprint("\n")
    }
    irqHandlers[irq](irq)
    // EOI
    irqController.ackIRQ(irq)
}


private func unexpectedInterrupt(irq: Int) {
    kprint("unexpected interrupt: ")
    kprint_byte(UInt8(truncatingBitPattern: irq))
    irqController.printStatus()
    kprint("\n")
}


private func queueIrq(irq: Int) {
    let nextIn = (irqQIn + 1) & (irqQueueSize - 1)
    if (nextIn == irqQOut) {
        kprint("Irq queue full\n")
    } else {
        irqQueue[nextIn] = irq
        irqQIn = nextIn
    }
}
