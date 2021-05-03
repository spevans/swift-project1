//
//  kernel/traps/IRQSetting.swift
//  project1
//
//  Created by Simon Evans on 04/05/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//

// Describes an IRQ
struct IRQSetting: CustomStringConvertible {
    private let bits: BitArray16

    init(irq: UInt8, activeHigh: Bool, levelTriggered: Bool, shared: Bool, wakeCapable: Bool) {
        var _bits = BitArray16(UInt16(irq)) // bits 0-7
        _bits[8] = activeHigh ? 1 : 0
        _bits[9] = levelTriggered ? 1 : 0
        _bits[10] = shared ? 1 : 0
        _bits[11] = wakeCapable ? 1 : 0
        bits = _bits
    }

    var description: String { "\(irq) activeHigh: \(activeHigh) levelTrig: \(levelTriggered) shared: \(shared) wake: \(wakeCapable)" }

    init(isaIrq: UInt8) {
        var _bits = BitArray16(UInt16(isaIrq)) // bits 0-7
        _bits[8] = 1
        bits = _bits
    }

    var irq: Int { Int(bits[0...7])}
    var activeHigh: Bool { Bool(bits[8]) }
    var levelTriggered: Bool { Bool(bits[9]) }
    var egdeTriggered: Bool { !levelTriggered }
    var shared: Bool { Bool(bits[10]) }
    var wakeCapable: Bool { Bool(bits[11]) }
}
