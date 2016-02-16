/*
 * kernel/init/bootparams.swift
 *
 * Created by Simon Evans on 24/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Initial setup for available physical memory etc
 *
 */

// Singleton that will be initialised by BootParams.parse()
let memoryRanges = BootParams.parseE820Table()


struct BootParams {
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


    static private var bootParamsSize: Int = 0
    static private var e820MapAddr: UInt = 0
    static private var e820Entries: Int = 0


    static func parse(bootParamsAddr: UInt) {
        kprintf("parsing bootParams @ 0x%lx\n", bootParamsAddr)
        if (bootParamsAddr == 0) {
            print("bootParamsAddr is null");
            return;
        }
        let membuf = MemoryBufferReader(bootParamsAddr, size: strideof(bios_boot_params))
        let sig = try! membuf.readASCIIZString(maxSize: 8)

        guard sig == "BIOS" else {
            print("boot_params are not BIOS")
            return
        }
        membuf.offset = 8
        bootParamsSize = try! membuf.read()
        e820MapAddr = try! membuf.read()
        e820Entries = try! membuf.read()

        // Create the singleton and force parsing
        if memoryRanges.count > 0 {
            print("E820: Memory Ranges    From -         To      Type")
            for (idx, entry) in memoryRanges.enumerate() {
                printf("E820: %2.2d: \(entry)\n", idx)
            }
        }
    }


    static func highestMemoryAddress() -> UInt64 {
        if (memoryRanges.count > 0) {
            let entry = memoryRanges[memoryRanges.count-1]
            return entry.baseAddr + entry.length - 1
        } else {
            return 0
        }
    }


    // FIXME - still needs to check for overlapping regions
    static private func parseE820Table() -> [E820MemoryEntry] {
        var ranges: [E820MemoryEntry] = []
        printf("Found %d E820 entries\n", e820Entries)
        if (e820Entries > 0 && e820MapAddr > 0) {
            let buf = MemoryBufferReader(e820MapAddr, size: strideof(E820MemoryEntry) * e820Entries)
            ranges.reserveCapacity(e820Entries)

            for _ in 0..<e820Entries {
                let entry: E820MemoryEntry = try! buf.read()
                ranges.append(entry)
            }
            sortRanges(&ranges)
            findHoles(&ranges)
            // These values are only valid during startup before the memory is reclaimed so
            // forget the addresss as they wont be valid later on anyway
            e820MapAddr = 0
            e820Entries = 0
        }
        return ranges
    }


    static private func sortRanges(inout ranges: [E820MemoryEntry]) {
        ranges.sortInPlace({
            $0.baseAddr < $1.baseAddr
        })
    }


    static private func findHoles(inout ranges: [E820MemoryEntry]) {
        var addr: UInt64 = 0
        for entry in ranges {
            if addr < entry.baseAddr {
                let length = entry.baseAddr - addr
                // BUG - Appending to a 2nd list and then adding this list to memoryRanges
                // somehow lost the first entry after the sort and caused an invalid opcode
                //holes.append(hole)
                //memoryRanges.appendContentsOf(holes)
                ranges.append(E820MemoryEntry(baseAddr: addr, length: length, type: E820Type.HOLE.rawValue))
            }
            addr = entry.baseAddr + entry.length
        }
        sortRanges(&ranges)
    }
}
