//
//  kernel/devices/acpi/hpet.swift
//
//  Created by Simon Evans on 29/04/2017.
//  Copyright © 2017 - 2021 Simon Evans. All rights reserved.
//
//  Parsing of High Precision Event Timer (HPET).

// FIXME: The individual timers should probable be represented with a 'class HPETTimer' or something
struct HPET: ACPITable, CustomStringConvertible {

    private let table: acpi_hpet_table
    private let mmioRegion: MMIORegion

    // ACPI Fields
    var pciVendorId: UInt16 {
        let val = BitArray32(table.timer_block_id)
        let val2 = UInt16(val[16...31])
        return val2
    }

    var legacyIrqReplacement: Bool {
        let val = BitArray32(table.timer_block_id)
        return (val[15] != 0)
    }

    var counterSizeCap: Bool {
        let val = BitArray32(table.timer_block_id)
        return (val[13] != 0)
    }

    var isMainCounter32Bit: Bool {
        return !counterSizeCap
    }

    var isMainCounter64Bit: Bool {
        return counterSizeCap
    }

    var maxComparatorIndex: Int {
        let val = BitArray32(table.timer_block_id)
        return Int(val[8...12])
    }

    var comparatorCount: Int { maxComparatorIndex + 1 }

    var hardwareRevisionId: UInt8 {
        let val = BitArray32(table.timer_block_id)
        return UInt8(val[0...7])
    }

    var baseAddress: ACPIGenericAddressStrucure {
        return ACPIGenericAddressStrucure(table.base_address)
    }

    var hpetNumber: Int {
        return Int(table.hpet_number)
    }

    // Unit: Clock tick
    // The minimum clock ticks can be set without lost interrupts while
    // the counter is programmed to operate in periodic mode.
    var mainCounterMinClockTicks: Int { Int(table.min_clock_ticks) }

    // Size of page including the 1K block that can be accessed without causing an MCE.
    var pageProtection: Int {
        let protection = table.page_protection & 0b1111
        switch protection {
            case 0: return 1024
            case 1: return 4096
            case 2: return 65536
            default:
                print("HPET: unknown page protection: \(protection)")
                return 0
        }
    }


    var description: String {
        return "HPET: \(String(baseAddress.baseAddress, radix: 16)) vendor: \(asHex(pciVendorId)) legacyIrq: \(legacyIrqReplacement)"
            + " counterSizeCap: \(counterSizeCap) clockPersion: \(counterClockPeriod) comparators: \(comparatorCount)"
            + " revId: \(asHex(hardwareRevisionId)) hpetNumber: \(hpetNumber) legacyReplacementRoute: \(legacyReplacementRoute)"
    }


    init(_ ptr: UnsafeRawPointer) {
        table = ptr.load(as: acpi_hpet_table.self)
        let length = table.header.length
        guard length >= MemoryLayout<acpi_hpet_table>.size else {
            fatalError("ACPI: FACS table is too short at \(length) bytes")
        }

        let gas = ACPIGenericAddressStrucure(table.base_address)
        let physicalRegion = PhysPageRange(gas.physicalAddress, pageSize: PAGE_SIZE, pageCount: 1)
        mmioRegion = mapIORegion(region: physicalRegion)
    }

    // HPET capabilities

    // Main Counter Tick Period in femptoseconds (10^-15 seconds).
    var counterClockPeriod: UInt32 {
        baseAddress.rawPointer.load(fromByteOffset: 4, as: UInt32.self)
    }

    private var generalConfigurationRegister: UInt32 {
        get { mmioRegion.read(fromByteOffset: 0x10) }
        set { mmioRegion.write(value: newValue, toByteOffset: 0x10) }
    }

    // GLOBAL_ENABLE_CNF
    var overallEnable: Bool {
        get { Bool(BitArray32(generalConfigurationRegister)[0]) }
        set {
            var value = BitArray32(generalConfigurationRegister)
            value[0] = newValue ? 1 : 0
            generalConfigurationRegister = value.rawValue
        }
    }


    // LEG_RT_CNF
    var legacyReplacementRoute: Bool {
        get { Bool(BitArray32(generalConfigurationRegister)[1]) }
        set {
            var value = BitArray32(generalConfigurationRegister)
            value[1] = newValue ? 1 : 0
            generalConfigurationRegister = value.rawValue
        }
    }

    var generalInterruptStatusRegister: UInt32 {
        get { baseAddress.rawPointer.load(fromByteOffset: 0x20, as: UInt32.self) }
        set { baseAddress.rawPointer.storeBytes(of: newValue, toByteOffset: 0x20, as: UInt32.self) }
    }


    var mainCounterRegister: UInt64 {
        get { mmioRegion.read(fromByteOffset: 0xf0) }
        set { mmioRegion.write(value: newValue, toByteOffset: 0xf0) }
    }


    // Timer Blocks, 0 - .maxComparatorIndex
    func configFor(timer: Int) -> TimerConfiguration {
        precondition(timer <= maxComparatorIndex)
        let offset = 0x100 + (timer * 0x20)
        let low: UInt32 = mmioRegion.read(fromByteOffset: offset)
        let high: UInt32 = mmioRegion.read(fromByteOffset: offset + 4)
        return TimerConfiguration(low: low, high: high)
    }

    func setConfigFor(timer: Int, config: TimerConfiguration) {
        precondition(timer <= maxComparatorIndex)
        let offset = 0x100 + (timer * 0x20)
        mmioRegion.write(value: config.rawValue, toByteOffset: offset)
    }

    func comparatorValueFor(timer: Int) -> UInt64 {
        precondition(timer <= maxComparatorIndex)
        let offset = 0x108 + (timer * 0x20)
        return mmioRegion.read(fromByteOffset: offset)
    }

