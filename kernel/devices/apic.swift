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
        set(newValue) {
            //let data = BitArray32(rawValue: newValue)
            value[0...7] = UInt32(newValue)
            //value.replaceSubrange(0...7, with: data)
        }
    }

    var deliveryStatus: DeliveryStatus {
        return DeliveryStatus(rawValue: value[12])!
    }

    var masked: Bool {
        get { return value[16] == 1 }
        set(newValue) { value[16] = newValue ? 1 : 0 }
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
        set(newValue) {
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
        set(newValue) {
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


public class APIC: InterruptController {

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


    private let IA32_APIC_BASE_MSR: UInt32 = 0x1B
    private let APIC_REGISTER_SPACE_SIZE = 0x400
    private let bootProcessorBit = 8
    private let globalEnableBit = 11

    private let apicRegistersVaddr: VirtualAddress
    private let apicRegisters: UnsafeMutableRawBufferPointer

    var localAPICId:      UInt32 { return atOffset(0x20) }
    var localAPICVersion: UInt32 { return atOffset(0x30) }
    var taskPriority:     UInt32 { return atOffset(0x80) }
    var arbitrationPriority: UInt32 { return atOffset(0x90) }
    var processorPriority: UInt32 { return atOffset(0xA0) }
    var EOI: UInt32 {
        get { return 0 }
        set(value) { atOffset(0xB0, value: value) }
    }
    var remoteRead:       UInt32 { return atOffset(0xC0) }
    var logicalDestination: UInt32 {
        get { return atOffset(0xD0) }
        set(value) { atOffset(0xD0, value: value) }
    }
    var destinationFormat: UInt32 {
        get { return atOffset(0xE0) }
        set(value) { atOffset(0xE0, value: value) }
    }
    var spuriousIntVector: UInt32 {
        get { return atOffset(0xF0) }
        set(value) { atOffset(0xF0, value: value) }
    }
    var inService:    Register256 { return Register256(apicRegisters, 0x100) }
    var triggerMode:  Register256 { return Register256(apicRegisters, 0x180) }
    var interruptReq: Register256 { return Register256(apicRegisters, 0x200) }
    var errorStatus:  UInt32      { return atOffset(0x280) }

    var lvtCMCI: InterruptEntry {
        get { return InterruptEntry(rawValue: atOffset(0x2F0)) }
        set(newValue) { atOffset(0x2F0, value: newValue.rawValue) }
    }

    var interruptCmd: UInt64 {
        get {
            let lo = atOffset(0x300)
            let hi = atOffset(0x310)
            return UInt64(withDWords: lo, hi)
        }
        set(value) {
            let v = DWordArray2(value)
            atOffset(0x300, value: v[0])
            atOffset(0x310, value: v[1])
        }
    }
    var lvtTimer: TimerEntry {
        get { return TimerEntry(rawValue: atOffset(0x320)) }
        set(newValue) { atOffset(0x320, value: newValue.rawValue) }
    }

    var lvtThermalSensor: InterruptEntry {
        get { return InterruptEntry(rawValue: atOffset(0x330)) }
        set(newValue) { atOffset(0x330, value: newValue.rawValue) }
    }
    var lvtPerfMonitorCounters: InterruptEntry {
        get { return InterruptEntry(rawValue: atOffset(0x340)) }
        set(newValue) { atOffset(0x340, value: newValue.rawValue) }
    }
    var lvtLint0: LocalInterruptEntry {
        get { return LocalInterruptEntry(rawValue: atOffset(0x350)) }
        set(newValue) { atOffset(0x350, value: newValue.rawValue) }
    }
    var lvtLint1: LocalInterruptEntry {
        get { return LocalInterruptEntry(rawValue: atOffset(0x360)) }
        set(newValue) { atOffset(0x360, value: newValue.rawValue) }
    }
    var lvtError: LVTEntry {
        get { return LVTEntry(rawValue: atOffset(0x370)) }
        set(newValue) { atOffset(0x370, value: newValue.rawValue) }
    }
    var initialCount: UInt32 {
        get { return atOffset(0x380) }
        set(value) { atOffset(0x380, value: value) }
    }
    var currentCount: UInt32 { return atOffset(0x390) }
    var divideConfig: UInt32 {
        get { return atOffset(0x3E0) }
        set(value) { atOffset(0x3E0, value: value) }
    }


    private func atOffset(_ offset: Int) -> UInt32 {
        return apicRegisters.load(fromByteOffset: offset, as: UInt32.self)
    }

    private func atOffset(_ offset: Int, value: UInt32) {
        apicRegisters.storeBytes(of: value, toByteOffset: offset,
            as: UInt32.self)
    }


    private let ioapics: [IOAPIC]

    init?(madtEntries: [MADTEntry]) {
        guard CPU.capabilities.apic else {
            print("APIC: No APIC installed")
            return nil
        }
        print("APIC: Initialising..")

        var apicStatus = BitArray64(CPU.readMSR(IA32_APIC_BASE_MSR))

        // Enable the APIC if currently disabled
        if apicStatus[globalEnableBit] != 1 {
            apicStatus[globalEnableBit] = 1
            CPU.writeMSR(IA32_APIC_BASE_MSR, apicStatus.toUInt64())
            apicStatus = BitArray64(CPU.readMSR(IA32_APIC_BASE_MSR))
            if apicStatus[globalEnableBit] != 1 {
                print("APIC: failed to enable")
                return nil
            }
        }

        let bootProcessor = apicStatus[bootProcessorBit] == 1
        let maxPhyAddrBits = CPU.capabilities.maxPhyAddrBits
        let lomask = ~(UInt(1 << 12) - 1)
        let himask = (UInt(1) << maxPhyAddrBits) - 1
        let mask = lomask & himask
        let address = RawAddress(apicStatus.toUInt64() & UInt64(mask))
        let baseAddress = PhysAddress(address)
        printf("APIC: base address: 0x%X\n", baseAddress.value)

        apicRegistersVaddr = mapIORegion(physicalAddr: baseAddress,
            size: APIC_REGISTER_SPACE_SIZE, cacheType: 7)
        let ptr = UnsafeMutableRawPointer(bitPattern: apicRegistersVaddr)!
        apicRegisters = UnsafeMutableRawBufferPointer(start: ptr,
            count: APIC_REGISTER_SPACE_SIZE)
        print("APIC: boot \(bootProcessor) maxPhyAddrBits: \(maxPhyAddrBits)")

        var ioapicEntries: [MADT.IOApicTable] = []
        var overrideEntries: [MADT.InterruptSourceOverrideTable] = []

        madtEntries.forEach {
            if let entry = $0 as? MADT.IOApicTable {
                ioapicEntries.append(entry)
            } else if let entry = $0 as? MADT.InterruptSourceOverrideTable {
                overrideEntries.append(entry)
            }
        }

        guard ioapicEntries.count > 0 else {
            fatalError("Cant find any IO-APICs in the ACPI:MADT tables")
            return nil
        }
        var _ioapics: [IOAPIC] = []
        for entry in ioapicEntries {
            if let ioapic = IOAPIC(apic: entry,
                intSourceOverrides: overrideEntries) {
                print("ioapic: ", ioapic)
                _ioapics.append(ioapic)
            }
        }
        ioapics = _ioapics
        print("APIC: Have \(ioapics.count) IO-APICs")

        printStatus()
        setupTimer()
        spuriousIntVector = 0x1ff
    }


    func enableIRQ(_ irq: Int) {
        print("APIC: enableIRQ:", irq)
        ioapics[0].enableIRQ(irq)
    }


    func disableIRQ(_ irq: Int) {
        print("APIC: disableIRQ:", irq)
        ioapics[0].disableIRQ(irq)
    }


    func disableAllIRQs() {
    }


    func ackIRQ(_ irq: Int) {
        EOI = 1
    }

    func printStatus() {
        print("APIC id: \(localAPICId) version: \(localAPICVersion)")
        printf("APIC: TPR: %8.8x APR: %8.8x PPR: %8.8x RRD: %8.8x ICR: %16.16X\n",
            taskPriority, arbitrationPriority, processorPriority, remoteRead,
            interruptCmd)
        printf("APIC: Logical Dest: %8.8x format: %8.8x Spurious INT: %8.8x\n",
            logicalDestination, destinationFormat, spuriousIntVector)


        print("APIC: LVT:   Timer:", lvtTimer)
        print("APIC: LVT:    CMCI:", lvtCMCI)
        print("APIC: LVT:   LINT0:", lvtLint0)
        print("APIC: LVT:   LINT1:", lvtLint1)
        print("APIC: LVT:   Error:", lvtError)
        print("APIC: LVT: PerfMon:", lvtPerfMonitorCounters)
        print("APIC: LVT: Thermal:", lvtThermalSensor)
    }


    func setupTimer() {
                printf("APIC: InitialCount: %8.8X CurrentCount: %8.8X Divide Config: %8.8X\n",
            initialCount, currentCount, divideConfig)

        var newLvtTimer = lvtTimer
        newLvtTimer.deliveryMode = .Fixed
        newLvtTimer.vector = 48
        newLvtTimer.masked = false
        newLvtTimer.timerMode = .periodic
        lvtTimer = newLvtTimer
        divideConfig = 0b1001
        initialCount = 100000000
        print("APIC, new Timer: ", lvtTimer)

        printf("APIC: InitialCount: %8.8X CurrentCount: %8.8X Divide Config: %8.8X\n",
            initialCount, currentCount, divideConfig)
    }
}


// Called from entry.asm:_apic_int_handler
@_silgen_name("apicIntHandler")
public func apicIntHandler(registers: ExceptionRegisters) {
    let apicInt = Int(registers.pointee.error_code)
    guard apicInt >= 0 && apicInt < 7 else {
        printf("OOPS: Invalid APIC interrupt: %#x\n", apicInt)
        stop()
    }

    //printf("APIC INT Handler: %d\n", apicInt)
    if let apic = localAPIC {
        apic.EOI = 1
    }
}
