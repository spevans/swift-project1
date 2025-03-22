/*
 * kernel/init/tests.swift
 *
 * Created by Simon Evans on 30/12/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * Random test routines to test subsystems during boot and intialisation.
 *
 */

public func cacheTest() {
    let buffer = alloc(pages: 1)
    #kprint("cacheTest buffer:", buffer)
    if buffer.baseAddress.value < 0x100000 || buffer.endAddress.value > 0x1000000 {
        fatalError("Cache test page not in correct region")
    }
    let start = UnsafeMutablePointer<UInt8>(bitPattern: buffer.vaddr)
    let count = buffer.size
    #kprint("Testing default")
    for _ in 1...3 {
        let read = _cacheReadTest(start, UInt64(count), nil)
        let write = _cacheWriteTest(start, UInt64(count), 1)
        #kprintf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    #kprint("Testing uncacheable")
    _ = remapAsIORegion(region: buffer, cacheType: .uncacheable)
    for _ in 1...3 {
        let read = _cacheReadTest(start, UInt64(count), nil)
        let write = _cacheWriteTest(start, UInt64(count), 1)
        #kprintf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    #kprint("Testing writeBack")
    _ = remapAsIORegion(region: buffer, cacheType: .writeBack)
    for _ in 1...3 {
        let read = _cacheReadTest(start, UInt64(count), nil)
        let write = _cacheWriteTest(start, UInt64(count), 1)
        #kprintf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    #kprint("Testing writeThrough")
    _ = remapAsIORegion(region: buffer, cacheType: .writeThrough)
    for _ in 1...3 {
        let read = _cacheReadTest(start, UInt64(count), nil)
        let write = _cacheWriteTest(start, UInt64(count), 1)
        #kprintf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    #kprint("Testing writeCombining")
    _ = remapAsIORegion(region: buffer, cacheType: .writeCombining)
    for _ in 1...3 {
        let read = _cacheReadTest(start, UInt64(count), nil)
        let write = _cacheWriteTest(start, UInt64(count), 1)
        #kprintf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    _ = remapAsIORegion(region: buffer, cacheType: .writeBack)
    freePages(pages: buffer)

    let ioBuffer = allocIOPage()
    let ioStart = UnsafeMutablePointer<UInt8>(bitPattern: ioBuffer.vaddr)
    let ioCount = ioBuffer.size
    #kprint("Testing IO Page")
    for _ in 1...3 {
        let read = _cacheReadTest(ioStart, UInt64(ioCount), nil)
        let write = _cacheWriteTest(ioStart, UInt64(ioCount), 1)
        #kprintf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    freeIOPage(ioBuffer)
}

func sleepTest(milliseconds: Int) {
    // sleepTest
    if let cmos = system.deviceManager.rtc {
        #kprint(milliseconds, "ms sleep test")
        #kprint(cmos.readTime())
        sleep(milliseconds: milliseconds)
        #kprint(cmos.readTime())
    }
}

func dateTest() {
    if let cmos = system.deviceManager.rtc {
        #kprint(cmos.readTime())
    } else {
        #kprint("Cant find a RTC")
    }
}
