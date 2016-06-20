/*
 * kernel/devices/acpi/mcfg.swift
 *
 * Created by Simon Evans on 02/03/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Parsing of ACPI MCFG (PCI Express MM configuration space address description
 * table)
 */


// FIXME: This table may need to be fixedup using PNP0C01/PNP0C02 info from
// motherboard resources as the bus range may be too big
struct MCFG: ACPITable {

    struct ConfigBaseAddress: CustomStringConvertible {
        let baseAddress: PhysAddress
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
        let headerSize = sizeof(acpi_sdt_header.self) + 8 // 8 is for reserved bytes
        let itemLen = Int(header.length) - headerSize
        let itemCnt = itemLen / strideof(ConfigBaseAddress.self)
        var items: [ConfigBaseAddress] = []
        let dataPtr: UnsafePointer<ConfigBaseAddress> = ptr.advancedBy(bytes: headerSize)
        let dataBuffer = UnsafeBufferPointer(start: dataPtr, count: itemCnt)

        for idx in 0..<itemCnt {
            items.append(dataBuffer[idx])
            print("ACPI: MCFG: \(dataBuffer[idx])")
        }
        if (BootParams.vendor == "Apple Inc.") && (BootParams.product == "MacBook3,1") {
            if items[0].endBus == 0xff {
                items[0] = ConfigBaseAddress(
                    baseAddress: items[0].baseAddress,
                    segmentGroup: items[0].segmentGroup,
                    startBus: items[0].startBus, endBus: 0x3f,
                    reserved: items[0].reserved)
                print("ACPI: MCFG: Overrode endBus from 0xff to 0x3f for",
                    BootParams.vendor, BootParams.product)
            }
        }

        allocations = items
    }


    func baseAddressForBus(_ bus: UInt8) -> UInt? {
        for entry in allocations {
            if bus >= entry.startBus && bus <= entry.endBus {
                return entry.baseAddress
            }
        }

        return nil
    }
}
