//
//  MMIORegion.swift
//  project1
//
//  Created by Simon Evans on 21/04/2021.
//  Copyright © 2021 - 2022 Simon Evans. All rights reserved.
//
//  Access to a mapped region used for device IO. May represent the
//  underlying hardware (eg frame buffer) or memory allocated for IO
//  buffers. In both cases the pages are mapped as uncacheable so that
//  the CPU doesnt reorder accesses.
//

struct MMIORegion: CustomStringConvertible {
    let physAddressRegion: PhysRegion

    var baseAddress: PhysAddress { physAddressRegion.baseAddress }
    var endAddress: PhysAddress { baseAddress + physAddressRegion.size - 1 }
    var regionSize: Int { Int(physAddressRegion.size) }
    var physicalRegion: PhysPageAlignedRegion {
        physAddressRegion.physPageAlignedRegion
    }

    var description: String {
        "MMIO @ \(physicalRegion) [\(physAddressRegion)]"
    }

    init(_ region: PhysPageAlignedRegion) {
        self = Self(region: PhysRegion(region))
    }

    init(region: PhysRegion) {
        physAddressRegion = region
    }

    @inline(__always)
    func read<T: FixedWidthInteger & UnsignedInteger>(fromByteOffset offset: Int) -> T {
        let bytes = T.bitWidth / 8

        if offset + bytes > regionSize {
            fatalError("MMIORegion.read: offset \(offset) + bytes \(bytes) > regionSize \(regionSize)")
        }
        precondition(offset + bytes <= regionSize)
        let address = (baseAddress + offset).rawPointer
        switch bytes {
            case 1: return T(mmio_read_uint8(address))
            case 2: return T(mmio_read_uint16(address))
            case 4: return T(mmio_read_uint32(address))
            case 8: return T(mmio_read_uint64(address))
            default: fatalError("Invalid MMIO read of \(bytes) bytes")
        }
    }

    @inline(__always)
    func write<T: FixedWidthInteger & UnsignedInteger>(value: T, toByteOffset offset: Int) {
        let bytes = T.bitWidth / 8
        if offset + bytes > regionSize {
            fatalError("MMIORegion.read: offset \(offset) + bytes \(bytes) > regionSize \(regionSize)")
        }
        precondition(offset + bytes <= regionSize)
        let address = (baseAddress + offset).rawPointer
        switch bytes {
            case 1: return mmio_write_uint8(address, UInt8(value))
            case 2: return mmio_write_uint16(address, UInt16(value))
            case 4: return mmio_write_uint32(address, UInt32(value))
            case 8: return mmio_write_uint64(address, UInt64(value))
            default: fatalError("Invalid MMIO write of \(bytes) bytes")
        }
    }

    func mmioSubRegion(offset: Int, count: Int) -> MMIOSubRegion {
        precondition(count > 0)
        precondition(offset + count <= regionSize)
        return MMIOSubRegion(baseAddress: baseAddress + offset, count: count)
    }

    func mmioSubRegion(containing address: PhysAddress, count: Int) -> MMIOSubRegion? {
        precondition(count > 0)
        if baseAddress <= address && endAddress >= (address + count - 1) {
            return MMIOSubRegion(baseAddress: address, count: count)
        } else {
            return nil
        }
    }

    func dump(offset: UInt, count: UInt) {
        let sub = mmioSubRegion(offset: Int(offset), count: min(regionSize - Int(offset), Int(count)))
        hexDump(buffer: sub)
    }

    func including(region: PhysRegion) -> Self {
        let newRegion = PhysRegion(
            start: min(physAddressRegion.baseAddress, region.baseAddress),
            end: max(physAddressRegion.endAddress, region.endAddress)
        )

        if physAddressRegion.contains(newRegion) {
            return self
        }

        let (before, after) = newRegion.physPageAlignedRegion.extraRanges(containing: physicalRegion)
        if let range = before {
            _ = mapRORegion(region: range)
        }

        if let range = after {
            _ = mapRORegion(region: range)
        }
        return Self(region: newRegion)
    }
}


struct MMIOSubRegion: CustomStringConvertible, RandomAccessCollection {
    typealias Element = UInt8
    typealias Index = Int
    typealias SubSequence = Self

    let baseAddress: PhysAddress
    let count: Int

    let startIndex: Index = 0
    var endIndex: Index { count }

    // FIXME, make sure this never fails if needed (ie buffer is in first 4G)
    var physAddress32: UInt32 { UInt32(baseAddress.value) }


    init(baseAddress: PhysAddress, count: Int) {
        self.baseAddress = baseAddress
        self.count = count
    }

    subscript(index: Index) -> Element {
        get { mmio_read_uint8(baseAddress.rawPointer.advanced(by: index)) }
        set { mmio_write_uint8(baseAddress.rawPointer.advanced(by: index), newValue) }
    }


    subscript(range: Range<Index>) -> SubSequence {
        precondition(range.count > 0)
        precondition(range.upperBound < self.count)
        return Self(baseAddress: baseAddress + range.lowerBound, count: range.count)
    }

    @inline(__always)
    func read<T: FixedWidthInteger & UnsignedInteger>(fromByteOffset offset: Int) -> T {
        let bytes = T.bitWidth / 8
        guard offset + bytes <= count else {
            fatalError("mmioSubReagion Read, offset = \(offset) bytes = \(bytes) \(self)")
        }
        precondition(offset + bytes <= count)
        let address = baseAddress.rawPointer.advanced(by: offset)
        switch bytes {
            case 1: return T(mmio_read_uint8(address))
            case 2: return T(mmio_read_uint16(address))
            case 4: return T(mmio_read_uint32(address))
            case 8: return T(mmio_read_uint64(address))
            default: fatalError("Invalid MMIO read of \(bytes) bytes")
        }
    }

    @inline(__always)
    func write<T: FixedWidthInteger & UnsignedInteger>(value: T, toByteOffset offset: Int) {
        let bytes = T.bitWidth / 8
        precondition(offset + bytes <= count)
        let address = baseAddress.rawPointer.advanced(by: offset)
        switch bytes {
            case 1: return mmio_write_uint8(address, UInt8(value))
            case 2: return mmio_write_uint16(address, UInt16(value))
            case 4: return mmio_write_uint32(address, UInt32(value))
            case 8: return mmio_write_uint64(address, UInt64(value))
            default: fatalError("Invalid MMIO write of \(bytes) bytes")
        }
    }

    func storeBytes<T>(of value: T, as type: T.Type) {
        var temp = value
        withUnsafeBytes(of: &temp) { (bufferPtr: UnsafeRawBufferPointer) in
            precondition(bufferPtr.count <= count)
            var offset = 0
            for byte in bufferPtr {
                let address = baseAddress.rawPointer.advanced(by: offset)
                mmio_write_uint8(address, byte)
                offset += 1
            }
        }
    }

    mutating func clearBuffer() {
        for index in startIndex..<endIndex {
            self[index] = 0
        }
    }

    var description: String {
        "MMIO @ \(baseAddress), count: \(count)"
    }
}
