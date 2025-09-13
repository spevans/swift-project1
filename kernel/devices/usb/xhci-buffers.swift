/*
 *  xhci-buffers.swift
 *  Kernel
 *
 *  Created by Simon Evans on 04/09/2025.
 */

extension HCD_XHCI {

    final class XHCIAllocator {
        private let scratchPadRestore: Bool
        private let maxScratchPadBuffers: Int
        private let maxSlots: Int
        private var allocatedPages: [PhysPageAlignedRegion] = []
        private let deviceContextIndex: MMIORegion
        private let scratchPadIndex: MMIORegion?
        let contextSize: Int
        var deviceContextIndexAddress: RawAddress { deviceContextIndex.baseAddress.value }


        init(_ capabilities: borrowing CapabilityRegisters) {
            self.scratchPadRestore = capabilities.scratchPadRestore
            self.maxScratchPadBuffers = capabilities.maxScratchPadBuffers
            self.maxSlots = capabilities.maxSlots
            self.contextSize = capabilities.contextSize
            let page = allocIOPage()
            self.allocatedPages.append(page)
            self.deviceContextIndex = MMIORegion(page)

            if self.scratchPadRestore, self.maxScratchPadBuffers > 0 {
                // Allocate a page to hold max_bufs scratch entries, clip to 4096/8 for now
                if self.maxScratchPadBuffers > 4096 / 8 {
                    fatalError("xhci: Too many scratch pad buffers to fit in a page")
                }
                let page = allocIOPage()
                allocatedPages.append(page)
                let spIndex = MMIORegion(page)

                #kprintf("xhci: Setting up %d scratch Pad buffers", self.maxScratchPadBuffers)
                for bufferIdx in 0..<self.maxScratchPadBuffers {
                    let page = allocIOPage()
                    allocatedPages.append(page)
                    let scratchPadBuffer = MMIORegion(page)
                    let address = scratchPadBuffer.baseAddress.value
                    spIndex.write(value: address, toByteOffset: bufferIdx * 8)
                    //#kprintf("xhci: Setting up scratch pad buffer %d at %p\n", bufferIdx, address)
                }
                let address = spIndex.baseAddress.value
                self.deviceContextIndex.write(value: address, toByteOffset: 0)
                #kprintf("xhci: Setting up scratch pad index at %p\n", address)
                self.scratchPadIndex = spIndex
            } else {
                self.scratchPadIndex = nil
            }
        }

        deinit {
            for page in allocatedPages {
                freeIOPage(page)
            }
        }

        private func getPage() -> PhysPageAlignedRegion {
            let page = allocIOPage()
            allocatedPages.append(page)
            return page
        }

        // FIXME: grim!
        func allocPhysBuffer(length: Int) -> MMIOSubRegion {
            precondition(length <= 4096)
            let page = getPage()
            return MMIORegion(page).mmioSubRegion(offset: 0, count: length)
        }

        func freePhysBuffer(_ region: MMIOSubRegion) {
            // FIXME: free the above allocated buffer
        }


        // Input Device Context, one per device, read from by xHC
        func allocInputDeviceContect() -> MMIORegion {
            // Size is 33 * contextSize. Use a page for now
            let context = MMIORegion(getPage())
            return context
        }

        // Output Device Context, multiple per device, written to by xHC
        func allocDeviceContext(forSlot slot: UInt8) -> MMIORegion {
            precondition(slot > 0)
            precondition(slot <= self.maxSlots)
            let deviceContext = MMIORegion(getPage())
            let address = UInt64(deviceContext.baseAddress.value)
            self.deviceContextIndex.write(value: address, toByteOffset: Int(slot) * 8)
            return deviceContext
        }
    }
}
