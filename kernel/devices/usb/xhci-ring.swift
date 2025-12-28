/*
 *  xhci-ring.swift
 *  Kernel
 *
 *  Created by Simon Evans on 30/08/2025.
 *
 *  ProducerRing and EventRing used by the XHCI driver
 *
 *  ProducerRing is used for the Command Ring and Transfer Rings used to send data to the xHC.
 *  EventRing is used for receiving events from the xHC.
 */

extension HCD_XHCI {

    struct ProducerRing<T: ProducerTRB>: ~Copyable {
        private let trbSize = 16
        private let trbRing: MMIORegion
        private let ringSize: Int
        private let maxSlotIndex: Int
        private var cycle = true
        private var dwordToEnable: (UInt32, Int)? = nil
        private(set) var slotIndex = 0
        var ringBaseAddress: PhysAddress { trbRing.baseAddress }


        init() {
            self.trbRing = MMIORegion(allocIOPage())
            self.ringSize = self.trbRing.regionSize
            self.maxSlotIndex = (self.ringSize / self.trbSize) - 1
        }

        deinit {
            freeIOPage(self.trbRing.physicalRegion)
        }

        // TODO: Shrink the size of the generated code
        @discardableResult
        mutating func addTRB(_ trb: some ProducerTRB, chain: Bool = false, enable: Bool = true) -> PhysAddress {
            let trRingOffset = slotIndex * trbSize

//            #kprintf("xhci-pipe: Adding TRB: 0x%8.8x  0x%8.8x  0x%8.8x  0x%8.8x @ %d %p\n",
//                     trb.dwords[0], trb.dwords[1], trb.dwords[2], trb.dwords[3],
//                     trRingOffset, trbRing.baseAddress + trRingOffset
//            )

            trbRing.write(value: trb.dwords[0], toByteOffset: trRingOffset + 0x0)
            trbRing.write(value: trb.dwords[1], toByteOffset: trRingOffset + 0x4)
            trbRing.write(value: trb.dwords[2], toByteOffset: trRingOffset + 0x8)

            // `enable` flag will set the cycle bit appropiately to enable the TRB
            // immediately or allow it to be enabled later. This is used when adding
            // multiple TRBs into the ring, eg SETUP/DATA/STATUS, and not wanting the
            // first one to be active until all TRBs are present
            let cycleBit = UInt32(self.cycle ? 1 : 0)
            let dword: UInt32
            if enable {
                dword = trb.dwords[3] | cycleBit
            } else {
                self.dwordToEnable = (trb.dwords[3] | cycleBit, trRingOffset + 0xC)
                dword = trb.dwords[3] | cycleBit^1
            }
            trbRing.write(value: dword, toByteOffset: trRingOffset + 0xC)
            slotIndex += 1

            if slotIndex == maxSlotIndex {
                let trRingOffset = slotIndex * trbSize
//                #kprintf("xhci-ring: Wrap around from %d -> 0\n", slotIndex)
                // Last slot, insert a LINK TRB and wrap around, also toggle the cycle bit
                let linkTrb = TransferTRB.link(ringSegmentPointer: trbRing.baseAddress,
                                               interrupter: 0, toggleCycle: true, chain: chain,
                                               interruptOnComplete: false, cycle: self.cycle)
                trbRing.write(value: linkTrb.dwords[0], toByteOffset: trRingOffset + 0x0)
                trbRing.write(value: linkTrb.dwords[1], toByteOffset: trRingOffset + 0x4)
                trbRing.write(value: linkTrb.dwords[2], toByteOffset: trRingOffset + 0x8)
                trbRing.write(value: linkTrb.dwords[3], toByteOffset: trRingOffset + 0xC)
                self.slotIndex = 0
                self.cycle.toggle()
            }
            return trbRing.baseAddress + UInt(trRingOffset)
        }

        // Enable a TRB that was previously added with the `enable` flag `false`
        mutating func enableTRB() {
            guard let (dword, offset) = self.dwordToEnable else {
                fatalError("xhci-ring: Trying to enable TRB with no saved dword")
            }
            //#kprintf("xhci-ring: Updating dword3 @ %d to %8.8x\n", offset, dword)
            self.dwordToEnable = nil
            trbRing.write(value: dword, toByteOffset: offset)
        }

        func ringAddrToIndex(_ address: PhysAddress) -> Int? {
            guard address >= trbRing.baseAddress, // Check address is inside the ring and TRB aligned
                  address <= trbRing.endAddress,
                  address.value & 0xf == 0 else {
                return nil
            }
            return (address - trbRing.baseAddress) / self.trbSize
        }
    }

    struct EventRing: ~Copyable {
        private let interrupter: MMIOSubRegion
        private let segmentTable: MMIORegion
        private let ringSegment: MMIORegion

        private let trbSize = 16
        private let ringSize: Int
        private let maxSlotIndex: Int
        private let nrTRBs: UInt32
        private var cycle = true
        private var unAckedEvents = 0
        private(set) var slotIndex = 0


        init(interrupter: MMIOSubRegion) {
            self.interrupter = interrupter
            self.ringSegment = MMIORegion(allocIOPage())
            self.ringSize = self.ringSegment.regionSize

            // Create RingSegmentTable with 1 entry in
            self.segmentTable = MMIORegion(allocIOPage())

            // 1st entry in RingSegmentTable points to RingSegment
            let ringSegmentAddr = ringSegment.baseAddress.value
            self.segmentTable.write(value: UInt32(truncatingIfNeeded: ringSegmentAddr), toByteOffset: 0x0)
            self.segmentTable.write(value: UInt32(truncatingIfNeeded: ringSegmentAddr >> 32), toByteOffset: 0x4)
            self.nrTRBs = UInt32(self.ringSize / self.trbSize)
            self.maxSlotIndex = Int(self.nrTRBs - 1)
            self.segmentTable.write(value: self.nrTRBs, toByteOffset: 0x8)
            #kprintf("xhci-ring: size: %d nrTRBs: %d maxSlotIndex: %d\n",
                     self.ringSize, self.nrTRBs, self.maxSlotIndex)
        }

