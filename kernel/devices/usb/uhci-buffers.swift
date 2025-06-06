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

    struct FrameListPage: RandomAccessCollection, CustomStringConvertible {
        fileprivate let region: MMIORegion

        typealias Index = Int
        typealias Element = FrameListPointer
        let count = 1024
        let startIndex = 0
        let endIndex = 1024

        var description: String {
            region.description
        }

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
                writeMemoryBarrier()
            }
        }

        func setAllPointers(to flp: FrameListPointer) {
            let value = flp.rawValue
            for index in startIndex..<endIndex {
                region.write(value: value, toByteOffset: index * 4)
            }
            writeMemoryBarrier();
        }

        var physicalAddress: UInt32 { UInt32(region.physicalRegion.baseAddress.value) }
    }


    final class UHCIAllocator {

        // For Queue Heads - 256x 16 byte blocks
        private let qhBufferPool16: MMIORegion
        private var qhBufferPool16Bitmap = LargeBitmapAllocator(maxElements: 256)

        // For TransferDescriptors - 128x 32 byte blocks
        private let tdBufferPool32: MMIORegion
        private var tdBufferPool32Bitmap = BitmapAllocator128()

        // For data buffers - 8x 512 byte blocks
        private let bufferPool512: MMIORegion
        private var bufferPool512Bitmap = BitmapAllocator8()

        let frameListPage: FrameListPage

        var freeQHs: Int { qhBufferPool16Bitmap.freeEntryCount() }
        var freeTDs: Int { tdBufferPool32Bitmap.freeEntryCount() }


        init() {
            let flp = allocIOPage()
            frameListPage = FrameListPage(region: MMIORegion(flp))
            qhBufferPool16 = MMIORegion(allocIOPage())
            tdBufferPool32 = MMIORegion(allocIOPage())
            bufferPool512 = MMIORegion(allocIOPage())
        }

        deinit {
            // Validate that all buffers were freed and nothing leaked
            assert(qhBufferPool16Bitmap.freeEntryCount() == qhBufferPool16Bitmap.entryCount)
            assert(tdBufferPool32Bitmap.freeEntryCount() == tdBufferPool32Bitmap.entryCount)
            assert(bufferPool512Bitmap.freeEntryCount() == bufferPool512Bitmap.entryCount)

            freeIOPage(qhBufferPool16.physicalRegion)
            freeIOPage(tdBufferPool32.physicalRegion)
            freeIOPage(bufferPool512.physicalRegion)
            freeIOPage(frameListPage.region.physicalRegion)
        }


        // 512byte aligned 512 bytes buffer in 32bit physical space
        func allocPhysBuffer(length: Int) -> MMIOSubRegion {
            precondition(length <= 512)
            let region = next512ByteBuffer()
            return  MMIOSubRegion(baseAddress: region.baseAddress, count: length)
        }


        func freePhysBuffer(_ region: MMIOSubRegion) {
            free512ByteBuffer(region: region)
        }


        func allocTransferDescriptor() -> PhysTransferDescriptor {
            guard let entry = tdBufferPool32Bitmap.allocate() else {
                fatalError("Used up allocation of 32 byte buffers")
            }
            let buffer =  tdBufferPool32.mmioSubRegion(offset: entry * 32, count: 32)
            return PhysTransferDescriptor(mmioSubRegion: buffer)
        }


        func freeTransferDescriptor(_ descriptor: PhysTransferDescriptor) {
            precondition(descriptor.mmioSubRegion.count == 32)
            let entry = (descriptor.mmioSubRegion.baseAddress - tdBufferPool32.baseAddress) / 32
            precondition(entry >= 0)
            precondition(entry < 128)
            tdBufferPool32Bitmap.free(entry: Int(entry))
        }


        func allocQueueHead() -> PhysQueueHead {
            guard let entry = qhBufferPool16Bitmap.allocate() else {
                fatalError("Used up allocation of 16 byte buffers")
            }
            let buffer = qhBufferPool16.mmioSubRegion(offset: entry * 16, count: 16)
            return PhysQueueHead(mmioSubRegion: buffer)
        }


        func freeQueueHead(_ queueHead: PhysQueueHead) {
            precondition(queueHead.mmioSubRegion.count == 16)
            let entry = (queueHead.mmioSubRegion.baseAddress - qhBufferPool16.baseAddress) / 16
            precondition(entry >= 0)
            precondition(entry < 256)
            qhBufferPool16Bitmap.free(entry: Int(entry))
        }


        // Returns an MMIOSubRegion which covers the specified physical address.
        // It must be known in the MMIORegions already allocated
        func fromPhysical(address: PhysAddress) -> MMIOSubRegion {
            if let region = qhBufferPool16.mmioSubRegion(containing: address, count: 16) { return region }
            else if let region = tdBufferPool32.mmioSubRegion(containing: address, count: 32) { return region }
            else if let region = bufferPool512.mmioSubRegion(containing: address, count: 512) { return region }
            else { fatalError("UHCI: Bufers: No MMIORegion contains physical address \(address)") }
        }


        // 512byte aligned 512 bytes buffer in 32bit physical space
        private func next512ByteBuffer() -> MMIOSubRegion {
            guard let entry = bufferPool512Bitmap.allocate() else {
                fatalError("Used up allocation of 512 byte buffers")
            }
            return bufferPool512.mmioSubRegion(offset: entry * 512, count: 512)
        }

        private func free512ByteBuffer(region: MMIOSubRegion) {
            let entry = (region.baseAddress - bufferPool512.baseAddress) / 512
            precondition(entry >= 0)
            precondition(entry < 8)
            bufferPool512Bitmap.free(entry: Int(entry))
        }
    }
}
