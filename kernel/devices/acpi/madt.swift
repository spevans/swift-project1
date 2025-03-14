/*
 * kernel/devices/acpi/madt.swift
 *
 * Created by Simon Evans on 26/07/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Parsing of Multiple APIC Description Table (MADT).
 */

enum IntControllerTableType: UInt8, CustomStringConvertible {
    case processorLocalApic             = 0x00
    case ioApic                         = 0x01
    case interruptSourceOverride        = 0x02
    case nmiSource                      = 0x03
    case localApicNmi                   = 0x04
    case localApicAddressOverride       = 0x05
    case ioSapic                        = 0x06
    case localSapic                     = 0x07
    case platformInterruptSources       = 0x08
    case processorLocalx2Apic           = 0x09
    case localx2ApicNmi                 = 0x0A
    case gicCPUInterface                = 0x0B
    case gicDistributor                 = 0x0C
    case gicMsiFrame                    = 0x0D
    case gicRedistributor               = 0x0E
    case gicInterruptTranslationService = 0x0F
    // 0x10 - 0x7F are reserved, 0x80-0xFF are for OEM use so treat as
    // invalid for now

    var description: String {
        switch self {
        case .processorLocalApic:               return "LocalAPIC"
        case .ioApic:                           return "IO-APIC"
        case .interruptSourceOverride:          return "INT Source Override"
        case .nmiSource:                        return "NMI Source"
        case .localApicNmi:                     return "Local API NMI"
        case .localApicAddressOverride:         return "APIC-Address Override"
        case .ioSapic:                          return "IO-SAPIC"
        case .localSapic:                       return "Local SAPIC"
        case .platformInterruptSources:         return "Platform INT Src"
        case .processorLocalx2Apic:             return "CPU x2APIC"
        case .localx2ApicNmi:                   return "x2APIC NMI"
        case .gicCPUInterface:                  return "GIC-CPU Interface"
        case .gicDistributor:                   return "GIC-Distributor"
        case .gicMsiFrame:                      return "GIC-MSI-Frame"
        case .gicRedistributor:                 return "GIC-Redistributor"
        case .gicInterruptTranslationService:   return "GIC-INT-XLATE"
        }
    }
}

struct MADT: CustomDebugStringConvertible {

    enum MADTEntry: CustomStringConvertible {
        case processorLocalApic(ProcessorLocalApicTable)
        case ioApic(IOApicTable)
        case interruptSourceOverride(InterruptSourceOverrideTable)
        case localApicNmi(LocalApicNmiTable)
        //var tableType: IntControllerTableType { get }

        var description: String {
            switch self {
                case .processorLocalApic(_):
                    return "Local-APIC"
                case .ioApic(_):
                    return "IO-APIC"
                case .interruptSourceOverride(_):
                    return "INT-SrcOverride"
                case .localApicNmi(_):
                    return "Local-APIC-NMI"
            }
        }
    }


    // Multiple APIC Flags (bit)
    private let PCAT_COMPAT = 0

    let localIntControllerAddr: UInt32
    let multipleApicFlags: UInt32
    private(set) var madtEntries: [MADTEntry] = []

    var hasCompatDual8259: Bool { return multipleApicFlags.bit(PCAT_COMPAT) }

    var debugDescription: String {
        return "MADT: LocalControllerAddr: " + asHex(localIntControllerAddr)
            + " multipleApicFlags: " + asHex(multipleApicFlags)
            + " hasCompatDual8259: " + (hasCompatDual8259 ? "Yes" : "No")
    }


    init(_ ptr: UnsafeRawPointer) {
        let table = ptr.load(as: acpi_madt_table.self)
        localIntControllerAddr = table.local_int_controller_addr
        multipleApicFlags = table.multiple_apic_flags

        let tableSize = MemoryLayout<acpi_madt_table>.size
        let dataLength = Int(table.header.length) - tableSize
        guard dataLength >= 2 else {
            // needs at least a type/len pair
            fatalError("ACPI: MADT dataLength is less than 2")
        }

        // loop through controller structures
        madtEntries = decodeEntries(ptr: ptr.advanced(by: MemoryLayout<acpi_madt_table>.size), dataLength: dataLength)
    }


    private func decodeEntries(ptr: UnsafeRawPointer, dataLength: Int) -> [MADTEntry] {
        var entries: [MADTEntry] = []
        let controllers = UnsafeBufferPointer(start: ptr.bindMemory(to: UInt8.self, capacity: dataLength),
                                              count: dataLength)
        var position = 0
        while position < controllers.count {
            let bytesRemaining = controllers.count - position
            guard bytesRemaining > 2 else {
                fatalError("error: bytesRemaining: \(bytesRemaining) "
                    + "count: \(controllers.count) position: \(position)")
            }
            let tableLen = Int(controllers[position + 1])
            guard tableLen > 0 && tableLen <= controllers.count - position
                else {
                    fatalError("error: tableLen: \(tableLen) "
                        + "position: \(position) "
                        + "controllers.count: \(controllers.count)")
            }

            let start: UnsafePointer<UInt8> = controllers.baseAddress!.advancedBy(bytes: position)
            let tableData = UnsafeBufferPointer(start: start,
                                                count: tableLen)
            let table = decodeTable(table: tableData)
            entries.append(table)
            position += tableLen
        }
        return entries
    }


