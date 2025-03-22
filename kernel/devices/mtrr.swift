/*
 * kernel/devices/mtrr.swift
 *
 * Created by Simon Evans on 18/10/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * MTRR Access (Memory Type Range Registers).
 *
 */


let IA32_MTRRCAP: UInt32 = 0xFE
let IA32_MTRR_DEF_TYPE: UInt32 = 0x2FF
let IA32_MTRR_FIX64K_00000: UInt32 = 0x250
let IA32_MTRR_FIX16K_80000: UInt32 = 0x258
let IA32_MTRR_FIX16K_A0000: UInt32 = 0x259
let IA32_MTRR_FIX4K_C0000: UInt32 = 0x268
let IA32_MTRR_FIX4K_C8000: UInt32 = 0x269
let IA32_MTRR_FIX4K_D0000: UInt32 = 0x26A
let IA32_MTRR_FIX4K_D8000: UInt32 = 0x26B
let IA32_MTRR_FIX4K_E0000: UInt32 = 0x26C
let IA32_MTRR_FIX4K_E8000: UInt32 = 0x26D
let IA32_MTRR_FIX4K_F0000: UInt32 = 0x26E
let IA32_MTRR_FIX4K_F8000: UInt32 = 0x26F

let IA32_MTRR_PHYSBASE0: UInt32 = 0x200
let IA32_MTRR_PHYSMASK0: UInt32 = 0x201
let IA32_MTRR_PHYSBASE1: UInt32 = 0x202
let IA32_MTRR_PHYSMASK1: UInt32 = 0x203
let IA32_MTRR_PHYSBASE2: UInt32 = 0x204
let IA32_MTRR_PHYSMASK2: UInt32 = 0x205
let IA32_MTRR_PHYSBASE3: UInt32 = 0x206
let IA32_MTRR_PHYSMASK3: UInt32 = 0x207
let IA32_MTRR_PHYSBASE4: UInt32 = 0x208
let IA32_MTRR_PHYSMASK4: UInt32 = 0x209
let IA32_MTRR_PHYSBASE5: UInt32 = 0x20A
let IA32_MTRR_PHYSMASK5: UInt32 = 0x20B
let IA32_MTRR_PHYSBASE6: UInt32 = 0x20C
let IA32_MTRR_PHYSMASK6: UInt32 = 0x20D
let IA32_MTRR_PHYSBASE7: UInt32 = 0x20E
let IA32_MTRR_PHYSMASK7: UInt32 = 0x20F
let IA32_MTRR_PHYSBASE8: UInt32 = 0x210
let IA32_MTRR_PHYSMASK8: UInt32 = 0x211
let IA32_MTRR_PHYSBASE9: UInt32 = 0x212
let IA32_MTRR_PHYSMASK9: UInt32 = 0x213


struct MTRR: CustomStringConvertible {

    enum MemoryType: UInt8, CustomStringConvertible {
        case uncacheable = 0
        case writeCombining = 1
        case writeThrough = 4
        case writeProtected = 5
        case writeBack = 6

        var description: String {
            switch self {
            case .uncacheable: return "UC"
            case .writeCombining: return "WC"
            case .writeThrough: return "WT"
            case .writeProtected: return "WP"
            case .writeBack: return "WB"
            }
        }
    }

    private let physBaseBits: BitArray64
    private let physMaskBits: BitArray64

    var description: String {
        return "base: \(asHex(base)) mask: \(asHex(mask)) valid: \(isValid) type: \(memoryType)"
    }

    var base: UInt64 { physBaseBits[12...63] << 12 }
    var mask: UInt64 { physMaskBits[12...63] << 12 }
    var memoryType: MemoryType { MemoryType(rawValue: UInt8(physBaseBits[0...7]))! }
    var isValid: Bool { physMaskBits[11] == 0 ? false : true }


    init(physBase: UInt64, physMask: UInt64) {
        physBaseBits = BitArray64(physBase)
        physMaskBits = BitArray64(physMask)
    }


    init(base: UInt64, mask: UInt64, memoryType: MemoryType) {
        physBaseBits = BitArray64(base | UInt64(memoryType.rawValue))
        physMaskBits = BitArray64(mask | (1 << 11))
    }
}


private func fixedWidthMTRRs(base: UInt64, regionSize: UInt64, _ memoryTypes: UInt64) -> [MTRR] {
    #kprintf("Reading fixed width mtrr, base: %x, regionSize: %x, types: %x\n", base, regionSize, memoryTypes)
    var mtrrs: [MTRR] = []
    mtrrs.reserveCapacity(8)

    var base = base
    let mask = ~((UInt64(1) << regionSize.trailingZeroBitCount) - 1)
    for i in 0...7 {
        let value = UInt8(truncatingIfNeeded: memoryTypes >> (i * 8))
        let mt = MTRR.MemoryType(rawValue: value)!
        let mtrr = MTRR(base: base, mask: mask, memoryType: mt)
        mtrrs.append(mtrr)
        base += regionSize
    }
    return mtrrs
}


