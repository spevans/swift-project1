/*
 * kernel/klib/extensions/integer.swift
 *
 * Created by Simon Evans on 28/03/2017.
 * Copyright © 2015 - 2017 Simon Evans. All rights reserved.
 *
 * Extras for UInt8/16/32/64 including initialisers.
 *
 */

extension UnsignedInteger {
    typealias Byte = UInt8
    typealias Word = UInt16
    typealias DWord = UInt32


    func bit(_ bit: Int) -> Bool {
   //     precondition(bit >= 0 && bit < MemoryLayout<Self>.size * 8,
   //         "Bit must be in range 0-\(MemoryLayout<Self>.size * 8 - 1)")
        return self & (Self(1) << bit) != 0
    }

    mutating func bit(_ bit: Int, _ newValue: Bool) {
        precondition(bit >= 0 && bit < MemoryLayout<Self>.size * 8,
            "Bit must be in range 0-\(MemoryLayout<Self>.size * 8 - 1)")
        if newValue {
            self |= (Self(1) << bit)
        } else {
            self &= ~(Self(1) << bit)
        }
    }

    init(withBytes bytes: [Byte]) {
        precondition(bytes.count > 0 && bytes.count <= MemoryLayout<Self>.size,
            "Array must have from 1-\(MemoryLayout<Self>.size) elements")

        self = 0
        var shift: UInt = 0
        for byte in bytes {
            self |= (Self(UInt(byte) << shift))
            shift += UInt(MemoryLayout<Byte>.size * 8)
        }
    }

    init(withBytes bytes: Byte...) {
        self.init(withBytes: bytes)
    }

    init(withWords words: [Word]) {
        let maxElements = MemoryLayout<Self>.size / MemoryLayout<Word>.size
        precondition(words.count > 0 && words.count <= maxElements,
            "Array must have from 1-\(maxElements) elements")

        self = 0
        var shift: UInt = 0
        for word in words {
            self |= (Self(UInt(word) << shift))
            shift += UInt(MemoryLayout<Word>.size * 8)
        }
    }

    init(withWords words: Word...) {
        self.init(withWords: words)
    }

    init(withDWords dwords: [DWord]) {
        let maxElements = MemoryLayout<Self>.size / MemoryLayout<DWord>.size
        precondition(dwords.count > 0 && dwords.count <= maxElements,
            "Array must have from 1-\(maxElements) elements")

        self = 0
        var shift: UInt = 0
        for dword in dwords {
            self |= (Self(UInt(dword) << shift))
            shift += UInt(MemoryLayout<DWord>.size * 8)
        }
    }

    init(withDWords dwords: DWord...) {
        self.init(withDWords: dwords)
    }
}

extension Bool {
    init(_ bit: Int) {
        precondition(bit == 0 || bit == 1)
        self = (bit == 1) ? true : false
    }
}

extension FixedWidthInteger {

    init(maskFromBitCount bitCount: Int) {
        precondition(Self.min == 0, "Only unsigned integers allowed")
        precondition(bitCount >= 0 && bitCount <= Self.bitWidth)
        if bitCount == Self.bitWidth {
            self = Self.max
        } else {
            self = (1 << bitCount) - 1
        }
    }

    @inline(never)
    init?(_ value: String) {
        func valueOfCharacter(_ character: Character, _ base: Int) -> Int? {
            guard let ch = character.asciiValue else { return nil }
            let value: Int
            if ch >= 0x30, ch <= 0x39 {
                value  = Int(ch - 0x30)
            } else if ch >= 97, ch <= 102 {
                value = Int(ch - 0x61) + 10
            } else {
                return nil
            }
            return value < base ? value : nil
        }
        guard !value.isEmpty else {
            return nil
        }
        let value = value.lowercased()
        var base = 10
        let negate: Bool
        var index = value.startIndex
        if value.first == "-" {
            negate = true
            index = value.index(index, offsetBy: 1)
        } else {
            negate = false
        }

        if !negate, value.count > 1, value.first == "0" {
            index = value.index(index, offsetBy: 1)
            switch value[index] {
                case "x":
                    base = 16
                    index = value.index(index, offsetBy: 1)
                case "b":
                    base = 2
                    index = value.index(index, offsetBy: 1)
                default:
                    break
            }
        }
        var result: Self = 0
        while index < value.endIndex {
            let ch = value[index]
            guard let digitValue = valueOfCharacter(ch, base) else {
                return nil
            }
            let (partialValue1, overflow1) = result.multipliedReportingOverflow(by: Self(base))
            if overflow1 {
                return nil
            }
            result = partialValue1
            let (partialValue2, overflow2) = result.addingReportingOverflow(Self(digitValue))
            if overflow2 {
                return nil
            }
            result = partialValue2
            index = value.index(index, offsetBy: 1)
        }
        if negate {
            let (partialValue, overflow) = result.multipliedReportingOverflow(by: -1)
            if overflow { return nil }
            result = partialValue
        }
        self = result
    }
}


extension FixedWidthInteger {

    init<C: Collection>(littleEndianBytes: C) where C.Element == UInt8, C.Index == Int {
        let count = Self.bitWidth / 8
        precondition(littleEndianBytes.count >= count)

        var value = Self(0)
        var shift = 0
        for idx in littleEndianBytes.startIndex..<(littleEndianBytes.startIndex + count) {
            value |= Self(littleEndianBytes[idx]) << shift
            shift += 8
        }
        self = value
    }

    init<C: Collection>(bigEndianBytes: C) where C.Element == UInt8, C.Index == Int {
        let count = Self.bitWidth / 8
        precondition(bigEndianBytes.count >= count)

        var value = Self(0)
        for idx in bigEndianBytes.startIndex..<(bigEndianBytes.startIndex + count) {
            value <<= 8
            value |= Self(bigEndianBytes[idx])
        }
        self = value
    }
}
