/*
 * kernel/devices/acpi/mcfg.swift
 *
 * Created by Simon Evans on 02/03/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Parsing of ACPI MCFG (PCI Express MM configuration space address description
 * table).
 */


// FIXME: This table may need to be fixedup using PNP0C01/PNP0C02 info from
// motherboard resources as the bus range may be too big
struct MCFG: ACPITable {

    struct ConfigEntry: CustomStringConvertible {
        let baseAddress: PhysAddress
        let segmentGroup: UInt16
        let startBus: UInt8
        let endBus: UInt8
        let reserved: UInt32

        var description: String {
            return "base: \(asHex(baseAddress.value)) segment: \(segmentGroup)"
                + " startBus: \(asHex(startBus)) endBus: \(asHex(endBus))"
        }

        init(entry: acpi_mcfg_config_entry) {
            baseAddress = PhysAddress(RawAddress(entry.base_address))
            segmentGroup = entry.segment_group
            startBus = entry.start_bus
            endBus = entry.end_bus
            reserved = 0
        }

        init(baseAddress: PhysAddress, segmentGroup: UInt16, startBus: UInt8,
             endBus: UInt8) {
            self.baseAddress = baseAddress
            self.segmentGroup = segmentGroup
            self.startBus = startBus
            self.endBus = endBus
            reserved = 0
        }
    }

    let allocations: [ConfigEntry]


    init(_ ptr: UnsafeRawPointer, vendor: String, product: String) {
        let tablePtr = ptr.bindMemory(to: acpi_mcfg_table.self, capacity: 1)
        // Multiple acpi_mcfg_config_entrys follow the table
        let itemLen = Int(tablePtr.pointee.header.length)
            - MemoryLayout<acpi_mcfg_table>.stride
        let configEntrySize = MemoryLayout<acpi_mcfg_config_entry>.size

        assert(itemLen > 0)
        assert(itemLen % configEntrySize == 0)
        // validate the structure is packed
        assert(configEntrySize == MemoryLayout<acpi_mcfg_config_entry>.stride)

        let itemCnt = itemLen / configEntrySize
        var items: [ConfigEntry] = []
        items.reserveCapacity(itemCnt)

        tablePtr.advanced(by: 1).withMemoryRebound(
            to: acpi_mcfg_config_entry.self,
            capacity: itemCnt, { dataPtr in
                let dataBuffer = UnsafeBufferPointer(start: dataPtr,
                                                     count: itemCnt)

                for idx in 0..<itemCnt {
                    let entry = ConfigEntry(entry: dataBuffer[idx])
                    items.append(entry)
                }
        })

        if (vendor == "Apple Inc.") && (product == "MacBook3,1")
        && (items[0].endBus == 0xff) {
            items[0] = ConfigEntry(
                baseAddress: items[0].baseAddress,
                segmentGroup: items[0].segmentGroup,
                startBus: items[0].startBus,
                endBus: 0x3f)

            print("ACPI: MCFG: Overrode endBus from 0xff to 0x3f for",
                vendor, product)
        }

        allocations = items
    }


    func baseAddressFor(bus: UInt8) -> PhysAddress? {
        for entry in allocations {
            if bus >= entry.startBus && bus <= entry.endBus {
                return entry.baseAddress
            }
        }

        return nil
    }
}
