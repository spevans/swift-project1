/*
 * kernel/devices/cmos.swift
 *
 * Created by Simon Evans on 23/09/2018.
 * Copyright © 2018 Simon Evans. All rights reserved.
 *
 * CMOS RTC driver.
 *
 */


final class CMOSRTC: Device, ISADevice, CustomStringConvertible {

    private let interruptManager: InterruptManager
    private let addressPort: UInt16
    private let dataPort: UInt16
    private let irq: UInt8
    private let centuryIndex: UInt8

    var description: String {
        return String.sprintf("CMOS RTC addr: 0x%2.2x data: 0x%2.2x irq: %u",
            addressPort, dataPort, irq)
    }


    init?(interruptManager: InterruptManager, pnpName: String,
        resources: ISABus.Resources, facp: FACP?) {
        print("CMOS: init:", resources)
        guard let ports = resources.ioPorts.first, ports.count > 1
            && resources.interrupts.count > 0 else {
            print("CMOS: Requires 2 IO ports and 1 IRQ")
            return nil
        }
        self.interruptManager = interruptManager
        let idx = ports.startIndex
        addressPort = ports[ports.index(idx, offsetBy: 0)]
        dataPort = ports[ports.index(idx, offsetBy: 1)]
        irq = resources.interrupts[0]
        if let century = facp?.rtcCenturyIndex, century < 64 {
            centuryIndex = century
        } else {
            centuryIndex = 0
        }
    }


    private func bcdToInt(_ value: UInt8) -> Int {
        let tens = (value & 0xF0) >> 4
        let ones = (value & 0x0F)
        return Int((10 * tens) + ones)
    }


    func readTime() -> String {
        // Slow method
        // wait until update bit is set

        func waitForUpdateToFinish() {
            while (statusRegA & 0x80) == 1 {}
        }

        func readTimeComponents() -> (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) {
            let seconds = self.seconds
            let minutes = self.minutes
            let hours = self.hours
            let dayOfMonth = self.dayOfMonth
            let month = self.month
            let year = self.year
            return (year, month, dayOfMonth, hours, minutes, seconds)
        }

        let regB = statusRegB
        //let hour24mode = (regB & 0x2) == 0x2
        let bcdMode = (regB & 0x4) == 0x0

        func convertValue(_ value: UInt8) -> Int {
            return bcdMode ? bcdToInt(value) : Int(value)
        }

        waitForUpdateToFinish()
        var values = readTimeComponents()
        while true {
            let lastValues = values
            waitForUpdateToFinish()
            values = readTimeComponents()
            if lastValues == values {
                let century = convertValue(self.century)
                return String.sprintf("%2.2d%2.2d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d",
                    century > 0 ? century : 20,
                    convertValue(values.0),
                    convertValue(values.1),
                    convertValue(values.2),
                    convertValue(values.3),
                    convertValue(values.4),
                    convertValue(values.5)
                )
            }
        }

    }


    private var seconds: UInt8 { return readMemory(0x00) }
    private var minutes: UInt8 { return readMemory(0x02) }
    private var hours: UInt8 { return readMemory(0x04) }
    private var dayOfMonth: UInt8 { return readMemory(0x07) }
    private var month: UInt8 { return readMemory(0x08) }
    private var year: UInt8 { return readMemory(0x09) }
    private var century: UInt8 {
        return centuryIndex > 0 ? readMemory(centuryIndex) : 0
    }
    private var statusRegA: UInt8 { return readMemory(0x0A) }
    private var statusRegB: UInt8 { return readMemory(0x0B) }
    private var statusRegC: UInt8 { return readMemory(0x0C) }
    private var statusRegD: UInt8 { return readMemory(0x0D) }


    private func readMemory(_ index: UInt8) -> UInt8 {
        precondition(index >= 0 && index < 64)
        let flags = local_irq_save()
        outb(addressPort, index)
        let data: UInt8 = inb(dataPort)
        load_eflags(flags)
        return data
    }


    private func writeMemory(_ index: UInt8, data: UInt8) {
        precondition(index >= 0 && index < 64)
        let flags = local_irq_save()
        outb(addressPort, index)
        outb(dataPort, data)
        load_eflags(flags)
    }
}
