//
//  kernel/devices/acpi/waet.swift
//
//  Created by Simon Evans on 07/05/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  Parsing of Windows ACPI Enlightenment Table (WAET) Table.

struct WAET: ACPITable, CustomStringConvertible {

    private let deviceFlags: BitArray32

    var isRTCGood: Bool { deviceFlags[0] == 1 }
    var isPMTimerGood: Bool { deviceFlags[1] == 1 }
    var description: String { return "WAET: isRTCGood: \(isRTCGood) isPMTimerGood: \(isPMTimerGood)" }


    init(_ ptr: UnsafeRawPointer) {
        let table = ptr.load(as: acpi_waet_table.self)
        guard Int(table.header.length) == MemoryLayout<acpi_waet_table>.size else {
            fatalError("ACPI: WAET: Table length is incorrect")
        }
        deviceFlags = BitArray32(table.device_flags)
    }
}
