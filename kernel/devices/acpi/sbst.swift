//
//  kernel/devices/acpi/sbst.swift
//
//  Created by Simon Evans on 06/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  Smart Battery (SBST) Table.


struct SBST: ACPITable, CustomStringConvertible {

    let warningLevelInmWh:  Int
    let lowLevelInmWh:      Int
    let criticalLevelInmWh: Int

    var description: String {
        return "SBST: battery warning: \(warningLevelInmWh)mWh"
            + " low: \(lowLevelInmWh)mWh critical: \(criticalLevelInmWh)mWh"
    }


    init(_ ptr: UnsafeRawPointer) {
        let table = ptr.load(as: acpi_sbst_table.self)
        let length = table.header.length
        guard length >= MemoryLayout<acpi_sbst_table>.size else {
            fatalError("ACPI: SBST table too short: \(length)")
        }
        warningLevelInmWh = Int(table.warning_energy_level)
        lowLevelInmWh = Int(table.low_energy_level)
        criticalLevelInmWh = Int(table.critical_energy_level)
    }
}
