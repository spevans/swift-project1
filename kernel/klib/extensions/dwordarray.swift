/*
 * kernel/klib/extensions/dwordarray.swift
 *
 * Created by Simon Evans on 29/03/2017.
 * Copyright © 2015 - 2017 Simon Evans. All rights reserved.
 *
 * DWordArray<x> types. Treat UInt64 as arrays of 2 dwords.
 *
 */

struct DWordArray2: Collection, Sequence, CustomStringConvertible {
    typealias Index = Int
    typealias Element = UInt32

    private(set) var rawValue: UInt64

    var count: Int { return 2 }
    var isEmpty: Bool { return false }
    var startIndex: Index { return 0 }
    var endIndex: Index { return 2 }

    var description: String { return "0x\(String(self[0], radix: 16)), 0x\(String(self[1], radix: 16))" }


    init() {
        rawValue = 0
    }

    init(_ rawValue: Int) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt8) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt16) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt32) {
        self.rawValue = UInt64(rawValue)
    }

    init(_ rawValue: UInt64) {
        self.rawValue = UInt64(rawValue)
    }

    init(withDWords dwords: Element...) {
        precondition(dwords.count > 0)
        precondition(dwords.count <= 2)

        self.rawValue = 0
        var shift: UInt64 = 0
        for dword in dwords {
            self.rawValue |= (UInt64(dword) << shift)
            shift += 32
        }
    }

    init(_ dwords: [Element]) {
        precondition(dwords.count > 0)
        precondition(dwords.count <= 2)

        self.rawValue = 0
        var shift: UInt64 = 0
        for dword in dwords {
            self.rawValue |= (UInt64(dword) << shift)
            shift += 32
        }
    }

    subscript(index: Int) -> Element {
        get {
            precondition(index >= 0)
            precondition(index < endIndex)

            let shift = UInt64(index * 32)
            return Element((rawValue >> shift) & UInt64(Element.max))
        }

        set(newValue) {
            precondition(index >= 0)
            precondition(index < endIndex)
            precondition(newValue >= 0 || newValue <= Element.max)

            let shift = UInt64(index * 32)
            let mask = ~(UInt64(UInt32.max) << shift)
            let newValue = UInt64(newValue) << shift
            rawValue &= mask
            rawValue |= newValue
        }
    }

    struct Iterator: IteratorProtocol {
        var index = 0
        let array: DWordArray2

        init(_ value: DWordArray2) {
            array = value
        }

        mutating func next() -> Element? {
            if index < array.endIndex {
                defer { index += 1 }
                return array[index]
            } else {
                return nil
            }
        }
    }

    func makeIterator() -> Iterator {
        return Iterator(self)
    }

    func index(after i: Index) -> Index {
        precondition(i >= 0)
        precondition(i < endIndex)
        return i + 1
    }

    func toInt() -> Int {
        return Int(rawValue)
    }
}