    struct ProcessorLocalApicTable: CustomDebugStringConvertible {
        let tableType = IntControllerTableType.processorLocalApic
        let tableLength = 8
        let processorUID: UInt8
        let apicID: UInt8
        let localApicFlags: UInt32
        var enabled: Bool { return localApicFlags.bit(0) }
        var debugDescription: String {
            let desc: String = tableType.description
            + ": uid: \(asHex(processorUID)) "
            + "apicID: \(asHex(apicID)) flags: \(asHex(localApicFlags)) "
            + "enabled: " + String(enabled ? "Yes" : "No")
            return desc
        }


        fileprivate init(table: UnsafeBufferPointer<UInt8>) {
            guard table.count == tableLength else {
                fatalError("Invalid ProcessorLocalApic size")
            }
            processorUID = table[2]
            apicID = table[3]
            // ACPI tables are all little endian
            localApicFlags = UInt32(withBytes: table[4], table[5],
                                    table[6], table[7]);
        }
    }


    struct IOApicTable: CustomDebugStringConvertible {
        let tableType = IntControllerTableType.ioApic
        let tableLength = 12
        let ioApicID: UInt8
        let ioApicAddress: UInt32
        let globalSystemInterruptBase: UInt32
        var debugDescription: String {
            let desc = "IO-APIC: APIC ID: \(asHex(ioApicID)) "
            + "Addr: \(asHex(ioApicAddress)) "
            + "Interrupt Base: \(asHex(globalSystemInterruptBase))"
            return desc
        }


        fileprivate init(table: UnsafeBufferPointer<UInt8>) {
            guard table.count == tableLength else {
                fatalError("Invalid IOApicTable size")
            }
            ioApicID = table[2]
            ioApicAddress = UInt32(withBytes: table[4], table[5],
                table[6], table[7]);
            globalSystemInterruptBase = UInt32(withBytes: table[8], table[9],
                table[10], table[11])
        }
    }


    struct InterruptSourceOverrideTable: CustomDebugStringConvertible {

        let tableType = IntControllerTableType.interruptSourceOverride
        let tableLength = 10
        let sourceIRQ: UInt8
        let irqSetting: IRQSetting

        var debugDescription: String {
            return "\(tableType.description): irq: \(sourceIRQ) -> \(irqSetting)"
        }


        fileprivate init(table: UnsafeBufferPointer<UInt8>) {
            guard table.count == tableLength else {
                fatalError("Invalid InterruptSourceOverrideTable size")
            }
            let bus = table[2]
            // 0 = ISA, all other values invalid
            guard bus == 0 else {
                fatalError("InterruptSourceOverrideTable has a bus value of \(bus)")
            }

            sourceIRQ = table[3]
            let globalInterrupt = UInt32(withBytes: table[4], table[5],
                table[6], table[7]);
            let flags = BitArray16(UInt16(withBytes: table[8], table[9]))

            let polarity = flags[0...1]
            let activeHigh: Bool
            switch polarity {
                case 0: activeHigh = true   // 0b00 Conforms to the specifications of the bus
                case 1: activeHigh = true   // 0b01 Active high
                case 3: activeHigh = false  // 0b11 Active low
                                            // 0b10 Reserved
                default: fatalError("InterruptSourceOverrideTable has flags value: \(asHex(flags.rawValue))")
            }

            let triggerMode = flags[2...3]
            let levelTriggered: Bool
            switch triggerMode {
                case 0: levelTriggered = false  // 0b00 Conforms to the specifications of the bus
                case 1: levelTriggered = false  // 0b01 Edge-triggered
                case 3: levelTriggered = true   // 0b11 Level-Triggered
                                                // 0b10 Reserved
                default: fatalError("InterruptSourceOverrideTable has flags value: \(asHex(flags.rawValue))")
            }

            irqSetting = IRQSetting(gsi: globalInterrupt, activeHigh: activeHigh, levelTriggered: levelTriggered, shared: false, wakeCapable: false)
        }
    }


    struct LocalApicNmiTable: CustomDebugStringConvertible {
        let tableType = IntControllerTableType.localApicNmi
        let tableLength = 6
        let acpiProcessorUID: UInt8
        let flags: UInt16
        let localApicLint: UInt8
        var debugDescription: String {
                return "\(tableType.description): processor UID: \(asHex(acpiProcessorUID)) "
                + "flags: \(asHex(flags)) LINT# \(asHex(localApicLint))"
        }


        fileprivate init(table: UnsafeBufferPointer<UInt8>) {
            guard table.count == tableLength else {
                fatalError("Invalid LocalApicNmiTable size")
            }
            acpiProcessorUID = table[2]
            flags = UInt16(withBytes: table[3], table[4])
            localApicLint = table[5]
        }
    }


    private func decodeTable(table: UnsafeBufferPointer<UInt8>) -> MADTEntry {
        guard let type = IntControllerTableType(rawValue: table[0]) else {
            fatalError("Unknown MADT entry: \(asHex(table[0]))")
        }
        switch type {
        case .processorLocalApic:
            return  .processorLocalApic(ProcessorLocalApicTable(table: table))

        case .ioApic:
            return .ioApic(IOApicTable(table: table))

        case .interruptSourceOverride:
            return .interruptSourceOverride(InterruptSourceOverrideTable(table: table))

        case .localApicNmi:
            return .localApicNmi(LocalApicNmiTable(table: table))

        default:
            fatalError("\(type): unsupported")
        }
    }
}
