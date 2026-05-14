/*
 * kernel/devices/apic.swift
 *
 * Created by Simon Evans on 04/01/2017.
 * Copyright © 2017 Simon Evans. All rights reserved.
 *
 * Advanced Programmable Interrupt Controller
 *
 */


struct LVTEntry: CustomStringConvertible {
    fileprivate(set) var value: BitArray32

    enum DeliveryStatus: Int {
    case Idle = 0
    case SendPending = 1
    }

    var vector: UInt8 {
        get {
            return UInt8(value[0...7])
        }
        set {
            //let data = BitArray32(rawValue: newValue)
            value[0...7] = UInt32(newValue)
            //value.replaceSubrange(0...7, with: data)
        }
    }

    var deliveryStatus: DeliveryStatus {
        return DeliveryStatus(rawValue: value[12])!
    }

    var masked: Bool {
        get { value[16] == 1 }
        set { value[16] = newValue ? 1 : 0 }
    }


    var description: String {
        return "INT\(vector) Masked: " + (masked ? "Yes" : "No")
    }

    var rawValue: UInt32 { return value.rawValue }

    init(rawValue: UInt32) {
        value = BitArray32(rawValue)
    }
}


typealias TimerEntry = LVTEntry
extension TimerEntry {

    enum TimerMode: UInt8 {
    case oneShot     = 0b00
    case periodic    = 0b01
    case tscDeadline = 0b10
    }

    var timerMode: TimerMode {
        get {
            let rawValue = UInt8(value[17...18])
            return TimerMode(rawValue: rawValue) ?? .oneShot
        }
        set {
            //let data = BitArray32(newValue.rawValue)
            value[17...18] = UInt32(newValue.rawValue)
            //value.replaceSubrange(17...18, with: data)
        }
    }


//    var description: String {
//        return "\(entry) TimerMode: " + String(describing: timerMode)
//    }
}


typealias InterruptEntry = LVTEntry
extension InterruptEntry {

    enum DeliveryMode: Int {
    case Fixed  = 0b000
    case SMI    = 0b010
    case NMI    = 0b100
    case ExtInt = 0b111
    case INIT   = 0b101
    }

    var deliveryMode: DeliveryMode {
        get {
            let mode = DeliveryMode(rawValue: Int(value[8...10]))
            return mode ?? .Fixed
        }
        set {
            //let data = BitArray32(newValue.rawValue)
            //value.replaceSubrange(8...10, with: data)
            value[8...10] = UInt32(newValue.rawValue)
        }
    }

//    var description: String {
//        return "\(entry) DeliveryMode: " + String(describing: deliveryMode)
//    }
}

typealias LocalInterruptEntry = InterruptEntry
extension LocalInterruptEntry {
    enum InputPinPolarity {
    case ActiveHigh
    case ActiveLow
    }

    enum TriggerMode: Int {
    case Edge
    case Level
    }

    var inputPinPolarity: InputPinPolarity {
        return value[13] == 0 ? .ActiveHigh : .ActiveLow
    }

    var triggerMode: TriggerMode {
        return value[15] == 0 ? .Edge : .Level
    }

    var remoteIRR: Bool { return value[14] == 1 }

//    var description: String {
//        return "\(intEntry) Trigger: \(triggerMode)"
//            + " InputPolarity: \(inputPinPolarity)"
//    }
}

private var apic = APIC()

struct APIC: ~Copyable {

    // 256 bit register composed of 8x32bit values
    // Each 32bit value is on a 128bit (16byte) boundary
    // These registers can only be read using 32bit accesses
    struct Register256 {
        private let registers: UnsafeMutableRawBufferPointer
        private let offset: Int

        init(_ registers: UnsafeMutableRawBufferPointer, _ offset: Int) {
            self.registers = registers
            self.offset = offset
        }

        func bit(_ bit: Int) -> Bool {
            let idx = (bit / 32) * 16
            let value = registers.load(fromByteOffset: offset + idx,
                as: UInt32.self)
            return value.bit(bit % 32)
        }
    }


