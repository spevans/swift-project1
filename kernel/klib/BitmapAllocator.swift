/*
 * kernel/klib/BitmapAllocator.swift
 *
 * Created by Simon Evans on 03/11/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * Simple allocators that use a bitmap to store free/allocated blocks.
 *
 */


protocol BitmapAllocatorProtocol {
    var entryCount: Int { get }
    mutating func allocate() -> Int?
    mutating func free(entry: Int)
    func hasSpace() -> Bool
    func freeEntryCount() -> Int
}


/// Bitmap using UInt64 to allocate upto 8 entries.
struct BitmapAllocator8: BitmapAllocatorProtocol {
    typealias BitmapType = UInt8
    private var bitmap: BitmapType


    init() {
        // Preallocate the entries upto bitWidth
        bitmap = BitmapType.max
    }

    var entryCount: Int { BitmapType.bitWidth }

    mutating func allocate() -> Int? {
        let tzbc = bitmap.trailingZeroBitCount
        guard tzbc < entryCount else { return nil }
        bitmap &= ~(BitmapType(1) << tzbc)
        return tzbc
    }

    mutating func free(entry: Int) {
        let bit: BitmapType = 1 << BitmapType(entry)
        precondition(bitmap & bit == 0)
        bitmap |= bit
    }

    func hasSpace() -> Bool {
        return bitmap != 0
    }

    func freeEntryCount() -> Int {
        return bitmap.nonzeroBitCount
    }

    func dump() {
        func padding(_ str: String) -> String {
            return String(repeating: "0", count: BitmapType.bitWidth - str.count) + str
        }
        #kprint("0b\(padding(String(bitmap, radix: 2)))")
    }
}


struct BitmapAllocator16: BitmapAllocatorProtocol {
    typealias BitmapType = UInt16
    private var bitmap: BitmapType


    init() {
        // Preallocate the entries upto bitWidth
        bitmap = BitmapType.max
    }

    var entryCount: Int { BitmapType.bitWidth }

    mutating func allocate() -> Int? {
        let tzbc = bitmap.trailingZeroBitCount
        guard tzbc < entryCount else { return nil }
        bitmap &= ~(BitmapType(1) << tzbc)
        return tzbc
    }

    mutating func free(entry: Int) {
        let bit: BitmapType = 1 << BitmapType(entry)
        precondition(bitmap & bit == 0)
        bitmap |= bit
    }

    func hasSpace() -> Bool {
        return bitmap != 0
    }

    func freeEntryCount() -> Int {
        return bitmap.nonzeroBitCount
    }

    func dump() {
        func padding(_ str: String) -> String {
            return String(repeating: "0", count: BitmapType.bitWidth - str.count) + str
        }
        #kprint("0b\(padding(String(bitmap, radix: 2)))")
    }
}



/// Bitmap using UInt32 to allocate upto 32 entries.
struct BitmapAllocator32: BitmapAllocatorProtocol {
    typealias BitmapType = UInt32
    private var bitmap: BitmapType
    private let maxEntry: UInt32


    init(entries: Int) {
        precondition(entries <= BitmapType.bitWidth)
        maxEntry = UInt32(entries )

        // Preallocate the entries upto bitWidth
        bitmap = entries == BitmapType.bitWidth ? BitmapType.max : BitmapType((1 << entries) - 1)
    }

    var entryCount: Int { Int(maxEntry)  }

    mutating func allocate() -> Int? {
        let tzbc = bitmap.trailingZeroBitCount
        guard tzbc < entryCount else { return nil }
        bitmap &= ~(BitmapType(1) << tzbc)
        return tzbc
    }

    mutating func free(entry: Int) {
        precondition(entry <= maxEntry)
        let bit: BitmapType = 1 << BitmapType(entry)
        precondition(bitmap & bit == 0)
        bitmap |= bit
    }

    func hasSpace() -> Bool {
        return bitmap != 0
    }

    func freeEntryCount() -> Int {
        return bitmap.nonzeroBitCount
    }

    func dump() {
        func padding(_ str: String) -> String {
            return String(repeating: "0", count: BitmapType.bitWidth - str.count) + str
        }
        #kprint("0b\(padding(String(bitmap, radix: 2)))")
    }
}


/// Bitmap using UInt64 to allocate upto 64 entries.
struct BitmapAllocator64: BitmapAllocatorProtocol {
    typealias BitmapType = UInt64
    private var bitmap: BitmapType


    init() {
        // Preallocate the entries upto bitWidth
        bitmap = BitmapType.max
    }

