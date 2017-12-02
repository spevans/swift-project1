//
//  kernel/devices/acpi/hpet.swift
//
//  Created by Simon Evans on 29/04/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  Parsing of High Precision Event Timer (HPET).

struct HPET: ACPITable, CustomStringConvertible {

    private let tablePtr: UnsafePointer<acpi_hpet_table>

    var pciVendorId: UInt16 {
        let val = BitArray32(tablePtr.pointee.timer_block_id)
        let val2 = UInt16(val[16...31])
        return val2
    }

    var legacyIrqReplacement: Bool {
        let val = BitArray32(tablePtr.pointee.timer_block_id)
        return (val[15] != 0)
    }

    var counterSizeCap: Bool {
        let val = BitArray32(tablePtr.pointee.timer_block_id)
        return (val[13] != 0)
    }

    var isMainCounter32Bit: Bool {
        return !counterSizeCap
    }

    var isMainCounter64Bit: Bool {
        return counterSizeCap
    }

    var comparatorCount: Int {
        let val = BitArray32(tablePtr.pointee.timer_block_id)
        return Int(val[8...12])
    }

    var hardwareRevisionId: UInt8 {
        let val = BitArray32(tablePtr.pointee.timer_block_id)
        return UInt8(val[0...7])
    }

    var hpetNumber: Int {
        return Int(tablePtr.pointee.hpet_number)
    }

    var description: String {
        return "vendor: \(asHex(pciVendorId)) legacyIrq: \(legacyIrqReplacement)"
            + " counterSizeCap: \(counterSizeCap) comparators: \(comparatorCount)"
            + " revId: \(asHex(hardwareRevisionId)) hpetNumber: \(hpetNumber)"
    }


    init(_ ptr: UnsafeRawPointer) {
        tablePtr = ptr.bindMemory(to: acpi_hpet_table.self, capacity: 1)
    }
}
