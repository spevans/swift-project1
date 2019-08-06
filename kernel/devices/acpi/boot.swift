//
//  kernel/devices/acpi/boot.swift
//
//  Created by Simon Evans on 07/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
// Parsing of Simple Boot Flag (BOOT) Table.

struct BOOT: ACPITable, CustomStringConvertible {

    // Offset in CMOS memory where the BOOT register is located.
    let cmosOffset: Int
    var description: String { return "BOOT: CMOS memory index: \(cmosOffset)" }


    init(_ ptr: UnsafeRawPointer) {
        let table = ptr.load(as: acpi_boot_table.self)
        guard Int(table.header.length) == MemoryLayout<acpi_boot_table>.size else {
            fatalError("ACPI: BOOT: Table length is incorrect")
        }
        cmosOffset = Int(table.cmos_index)
    }
}
