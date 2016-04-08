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


private let irqDispatchTablePtr = UnsafeMutablePointer<irq_handler>(irq_dispatch_table_addr)
private let irqDispatchTable = UnsafeMutableBufferPointer(start: irqDispatchTablePtr, count:NR_IRQS)
private var queuedIrqHandlers: [irq_handler] = []

// Circular queue of IRQs
private let irqQueueSize = 128
private var irqQueue: [Int] = Array(repeating: 0, count: irqQueueSize)
private var irqQIn = 0
private var irqQOut = 0


public func initIRQs() {
    irqQueue.reserveCapacity(irqQueueSize)
    for idx in 0..<irqDispatchTable.endIndex {
        irqDispatchTable[idx] = unexpectedInterrupt
    }
    queuedIrqHandlers = Array(repeating: unexpectedInterrupt, count: NR_IRQS)
}


public func enableIRQs() {
    print("Enabling IRQs")
    sti()
}


public func setIrqHandler(_ irq: Int, handler: irq_handler) {
    irqDispatchTable[irq] = handler
    PIC8259.enableIRQ(irq)
}


public func removeIrqHandler(_ irq: Int) {
    PIC8259.disableIRQ(irq)
    irqDispatchTable[irq] = unexpectedInterrupt
}


public func setQueuedIrqHandler(_ irq: Int, handler: irq_handler) {
    queuedIrqHandlers[irq] = handler
    setIrqHandler(irq, handler: queueIrq)
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


public func queuedIRQsTask() {
    while (irqQOut != irqQIn) {
        irqQOut = (irqQOut + 1) & (irqQueueSize - 1)
        let irq = irqQueue[irqQOut]
        queuedIrqHandlers[irq](irq)
    }
}


func unexpectedInterrupt(irq: Int) {
    kprint("unexpected interrupt: ")
    print_dword(UInt32(irq))
    kprint("\n");
}
