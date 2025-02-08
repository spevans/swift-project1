//
//  kernel/devices/acpi/amlutils.swift
//
//  Created by Simon Evans on 30/04/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  ACPI misc utilities


// Convert a compressed 32bit EISA type ID to a string
// FIXME, this shoule be a function in AMLString
private func decodeEISAId(_ id: UInt32) -> String {
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

    return try! AMLString(hid).asString()
}


func decodeHID(obj: AMLObject) -> String {
    if let string = obj.stringValue {
        return string.asString()
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

func walkUpFullPath<R>(_ name: AMLNameString, block: (String) -> R?) -> (R, String)? {
    // Do a search up the tree
    guard name.isFullPath else {
        return nil
    }
    let separator = AMLNameString.pathSeparatorChar
    var path = name.value
    while let separatorIndex = path.lastIndex(of: separator) {
        if let obj = block(path) {
            return (obj, path)
        }
        let subRange = path[..<separatorIndex]
        if let prevIndex = subRange.lastIndex(of: separator) {
            path.removeSubrange(prevIndex..<separatorIndex)
        } else {
            path.removeSubrange(...separatorIndex)
        }
    }
    if !path.hasPrefix(String(AMLNameString.rootChar)) {
        path = String(AMLNameString.rootChar) + path
    }
    if let obj = block(path) {
        return (obj, path)
    }
    return nil
}
