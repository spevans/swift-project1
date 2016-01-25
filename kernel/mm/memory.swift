/*
 * kernel/mm/memory.swift
 *
 * Created by Simon Evans on 24/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Initial setup for available physical memory etc
 *
 */


public struct BootParams {
    enum E820Type: UInt32 {
        case HOLE     = 0
        case RAM      = 1
        case RESERVED = 2
        case ACPI     = 3
        case NVS      = 4
        case UNUSABLE = 5
    }


    struct E820MemoryEntry: CustomStringConvertible {
        let baseAddr: UInt64
        let length: UInt64
        let type: UInt32

        var description: String {
            let kb: UInt64 = 1024
            let mb: UInt64 = 1048576

            var desc = String.sprintf("%12X - %12X %4.4X", baseAddr, baseAddr + length - 1, type)
            if (length >= mb) {
                desc += String.sprintf(" %6uMB  ", length / mb)
            } else {
                desc += String.sprintf(" %6uKB  ", length / kb)
            }
            desc += String(E820Type.init(rawValue: type)!)

            return desc
        }
    }


    private let e820MemoryEntryCount: UInt32
    var memoryRanges: [E820MemoryEntry] = []
    var highestMemoryAddress: UInt64 = 0


    // FIXME - still needs to check for overlapping regions
    init() {
        let buf = MemoryBufferReader(PHYSICAL_MEM_BASE + 0x30000, size: 4096)
        e820MemoryEntryCount = try! buf.read()
        memoryRanges.reserveCapacity(Int(e820MemoryEntryCount))
        for _ in 0..<e820MemoryEntryCount {
            let entry: E820MemoryEntry = try! buf.read()
            memoryRanges.append(entry)
        }
        sortRanges()
        findHoles()
        if (memoryRanges.count > 0) {
            let entry = memoryRanges[memoryRanges.count-1]
            highestMemoryAddress = entry.baseAddr + entry.length - 1
        }
    }


    public func print() {
        printf("Memory Ranges    From -         To      Type\n")
        for (idx, entry) in memoryRanges.enumerate() {
            printf("E820 %2.2d: \(entry)\n", idx)
        }
    }


    private mutating func sortRanges() {
        memoryRanges.sortInPlace({
            $0.baseAddr < $1.baseAddr
        })
    }


    private mutating func findHoles() {
        var addr: UInt64 = 0
        for entry in memoryRanges {
            if addr < entry.baseAddr {
                let length = entry.baseAddr - addr
                // BUG - Appending to a 2nd list and then adding this list to memoryRanges
                // somehow lost the first entry after the sort and caused an invalid opcode
                //holes.append(hole)
                //memoryRanges.appendContentsOf(holes)
                memoryRanges.append(E820MemoryEntry(baseAddr: addr, length: length, type: E820Type.HOLE.rawValue))
            }
            addr = entry.baseAddr + entry.length
        }
        sortRanges()
    }
}