    func setComparatorValueFor(timer: Int, value: UInt64) {
        precondition(timer <= maxComparatorIndex)
        let offset = 0x108 + (timer * 0x20)
        mmioRegion.write(value: value, toByteOffset: offset)
    }

    func fsbInterruptRouteRegisterFor(timer: Int) -> (address: UInt32, value: UInt32) {
        precondition(timer <= maxComparatorIndex)
        let offset = 0x110 + (timer * 0x20)
        let address = baseAddress.rawPointer.load(fromByteOffset: offset + 4, as: UInt32.self)
        let value = baseAddress.rawPointer.load(fromByteOffset: offset, as: UInt32.self)
        return (address, value)
    }

    func setFsbInterruptRouteRegisterFor(timer: Int, address: UInt32, value: UInt32) {
        precondition(timer <= maxComparatorIndex)
        let offset = 0x110 + (timer * 0x20)
        baseAddress.rawPointer.storeBytes(of: address, toByteOffset: offset + 4, as: UInt32.self)
        baseAddress.rawPointer.storeBytes(of: value, toByteOffset: offset, as: UInt32.self)
    }


    private func comparatorValueFor(ticksPerSecond: Int) -> UInt64 {
        let frequency: UInt64 = 1_000_000_000_000_000 / UInt64(counterClockPeriod)  // 10^15 / tick period
        let ticks = frequency / UInt64(ticksPerSecond)
        return ticks
    }


    func showConfiguration() {
        print("HPET", self)
        print("HPET: mainCounterRegister:", mainCounterRegister)

        guard comparatorCount > 0 else {
            print("HPET: No timers found")
            return
        }
        for timer in 0...maxComparatorIndex {
            let config = configFor(timer: timer)
            print("HPET: Timer\(timer) config:", config, "comparatorValue:", comparatorValueFor(timer: timer))
        }
    }

    mutating func emulateLegacyPIT(ticksPerSecond: Int) -> Bool {
        print("HPET: Emulating Legacy PIT with period \(ticksPerSecond)Hz")
        showConfiguration()
        var timer0 = configFor(timer: 0)
        guard timer0.periodicInterruptCapable else {
            print("HPET: timer0 is not capable of periodic interrupts")
            return false
        }

        let comparatorValue = comparatorValueFor(ticksPerSecond: ticksPerSecond)
        // Halt the main counter
        overallEnable = false
        // Clear main counter
        mainCounterRegister = 0

        // Enable Legacy interrupt routing
        legacyReplacementRoute = true

        // Setup timer0
        timer0.isLevelTriggered = false
        timer0.interruptEnabled = true
        timer0.interruptsArePeriodic = true
        timer0.enableTimerValueSet = true   // writing a value
        setConfigFor(timer: 0, config: timer0)

        // Set comparator value for requested period
        setComparatorValueFor(timer: 0, value: comparatorValue)
        // Enable the main counter
        overallEnable = true
        return true
    }
}

extension HPET {
    // There are multiple timers
    struct TimerConfiguration: CustomStringConvertible {
        private var bits: BitArray32

        var rawValue: UInt32 { bits.rawValue }

        var description: String {
            return "isLevel: \(isLevelTriggered) intEnabled: \(interruptEnabled) periodicCap: \(periodicInterruptCapable)"
                + " isPeriodic: \(interruptsArePeriodic) is64Bit: \(timerIs64Bit) fsbIntCap: \(fsbInterruptDeliveryCapable)"
                + " FSB IntEnable: \(fsbInterruptDeliveryEnable) intRoutingCap: \(String(interruptRoutingCapability, radix: 16))"
                + " intRoute: \(String(interruptRoute))"
        }

        init(low: UInt32, high: UInt32) {
            bits = BitArray32(low)
            interruptRoutingCapability = high
        }

        // Tn_INT_TYPE_CNF
        var isLevelTriggered: Bool {
            get { Bool(bits[1]) }
            set { bits[1] = newValue ? 1 : 0 }
        }

        // Tn_INT_ENB_CNF
        var interruptEnabled: Bool {
            get { Bool(bits[2]) }
            set { bits[2] = newValue ? 1 : 0 }
        }

        // Tn_TYPE_CNF
        var interruptsArePeriodic: Bool {
            get { Bool(bits[3]) }
            set { bits[3] = newValue ? 1 : 0 }
        }

        // Tn_INT_PER_CAP
        var periodicInterruptCapable: Bool { Bool(bits[4]) }

        // Tn_SIZE_CAP
        var timerIs64Bit: Bool { Bool(bits[5]) }

        // Tn_VAL_SET_CNF
        var enableTimerValueSet: Bool {
            get { Bool(bits[6]) }
            set { bits[6] = newValue ? 1 : 0 }
        }

        // Tn_32MODE_CNF
        var force32bitTimer: Bool {
            get { Bool(bits[8]) }
            set { bits[8] = newValue ? 1 : 0 }
        }

        // Tn_INT_ROUTE_CNF
        var interruptRoute: Int {
            get { Int(bits[9...13]) }
            set { bits[9...13] = UInt32(newValue) }
        }

        // Tn_FSB_EN_CNF
        var fsbInterruptDeliveryEnable: Bool {
            get { Bool(bits[14]) }
            set { bits[14] = newValue ? 1 : 0 }
        }

        // Tn_FSB_INT_DEL_CAP
        var fsbInterruptDeliveryCapable: Bool { Bool(bits[15]) }

        // Tn_INT_ROUTE_CAP (set in init)timer
        let interruptRoutingCapability: UInt32
    }
}
