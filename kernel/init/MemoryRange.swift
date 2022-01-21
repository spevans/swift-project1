//
//  kernel/init/MemoryRange.swift
//  project1
//
//  Created by Simon Evans on 10/04/2021.
//  Copyright © 2021 - 2022 Simon Evans. All rights reserved.
//


// These memory types are just the EFI ones, the BIOS ones are
// actually a subset so these definitions cover both cases
enum MemoryType: UInt32 {
    case Reserved    = 0            // Not usable
    case LoaderCode                 // Usable
    case LoaderData                 // Usable
    case BootServicesData           // Usable
    case BootServicesCode           // Usable
    case RuntimeServicesCode        // Needs to be preserved / Not usable
    case RuntimeServicesData        // Needs to be preserved / Not usable
    case Conventional               // Usable (RAM)
    case Unusable                   // Unusable (RAM with errors)
    case ACPIReclaimable            // Usable after ACPI enabled
    case ACPINonVolatile            // Needs to be preserved / Not usable
    case MemoryMappedIO             // Unusable
    case MemoryMappedIOPortSpace    // Unusable

    // OS defined values
    case Hole         = 0x80000000  // Used for holes in the map to keep ranges contiguous
    case PageMap      = 0x80000001  // Temporary page maps setup by the boot loader
    case BootData     = 0x80000002  // Other temporary data created by boot code inc BootParams
    case Kernel       = 0x80000003  // The loaded kernel + data + bss
    case FrameBuffer  = 0x80000004  // Framebuffer address if it is the top of the address space
    case E820Reserved = 0x80000005  // Ranges marked in E820 map as reserved

    enum Access {
        case unusable
        case mmio
        case readOnly
        case readWrite

        func lowest(_ other: Access) -> Access {
            switch (self, other) {
                case (.mmio, _), (_, .mmio):
                    return .mmio

                case (.unusable, _), (_, .unusable):
                    return .unusable

                case (.readOnly, _), (_, .readOnly):
                    return .readOnly

                default: return .readWrite
            }
        }
    }

    var access: Access {
        switch self {
            case .Hole, .Reserved, .Unusable, .MemoryMappedIOPortSpace:
                return .unusable

            case .LoaderCode, .LoaderData, .BootServicesCode, .BootServicesData, .RuntimeServicesCode, .RuntimeServicesData,
                    .ACPIReclaimable, .ACPINonVolatile, .BootData, .E820Reserved:
                return .readOnly

            case .MemoryMappedIO, .FrameBuffer:
                return .mmio

            case .Conventional, .Kernel, .PageMap:
                return .readWrite
        }
    }
}


let kb: UInt = 1024
let mb: UInt = 1048576
let gb = kb * mb


struct MemoryRange: Equatable, CustomStringConvertible {
    let type: MemoryType
    let start: PhysAddress
    let size: UInt
    var endAddress: PhysAddress { start + (size - 1 ) }


    init(type: MemoryType, start: PhysAddress, size: UInt) {
        self.type = type
        self.start = start
        self.size = size
    }

    init(type: MemoryType, start: PhysAddress, endAddress: PhysAddress) {
        self.type = type
        self.start = start
        self.size = UInt((endAddress - start) + 1)
    }

    var physPageRanges: [PhysPageRange] {
        precondition(start.isPageAligned)
        return PhysPageRange.createRanges(startAddress: start, endAddress: endAddress, pageSizes: [PageSize()])
    }

    func physPageRanges(using pageSizes: [PageSize]) -> [PhysPageRange]  {
        precondition(start.isPageAligned)
        return PhysPageRange.createRanges(startAddress: start, endAddress: endAddress, pageSizes: pageSizes)
    }

    var description: String {
        let str = (size >= mb) ? String.sprintf(" %6uMB  ", size / mb) :
        String.sprintf(" %6uKB  ", size / kb)

        return String.sprintf("%12X - %12X %@ %@", start.value,  endAddress.value, str, type)
    }
}


// Returns an iterator over the ranges in an array, filling in any gaps in the address space
// with a MemoryRange of .Hole.
private struct RangesWithHoles: IteratorProtocol {
    typealias Element = MemoryRange

