/*
 * kernel/devices/acpi/mcfg.swift
 *
 * Created by Simon Evans on 02/03/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Parsing of ACPI MCFG (PCI Express MM configuration space address description
 * table)
 */

struct MCFG: ACPITable {

    struct ConfigBaseAddress: CustomStringConvertible {
        let baseAddress: UInt64
        let segmentGroup: UInt16
        let startBus: UInt8
        let endBus: UInt8
        let reserved: UInt32

        var description: String {
            return String.sprintf("base:%p segment: %u start:%u end: %u", baseAddress, segmentGroup,
                startBus, endBus)
        }
    }


    let header: ACPI_SDT
    let reserved: UInt64 = 0
    let allocations: [ConfigBaseAddress]


    init(acpiHeader: ACPI_SDT, ptr: UnsafePointer<acpi_sdt_header>) {
        header = acpiHeader
        let headerSize = sizeof(acpi_sdt_header) + 8 // 8 is for reserved bytes
        let itemLen = Int(header.length) - headerSize
        let itemCnt = itemLen / strideof(ConfigBaseAddress)
        var items: [ConfigBaseAddress] = []
        let dataPtr: UnsafePointer<ConfigBaseAddress> = ptr.advancedBy(bytes: headerSize)
        let dataBuffer = UnsafeBufferPointer(start: dataPtr, count: itemCnt)

        for idx in 0..<itemCnt {
            items.append(dataBuffer[idx])
            print("ACPI: MCFG: \(dataBuffer[idx])")
        }
        allocations = items
    }
}
