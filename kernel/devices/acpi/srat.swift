//
//  kernel/devices/acpi/srat.swift
//
//  Created by Simon Evans on 07/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  Parsing of System Resource Affinity Table (SRAT)

protocol SRATAffinityEntry {
}

struct SRAT: ACPITable, CustomStringConvertible {

    struct SRATApicAffinityEntry: SRATAffinityEntry {
        private let proximityDomain: Int
        private let apicId: Int
        private let sapicEid: Int
        private let clockDomain: Int

        init(_ ptr: UnsafeRawPointer) {
            let entry = ptr.load(as: srat_apic_affinity.self)
            proximityDomain = ByteArray4([entry.proximity_domain_0_7,
                                          entry.proximity_domain_8_15, entry.proximity_domain_16_23,
                                          entry.proximity_domain_24_31]).toInt()

            apicId = Int(entry.apic_id)
            sapicEid = Int(entry.local_sapic_eid)
            clockDomain = Int(entry.clock_domain)
        }
    }

    struct SRATX2ApicAffinityEntry: SRATAffinityEntry {
        private let proximityDomain: Int
        private let x2apicId: Int
        private let clockDomain: Int

        init(_ ptr: UnsafeRawPointer) {
            let entry = ptr.load(as: srat_x2apic_affinity.self)
            proximityDomain = Int(entry.proximity_domain)
            x2apicId = Int(entry.x2apic_id)
            clockDomain = Int(entry.clock_domain)
        }
    }

    struct SRATMemoryAffinityEntry: SRATAffinityEntry {
        private let proximityDomain: Int
        private let baseAddress: UInt64
        private let length: UInt64
        private let hotPluggable: Bool
        private let nonVolatile: Bool

        init(_ ptr: UnsafeRawPointer) {
            let entry = ptr.load(as: srat_memory_affinity.self)
            proximityDomain = Int(entry.proximity_domain)
            baseAddress = DWordArray2([entry.base_address_low, entry.base_address_high]).rawValue
            length = DWordArray2([entry.length_low, entry.length_high]).rawValue
            let flags = BitArray32(entry.flags)
            hotPluggable = (flags[1] != 0)
            nonVolatile = (flags[2] != 0)
        }
    }

    struct SRATGiccAffinityEntry: SRATAffinityEntry {
        private let proximityDomain: Int
        private let acpiProcessUid: Int
        private let clockDomain: Int

        init(_ ptr: UnsafeRawPointer) {
            let entry = ptr.load(as: srat_gicc_affinity.self)
            proximityDomain = Int(entry.proximity_domain)
            acpiProcessUid = Int(entry.acpi_processor_uid)
            clockDomain = Int(entry.clock_domain)
        }
    }

    // Treat the entries as a read only Collection
    struct SRATEntries: Collection, Sequence {
        typealias Index = Int
        typealias Element = SRATAffinityEntry

        // Offsets into the main table of each entry
        private let entryOffsets: [Int];
        private let rawTablePtr: UnsafeRawPointer

        // Collection interface for the SRAT Affinity entries
        var count: Int { return entryOffsets.count }
        var startIndex: Int { return entryOffsets.startIndex }
        var endIndex: Int { return entryOffsets.endIndex }

        init(_ ptr: UnsafeRawPointer, _ offsets: [Int]) {
            rawTablePtr = ptr
            entryOffsets = offsets
        }


        func index(after i: Index) -> Int {
            return entryOffsets.index(after: i)
        }


        subscript(index: Int) -> SRATAffinityEntry {
            let offset = entryOffsets[index]
            let ptr = rawTablePtr.advanced(by: offset)
            let type = ptr.load(as: UInt8.self)

            switch type {
            case 0: return SRATApicAffinityEntry(ptr)
            case 1: return SRATMemoryAffinityEntry(ptr)
            case 2: return SRATX2ApicAffinityEntry(ptr)
            case 3: return SRATGiccAffinityEntry(ptr)
            default: fatalError("ACPI: Invalid SRAT type: \(type)")
            }
        }


        struct Iterator: IteratorProtocol {
            let entries: SRATEntries
            var index = 0


            init(_ value: SRATEntries) {
                entries = value
            }

            mutating func next() -> Element? {
                if index < entries.count {
                    defer { index += 1 }
                    return entries[index]
                } else {
                    return nil
                }
            }
        }

        func makeIterator() -> Iterator {
            return Iterator(self)
        }
    }


    private let rawTablePtr: UnsafeRawPointer

    let entries: SRATEntries
    var description: String { return "SRAT: \(entries.count) entries" }


    init(_ ptr: UnsafeRawPointer) {
        rawTablePtr = ptr
        let tablePtr = ptr.bindMemory(to: acpi_srat_table.self, capacity: 1)
        let tableLength = Int(tablePtr.pointee.header.length)

        guard tableLength >= MemoryLayout<acpi_srat_table>.size else {
            fatalError("ACPI: FACS table is too short \(tableLength) bytes")
        }
        guard tablePtr.pointee.table_revision == 1 else {
            fatalError("ACPI: SRAT invalid table revision \(tablePtr.pointee.table_revision)")
        }

        var offset = MemoryLayout<acpi_srat_table>.size
        var structureSize = tableLength - offset
        var tableOffsets: [Int] = []

        // Create an array of offsets to enabled strutures. When a struture
        // is accessed via the collection methods it can be constructed as
        // needed.
        while structureSize > 0 {
            guard structureSize >= 16 else { // shortest table size
                fatalError("ACPI: SRAT Remaining structureSize too short")
            }
            let structurePtr = ptr.advanced(by: offset)
            let type = structurePtr.load(as: UInt8.self)
            let size = structurePtr.advanced(by: 1).load(as: UInt8.self)

            func checkSpace(space: Int, needed: Int) {
                if needed > space {
                    fatalError("Remaining table \(needed) > \(space)")
                }
            }

            switch (type, size) {
            case (0, 16):
                let t = structurePtr.bindMemory(to: srat_apic_affinity.self,
                                                capacity: 1)
                checkSpace(space: structureSize, needed: Int(size))
                if BitArray32(t.pointee.flags)[0] == 1 { // enabled
                    tableOffsets.append(offset)
                }

            case (1, 40):
                let t = structurePtr.bindMemory(to: srat_memory_affinity.self,
                                                capacity: 1)
                checkSpace(space: structureSize, needed: Int(size))
                if BitArray32(t.pointee.flags)[0] == 1 { // enabled
                    tableOffsets.append(offset)
                }

            case (2, 24):
                let t = structurePtr.bindMemory(to: srat_x2apic_affinity.self,
                                                capacity: 1)
                checkSpace(space: structureSize, needed: Int(size))
                if BitArray32(t.pointee.flags)[0] == 1 { // enabled
                    tableOffsets.append(offset)
                }

            case (3, 18):
                let t = structurePtr.bindMemory(to: srat_gicc_affinity.self,
                                                capacity: 1)
                checkSpace(space: structureSize, needed: Int(size))
                if BitArray32(t.pointee.flags)[0] == 1 { // enabled
                    tableOffsets.append(offset)
                }

            default:
                fatalError("ACPI: SRAT Invalid type/size \(type)/\(size)")
            }

            offset += Int(size)
            structureSize -= Int(size)
        }
        entries = SRATEntries(ptr, tableOffsets)
    }
}
