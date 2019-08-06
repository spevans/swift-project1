//
//  kernel/devices/acpi/facs.swift
//
//  Created by Simon Evans on 07/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  Parsing of Firmware ACPI Control Structure (FACS).

struct FACS: ACPITable, CustomStringConvertible {

    private let table: acpi_facs_table
    var description: String { "FACS: 0x\(String(table.hardware_signature, radix: 16))" }


    init(_ ptr: UnsafeRawPointer) {
        table = ptr.load(as: acpi_facs_table.self)
        guard table.length >= MemoryLayout<acpi_facs_table>.size else {
            fatalError("ACPI: FACS table is too short \(table.length) bytes")
        }
    }
}
