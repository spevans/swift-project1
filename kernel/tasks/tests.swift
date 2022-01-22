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
    print("cacheTest buffer:", buffer)
    if buffer.baseAddress.value < 0x100000 || buffer.endAddress.value > 0x1000000 {
        fatalError("Cache test page not in correct region")
    }
    let start = UnsafeMutablePointer<UInt8>(bitPattern: buffer.vaddr)
    let count = buffer.size
    printf("Testing default\n")
    for _ in 1...3 {
        let read = _cacheReadTest(start, UInt64(count), nil)
        let write = _cacheWriteTest(start, UInt64(count), 1)
        printf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    printf("Testing uncacheable\n")
    _ = remapAsIORegion(region: buffer, cacheType: .uncacheable)
    for _ in 1...3 {
        let read = _cacheReadTest(start, UInt64(count), nil)
        let write = _cacheWriteTest(start, UInt64(count), 1)
        printf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    printf("Testing writeBack\n")
    _ = remapAsIORegion(region: buffer, cacheType: .writeBack)
    for _ in 1...3 {
        let read = _cacheReadTest(start, UInt64(count), nil)
        let write = _cacheWriteTest(start, UInt64(count), 1)
        printf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    printf("Testing writeThrough\n")
    _ = remapAsIORegion(region: buffer, cacheType: .writeThrough)
    for _ in 1...3 {
        let read = _cacheReadTest(start, UInt64(count), nil)
        let write = _cacheWriteTest(start, UInt64(count), 1)
        printf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    printf("Testing writeCombining\n")
    _ = remapAsIORegion(region: buffer, cacheType: .writeCombining)
    for _ in 1...3 {
        let read = _cacheReadTest(start, UInt64(count), nil)
        let write = _cacheWriteTest(start, UInt64(count), 1)
        printf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    _ = remapAsIORegion(region: buffer, cacheType: .writeBack)
    freePages(pages: buffer)

    let ioBuffer = allocIOPage()
    let ioStart = UnsafeMutablePointer<UInt8>(bitPattern: ioBuffer.vaddr)
    let ioCount = ioBuffer.size
    printf("Testing IO Page\n")
    for _ in 1...3 {
        let read = _cacheReadTest(ioStart, UInt64(ioCount), nil)
        let write = _cacheWriteTest(ioStart, UInt64(ioCount), 1)
        printf("Timing to read buffer: %lu write: %lu\n", read, write)
    }
    freeIOPage(ioBuffer)
}

func sleepTest(milliseconds: Int) {
    // sleepTest
    if let cmos = system.deviceManager.rtc {
        print(milliseconds, "ms sleep test")
        print(cmos.readTime())
        sleep(milliseconds: milliseconds)
        print(cmos.readTime())
    }
}

func dateTest() {
    if let cmos = system.deviceManager.rtc {
        print(cmos.readTime())
    } else {
        print("Cant find a RTC")
    }
}
