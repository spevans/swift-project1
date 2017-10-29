//
//  amlutils.swift
//  acpi
//
//  Created by Simon Evans on 30/04/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//


// Convert a compressed 32bit EISA type ID to a string
private func decodeEISAId(_ id: UInt32) -> AMLDataRefObject {
    let eisaid = BitArray32(UInt32(bigEndian: id))

    func hexDigit(_ x: Int) -> UnicodeScalar {
        precondition(x >= 0 && x < 16)
        let digits: StaticString = "0123456789ABCDEF"

        let digitsBuffer = UnsafeBufferPointer(start: digits.utf8Start,
                                               count: digits.utf8CodeUnitCount)

        return UnicodeScalar(digitsBuffer[x])
    }

    var hid = ""
    UnicodeScalar(eisaid[26...30] + 0x40)!.write(to: &hid)
    UnicodeScalar(eisaid[21...25] + 0x40)!.write(to: &hid)
    UnicodeScalar(eisaid[16...20] + 0x40)!.write(to: &hid)
    hexDigit(Int(eisaid[12...15])).write(to: &hid)
    hexDigit(Int(eisaid[8...11])).write(to: &hid)
    hexDigit(Int(eisaid[4...7])).write(to: &hid)
    hexDigit(Int(eisaid[0...3])).write(to: &hid)

    return AMLString(hid)
}


func decodeHID(obj: AMLDataRefObject) -> AMLDataRefObject {
    if let value = obj.asInteger {
        return decodeEISAId(UInt32(value))
    } else {
        return obj
    }
}


func resolveNameTo(scope: AMLNameString, path: AMLNameString) -> AMLNameString {
    if let x = path._value.first {
        if x == AMLNameString.rootChar {
            return path
        }
        var newScope = scope._value
        var newPath = path._value
        if x == AMLNameString.parentPrefixChar {
            newPath = ""
            var parts = scope._value.components(separatedBy: AMLNameString.pathSeparatorChar)
            for ch in path._value {
                if ch == AMLNameString.parentPrefixChar {
                    _ = parts.popLast()
                } else {
                    newPath.append(ch)
                }
            }
            newScope = parts.joined(separator: String(AMLNameString.pathSeparatorChar))
        }
        if !newScope.isEmpty, newScope != String(AMLNameString.rootChar) {
            newScope.append(AMLNameString.pathSeparatorChar)
        }
        newScope.append(newPath)
        return AMLNameString(value: newScope)
    } else {
        return scope // path is empty
    }
}

