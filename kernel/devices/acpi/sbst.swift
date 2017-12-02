//
//  kernel/devices/acpi/sbst.swift
//
//  Created by Simon Evans on 06/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  Smart Battery (SBST) Table.


struct SBST: ACPITable, CustomStringConvertible {

    private let tablePtr: UnsafePointer<acpi_sbst_table>

    var warningLevelInmWh:  Int { return Int(tablePtr.pointee.warning_energy_level) }
    var lowLevelInmWh:      Int { return Int(tablePtr.pointee.low_energy_level) }
    var criticalLevelInmWh: Int { return Int(tablePtr.pointee.critical_energy_level) }

    var description: String {
        return "SBST: battery warning: \(warningLevelInmWh)mWh"
            + " low: \(lowLevelInmWh)mWh critical: \(criticalLevelInmWh)mWh"
    }


    init(_ ptr: UnsafeRawPointer) {
        tablePtr = ptr.bindMemory(to: acpi_sbst_table.self, capacity: 1)
        let length = Int(tablePtr.pointee.header.length)
        guard length >= MemoryLayout<acpi_sbst_table>.size else {
            fatalError("ACPI: SBST table too short: \(length)")
        }
    }
}
