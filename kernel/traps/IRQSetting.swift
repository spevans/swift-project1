//
//  kernel/traps/IRQSetting.swift
//  project1
//
//  Created by Simon Evans on 04/05/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//

// Describes a hardware interrupt. The interrupt pin may be an IRQ or a
// GSI (Global System Interrupt). The only difference is that an IRQ may need
// to be remapped according to possible MADT.InterruptSourceOverrideTable entries.
struct IRQSetting: CustomStringConvertible {

    private let bits: BitArray16

    // IRQ: Interrupt Request, will need to be mapped to a GSI before use.
    init(irq: UInt8, activeHigh: Bool, levelTriggered: Bool, shared: Bool, wakeCapable: Bool) {
        var _bits = BitArray16(UInt16(irq)) // bits 0-7
        _bits[8] = activeHigh ? 1 : 0
        _bits[9] = levelTriggered ? 1 : 0
        _bits[10] = shared ? 1 : 0
        _bits[11] = wakeCapable ? 1 : 0
        _bits[12] = 1   // isIRQ
        bits = _bits
    }

    // GSI: Global System Interrupt.
    init(gsi: UInt32, activeHigh: Bool, levelTriggered: Bool, shared: Bool, wakeCapable: Bool) {
        var _bits = BitArray16(UInt16(gsi)) // bits 0-7
        _bits[8] = activeHigh ? 1 : 0
        _bits[9] = levelTriggered ? 1 : 0
        _bits[10] = shared ? 1 : 0
        _bits[11] = wakeCapable ? 1 : 0
        _bits[12] = 0   // isGSI
        bits = _bits
    }

    init(isaIrq: UInt8) {
        // Active high, edge triggered, not shared, not wake capable, isIRQ
        var _bits = BitArray16(UInt16(isaIrq)) // bits 0-7
        _bits[8] = 1
        _bits[12] = 1   // isIRQ
        bits = _bits
    }

    var description: String { "\(isGSI ? "GSI" : "IRQ")\(irq) activeHigh: \(activeHigh) levelTrig: \(levelTriggered) shared: \(shared) wake: \(wakeCapable)" }

    var irq: Int { Int(bits[0...7]) }
    var activeHigh: Bool { Bool(bits[8]) }
    var levelTriggered: Bool { Bool(bits[9]) }
    var egdeTriggered: Bool { !levelTriggered }
    var shared: Bool { Bool(bits[10]) }
    var wakeCapable: Bool { Bool(bits[11]) }
    var isIRQ: Bool { Bool(bits[12]) }
    var isGSI: Bool { !isIRQ }
}
