//
//  AMLFieldSettings.swift
//  project1
//
//  Created by Simon Evans on 26/01/2025.
//  Copyright © 2025 Simon Evans. All rights reserved.
//

// FIXME, use accessField, extendedAccessField correctly
// Shrink this down and hold bitOffset, bitWidth outside of this struct
struct AMLFieldSettings: CustomStringConvertible {
    let bitOffset: UInt
    let bitWidth: UInt
    let fieldFlags: AMLFieldFlags
    let accessField: AMLAccessField
    let extendedAccessField: AMLExtendedAccessField?

    var description: String {
        #sprintf("bitOffset: %u width: %u flags: %s", bitOffset, bitWidth, fieldFlags.description)
    }
}

struct AMLFieldFlags: CustomStringConvertible {
    // let value: AMLByteData
    let fieldAccessType: AMLFieldAccessType
    let lockRule: AMLLockRule
    let updateRule: AMLUpdateRule

    var description: String {
        return "\(fieldAccessType), \(lockRule), \(updateRule)"
    }

    init(fieldAccessType: AMLFieldAccessType, lockRule: AMLLockRule, updateRule: AMLUpdateRule) {
        self.fieldAccessType = fieldAccessType
        self.lockRule = lockRule
        self.updateRule = updateRule
    }

    init(flags value: AMLByteData) {
        guard let _fieldAccessType = AMLFieldAccessType(value) else {
            fatalError("Invalid AMLFieldAccessType")
        }
        fieldAccessType = _fieldAccessType
        guard let _updateRule = AMLUpdateRule(value) else {
            fatalError("Invalid AMLUpdateRule")
        }
        updateRule = _updateRule
        lockRule = AMLLockRule(value)
    }
}

enum AMLFieldAccessType: AMLByteData, CustomStringConvertible {
    case AnyAcc     = 0
    case ByteAcc    = 1
    case WordAcc    = 2
    case DWordAcc   = 3
    case QWordAcc   = 4
    case BufferAcc  = 5 //

    var description: String {
        switch self {
            case .AnyAcc: return "AnyWidth"
            case .ByteAcc: return "Byte"
            case .WordAcc: return "Word"
            case .DWordAcc: return "DWord"
            case .QWordAcc: return "QWord"
            case .BufferAcc: return "Buffer"
        }
    }

    init?(_ value: AMLByteData) {
        let type = value & 0xf
        self.init(rawValue: type)
    }

    // Width in bits
    var accessWidth: Int {
        switch self {
            // TODO: Could be optimised in case of Any and Buffer access
            case .ByteAcc, .AnyAcc, .BufferAcc:
                return 8
            case .WordAcc:
                return 16
            case .DWordAcc:
                return 32
            case .QWordAcc:
                return 64
        }
    }
}

struct AMLAccessField {
    let type: AMLAccessType
    let attrib: AMLByteData
}

struct AMLExtendedAccessField {
    let type: AMLAccessType
    let attrib: AMLExtendedAccessAttrib
    let length: AMLInteger
}

struct AMLAccessType {
    let value: AMLByteData
}

enum AMLExtendedAccessAttrib: AMLByteData {
    case attribBytes = 0x0B
    case attribRawBytes = 0x0E
    case attribRawProcess = 0x0F
}

enum AMLLockRule: CustomStringConvertible {
    case NoLock
    case Lock

    init(_ value: AMLByteData) {
        if (value & 0x10) == 0x00 {
            self = .NoLock
        } else {
            self = .Lock
        }
    }

    var description: String {
        switch self {
            case .NoLock: "NoLock"
            case .Lock: "Lock"
        }
    }
}

enum AMLUpdateRule: AMLByteData, CustomStringConvertible {
    case Preserve     = 0
    case WriteAsOnes  = 1
    case WriteAsZeros = 2

    init?(_ value: AMLByteData) {
        self.init(rawValue: BitArray8(value)[5...6])
    }

    var description: String {
        switch self {
            case .Preserve: "Preserve"
            case .WriteAsOnes: "WriteAsOnes"
            case .WriteAsZeros: "WriteAsZeros"
        }
    }
}
