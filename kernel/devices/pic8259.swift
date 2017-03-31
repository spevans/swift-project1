/*
 * kernel/devices/pic8259.swift
 *
 * Created by Simon Evans on 07/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * 8259 Programmable Interrupt Controller
 *
 */


final class PIC8259: InterruptController {
    // IO Port addresses
    private let PIC1_CMD_REG:  UInt16 = 0x20
    private let PIC1_DATA_REG: UInt16 = 0x21
    private let PIC2_CMD_REG:  UInt16 = 0xA0
    private let PIC2_DATA_REG: UInt16 = 0xA1

    // 8259 Commands
    private let ICW1_ICW4:       UInt8 = 0x01    // ICW1/ICW4
    private let ICW1_SINGLE:     UInt8 = 0x02    // Single (cascade) mode
    private let ICW1_INTERVAL4:  UInt8 = 0x04    // Call address interval 4 (8)
    private let ICW1_LEVEL:      UInt8 = 0x08    // Level triggered (edge) mode
    private let ICW1_INIT:       UInt8 = 0x10    // Initialization

    private let ICW4_8086:       UInt8 = 0x01    // 8086/88 (MCS-80/85) mode
    private let ICW4_AUTO:       UInt8 = 0x02    // Auto (normal) EOI
    private let ICW4_BUF_SLAVE:  UInt8 = 0x08    // Buffered mode/slave
    private let ICW4_BUF_MASTER: UInt8 = 0x0C    // Buffered mode/master
    private let ICW4_SFNM:       UInt8 = 0x10    // Special fully nested (not)

    private let OCW3_READ_IRR:   UInt8 = 0x0A    // OCW3 IRR read
    private let OCW3_READ_ISR:   UInt8 = 0x0B    // OCW3 ISR read
    private let EOI:             UInt8 = 0x20    // End of interrupt
    private let SPECIFIC_EOI:    UInt8 = 0x60    // Specific IRQ (+ irq)
    private let CASCADE_IRQ:     UInt8 = 0x02    // PIC2 is at IRQ2 on PIC1


    init?() {
        guard BootParams.acpiTables?.madt?.hasCompatDual8259 == true else {
            print("PIC8259: Not installed")
            return nil
        }
        // Disable all IRQs
        disableAllIRQs()
        rebaseIRQs()
        print("PIC8259: initialised")
    }


    func enableIRQ(_ irq: Int) {
        printf("PIC8259: Enabling IRQ: %d\n", irq)
        guard irq < 16 else {
            printf("PIC8259: Enabling invalid IRQ: %2.2x\n", irq)
            return
        }
        if (irq <= 7) {
            var mask = inb(PIC1_DATA_REG)
            mask &= ~(UInt8(1 << irq))
            outb(PIC1_DATA_REG, mask)
        } else {
            var mask = inb(PIC2_DATA_REG)
            mask &= ~(1 << UInt8(irq - 7))
            outb(PIC2_DATA_REG, mask)
        }
    }


    func disableIRQ(_ irq: Int) {
        printf("PIC8259: Disabling IRQ: %d\n", irq)
        guard irq < 16 else {
            printf("PIC8259: Enabling invalid IRQ: %2.2x\n", irq)
            return
        }
        if (irq <= 7) {
            var mask = inb(PIC1_DATA_REG)
            mask |= (1 << UInt8(irq))
            outb(PIC1_DATA_REG, mask)
        } else {
            var mask = inb(PIC2_DATA_REG)
            mask |= (1 << UInt8(irq - 7))
            outb(PIC2_DATA_REG, mask)
        }
    }


    func disableAllIRQs() {
        outb(PIC1_DATA_REG, 0xff)
        outb(PIC2_DATA_REG, 0xff)
    }


    func ackIRQ(_ irq: Int) {
        guard irq < 16 else {
            kprint("PIC8259: EOI invalid IRQ: ")
            kprint_byte(UInt8(truncatingBitPattern: irq))
            kprint("\n")
            return
        }

        // Check real IRQ occurred
        let active = readISR().bit(irq)
        if !active {
            kprint("PIC8259: Spurious IRQ: ")
            kprint_byte(UInt8(irq))
            kprint("\n")
        }

        if (irq > 7) {
            outb(PIC2_CMD_REG, specificEOIFor(irq: irq))
            outb(PIC2_CMD_REG, specificEOIFor(irq: Int(CASCADE_IRQ)))
        } else {
            outb(PIC1_CMD_REG, specificEOIFor(irq: irq))
        }
    }


    // This isnt a var returning a String to avoid a malloc() as its called
    // inside an interrupt handler
    func printStatus() {
        kprint("PIC8259:: IRR: ")
        kprint_word(readIRR())
        kprint(" ISR: ")
        kprint_word(readISR())
        kprint("\n")
    }


    private func specificEOIFor(irq: Int) -> UInt8 {
        return SPECIFIC_EOI + UInt8(irq & 0x7)
    }


    // Reroute the interrupts to vectors 0x20 - 0x2F
    private func rebaseIRQs() {
        let loVector: UInt8 = 0x20
        let hiVector: UInt8 = 0x28

        outb(PIC1_CMD_REG, ICW1_ICW4 | ICW1_INIT)
        outb(PIC1_DATA_REG, loVector)
        outb(PIC1_DATA_REG, 1 << CASCADE_IRQ)
        outb(PIC1_DATA_REG, ICW4_8086)

        outb(PIC2_CMD_REG, ICW1_ICW4 | ICW1_INIT)
        outb(PIC2_DATA_REG, hiVector)
        outb(PIC2_DATA_REG, CASCADE_IRQ)
        outb(PIC2_DATA_REG, ICW4_8086)
    }


    // Helper routine for readIRR()/readISR(), UInt16 is mask of IRQ0-15
    private func readIRQReg(_ cmd: UInt8) -> UInt16 {
        outb(PIC1_CMD_REG, cmd)
        outb(PIC2_CMD_REG, cmd)
        let msb = inb(PIC2_CMD_REG)
        let lsb = inb(PIC1_CMD_REG)
        return UInt16(withBytes: lsb, msb)
    }


    // Read Interrupt Request Register, interrupts that have been raised
    private func readIRR() -> UInt16 {
        return readIRQReg(OCW3_READ_IRR)
    }


    // Read Interrupt Service Register, interrupts that are being serviced
    // (sent to CPU)
    private func readISR() -> UInt16 {
        return readIRQReg(OCW3_READ_ISR)
    }
}
