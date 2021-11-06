 /*
  * kernel/devices/ioapic.swift
  *
  * Created by Simon Evans on 11/02/2017.
  * Copyright © 2017 Simon Evans. All rights reserved.
  *
  * IO-APIC IO-Advanced Programmable Interrupt Controller
  *
  */


final class IOAPIC {

    fileprivate let registerSelect: UnsafeMutablePointer<UInt32>
    fileprivate let registerData: UnsafeMutablePointer<UInt32>

    private let registerBase: VirtualAddress
    let globalSystemInterruptBase: UInt32
    

    init(ioApicId: UInt8, baseAddress: PhysAddress, gsiBase: UInt32) {
        self.globalSystemInterruptBase = gsiBase

        print("IOAPIC: ID: \(ioApicId) Address: \(baseAddress) interrupt base: \(gsiBase)")

        // FIXME: Use MMIO
        registerBase = mapIORegion(physicalAddr: baseAddress, size: 0x20)
        registerSelect = UnsafeMutablePointer<UInt32>(bitPattern: registerBase)!
        registerData = UnsafeMutablePointer<UInt32>(bitPattern: registerBase + 0x10)!
    }


    func enableIRQ(_ irqSetting: IRQSetting, vector: UInt8) {
        let irq = irqSetting.irq
        print("IO-APIC: Enabling:", irq)
        let register = redirectionRegisterFor(irq: irq)
        print("IO-APIC: vector: \(vector) redirectionRegister: \(register)")

        var data = IORedirectionRegister()
        data.idtVector = vector 
        data.deliveryMode = .fixed
        data.destinationMode = .physical
        data.inputPinPolarity = irqSetting.activeHigh ? .activeHigh : .activeLow
        data.triggerMode = irqSetting.levelTriggered ? .level : .edge
        data.maskInterrupt = false
        data.destinationField = 0   // APIC ID
        writeWideRegister(register, data: data)
    }


    func disableIRQ(_ irqSetting: IRQSetting) {
        let irq = irqSetting.irq
        let register = redirectionRegisterFor(irq: irq)

        print("IO-APIC: disabling IRQ:", irq, "register:", register)
        var data = readWideRegister(register)
        data.maskInterrupt = true
        writeWideRegister(register, data: data)
    }


    func canHandleIrq(_ irqSetting: IRQSetting) -> Bool {
        let irq = irqSetting.irq
        print("IO-APIC: CanHandleIrq:", irq, "gsiBase:", globalSystemInterruptBase)
        if irq >= globalSystemInterruptBase {
            let mre = Int(versionRegister.maximumRedirectionEntry)
            print("IO-APIC: maximumRedirectionEntry:", mre)
            if Int(irq) < Int(globalSystemInterruptBase) + mre {
                return true
            }
        }
        return false
    }


    private func redirectionRegisterFor(irq: Int) -> UInt8 {
        // Redirection Table Registers start at offset 10h
        let irqEntry = UInt8(irq)
        return UInt8(0x10 + (irqEntry * 2))
    }

    func showIRRs() {
        for irq in 0..<Int(versionRegister.maximumRedirectionEntry) {
            let register = redirectionRegisterFor(irq: irq)
            let irr = readWideRegister(register)
            let remoteIRR = (irr.remoteIRR == .levelInterruptAccepted) ? 1 : 0
            print("\(irq): \(remoteIRR) ", terminator: "")
        }
        print("")
    }
}


fileprivate extension IOAPIC.IORedirectionRegister {
    // Bits 10:8
    enum DeliveryMode: Int { 
        case fixed = 0b000
        case lowestPriority = 0b001
        case SMI = 0b010
        case NMI = 0b100
        case INIT = 0b101
        case ExtINT = 0b111
    }


    // Bit 11
    enum DestinationMode: Int {  
        case physical = 0
        case logical = 1
    }


    // Bit 12 (RO)
    enum DeliveryStatus: Int { 
        case idle = 0
        case sendPending = 1
    }
    

    // Bit 13
    enum InputPinPolarity: Int { 
        case activeHigh = 0
        case activeLow = 1
    }


    // Bit 14 (RO)
    enum RemoteIRR: Int { 
        case eoiReceived = 0
        case levelInterruptAccepted = 1        
    }


    // Bit 15
    enum TriggerMode: Int { 
        case edge = 0
        case level = 1
    }
}


