//
//  kernel/devices/acpi/ecdt.swift
//
//  Created by Simon Evans on 06/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
// Parsing of Embedded Controller Boot Resources (ECDT) table.

struct ECDT: ACPITable, CustomStringConvertible {

    let ecId: String
    var description: String { return "ECDT: \(ecId)" }


    init(_ ptr: UnsafeRawPointer) {
        let table = ptr.load(as: acpi_ecdt_table.self)

        // The EC_ID string is variable length and at the end
        // of the table. It is not included in the struct
        // as it is variable length so cant be expressed
        let ecIdLen = Int(table.header.length) - MemoryLayout<acpi_ecdt_table>.size
        guard ecIdLen > 0 else {
            fatalError("ACPI: ECDT table lentgth is too short")
        }
        let ecIdPtr = ptr.advanced(by: MemoryLayout<acpi_ecdt_table>.size)
        ecId = String(ecIdPtr, maxLength: ecIdLen)
    }
}
