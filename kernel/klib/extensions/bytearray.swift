/*
 * kernel/klib/extensions/bytearray.swift
 *
 * Created by Simon Evans on 28/03/2017.
 * Copyright © 2015 - 2017 Simon Evans. All rights reserved.
 *
 * ByteArray<x> types. Treat UInt16/UInt32/UInt64 as arrays of bytes.
 *
 */

struct ByteArray2: RandomAccessCollection, Sequence, CustomStringConvertible {
    typealias Index = Int
    typealias Element = UInt8

    private(set) var rawValue: UInt16

    var count: Int { return 2 }
    var isEmpty: Bool { return false }
    var startIndex: Index { return 0 }
    var endIndex: Index { return 2 }
    var description: String { return String(rawValue, radix: 16) }


    init() {
        rawValue = 0
    }

    init(_ rawValue: Int) {
        self.rawValue = UInt16(rawValue)
    }

    init(_ rawValue: UInt16) {
        self.rawValue = rawValue
    }

    init(withBytes bytes: Element...) {
        precondition(bytes.count <= 2)

        self.rawValue = 0
        var shift: UInt16 = 0
        for byte in bytes {
            rawValue |= (UInt16(byte) << shift)
            shift += 8
        }
    }

    init(_ bytes: [Element]) {
        precondition(bytes.count <= 2)

        self.rawValue = 0
        var shift: UInt16 = 0
        for byte in bytes {
            rawValue |= (UInt16(byte) << shift)
            shift += 8
        }
    }

    subscript(index: Int) -> Element {
        get {
            precondition(index >= 0)
            precondition(index < endIndex)

            let shift = UInt16(index * 8)
            return Element((rawValue >> shift) & UInt16(Element.max))
        }

        set {
            precondition(index >= 0)
            precondition(index < endIndex)
            precondition(newValue >= 0 || newValue <= Element.max)

            let shift = UInt16(index * 8)
            let mask = ~(UInt16(Element.max) << shift)
            let newValue = UInt16(newValue) << shift
            rawValue &= mask
            rawValue |= newValue
        }
    }

    struct Iterator: IteratorProtocol {
        var index = 0
        let array: ByteArray2

        init(_ value: ByteArray2) {
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


struct ByteArray4: RandomAccessCollection, Sequence, CustomStringConvertible {
    typealias Index = Int
    typealias Element = UInt8

    private(set) var rawValue: UInt32

    var count: Int { return 4 }
    var isEmpty: Bool { return false }
    var startIndex: Index { return 0 }
    var endIndex: Index { return 4 }
    var description: String { return String(rawValue, radix: 16) }


    init() {
        rawValue = 0
    }

    init(_ rawValue: Int) {
        self.rawValue = UInt32(rawValue)
    }

    init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }

    init(withBytes bytes: Element...) {
        precondition(bytes.count <= 4)

        self.rawValue = 0
        var shift: UInt32 = 0
        for byte in bytes {
            rawValue |= (UInt32(byte) << shift)
            shift += 8
        }
    }

    init(_ bytes: [Element]) {
        precondition(bytes.count <= 4)

        self.rawValue = 0
        var shift: UInt32 = 0
        for byte in bytes {
            rawValue |= (UInt32(byte) << shift)
            shift += 8
        }
    }

    subscript(index: Int) -> Element {
        get {
            precondition(index >= 0)
            precondition(index < endIndex)

            let shift = UInt32(index * 8)
            return Element((rawValue >> shift) & UInt32(Element.max))
        }

        set {
            precondition(index >= 0)
            precondition(index < endIndex)
            precondition(newValue >= 0 || newValue <= Element.max)

            let shift = UInt32(index * 8)
            let mask = ~(UInt32(Element.max) << shift)
            let newValue = UInt32(newValue) << shift
            rawValue &= mask
            rawValue |= newValue
        }
    }

    struct Iterator: IteratorProtocol {
        var index = 0
        let array: ByteArray4

        init(_ value: ByteArray4) {
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


struct ByteArray8: RandomAccessCollection, Sequence, CustomStringConvertible {
    typealias Index = Int
    typealias Element = UInt8

    private(set) var rawValue: UInt64

    var count: Int { return 8 }
    var isEmpty: Bool { return false }
    var startIndex: Index { return 0 }
    var endIndex: Index { return 8 }
    var description: String { return String(rawValue, radix: 16) }


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

    init(_ rawValue: UInt64) {
        self.rawValue = rawValue
    }

    init(withBytes bytes: Element...) {
        precondition(bytes.count <= 8)

        self.rawValue = 0
        var shift: UInt64 = 0
        for byte in bytes {
            rawValue |= (UInt64(byte) << shift)
            shift += 8
        }
    }

    init(_ bytes: [Element]) {
        precondition(bytes.count <= 8)

        self.rawValue = 0
        var shift: UInt64 = 0
        for byte in bytes {
            rawValue |= (UInt64(byte) << shift)
            shift += 8
        }
    }

    subscript(index: Int) -> Element {
        get {
            precondition(index >= 0)
            precondition(index < endIndex)

            let shift = UInt64(index * 8)
            return Element((rawValue >> shift) & UInt64(Element.max))
        }

        set {
            precondition(index >= 0)
            precondition(index < endIndex)
            precondition(newValue >= 0 || newValue <= Element.max)

            let shift = UInt64(index * 8)
            let mask = ~(UInt64(UInt8.max) << shift)
            let newValue = UInt64(newValue) << shift
            rawValue &= mask
            rawValue |= newValue
        }
    }

    struct Iterator: IteratorProtocol {
        var index = 0
        let array: ByteArray8

        init(_ value: ByteArray8) {
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