    var array: Array<MemoryRange>
    var nextIndex: Array<MemoryRange>.Index
    var lastIndex: Array<MemoryRange>.Index

    init(ranges: Array<MemoryRange>) {
        self.array = ranges
        nextIndex = ranges.startIndex
        lastIndex = nextIndex
    }

    mutating func next() -> Element? {
        // Returns the next Range in the list, inserting a Hole range to ensure
        // no gaps between each region
        if nextIndex == array.endIndex { return nil }

        if lastIndex == nextIndex {
            nextIndex += 1
            return array[lastIndex]
        }

        if array[lastIndex].endAddress + 1 < array[nextIndex].start {
            // Insert a Hole
            defer { lastIndex += 1 }
            let size = UInt(array[nextIndex].start - (array[lastIndex].endAddress + 1))
            return MemoryRange(type: .Hole, start: array[lastIndex].endAddress + 1, size: size)
        }
        lastIndex += 1
        nextIndex += 1

        return array[lastIndex]
    }
}

extension MemoryRange {
    // Produce ranges aligned to page boundaries. Will only span pages if both the start and end are aligned.
    // Addresses are contiguous as .Holes are inserted into the gaps.
    struct PageOrSubPageAligned: IteratorProtocol {

        enum State {
            // White part of the region to process next
            case start
            case middle
            case end
        }

        typealias Element = MemoryRange
        fileprivate var holeIterator: RangesWithHoles
        let pageSize: PageSize
        var currentRange: MemoryRange?
        var state: State = .start

        init(ranges: Array<MemoryRange>, toPageSize pageSize: PageSize) {
            holeIterator = RangesWithHoles(ranges: ranges)
            self.pageSize = pageSize
        }

        mutating func next() -> Element? {
            //let pageMask = ~(pageSize - 1)

            if currentRange == nil { currentRange = holeIterator.next() }
            guard let range = currentRange else { return nil }

            if state == .start {
                state = .middle
                if !pageSize.isPageAligned(range.start) {
                    if !pageSize.onSamePage(range.start, range.endAddress) {
                        // If it crosses a page boundary, split in 2 with the split at the page boundary
                        let newEndAddress = pageSize.lastAddressInPage(range.start)
                        currentRange = MemoryRange(type: range.type, start: newEndAddress + 1, endAddress: range.endAddress)
                        return MemoryRange(type: range.type, start: range.start, endAddress: newEndAddress)
                    } else {
                        currentRange = nil
                        state = .start
                        return range
                    }
                }
            }

            if state == .middle {
                state = .end
                if pageSize.isPageAligned(range.start) && range.size >= pageSize.size {
                    if pageSize.isPageAligned(range.size) {
                        state = .start
                        currentRange = nil
                        return range
                    }
                    let result = MemoryRange(type: range.type, start: range.start, size: pageSize.roundDown(range.size))
                    if result.endAddress == range.endAddress {
                        currentRange = nil
                        state = .start
                    } else {
                        currentRange = MemoryRange(type: range.type, start: result.endAddress + 1, endAddress: range.endAddress)
                    }
                    return result
                }
            }

            if state == .end {
                state = .start
                currentRange = nil
                return range
            }
            return nil
        }
    }
}

extension Array where Element == MemoryRange {