fileprivate extension IOAPIC {
    struct IORedirectionRegister {
        private var bits: BitArray64
        var rawValue: UInt64 { bits.rawValue }

        init() {
            bits = BitArray64(0)
        }

        init(rawValue: UInt64) {
            bits = BitArray64(rawValue)
        }

        var idtVector: UInt8 {
            get { UInt8(bits[0...7]) }
            set { bits[0...7] = UInt64(newValue) }
        }

        var deliveryMode: DeliveryMode {
            get { DeliveryMode(rawValue: Int(bits[8...10])) ?? DeliveryMode.fixed }
            set { bits[8...10] = UInt64(newValue.rawValue) }
        }

        var destinationMode: DestinationMode {
            get { DestinationMode(rawValue: bits[11])! }
            set { bits[11] = newValue.rawValue }
        }

        var deliveryStatus: DeliveryStatus { DeliveryStatus(rawValue: bits[12])! }

        var inputPinPolarity: InputPinPolarity {
            get { InputPinPolarity(rawValue: bits[13])! }
            set { bits[13] = newValue.rawValue }
        }

        var remoteIRR: RemoteIRR { RemoteIRR(rawValue: bits[14])! }

        var triggerMode: TriggerMode {
            get { TriggerMode(rawValue: bits[15])! }
            set { bits[15] = newValue.rawValue }
        }

        var maskInterrupt: Bool {
            get { bits[16] == 1 }
            set { bits[16] = newValue ? 1 : 0 }
        }

        var destinationField: UInt8 {
            get { UInt8(bits[56...63]) }
            set { bits[56...63] = UInt64(newValue) }
        }
    }
}


fileprivate extension IOAPIC {
    /// Registers are 32bits wide and indexed using an 8 bit address
    /// WideRegisters are 64bits wide using 2 32bit reads at address
    /// and address+1

    struct IOAPICID {
        private var bits: BitArray32
        var rawValue: UInt32 { bits.rawValue }
        var identification: Int {
            get { Int(bits[24...27]) }
            set { bits[24...27] = UInt32(newValue) }
        }

        init(_ rawValue: UInt32) { bits = BitArray32(rawValue) }
    }

    struct IOAPICVER {
        private let bits: BitArray32
        var version: Int { Int(bits[0...7]) }
        var maximumRedirectionEntry: Int { Int(bits[16...23]) }

        init(_ rawValue: UInt32) { bits = BitArray32(rawValue) }
    }

    struct IOAPICArbitrationID {
        private let bits: BitArray32
        var identification: Int { Int(bits[24...27]) }

        init(_ rawValue: UInt32) { bits = BitArray32(rawValue) }
    }

    func readRegister(_ register: UInt8) -> UInt32 {
        let f = UInt32(register)
        registerSelect.pointee = f
        let data = registerData.pointee
        return data
    }


    func writeRegister(_ register: UInt8, data: UInt32) {
        let f = UInt32(register)
        registerSelect.pointee = f
        registerData.pointee = data
    }


    func readWideRegister(_ register: UInt8) -> IORedirectionRegister {
        let lo = UInt64(readRegister(register))
        let hi = UInt64(readRegister(register + 1)) << 32
        return IORedirectionRegister(rawValue: hi | lo)
    }


    func writeWideRegister(_ register: UInt8, data: IORedirectionRegister) {
        let value = data.rawValue
        writeRegister(register + 0, data: UInt32(value & 0xffff_ffff))
        writeRegister(register + 1, data: UInt32(value >> 32))
    }

    var idRegister: IOAPICID {
        get { IOAPICID(readRegister(0)) }
        set { writeRegister(0, data: newValue.rawValue) }
    }

    var versionRegister: IOAPICVER { IOAPICVER(readRegister(1)) }
    var arbitrationIdRegister: IOAPICArbitrationID { IOAPICArbitrationID(readRegister(2)) }
}
