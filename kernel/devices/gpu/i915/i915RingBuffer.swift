/*
 *  i915RingBuffer.swift
 *  Kernel
 *
 *  Created by Simon Evans on 09/08/2025.
 */


extension I915 {

    func rbReset() {
        #kprint("Ring Buffer reset")
        let prb0Start: UInt32 = mmioRegion.read(fromByteOffset: 0x2038)
        mmioRegion.write(value: prb0Start, toByteOffset: 0x2038)
        mmioRegion.write(value: UInt32(0), toByteOffset: 0x2030)
        mmioRegion.write(value: UInt32(0), toByteOffset: 0x2034)
    }


    func rbInfo() {
        #kprint("Ring Buffer")
        let prb0Start: UInt32 = mmioRegion.read(fromByteOffset: 0x2038)
        #kprintf("PRB0_Start: 0x%8.8x address: 0x%8.8x\n", prb0Start, prb0Start & 0xffff_f000)

        let prb0Head: UInt32 = mmioRegion.read(fromByteOffset: 0x2034)
        #kprintf("PRB0_HEAD: 0x%8.8x  wrapCount: %u  headOffset: %u wait: %s\n",
                 prb0Head, prb0Head >> 21, prb0Head & 0x3_ffff, prb0Head & 1 == 1)

        let prb0Tail: UInt32 = mmioRegion.read(fromByteOffset: 0x2030)
        #kprintf("PRB0_TAIL: 0x%8.8x  offset: %u\n", prb0Tail, prb0Tail)

        let prb0Ctl: UInt32 = mmioRegion.read(fromByteOffset: 0x203c)
        let rbPageCount = ((prb0Ctl >> 12) & 0x1ff) + 1
        #kprintf("PRB0_CTL: 0x%8.8x  bufferLength: %u 4kpages, rbWait: %s auto report HP: %u RB enabled: %s\n",
                 prb0Ctl, rbPageCount, prb0Ctl.bit(11), (prb0Ctl >> 1) & 0b11, prb0Ctl & 1 == 1)

        let prb0UHPTR: UInt32 = mmioRegion.read(fromByteOffset: 0x2134)
        #kprintf("PRB0_UHPTR: 0x%8.8x, HP address: 0x%x HP Valid: %s\n", prb0UHPTR, prb0UHPTR >> 3, prb0UHPTR & 1 == 1)

        let rbTail: UInt32 = mmioRegion.read(fromByteOffset: 0x2030)
        #kprintf("PRB0_TAIL: 0x%8.8x  offset: %x\n", rbTail, rbTail)
    }

    func writeToRingBuffer(_ commands: Span<UInt32>) {

        let prb0Ctl: UInt32 = mmioRegion.read(fromByteOffset: 0x203c)
        let rbPageCount = ((prb0Ctl >> 12) & 0x1ff) + 1
        let rbLength = rbPageCount * 4096
        var rbTail: UInt32 = mmioRegion.read(fromByteOffset: 0x2030)

        let ringBuffer = Int(rbTail)
        if rbDebug {
            #kprintf("Writing to ring buffer @ 0x%x\n", UInt(ringBuffer))
        }
        for idx in 0..<commands.count {
            let command = commands[idx]
            if rbDebug {
                #kprintf("Writing 0x%8.8x to offset %x\n", command, rbTail)
            }
            ringBufferMmioRegion.write(value: command, toByteOffset: Int(rbTail))
            rbTail += 4
            rbTail = rbTail % rbLength
        }

        #if false
        if rbDebug {
            let rbHead: UInt32 = mmioRegion.read(fromByteOffset: 0x2034)
            #kprintf("PRB0_HEAD: 0x%8.8x  wrapCount: %u  ",
                     rbHead, rbHead >> 21)
            let ipier: UInt32 = mmioRegion.read(fromByteOffset: 0x2064)
            let ipehr: UInt32 = mmioRegion.read(fromByteOffset: 0x2068)
            #kprintf("IPIER: 0x%8.8x    IPEHR: 0x%8.8x\n", ipier, ipehr)
        }
        #endif
        mmioRegion.write(value: rbTail, toByteOffset: 0x2030)
        if rbDebug {
            #kprintf("rbTail now: 0x%8.8x\t", rbTail)
            let rbHead: UInt32 = mmioRegion.read(fromByteOffset: 0x2034)
            #kprintf("PRB0_HEAD: 0x%8.8x  wrapCount: %u  ", rbHead, rbHead >> 21)
            let ipier: UInt32 = mmioRegion.read(fromByteOffset: 0x2064)
            let ipehr: UInt32 = mmioRegion.read(fromByteOffset: 0x2068)
            #kprintf("IPIER: 0x%8.8x    IPEHR: 0x%8.8x\n", ipier, ipehr)
        }
    }
}