        deinit {
            freeIOPage(self.ringSegment.physicalRegion)
        }


        // Used to setup the interrupter runtime registers after the HCD has been reset.
        func setupInterrupter() {
            let ringSegmentAddr = ringSegment.baseAddress.value
            setInterrupter(eventRingTableSize: 1)
            setInterrupter(eventRingDequeuePointer: UInt64(ringSegmentAddr))

            let segmentTableAddr = UInt64(self.segmentTable.baseAddress.value)
            setInterrupter(eventRingTableBaseAddr: segmentTableAddr)
            enableInterrupter(modInterval: 4000, modCounter: 4000)
        }


        mutating func nextTRB() -> EventTRB? {
            let eventRingOffset = self.slotIndex * self.trbSize
            let dword3: UInt32 = ringSegment.read(fromByteOffset: eventRingOffset + 0xC)
            if false {
                #kprintf("xhci-ring: nextEventTRB, ringSegment: %p, slotIndex: %d  cycle: %s currentCycle: %s\n",
                         ringSegment.baseAddress, self.slotIndex, dword3 & 1 == 1, self.cycle)
            }
            guard dword3 & 1 == (self.cycle ? 1 : 0) else {
                return nil
            }
            let dwords: InlineArray<4, UInt32> = [
                ringSegment.read(fromByteOffset: eventRingOffset + 0x0),
                ringSegment.read(fromByteOffset: eventRingOffset + 0x4),
                ringSegment.read(fromByteOffset: eventRingOffset + 0x8),
                dword3
            ]
            if false {
                #kprintf("xhci-event: Found EventTRB @ offset %d\n", eventRingOffset)
            }
            self.slotIndex += 1
            if self.slotIndex > self.maxSlotIndex {
                if XHCIDebug {
                    #kprint("xhci-ring: event ring wrap around")
                }
                self.slotIndex = 0
                self.cycle.toggle()
            }
            unAckedEvents += 1
            if unAckedEvents > self.nrTRBs / 2 {
                // Do not let the number of unacknowleged events in the queue get too high or it will fill up.
                updateDequeuePointer()
            }
            return EventTRB(dwords: dwords)
        }

        mutating func updateDequeuePointer() {
            // Write the ERDP with the address of the last processed Event TRB
            let ringSegmentAddr = UInt64(ringSegment.baseAddress.value)
            let eventRingOffset = self.slotIndex * self.trbSize
            let erdp = ringSegmentAddr + UInt64(eventRingOffset)
            let newErdp = erdp | 8
            if XHCIDebug {
                #kprintf("xhci: eventRingOffset: %d setting event dequeue to %p\n",
                         eventRingOffset, newErdp)
            }
            setInterrupter(eventRingDequeuePointer: newErdp)
            self.unAckedEvents = 0
        }


        func showEventRing(trbIdx: Int) {
            let offset = trbIdx * 16
            let trb = EventTRB(dwords: [
                ringSegment.read(fromByteOffset: offset + 0x0),
                ringSegment.read(fromByteOffset: offset + 0x4),
                ringSegment.read(fromByteOffset: offset + 0x8),
                ringSegment.read(fromByteOffset: offset + 0xC)
            ])
            EventRing.dumpTRB(trb)
        }

        static func dumpTRB(_ trb: EventTRB) {
            #kprint("xhci-event: Found EventTRB:", trb.description)
        }


        private func setInterrupter(eventRingTableSize: UInt32) {
            let offset = 0x8
            interrupter.write(value: eventRingTableSize, toByteOffset: offset)
        }

        private func setInterrupter(eventRingTableBaseAddr: UInt64) {
            let offset = 0x10
            interrupter.write(value: eventRingTableBaseAddr, toByteOffset: offset)
        }

        private func setInterrupter(eventRingDequeuePointer ptr: UInt64) {
            let offset = 0x18
            interrupter.write(value: UInt32(truncatingIfNeeded: ptr), toByteOffset: offset + 0)
            interrupter.write(value: UInt32(truncatingIfNeeded: ptr >> 32), toByteOffset: offset + 4)
        }

        func getEventRingDequeuePointer() -> UInt64 {
            let offset = 0x18
            return interrupter.read(fromByteOffset: offset)
        }

        private func enableInterrupter(modInterval: UInt16, modCounter: UInt16) {
            let imodOffset = 4
            let value = UInt32(modInterval) | (UInt32(modCounter) << 16)
            interrupter.write(value: value, toByteOffset: imodOffset)
            let imanOffset = 0
            var imanValue: UInt32 = interrupter.read(fromByteOffset: imanOffset)
            imanValue |= 3  // set interrupt enable, bit0 is RW1C so will clear pending bit if set
            interrupter.write(value: imanValue, toByteOffset: imanOffset)
        }

        func clearInterrupterPending() {
            let imanOffset = 0
            var value: UInt32 = interrupter.read(fromByteOffset: imanOffset)
            value |= 1  // RW1C
            interrupter.write(value: value, toByteOffset: imanOffset)
        }

        func interrupterPending() -> Bool {
            let imanOffset = 0
            let value: UInt32 = interrupter.read(fromByteOffset: imanOffset)
            if XHCIDebug {
                #kprintf("xhci: interrupterPending -> 0x%8.8x\n", value)
            }
            return value.bit(0)
        }
    }
}
