//
//  MMIORegion.swift
//  project1
//
//  Created by Simon Evans on 21/04/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//
//  Access to a mapped region used for device IO. May represent the
//  underlying hardware (eg frame buffer) or memory allocated for IO
//  buffers. In both cases the pages are mapped as uncacheable so that
//  the CPU doesnt reorder accesses.
//

struct MMIORegion: CustomStringConvertible {
    let physicalRegion: PhysPageRange
    let virtualAddress: VirtualAddress

    var description: String {
        "MMIO @ 0x\(String(virtualAddress, radix: 16)) -> \(physicalRegion)"
    }


    init(physicalRegion: PhysPageRange, virtualAddress: VirtualAddress) {
        self.physicalRegion = physicalRegion
        self.virtualAddress = virtualAddress
    }

    @inline(__always)
    func read<T: FixedWidthInteger & UnsignedInteger>(fromByteOffset offset: Int) -> T {
        let bytes = T.bitWidth / 8
        precondition(offset + bytes <= physicalRegion.regionSize)
        let address = UnsafeRawPointer(bitPattern: virtualAddress + UInt(offset))
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
        precondition(offset + bytes <= physicalRegion.regionSize)
        let address = UnsafeMutableRawPointer(bitPattern: virtualAddress + UInt(offset))
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
        precondition(offset + count <= physicalRegion.regionSize)
        return MMIOSubRegion(virtualAddress: virtualAddress + UInt(offset), physicalAddress: physicalRegion.address + offset, count: count)
    }

    func mmioSubRegion(containing address: PhysAddress, count: Int) -> MMIOSubRegion? {
        if physicalRegion.address <= address && physicalRegion.endAddress >= (address + count) {
            let offset = address - physicalRegion.address
            return MMIOSubRegion(virtualAddress: virtualAddress + UInt(offset), physicalAddress: address, count: count)
        } else {
            return nil
        }
    }
}


struct MMIOSubRegion: CustomStringConvertible, RandomAccessCollection {
    typealias Element = UInt8
    typealias Index = Int
    typealias SubSequence = Self

    let virtualAddress: VirtualAddress
    let physicalAddress: PhysAddress
    let count: Int

    let startIndex: Index = 0
    var endIndex: Index { count }


    // FIXME, make sure this never fails if needed (ie buffer is in first 4G)
    var physAddress32: UInt32 { UInt32(physicalAddress.value) }


    init(virtualAddress: VirtualAddress, physicalAddress: PhysAddress, count: Int) {
        self.virtualAddress = virtualAddress
        self.physicalAddress = physicalAddress
        self.count = count
    }

    subscript(index: Index) -> Element {
        get { mmio_read_uint8(UnsafeRawPointer(bitPattern: virtualAddress + UInt(index))) }
        set { mmio_write_uint8(UnsafeMutableRawPointer(bitPattern: virtualAddress + UInt(index)), newValue) }
    }


    subscript(range: Range<Index>) -> SubSequence {
        precondition(range.count > 0)
        precondition(range.upperBound < self.count)
        return Self(virtualAddress: virtualAddress + UInt(range.lowerBound),
                    physicalAddress: physicalAddress + range.lowerBound,
                    count: range.count)
    }

    @inline(__always)
    func read<T: FixedWidthInteger & UnsignedInteger>(fromByteOffset offset: Int) -> T {
        let bytes = T.bitWidth / 8
        guard offset + bytes <= count else {
            fatalError("mmioSubReagion Read, offset = \(offset) bytes = \(bytes) \(self)")
        }
        precondition(offset + bytes <= count)
        let address = UnsafeRawPointer(bitPattern: virtualAddress + UInt(offset))
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
        let address = UnsafeMutableRawPointer(bitPattern: virtualAddress + UInt(offset))
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
                mmio_write_uint8(UnsafeMutableRawPointer(bitPattern: virtualAddress + UInt(offset)), byte)
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
        "MMIO @ 0x\(String(virtualAddress, radix: 16)) -> \(physicalAddress), count: \(count)"
    }
}
