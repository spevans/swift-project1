/*
 * kernel/mm/memory.swift
 *
 * Created by Simon Evans on 24x/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Initial setup for available physical memory etc
 *
 */


struct E820MemoryEntry {
    let baseAddr: UInt64
    let length: UInt64
    let type: UInt32
}


public class BootParams {
    let e820MemoryEntryCount: UInt32
    var memoryRanges: [E820MemoryEntry] = []

    public init() {
        let buf = MemoryBufferReader(0x30000, size: 4096)
        e820MemoryEntryCount = try! buf.read()
        memoryRanges.reserveCapacity(Int(e820MemoryEntryCount))
        for _ in 0..<e820MemoryEntryCount {
            let entry: E820MemoryEntry = try! buf.read()
            memoryRanges.append(entry)
        }
    }


    public func print() {
         String.printf("Memory Ranges  From -     To    Type\n")
         for (idx, entry) in memoryRanges.enumerate() {
             String.printf("%d: %16X - %8X %4.4X\n", idx, entry.baseAddr,
                                entry.baseAddr + entry.length - 1, entry.type)
         }
    }
}