    static private let IA32_APIC_BASE_MSR: UInt32 = 0x1B
    static private let APIC_REGISTER_SPACE_SIZE = 0x400
    static private let globalEnableBit = 11

    private var apicRegisters = UnsafeMutableRawBufferPointer(start: nil, count: 0)

    static func initialise() -> Bool {
        apic.initialise()
    }

    static func disableAllIRQs() {
        apic.disableAllIRQs()
    }

    static func ackIRQ(_ irq: Int) {
        apic.ackIRQ(irq)
    }

    private mutating func initialise() -> Bool {
        guard CPU.capabilities.apic else {
            #kprint("APIC: No APIC installed")
            return false
        }
        #kprint("APIC: Initialising..")

        var apicStatus = BitArray64(CPU.readMSR(APIC.IA32_APIC_BASE_MSR))

        // Enable the APIC if currently disabled
        if apicStatus[Self.globalEnableBit] != 1 {
            apicStatus[Self.globalEnableBit] = 1
            CPU.writeMSR(APIC.IA32_APIC_BASE_MSR, apicStatus.toUInt64())
            apicStatus = BitArray64(CPU.readMSR(APIC.IA32_APIC_BASE_MSR))
            if apicStatus[Self.globalEnableBit] != 1 {
                #kprint("APIC: failed to enable")
                return false
            }
        }

        let region = APIC.addressRegion()
        #kprintf("APIC: base address: 0x%X\n", region.baseAddress.value)
        let mmio = mapIORegion(region: region, cacheType: .uncacheable)
        let ptr = mmio.baseAddress.rawPointer
        apicRegisters = UnsafeMutableRawBufferPointer(start: ptr,
            count: APIC.APIC_REGISTER_SPACE_SIZE)

        printStatus()
        spuriousIntVector = 0x1ff
        return true
    }


    var localAPICId:      UInt32 { return atOffset(0x20) }
    var localAPICVersion: UInt32 { return atOffset(0x30) }
    var taskPriority:     UInt32 { return atOffset(0x80) }
    var arbitrationPriority: UInt32 { return atOffset(0x90) }
    var processorPriority: UInt32 { return atOffset(0xA0) }
    var EOI: UInt32 {
        get { 0 }
        set { atOffset(0xB0, value: newValue) }
    }
    var remoteRead:       UInt32 { return atOffset(0xC0) }
    var logicalDestination: UInt32 {
        get { atOffset(0xD0) }
        set { atOffset(0xD0, value: newValue) }
    }
    var destinationFormat: UInt32 {
        get { atOffset(0xE0) }
        set { atOffset(0xE0, value: newValue) }
    }
    var spuriousIntVector: UInt32 {
        get { atOffset(0xF0) }
        set { atOffset(0xF0, value: newValue) }
    }
    var inService:    Register256 { return Register256(apicRegisters, 0x100) }
    var triggerMode:  Register256 { return Register256(apicRegisters, 0x180) }
    var interruptReq: Register256 { return Register256(apicRegisters, 0x200) }
    var errorStatus:  UInt32      { return atOffset(0x280) }

    var lvtCMCI: InterruptEntry {
        get { InterruptEntry(rawValue: atOffset(0x2F0)) }
        set { atOffset(0x2F0, value: newValue.rawValue) }
    }

    var interruptCmd: UInt64 {
        get {
            let lo = atOffset(0x300)
            let hi = atOffset(0x310)
            return UInt64(withDWords: lo, hi)
        }
        set {
            let v = DWordArray2(newValue)
            atOffset(0x300, value: v[0])
            atOffset(0x310, value: v[1])
        }
    }
    var lvtTimer: TimerEntry {
        get { TimerEntry(rawValue: atOffset(0x320)) }
        set { atOffset(0x320, value: newValue.rawValue) }
    }

    var lvtThermalSensor: InterruptEntry {
        get { InterruptEntry(rawValue: atOffset(0x330)) }
        set { atOffset(0x330, value: newValue.rawValue) }
    }

