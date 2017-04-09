//
//  kernel/devices/acpi/ecdt.swift
//
//  Created by Simon Evans on 06/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
// Parsing of Embedded Controller Boot Resources (ECDT) table.

struct ECDT: ACPITable, CustomStringConvertible {

    private let tablePtr: UnsafePointer<acpi_ecdt_table>
    let ecId: String

    var description: String { return "ECDT: \(ecId)" }


    init(_ ptr: UnsafeRawPointer) {
        tablePtr = ptr.bindMemory(to: acpi_ecdt_table.self, capacity: 1)
        let table = tablePtr.pointee

        // The EC_ID string is variable length and at the end
        // of the table. It is not included in the struct
        // as it is variable length so cant be expressed
        let ecIdLen = Int(table.header.length) -
            MemoryLayout<acpi_ecdt_table>.size
        guard ecIdLen > 0 else {
            fatalError("ACPI: ECDT table lentgth is too short")
        }
        var id = ""
        tablePtr.advanced(by: 1).withMemoryRebound(to: UInt8.self,
            capacity: ecIdLen) {
                let buffer = UnsafeBufferPointer(start: $0, count: ecIdLen)
                for ch in buffer {
                    if ch == 0 {
                        break
                    } else {
                        UnicodeScalar(ch).write(to: &id)
                    }
                }
        }
        ecId = id
    }
}