private func readFixedWidthMTRRs() -> [MTRR] {
    var mtrrs: [MTRR] = []
    mtrrs.reserveCapacity(88)
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0x00000, regionSize: 0x10000, CPU.readMSR(IA32_MTRR_FIX64K_00000)))
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0x80000, regionSize: 0x04000, CPU.readMSR(IA32_MTRR_FIX16K_80000)))
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0xA0000, regionSize: 0x04000, CPU.readMSR(IA32_MTRR_FIX16K_A0000)))
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0xC0000, regionSize: 0x01000, CPU.readMSR(IA32_MTRR_FIX4K_C0000)))
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0xC8000, regionSize: 0x01000, CPU.readMSR(IA32_MTRR_FIX4K_C8000)))
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0xD0000, regionSize: 0x01000, CPU.readMSR(IA32_MTRR_FIX4K_D0000)))
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0xD8000, regionSize: 0x01000, CPU.readMSR(IA32_MTRR_FIX4K_D8000)))
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0xE0000, regionSize: 0x01000, CPU.readMSR(IA32_MTRR_FIX4K_E0000)))
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0xE8000, regionSize: 0x01000, CPU.readMSR(IA32_MTRR_FIX4K_E8000)))
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0xF0000, regionSize: 0x01000, CPU.readMSR(IA32_MTRR_FIX4K_F0000)))
    mtrrs.append(contentsOf: fixedWidthMTRRs(base: 0xF8000, regionSize: 0x01000, CPU.readMSR(IA32_MTRR_FIX4K_F8000)))

    return mtrrs
}


private func readVariableMTRRs(count: Int) -> [MTRR] {
    let mtrrCount = min(count, 9)
    guard mtrrCount > 0 else { return [] }

    var mtrrs: [MTRR] = []
    var physBaseMsr = IA32_MTRR_PHYSBASE0
    var physMaskMsr = IA32_MTRR_PHYSMASK0


    for _ in 1...mtrrCount {
        let physBase: UInt64 = CPU.readMSR(physBaseMsr)
        let physMask: UInt64 = CPU.readMSR(physMaskMsr)
        mtrrs.append(MTRR(physBase: physBase, physMask: physMask))
        physBaseMsr += 2
        physMaskMsr += 2
    }

    return mtrrs
}



struct MTRRS {

    struct Capabilities: CustomStringConvertible {
        let bits: BitArray64

        var description: String {
            return "Variable Registers: \(variableRegisterCount) supports: fixed: \(supportsFixedRange)  writeCombining: \(supportsWriteCombining) SMRR: \(supportsSMRR)"
        }

        init(_ rawValue: UInt64) {
            bits = BitArray64(rawValue)
        }

        var variableRegisterCount: Int { Int(bits[0...7]) }
        var supportsFixedRange: Bool { bits[8] == 0 ? false : true }
        var supportsWriteCombining: Bool { bits[10] == 0 ? false : true }
        var supportsSMRR: Bool { bits[11] == 0 ? false : true }
    }

    struct Control: CustomStringConvertible {
        var bits: BitArray64

        var description: String {
            return "Enabled: \(enableMTRRs) enableFixedRange: \(enableFixedRange) default: \(defaultType)"
        }


        init(_ rawValue: UInt64) {
            bits = BitArray64(rawValue)
        }

        init(defaultType: MTRR.MemoryType, enableFixedRange: Bool, enableMTRRs: Bool) {
            var bits = BitArray64(UInt64(defaultType.rawValue))
            bits[10] = enableFixedRange ? 1 : 0
            bits[11] = enableMTRRs ? 1 : 0
            self.bits = bits
        }

        var defaultType: MTRR.MemoryType {
            get {
                MTRR.MemoryType(rawValue: UInt8(bits[0...7]))!
            }
            set {
                bits[0...7] = UInt64(newValue.rawValue)
            }
        }

        var enableFixedRange: Bool {
            get {
                Bool(bits[10])
            }
            set {
                bits[10] = newValue ? 1 : 0
            }
        }

        var enableMTRRs: Bool {
            get {
                Bool(bits[11])
            }
            set {
                bits[11] = newValue ? 1 : 0
            }
        }
    }

    let capabilities: Capabilities
    var control: Control

    init() {
        capabilities = Capabilities(CPU.readMSR(IA32_MTRRCAP))
        control = Control(CPU.readMSR(IA32_MTRR_DEF_TYPE))
    }


    func readMTRRs() -> [MTRR] {
        var mtrrs = capabilities.supportsFixedRange ? readFixedWidthMTRRs() : []
        mtrrs.append(contentsOf: readVariableMTRRs(count: capabilities.variableRegisterCount))
        return mtrrs
    }

    static func disableMTRRs() {
        let mtrrControl = MTRRS.Control(defaultType: .uncacheable, enableFixedRange: false, enableMTRRs: false)
        CPU.writeMSR(IA32_MTRR_DEF_TYPE, mtrrControl.bits.rawValue)
    }
}
