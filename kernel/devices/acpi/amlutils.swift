//
//  kernel/devices/acpi/amlutils.swift
//
//  Created by Simon Evans on 30/04/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  ACPI misc utilities


// Convert a compressed 32bit EISA type ID to a string
private func decodeEISAId(_ id: UInt32) -> AMLString {
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


func decodeHID(obj: AMLTermArg) -> AMLString {
    if let string = obj.stringValue {
        return string
    }
    else if let value = obj.integerValue {
        return decodeEISAId(UInt32(value))
    } else {
        fatalError("decodeHID: \(obj) is invalid argument for decoding an EISAid")
    }
}


func resolveNameTo(scope: AMLNameString, path: AMLNameString) -> AMLNameString {
    if let x = path.value.first {
        if path.isFullPath {
            return path
        }
        var newScope = scope.value
        var newPath = path.value
        if x == AMLNameString.parentPrefixChar {
            newPath = ""
            var parts = scope.value.components(separatedBy: AMLNameString.pathSeparatorChar)
            for ch in path.value {
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
        return AMLNameString(newScope)
    } else {
        return scope // path is empty
    }
}

