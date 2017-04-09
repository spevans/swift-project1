//
//  kernel/devices/acpi/facs.swift
//
//  Created by Simon Evans on 07/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
// Parsing of Firmware ACPI Control Structure (FACS).

struct FACS: ACPITable, CustomStringConvertible {

    private let table: acpi_facs_table
    var description: String {
        return "FACS: 0x\(String(table.hardware_signature, radix: 16))"
    }


    init(_ ptr: UnsafeRawPointer) {
        let tablePtr = ptr.bindMemory(to: acpi_facs_table.self, capacity: 1)
        guard tablePtr.pointee.length >= 64 else {
            fatalError("ACPI: FACS table is too short \(tablePtr.pointee.length) bytes")
        }
        table = tablePtr.pointee
    }
}
