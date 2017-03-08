/*
 * kernel/devices/apic.swift
 *
 * Created by Simon Evans on 04/01/2017.
 * Copyright © 2017 Simon Evans. All rights reserved.
 *
 * Advanced Programmable Interrupt Controller
 *
 */


class APIC: InterruptController {

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
    var lvtCMCI: UInt32 {
        get { return atOffset(0x2F0) }
        set(value) { atOffset(0x2F0, value: value) }
    }

    var interruptCmd: UInt64 {
        get {
            let lo = atOffset(0x300)
            let hi = atOffset(0x310)
            return UInt64(msw: hi, lsw: lo)
        }
        set(value) {
            let (hi, lo) = value.toWords()
            atOffset(0x300, value: lo)
            atOffset(0x310, value: hi)
        }
    }
    var lvtTimer: UInt32 {
        get { return atOffset(0x320) }
        set(value) { atOffset(0x320, value: value) }
    }
    var lvtThermalSensor: UInt32 {
        get { return atOffset(0x330) }
        set(value) { atOffset(0x330, value: value) }
    }
    var lvtPerfMonitorCounters: UInt32 {
        get { return atOffset(0x340) }
        set(value) { atOffset(0x340, value: value) }
    }
    var lvtLint0: UInt32 {
        get { return atOffset(0x350) }
        set(value) { atOffset(0x350, value: value) }
    }
    var lvtLint1: UInt32 {
        get { return atOffset(0x360) }
        set(value) { atOffset(0x360, value: value) }
    }
    var lvtError: UInt32 {
        get { return atOffset(0x370) }
        set(value) { atOffset(0x370, value: value) }
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

    init?() {
        guard CPU.capabilities.apic else {
            print("APIC: No APIC installed")
            return nil
        }
        print("APIC: Initialising..")
        let apicStatus: UInt64 = CPU.readMSR(IA32_APIC_BASE_MSR)
        let bootProcessor = apicStatus.bit(8)
        let globalEnable = apicStatus.bit(11)
        let maxPhyAddrBits = CPU.capabilities.maxPhyAddrBits
        let lomask = ~((1 << UInt(12)) - 1)
        let himask = (1 << maxPhyAddrBits) - 1
        let mask = lomask & himask
        let baseAddress = PhysAddress(apicStatus & UInt64(mask))
        printf("APIC: base address: 0x%lX\n", baseAddress)

        apicRegistersVaddr = mapIORegion(physicalAddr: baseAddress,
            size: APIC_REGISTER_SPACE_SIZE, cacheType: 7)
        let ptr = UnsafeMutableRawPointer(bitPattern: apicRegistersVaddr)!
        apicRegisters = UnsafeMutableRawBufferPointer(start: ptr,
            count: APIC_REGISTER_SPACE_SIZE)
        print("APIC: boot cpu: \(bootProcessor) maxPhyAddrBits: \(maxPhyAddrBits) enable: \(globalEnable)")

        printStatus()
        // Currently not finished so fail for now
        return nil
    }


    func enableIRQ(_ irq: Int) {
    }


    func disableIRQ(_ irq: Int) {
    }


    func disableAllIRQs() {
    }


    func ackIRQ(_ irq: Int) {
    }

    func printStatus() {
        print("APIC id: \(localAPICId) version: \(localAPICVersion)")
        printf("APIC: TPR: %8.8x APR: %8.8x PPR: %8.8x RRD: %8.8x ICR: %16.16X\n",
            taskPriority, arbitrationPriority, processorPriority, remoteRead,
            interruptCmd)
        printf("APIC: Logical Dest: %8.8x format: %8.8x Spurious INT: %8.8x\n",
            logicalDestination, destinationFormat, spuriousIntVector)
        printf("APIC: LVT: CMCI: %8.8X Timer: %8.8X Thermal: %8.8X PerfMon: %8.8X\n",
            lvtCMCI, lvtTimer, lvtThermalSensor, lvtPerfMonitorCounters)
        printf("APIC: LVT: LINT0: %8.8X LINT1: %8.8X Error: %8.8X\n",
            lvtLint0, lvtLint1, lvtError);
        printf("APIC: InitialCount: %8.8X CurrentCount: %8.8X Divide Config: %8.8X\n",
            initialCount, currentCount, divideConfig)
    }
}