    var lvtPerfMonitorCounters: InterruptEntry {
        get { InterruptEntry(rawValue: atOffset(0x340)) }
        set { atOffset(0x340, value: newValue.rawValue) }
    }

    var lvtLint0: LocalInterruptEntry {
        get { LocalInterruptEntry(rawValue: atOffset(0x350)) }
        set { atOffset(0x350, value: newValue.rawValue) }
    }

    var lvtLint1: LocalInterruptEntry {
        get { LocalInterruptEntry(rawValue: atOffset(0x360)) }
        set { atOffset(0x360, value: newValue.rawValue) }
    }

    var lvtError: LVTEntry {
        get { LVTEntry(rawValue: atOffset(0x370)) }
        set { atOffset(0x370, value: newValue.rawValue) }
    }

    var initialCount: UInt32 {
        get { atOffset(0x380) }
        set { atOffset(0x380, value: newValue) }
    }

    var currentCount: UInt32 { return atOffset(0x390) }
    var divideConfig: UInt32 {
        get { atOffset(0x3E0) }
        set { atOffset(0x3E0, value: newValue) }
    }


    private func atOffset(_ offset: Int) -> UInt32 {
        return apicRegisters.load(fromByteOffset: offset, as: UInt32.self)
    }

    private func atOffset(_ offset: Int, value: UInt32) {
        apicRegisters.storeBytes(of: value, toByteOffset: offset,
            as: UInt32.self)
    }

    static func addressRegion() -> PhysRegion {
        let maxPhyAddrBits = CPU.capabilities.maxPhyAddrBits
        let lomask = ~(UInt(1 << 12) - 1)
        let himask = (UInt(1) << maxPhyAddrBits) - 1
        let mask = lomask & himask
        let apicStatus = BitArray64(CPU.readMSR(IA32_APIC_BASE_MSR))
        let address = RawAddress(apicStatus.toUInt64() & UInt64(mask))
        let baseAddress = PhysAddress(address)
        return PhysRegion(start: baseAddress, size: UInt(APIC_REGISTER_SPACE_SIZE))
    }

    func disableAllIRQs() {
    }


    func ackIRQ(_ irq: Int) {
        atOffset(0xB0, value: 1)    // Send EOI
    }

