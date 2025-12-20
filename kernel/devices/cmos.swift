/*
 * kernel/devices/cmos.swift
 *
 * Created by Simon Evans on 23/09/2018.
 * Copyright © 2018 Simon Evans. All rights reserved.
 *
 * CMOS RTC driver.
 *
 */


final class CMOSRTC: PNPDeviceDriver {

    private var addressPort: UInt16 = 0
    private var dataPort: UInt16 = 0
    private var irq: IRQSetting?
    private var centuryIndex: UInt8 = 0


    override func info() -> String {
        return #sprintf("CMOS RTC addr: 0x%2.2x data: 0x%2.2x irq: %s",
                              addressPort, dataPort, irq?.description ?? "none" )
    }

    init?(pnpDevice: PNPDevice) {
        super.init(driverName: "cmosrtc", pnpDevice: pnpDevice)
    }


    override func initialise() -> Bool {
        guard let pnpDevice = device.busDevice as? PNPDevice, let resources = pnpDevice.getResources() else {
            return false
        }

        #kprint("CMOS: init:", resources)
        guard let ports = resources.ioPorts.first, ports.count > 1 else {
            #kprint("CMOS: Requires at least 2 IO ports:", resources)
            return false
        }

        let idx = ports.startIndex
        addressPort = ports[ports.index(idx, offsetBy: 0)]
        dataPort = ports[ports.index(idx, offsetBy: 1)]

        // Might be nil if no interrupt is specified in ACPI.
        irq = resources.interrupts.first

        if let century = system.deviceManager.acpiTables.facp?.rtcCenturyIndex, century < 64 {
            centuryIndex = century
        } else {
            centuryIndex = 0
        }
        device.initialised = true
        system.deviceManager.rtc = self
        self.setInstanceName(to: "cmos0")
        return true
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
                return #sprintf("%2.2d%2.2d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d",
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


    private var seconds: UInt8 { readMemory(0x00) }
    private var minutes: UInt8 { readMemory(0x02) }
    private var hours: UInt8 { readMemory(0x04) }
    private var dayOfMonth: UInt8 { readMemory(0x07) }
    private var month: UInt8 { readMemory(0x08) }
    private var year: UInt8 { readMemory(0x09) }
    private var century: UInt8 { centuryIndex > 0 ? readMemory(centuryIndex) : 0 }
    private var statusRegA: UInt8 { readMemory(0x0A) }
    private var statusRegB: UInt8 { readMemory(0x0B) }
    private var statusRegC: UInt8 { readMemory(0x0C) }
    private var statusRegD: UInt8 { readMemory(0x0D) }


    private func readMemory(_ index: UInt8) -> UInt8 {
        precondition(index >= 0 && index < 64)
        return noInterrupt {
            outb(addressPort, index)
            return inb(dataPort)
        }
    }


    private func writeMemory(_ index: UInt8, data: UInt8) {
        precondition(index >= 0 && index < 64)
        noInterrupt {
            outb(addressPort, index)
            outb(dataPort, data)
        }
    }
}
