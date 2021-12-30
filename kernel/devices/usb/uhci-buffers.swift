/*
 * kernel/devices/usb/uhci-buffers.swift
 *
 * Created by Simon Evans on 01/11/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * UHCI Buffers used for Queue Heads, Transfer Descriptors and other buffers that
 * need to be in the low 32bit address space
 *
 */

extension HCD_UHCI {

    struct FrameListPage: RandomAccessCollection {
        fileprivate let region: MMIORegion

        typealias Index = Int
        typealias Element = FrameListPointer
        let count = 1024
        let startIndex = 0
        let endIndex = 1024


        init(region: MMIORegion) {
            self.region = region
        }

        subscript(index: Index) -> Element {
            get {
                precondition(index >= startIndex && index < endIndex)
                let value: UInt32 = region.read(fromByteOffset: index * 4)
                return FrameListPointer(rawValue: value)
            }
            set {
                precondition(index >= startIndex && index < endIndex)
                region.write(value: newValue.rawValue, toByteOffset: index * 4)
            }
        }

        func setAllPointers(to flp: FrameListPointer) {
            let value = flp.rawValue
            for index in startIndex..<endIndex {
                region.write(value: value, toByteOffset: index * 4)
            }
        }

        var physicalAddress: UInt32 { UInt32(region.physicalRegion.address.value) }
    }


    final class UHCIAllocator {

        // For QHs and TDs - 128x 32 byte blocks
        private let bufferPool32: MMIORegion
        private var bufferPool32Bitmap = BitmapAllocator128()

        // For data buffers - 8x 512 byte blocks
        private let bufferPool512: MMIORegion
        private var bufferPool512Bitmap = BitmapAllocator8()

        let frameListPage: FrameListPage

        init() {
            let flp = allocIOPage()
            frameListPage = FrameListPage(region: MMIORegion(physicalRegion: flp, virtualAddress: flp.vaddr))

            let _bufferPool32 = allocIOPage()
            bufferPool32 = MMIORegion(physicalRegion: _bufferPool32, virtualAddress: _bufferPool32.vaddr)

            let _bufferPool512 = allocIOPage()
            bufferPool512 = MMIORegion(physicalRegion: _bufferPool512, virtualAddress: _bufferPool512.vaddr)
        }

        deinit {
            // Validate that all buffers were freed and nothing leaked
            assert(bufferPool32Bitmap.freeEntryCount() == bufferPool32Bitmap.entryCount)
            assert(bufferPool512Bitmap.freeEntryCount() == bufferPool512Bitmap.entryCount)

            freeIOPage(bufferPool32.physicalRegion)
            freeIOPage(bufferPool512.physicalRegion)
            freeIOPage(frameListPage.region.physicalRegion)
        }


        // 512byte aligned 512 bytes buffer in 32bit physical space
        func allocPhysBuffer(length: Int) -> MMIOSubRegion {
            precondition(length <= 512)
            let region = next512ByteBuffer()
            return  MMIOSubRegion(virtualAddress: region.virtualAddress, physicalAddress: region.physicalAddress, count: length)
        }


        func freePhysBuffer(_ region: MMIOSubRegion) {
            free512ByteBuffer(region: region)
        }


        func allocTransferDescriptor() -> PhysTransferDescriptor {
            let buffer = next32ByteBuffer()
            return PhysTransferDescriptor(mmioSubRegion: buffer)
        }


        func freeTransferDescriptor(_ descriptor: PhysTransferDescriptor) {
            precondition(descriptor.mmioSubRegion.count == 32)
            free32ByteBuffer(region: descriptor.mmioSubRegion)
        }


        func allocQueueHead() -> PhysQueueHead {
            let buffer = next32ByteBuffer()
            return PhysQueueHead(mmioSubRegion: buffer)
        }


        func freeQueueHead(_ queueHead: PhysQueueHead) {
            precondition(queueHead.mmioSubRegion.count == 32)
            free32ByteBuffer(region: queueHead.mmioSubRegion)
        }


        // Returns an MMIOSubRegion which covers the specified physical address.
        // It must be known in the MMIORegions already allocated
        func fromPhysical(address: PhysAddress) -> MMIOSubRegion {
            if let region = bufferPool32.mmioSubRegion(containing: address, count: 32) { return region }
            else if let region = bufferPool512.mmioSubRegion(containing: address, count: 512) { return region }
            else { fatalError("UHCI: Bufers: No MMIORegion contains physical address \(address)") }
        }


        // 16byte aligned 32 bytes buffer in 32bit physical space
        private func next32ByteBuffer() -> MMIOSubRegion {
            guard let entry = bufferPool32Bitmap.allocate() else {
                fatalError("Used up allocation of 32 byte buffers")
            }
            return bufferPool32.mmioSubRegion(offset: entry * 32, count: 32)
        }


        private func free32ByteBuffer(region: MMIOSubRegion) {
            let entry = (region.virtualAddress - bufferPool32.virtualAddress) / 32
            precondition(entry >= 0)
            precondition(entry < 128)
            bufferPool32Bitmap.free(entry: Int(entry))
        }


        // 512byte aligned 512 bytes buffer in 32bit physical space
        private func next512ByteBuffer() -> MMIOSubRegion {
            guard let entry = bufferPool512Bitmap.allocate() else {
                fatalError("Used up allocation of 512 byte buffers")
            }
            return bufferPool512.mmioSubRegion(offset: entry * 512, count: 512)
        }

        private func free512ByteBuffer(region: MMIOSubRegion) {
            let entry = (region.virtualAddress - bufferPool512.virtualAddress) / 512
            precondition(entry >= 0)
            precondition(entry < 8)
            bufferPool512Bitmap.free(entry: Int(entry))
        }
    }
}