    func printStatus() {
        #kprint("APIC id: \(localAPICId) version: \(localAPICVersion)")
        #kprintf("APIC: TPR: %8.8x APR: %8.8x PPR: %8.8x RRD: %8.8x ICR: %16.16X\n",
            taskPriority, arbitrationPriority, processorPriority, remoteRead,
            interruptCmd)
        #kprintf("APIC: Logical Dest: %8.8x format: %8.8x Spurious INT: %8.8x\n",
            logicalDestination, destinationFormat, spuriousIntVector)

        #kprint("APIC: LVT:   Timer:", lvtTimer)
        #kprint("APIC: LVT:    CMCI:", lvtCMCI)
        #kprint("APIC: LVT:   LINT0:", lvtLint0)
        #kprint("APIC: LVT:   LINT1:", lvtLint1)
        #kprint("APIC: LVT:   Error:", lvtError)
        #kprint("APIC: LVT: PerfMon:", lvtPerfMonitorCounters)
        #kprint("APIC: LVT: Thermal:", lvtThermalSensor)
    }

    static func setupTimer() -> Bool {
        apic.setupTimer()
    }

    static private(set) var calibratedFrequency: UInt32 = 0
    private mutating func setupTimer() -> Bool {
        #kprint("APIC: setting up timer")

        var newLvtTimer = lvtTimer
        newLvtTimer.deliveryMode = .Fixed
        // The 7 APIC interrupts start at IDT entry 240
        newLvtTimer.vector = 240
        newLvtTimer.masked = true

        let irq = IRQSetting(isaIrq: 240)
        let handler = InterruptHandler(name: "apic-timer", handler: timerInterrupt)
        InterruptManager.setIrqHandler(handler, forInterrupt: irq)

        if let timeSource = TimesourceTSC(), timeSource.hasDeadline {
            #kprint("APIC: setting up timer using TSC Deadline mode")
            newLvtTimer.timerMode = .tscDeadline
            newLvtTimer.masked = false
            lvtTimer = newLvtTimer
            memoryBarrier()
            tscDeadlinePeriod = timeSource.tscFrequency / TICKS_PER_SECOND
            tscDeadlineNext = rdtsc()
            #kprintf("apic: tscDeadlinePeriod: %u tscDeadlineNext: %u\n", tscDeadlinePeriod,
                     tscDeadlineNext)
            rearmAPICTimer()
        } else {
            #kprint("APIC: No valid TSC information")
            #kprint("APIC: setting up timer using Periodic mode")
            if cpu.crystalFrequency > 0 {
                #kprintf("APIC: Using busFrequency of %u hz\n", cpu.crystalFrequency)
                self.initialCount = UInt32(cpu.crystalFrequency / TICKS_PER_SECOND)
            } else {
                let freq1 = calibrate()
                let freq2 = calibrate()
                let freq3 = calibrate()
                let frequency = UInt32((freq1 + freq2 + freq3) / 3)
                #kprintf("APIC: calibrated frequency: %u setting initialCount to %u\n",
                         frequency, frequency / UInt32(TICKS_PER_SECOND)
                )
                self.initialCount = frequency / UInt32(TICKS_PER_SECOND)
                APIC.calibratedFrequency = frequency
            }
            self.divideConfig = 0x3 //0b1011   // Divide by 1
            newLvtTimer.timerMode = .periodic
            newLvtTimer.masked = false
            if currentTicks() > 0 {
                fatalError("currentTicks is \(currentTicks())")
            }
            lvtTimer = newLvtTimer
        }

        #kprint("APIC: new Timer: ", lvtTimer)
        #kprintf("APIC: InitialCount: %8.8X CurrentCount: %8.8X Divide Config: %8.8X\n",
            initialCount, currentCount, divideConfig)
        return true
    }

    // Calibrate the APIC against the PM timer to get the timer frequency
    private mutating func calibrate() -> UInt64 {
        guard let timerPort = ACPI.fadt?.pmTimerPort, timerPort > 0 else {
            fatalError("no PM timer")
        }
        // Set the ticks to maximum (0xffff_ffff), wait 100ms then read the new value
        self.divideConfig = 0x3 //0b1011   // Divide by 1
        self.initialCount = 0xffff_ffff

        let milliSeconds = 100
        let port = UInt16(timerPort)
        // Treat the timer as 24 bit and wrap appropiately
        let mask: UInt32 = 0xfff_fff //(1 << 24) - 1
        let totalTicks = (UInt64(ACPI.pmTimerFrequency) &* UInt64(milliSeconds)) / 1000

        // Read the port until it enters the next tick then loop until total ticks have passed
        var start = inl(port) & mask
        while true {
            let now = inl(port) & mask
            if now != start {
                start = now
                break
            }
        }

        let count0 = self.currentCount
        var elapsed: UInt32 = 0
        var last = start
        while elapsed <= totalTicks {
            let now = inl(port) & mask
            if now < last {
                elapsed += now + (mask + 1) - last
            } else {
                elapsed += (now - last)
            }
            last = now
            pause()
        }
        let count = self.currentCount

        let frequency = UInt64(count0 - count) * 10;
        #kprintf("APIC: calibrate, count0 is %u, count is %u for 100ms. frequency: %u.%uMHz\n",
                count0, count, frequency / 1000_000, frequency % 1_000_000
        )
        guard frequency > 0 else {
            fatalError("APIC has 0 frequency!")
        }
        return frequency
    }
}

private(set) var tscDeadlinePeriod: UInt64 = 0
private(set) var tscDeadlineNext: UInt64 = 0

func rearmAPICTimer() {
    if tscDeadlineNext > 0 {
        tscDeadlineNext &+= tscDeadlinePeriod
        wrmsr(0x6e0, UInt32(truncatingIfNeeded: tscDeadlineNext), UInt32(truncatingIfNeeded: tscDeadlineNext >> 32))
    }
}
