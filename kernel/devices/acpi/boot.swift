//
//  kernel/devices/boot.swift
//
//  Created by Simon Evans on 07/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
// Parsing of Simple Boot Flag (BOOT) Table.

struct BOOT: ACPITable, CustomStringConvertible {

    private let tablePtr: UnsafePointer<acpi_boot_table>

    // Offset in CMOS memory where the BOOT register is located.
    var cmosOffset: Int { return Int(tablePtr.pointee.cmos_index) }
    var description: String { return "BOOT: CMOS memory index: \(cmosOffset)" }


    init(_ ptr: UnsafeRawPointer) {
        tablePtr = ptr.bindMemory(to: acpi_boot_table.self, capacity: 1)
        let table = tablePtr.pointee
        guard Int(table.header.length) == MemoryLayout<acpi_boot_table>.size
            else {
                fatalError("ACPI: BOOT: Table length is incorrect")
        }
    }
}
