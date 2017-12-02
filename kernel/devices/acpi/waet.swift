//
//  kernel/devices/acpi/waet.swift
//
//  Created by Simon Evans on 07/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  Parsing of Windows ACPI Enlightenment Table (WAET) Table.

struct WAET: ACPITable, CustomStringConvertible {

    private let tablePtr: UnsafePointer<acpi_waet_table>

    var isRTCGood: Bool {
        return BitArray32(tablePtr.pointee.device_flags)[0] == 1
    }
    var isPMTimerGood: Bool {
        return BitArray32(tablePtr.pointee.device_flags)[1] == 1
    }
    var description: String { return "WAET: isRTCGood: \(isRTCGood) isPMTimerGood: \(isPMTimerGood)" }


    init(_ ptr: UnsafeRawPointer) {
        tablePtr = ptr.bindMemory(to: acpi_waet_table.self, capacity: 1)
        let table = tablePtr.pointee

        guard Int(table.header.length) == MemoryLayout<acpi_waet_table>.size
            else {
            fatalError("ACPI: WAET: Table length is incorrect")
        }
    }
}
