/*
 * kernel/devices/pic8259.swift
 *
 * Created by Simon Evans on 07/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * 8259 Programmable Interrupt Controller
 *
 */


public class PIC8259 {
    static let PIC1Cmd:  UInt16 = 0x20
    static let PIC1Data: UInt16 = 0x21
    static let PIC2Cmd:  UInt16 = 0xA0
    static let PIC2Data: UInt16 = 0xA1

    static let ICW1_ICW4:       UInt8 = 0x01    // ICW1/ICW4
    static let ICW1_SINGLE:     UInt8 = 0x02    // Single (cascade) mode
    static let ICW1_INTERVAL4:  UInt8 = 0x04    // Call address interval 4 (8)
    static let ICW1_LEVEL:      UInt8 = 0x08    // Level triggered (edge) mode
    static let ICW1_INIT:       UInt8 = 0x10    // Initialization

    static let ICW4_8086:       UInt8 = 0x01    // 8086/88 (MCS-80/85) mode
    static let ICW4_AUTO:       UInt8 = 0x02    // Auto (normal) EOI
    static let ICW4_BUF_SLAVE:  UInt8 = 0x08	// Buffered mode/slave
    static let ICW4_BUF_MASTER: UInt8 = 0x0C    // Buffered mode/master
    static let ICW4_SFNM:       UInt8 = 0x10    // Special fully nested (not)

    static let OCW3_READ_IRR:   UInt8 = 0x0A    // OCW3 IRR read
    static let OCW3_READ_ISR:   UInt8 = 0x0B    // OCW3 ISR read
    static let EOI:             UInt8 = 0x20    // End of interrupt
    static let SPECIFIC_EOI:    UInt8 = 0x60    // Specific IRQ (+ irq)
    static let CASCADE_IRQ:     UInt8 = 0x02    // PIC2 is at IRQ2 on PIC1

    static func initPIC() {
        // Disable all IRQs
        rebaseIRQs()
        outb(PIC1Data, 0xff)
        outb(PIC2Data, 0xff)
    }


    // Reroute the interrupts to vectors 0x20 - 0x2F
    static func rebaseIRQs() {
        let loVector: UInt8 = 0x20
        let hiVector: UInt8 = 0x28

        outb(PIC1Cmd, ICW1_ICW4 | ICW1_INIT)
        outb(PIC1Data, loVector)
        outb(PIC1Data, 1 << CASCADE_IRQ)
        outb(PIC1Data, ICW4_8086)

        outb(PIC2Cmd, ICW1_ICW4 | ICW1_INIT)
        outb(PIC2Data, hiVector)
        outb(PIC2Data, CASCADE_IRQ)
        outb(PIC2Data, ICW4_8086)
    }


    static func enableIRQ(_ irq: Int) {
        guard irq < 16 else {
            kprintf("Enabling invalid IRQ: %2.2x\n", irq)
            return
        }
        if (irq <= 7) {
            var mask = inb(PIC1Data)
            mask &= ~(UInt8(1 << irq))
            outb(PIC1Data, mask)
        } else {
            var mask = inb(PIC2Data)
            mask &= ~(1 << UInt8(irq - 7))
            outb(PIC2Data, mask)
        }
    }


    static func disableIRQ(_ irq: Int) {
        guard irq < 16 else {
            kprintf("Enabling invalid IRQ: %2.2x\n", irq)
            return
        }
        if (irq <= 7) {
            var mask = inb(PIC1Data)
            mask |= (1 << UInt8(irq))
            outb(PIC1Data, mask)
        } else {
            var mask = inb(PIC2Data)
            mask |= (1 << UInt8(irq - 7))
            outb(PIC2Data, mask)
        }
    }


    private static func specificEOIFor(irq: Int) -> UInt8 {
        return SPECIFIC_EOI + UInt8(irq & 0x7)
    }


    public static func sendEOI(irq: Int) {
        guard irq < 16 else {
            kprint("EOI invalid IRQ: ")
            kprint_byte(UInt8(truncatingBitPattern: irq))
            kprint("\n")
            return
        }

        // Check real IRQ occurred
        let active = readISR().bitSet(UInt16(irq))
        if !active {
            kprint("Spurious IRQ: ")
            kprint_byte(UInt8(irq))
            kprint("\n")
        }

        if (irq > 7) {
            outb(PIC2Cmd, specificEOIFor(irq: irq))
            outb(PIC2Cmd, specificEOIFor(irq: Int(CASCADE_IRQ)))
        } else {
            outb(PIC1Cmd, specificEOIFor(irq: irq))
        }
    }


    // Helper routine for readIRR()/readISR(), UInt16 is mask of IRQ0-15
    static func readIRQReg(_ cmd: UInt8) -> UInt16 {
        outb(PIC1Cmd, cmd)
        outb(PIC2Cmd, cmd)
        return UInt16(msb: inb(PIC2Cmd), lsb: inb(PIC1Cmd))
    }


    // Read Interrupt Request Register, interrupts that have been raised
    static func readIRR() -> UInt16 {
        return readIRQReg(OCW3_READ_IRR)
    }


    // Read Interrupt Service Register, interrupts that are being serviced (sent to CPU)
    static func readISR() -> UInt16 {
        return readIRQReg(OCW3_READ_ISR)
    }
}
