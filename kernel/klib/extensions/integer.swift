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
        precondition(bit >= 0 && bit < MemoryLayout<Self>.size * 8,
            "Bit must be in range 0-\(MemoryLayout<Self>.size * 8 - 1)")
        return self & Self(1 << UIntMax(bit)) != 0
    }

    init(withBytes bytes: [Byte]) {
        precondition(bytes.count > 0 && bytes.count <= MemoryLayout<Self>.size,
            "Array must have from 1-\(MemoryLayout<Self>.size) elements")

        self = 0
        var shift: UIntMax = 0
        for byte in bytes {
            self |= (Self(UIntMax(byte) << shift))
            shift += UIntMax(MemoryLayout<Byte>.size * 8)
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
        var shift: UIntMax = 0
        for word in words {
            self |= (Self(UIntMax(word) << shift))
            shift += UIntMax(MemoryLayout<Word>.size * 8)
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
        var shift: UIntMax = 0
        for dword in dwords {
            self |= (Self(UIntMax(dword) << shift))
            shift += UIntMax(MemoryLayout<DWord>.size * 8)
        }
    }

    init(withDWords dwords: DWord...) {
        self.init(withDWords: dwords)
    }
}
