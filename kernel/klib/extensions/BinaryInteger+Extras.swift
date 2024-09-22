//
//  BinaryInteger+Extras.swift
//  BABAB
//
//  Created by Simon Evans on 26/03/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//

extension BinaryInteger {
    /// Creates a new Integer value from the given Boolean.
    /// - parameter value: A `Bool` used to initialise the value.
    public init(_ value: Bool) {
        self = value ? 1 : 0
    }

    /// Returns a `String` of the binary representation zero padded to the width of the value.
    ///
    /// The value passed is converted to its `String` representation using base-16
    /// and then zero padded upto the width of the parameter if necessary. A `UInt8`
    /// will be padded to 8 characters, a `UInt64` will be padded upto 64 characters.
    /// ```
    ///   UInt8(1).binary()         // '00000001'
    ///   UInt8(0x12).binary()      // '00010011'
    ///   UInt16(0x1234).binary()   // '0001001000110100'
    /// ```
    ///
    /// The `separator` flag determines if a `_` should be added between every 4 digits.
    /// ```
    ///   UInt8(1).binary(separators: true)         // '0000_0001'
    ///   UInt16(0x1234).binary(separators: true)   // '0001_0010_0011_0100'
    /// ```
    ///
    /// - parameter value: The numeric value to convert.
    /// - parameter separators: `Boolean` flag to control  `_` added between every 4 digits. The default is `false`.
    /// - returns: The zero padded value as a `String`.
    public func binary(separators: Bool = false) -> String {
        var num = String(self, radix: 2)
        let width = self.bitWidth
        if num.count < width {
            num = String(repeating: "0", count: width - num.count) + num
        }
        return separators ? insertSeperators(string: num) : num
    }

    /// Returns a `String` of the octal representation zero padded to the width of the value.
    ///
    /// The value passed is converted to its `String` representation using base-8
    /// and then zero padded upto the width of the parameter if necessary. A `UInt8`
    /// will be padded to 3 characters, a `UInt64` will be padded upto 22 characters.
    /// ```
    ///   UInt8(1).octal()          // '00000001'
    ///   UInt8(0x12).octal()       // '00010011'
    ///   UInt16(0x1234).octal()    // '0001001000110100'
    /// ```
    ///
    /// The `separator` flag determines if a `_` should be added between every 4 digits.
    /// ```
    ///   UInt8(1).octal(separators: true)         // '0000_0001'
    ///   UInt16(0x1234).octal(separators: true)   // '0001_0010_0011_0100'
    /// ```
    ///
    /// - parameter value: The numeric value to convert.
    /// - parameter separators: `Boolean` flag to control  `_` added between every 4 digits. The default is `false`.
    /// - returns: The zero padded value as a `String`.
    public func octal(separators: Bool = false) -> String {
        var num = String(self, radix: 8)
        let width = (self.bitWidth + 2) / 3
        if num.count < width {
            num = String(repeating: "0", count: width - num.count) + num
        }
        return separators ? insertSeperators(string: num) : num
    }

    /// Returns a `String` of the hexadecimal representation zero padded to the width of the value.
    ///
    /// The value passed is converted to its `String` representation using base-16
    /// and then zero padded upto the width of the parameter if necessary. A `UInt8`
    /// will be padded to 2 characters, a `UInt64` will be padded upto 16 characters.
    /// ```
    ///   UInt8(1).hex()          // '01'
    ///   UInt8(0x12).hex()       // '12'
    ///   UInt32(0x1234).hex()    // '00001234'
    /// ```
    ///
    /// The `separator` flag determines if a `_` should be added between every 4 digits.
    /// ```
    ///   UInt8(1).hex(separators: true)        // '01'
    ///   UInt32(0x1234).hex(separators: true)  // '0000_1234'
    /// ```
    ///
    /// - parameter value: The numeric value to convert.
    /// - parameter separators: `Boolean` flag to control  `_` added between every 4 digits. The default is `false`.
    /// - returns: The zero padded value as a `String`.
    public func hex(separators: Bool = false) -> String {
        var num = String(self, radix: 16)
        let width = (self.bitWidth + 3) / 4
        if num.count < width {
           num = String(repeating: "0", count: width - num.count) + num
        }
        return separators ? insertSeperators(string: num) : num
    }
}

private func insertSeperators(string: String) -> String {
    let underscores = (string.count / 4)

    guard underscores > 0 else { return string }
    var result = string
    var position = 4
    for _ in 1...underscores {
        let index = result.index(result.endIndex, offsetBy: -position)
        if index > result.startIndex {
            result.insert(Character("_"), at: index)
            position += 5
        }
    }
    return result
}