    // Insert a memory range potentially overwriting a preexisting range, which will
    // be split up appropiately.
    mutating func insertRange(_ newRange: MemoryRange) {
        if self.isEmpty || newRange.start > self.last!.endAddress {
            self.append(newRange)
            return
        }

        var result: [MemoryRange] = []
        result.reserveCapacity(self.count)
        var iterator = self.makeIterator()

        while let range = iterator.next() {
            if range.endAddress < newRange.start {
                result.append(range)
                continue
            }

            if newRange.endAddress < range.start {
                result.append(newRange)
                result.append(range)
                break
            }

            if newRange.start <= range.start && newRange.endAddress >= range.endAddress {
                // Ignore the range as it is completely covered by the new range
                continue
            }

            if range.start > newRange.start && range.start < newRange.endAddress {
                result.append(newRange)
                let newStart = newRange.endAddress + 1
                let newSize = UInt(range.endAddress - newStart)
                result.append(MemoryRange(type: range.type, start: newStart, size: newSize))
                break
            }

            if range.endAddress > newRange.start && range.endAddress < newRange.endAddress {
                let newSize = UInt(newRange.start - range.start)
                result.append(MemoryRange(type: range.type, start: range.start, size: newSize))
                result.append(newRange)
                break
            }

            // New region sits within current region and may/maynot start or end on same address
            if newRange.start >= range.start && newRange.endAddress <= range.endAddress {
                let frontSize = UInt(newRange.start - range.start)
                if frontSize > 0 {
                    result.append(MemoryRange(type: range.type, start: range.start, size: frontSize))
                }
                result.append(newRange)
                let endSize = UInt(range.endAddress - newRange.endAddress)
                if endSize > 0 {
                    let start = (range.endAddress - endSize) + 1
                    result.append(MemoryRange(type: range.type, start: start, size: endSize))
                }
                break
            }
        }

        while let range = iterator.next() {
            result.append(range)
        }

        self = result
    }

    // Merge adjcent ranges of the same type
    mutating func mergeRanges() { //ranges: [MemoryRange]) -> [MemoryRange] {
        if self.count < 2 { return }
        var result: [MemoryRange] = []
        result.reserveCapacity(self.count)

        var iterator = self.makeIterator()
        if var range = iterator.next() {
            while let next = iterator.next() {
                if range.type == next.type && (range.endAddress + 1 == next.start) {
                    range = MemoryRange(type: range.type, start: range.start, size: range.size + next.size)
                } else {
                    result.append(range)
                    range = next
                }
            }
            result.append(range)
        }
        self = result
    }

    func rangesWithHoles() -> [MemoryRange] {
        if self.count < 2 {
            return self
        }

        var iterator = RangesWithHoles(ranges: self)
        var result: [MemoryRange] = []
        result.reserveCapacity(self.count)

        while let range = iterator.next() {
            result.append(range)
        }
        return result
    }


    func align(toPageSize pageSize: PageSize) -> [(PhysPageRange, MemoryType.Access)] {
        var iterator = MemoryRange.PageOrSubPageAligned(ranges: self, toPageSize: pageSize)
        guard let first = iterator.next() else { return [] }
        var result: [(PhysPageRange, MemoryType.Access)] = []
        result.reserveCapacity(self.count)

        var currentStart = first.start
        var currentEnd = first.endAddress
        var currentAccess = first.type.access
        if !pageSize.isPageAligned(currentStart) {
            // If the start is not page aligned, round it down and prepend a Hole
            currentStart = pageSize.roundDown(currentStart)
            currentAccess = currentAccess.lowest(MemoryType.Hole.access)
        }

        while let region = iterator.next() {
            assert(currentEnd + 1 == region.start)

            if pageSize.isPageAligned(currentEnd + 1) {
                let pageCount = UInt((currentEnd - currentStart) + 1) / pageSize.size
                let physPageRange = PhysPageRange(currentStart, pageSize: pageSize, pageCount: Int(pageCount))
                result.append((physPageRange, currentAccess))
                currentStart = region.start
                currentEnd = region.endAddress
                currentAccess = region.type.access
            }

            else {
                currentAccess = currentAccess.lowest(region.type.access)
                currentEnd = region.endAddress
            }
        }

        // Round the last address to end of page, appending a Hole
        if currentEnd != pageSize.lastAddressInPage(currentEnd) {
            currentEnd = pageSize.lastAddressInPage(currentEnd)
            currentAccess = currentAccess.lowest(MemoryType.Hole.access)
        }
        let pageCount = UInt((currentEnd - currentStart) + 1) / pageSize.size
        let physPageRange = PhysPageRange(currentStart, pageSize: pageSize, pageCount: Int(pageCount))
        result.append((physPageRange, currentAccess))
        return result
    }


    // Finds the MemoryRange covering the given pageRange or .nil if none is found.
    // If it covers multiple ranges then nil is returned
    func findRange(containing physAddress: PhysAddress) -> MemoryRange? {
        for range in self {
            if range.start <= physAddress && range.endAddress >= physAddress {
                return range
            }
        }
        return nil
    }
}
