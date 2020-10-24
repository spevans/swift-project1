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

struct PhysBuffer32 {
    let address: PhysAddress    // FIXME, need a PhysAddress32
    var length: UInt32

    init(address: PhysAddress, length: UInt32) {
        precondition(address.value <= UInt64(UInt32.max))
        self.address = address
        self.length = length
    }

    var mutableRawPointer: UnsafeMutableRawPointer {
        address.rawPointer
    }

    var rawBufferPointer: UnsafeRawBufferPointer {
        UnsafeRawBufferPointer(start: address.rawPointer, count: Int(length))
    }

    var physAddress: UInt32 { UInt32(address.value) }
}



extension HCD_UHCI {
    typealias QueueHeadPtr = UnsafeMutablePointer<QueueHead>
    typealias TransferDescriptorPtr = UnsafeMutablePointer<TransferDescriptor>

    struct PhysQueueHead {
        fileprivate let address: PhysAddress

        init(address: PhysAddress) {
            self.address = address
        }

        var pointer: QueueHeadPtr {
            return address.rawPointer.bindMemory(to: QueueHead.self, capacity: 1)
        }

        var physAddress: UInt32 { UInt32(address.value) }
    }


    struct PhysTransferDescriptor {
        fileprivate let address: PhysAddress

        init(address: PhysAddress) {
            self.address = address
        }

        var pointer: TransferDescriptorPtr {
            return address.rawPointer.bindMemory(to: TransferDescriptor.self, capacity: 1)
        }

        var physAddress: UInt32 { UInt32(address.value) }
    }


    class UHCIAllocator {

        // For QHs and TDs - 128x 32 byte blocks
        private let bufferPool32 = alloc(pages: 1)
        private var bufferPool32Bitmap = BitmapAllocator128()

        // For data buffers - 8x 512 byte blocks
        private let bufferPool512 = alloc(pages: 1)
        private var bufferPool512Bitmap = BitmapAllocator8()

        deinit {
            // Validate that all buffers were freed and nothing leaked
            assert(bufferPool32Bitmap.freeEntryCount() == bufferPool32Bitmap.entryCount)
            assert(bufferPool512Bitmap.freeEntryCount() == bufferPool512Bitmap.entryCount)
            freePages(pages: bufferPool32)
            freePages(pages: bufferPool512)
        }


        // 512byte aligned 512 bytes buffer in 32bit physical space
        func allocPhysBuffer(length: Int) -> PhysBuffer32 {
            precondition(length <= 512)
            let buffer = next512ByteBuffer()
            return PhysBuffer32(address: buffer, length: UInt32(length))
        }


        func freePhysBuffer(_ buffer: PhysBuffer32) {
            free512ByteBuffer(address: buffer.address)
        }


        func allocTransferDescriptor() -> PhysTransferDescriptor {
            let buffer = next32ByteBuffer()
            return PhysTransferDescriptor(address: buffer)
        }


        func freeTransferDescriptor(_ descriptor: PhysTransferDescriptor) {
            free32ByteBuffer(address: descriptor.address)
        }


        func allocQueueHead() -> PhysQueueHead {
            let buffer = next32ByteBuffer()
            return PhysQueueHead(address: buffer)
        }


        func freeQueueHead(_ queueHead: PhysQueueHead) {
            free32ByteBuffer(address: queueHead.address)
        }


        // 16byte aligned 32 bytes buffer in 32bit physical space
        private func next32ByteBuffer() -> PhysAddress {
            guard let entry = bufferPool32Bitmap.allocate() else {
                fatalError("Used up allocation of 32 byte buffers")
            }
            return bufferPool32.address + UInt(entry * 32)
        }


        private func free32ByteBuffer(address: PhysAddress) {
            let entry = (address - bufferPool32.address) / 32
            precondition(entry >= 0)
            precondition(entry < 128)
            bufferPool32Bitmap.free(entry: entry)
        }


        // 512byte aligned 512 bytes buffer in 32bit physical space
        private func next512ByteBuffer() -> PhysAddress {
            guard let entry = bufferPool512Bitmap.allocate() else {
                fatalError("Used up allocation of 512 byte buffers")
            }
            return bufferPool512.address + UInt(entry * 512)
        }

        private func free512ByteBuffer(address: PhysAddress) {
            let entry = (address - bufferPool512.address) / 512
            precondition(entry >= 0)
            precondition(entry < 8)
            bufferPool512Bitmap.free(entry: entry)
        }
    }
}