    var entryCount: Int { BitmapType.bitWidth }

    mutating func allocate() -> Int? {
        let tzbc = bitmap.trailingZeroBitCount
        guard tzbc < entryCount else { return nil }
        bitmap &= ~(BitmapType(1) << tzbc)
        return tzbc
    }

    mutating func free(entry: Int) {
        let bit: BitmapType = 1 << BitmapType(entry)
        precondition(bitmap & bit == 0)
        bitmap |= bit
    }

    func hasSpace() -> Bool {
        return bitmap != 0
    }

    func freeEntryCount() -> Int {
        return bitmap.nonzeroBitCount
    }

    func dump() {
        func padding(_ str: String) -> String {
            return String(repeating: "0", count: BitmapType.bitWidth - str.count) + str
        }
        #kprint("0b\(padding(String(bitmap, radix: 2)))")
    }
}


/// Bitmap using 2x UInt64 to allocate upto 128 entries.
struct BitmapAllocator128: BitmapAllocatorProtocol {
    typealias BitmapType = UInt64
    private var bitmap0: BitmapType      // 1: free 0: allocated
    private var bitmap1: BitmapType


    init() {
        // Set the bits to 1 to mark them as available
        bitmap0 = BitmapType.max
        bitmap1 = BitmapType.max
    }

    var entryCount: Int { 2 * BitmapType.bitWidth }

    // Returns index of the least significant 1-bit of x, or if x is zero, returns nil
    // (same as __builtin_ffs)
    mutating func allocate() -> Int? {

        let tzbc0 = bitmap0.trailingZeroBitCount
        if tzbc0 < BitmapType.bitWidth {
            bitmap0 &= ~(BitmapType(1) << tzbc0)
            return tzbc0
        }

        let tzbc1 = bitmap1.trailingZeroBitCount
        if tzbc1 < BitmapType.bitWidth {
            bitmap1 &= ~(BitmapType(1) << tzbc1)
            return tzbc1 + BitmapType.bitWidth
        }

        return nil
    }

    mutating func free(entry: Int) {
        if entry < BitmapType.bitWidth {
            let bit: BitmapType = 1 << BitmapType(entry)
            precondition(bitmap0 & bit == 0)
            bitmap0 |= bit
        } else {
            let bit: BitmapType = 1 << BitmapType(entry - BitmapType.bitWidth)
            precondition(bitmap1 & bit == 0)
            bitmap1 |= bit
        }
    }

    func freeEntryCount() -> Int {
        return bitmap0.nonzeroBitCount + bitmap1.nonzeroBitCount
    }

    func hasSpace() -> Bool {
        return bitmap0 != 0 || bitmap1 != 0
    }


    func dump() {
        func padding(_ str: String) -> String {
            return String(repeating: "0", count: BitmapType.bitWidth - str.count) + str
        }
        #kprint("0b\(padding(String(bitmap1, radix: 2)))_\(padding(String(bitmap0, radix: 2)))")
    }
}

// FIXME, should be a macro using an InlineArray instead of an Array
struct LargeBitmapAllocator: BitmapAllocatorProtocol {
    typealias BitmapType = UInt64
    let entryCount: Int
    private var bitmap: [UInt]

    init(maxElements: Int) {
        precondition(maxElements > 0)
        self.entryCount = maxElements
        let wordCount = (maxElements + (UInt.bitWidth - 1)) / UInt.bitWidth
        bitmap = Array(repeating: UInt.max, count: wordCount)
        let unusedBits = maxElements % UInt.bitWidth
        if unusedBits != 0 {
            // Set the top N bits of the last element to mark them as taken
            bitmap[wordCount - 1] = ~(UInt.max << unusedBits)
        }
    }

    mutating func allocate() -> Int? {
        for index in bitmap.startIndex..<bitmap.endIndex {
            let tzbc = bitmap[index].trailingZeroBitCount
            if tzbc < BitmapType.bitWidth {
                bitmap[index].bit(tzbc, false)
                return (index * BitmapType.bitWidth) + tzbc
            }
        }
        return nil
    }

    mutating func free(entry: Int) {
        precondition(entry < entryCount)
        let index = entry / UInt.bitWidth
        let bit = entry % UInt.bitWidth
        if bitmap[index].bit(bit) {
            fatalError("Bit at entry \(entry) is already free")
        }
        bitmap[index].bit(bit, true)
    }

    func freeEntryCount() -> Int {
        bitmap.reduce(0, { $0 + $1.nonzeroBitCount})
    }

    func hasSpace() -> Bool {
        freeEntryCount() > 0
    }
}
