/*
 * kernel/init/startup.swift
 *
 * Created by Simon Evans on 12/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Simple test hello world
 *
 */


@_silgen_name("startup")
public func startup(bootParams: UInt) {
    printf("bootParams: %p\n", bootParams)
    // BootParams must come first to get framebuffer and kernel address
    BootParams.parse(bootParams)
    TTY.sharedInstance.setTTY(frameBufferInfo: BootParams.frameBufferInfo)
    printf("Highest Address: %p kernel phys address: %p\n",
        BootParams.highestMemoryAddress, BootParams.kernelAddress)
    setupGDT()
    setupIDT()
    CPU.getInfo()
    setupMM()
    BootParams.findTables()
    initialiseDevices()
    print("Hello world")

    TTY.sharedInstance.scrollTimingTest()
    _ = addTask(task: mainLoop)
    runTasks()
    run_first_task()
    koops("Shouldnt get here")
}


private func mainLoop() {
    enableIRQs()
    // Idle, woken up by interrupts
    while true {
        hlt()
        queuedIRQsTask()
        yield()
    }
}


private let timer = PIT8254.sharedInstance
private func initialiseDevices() {
    // Set the timer interrupt for 200Hz
    timer.setChannel(.CHANNEL_0, mode: .MODE_3, hz: 20)
    print(timer)
    KBD8042.initKbd()
    PCI.scan()
}


func benchmark(_ function: () -> ()) -> UInt64 {
    let t0 = rdtsc()
    function()
    return rdtsc() - t0
}


public func printSections() {
    let text_start = _text_start_ptr()
    let text_end = _text_end_ptr()
    let data_start = _data_start_ptr()
    let data_end = _data_end_ptr()
    let bss_start = _bss_start_ptr()
    let bss_end = _bss_end_ptr()

    print("_text_start: \(text_start)")
    print("_text_end:   \(text_end)")
    print("_data_start: \(data_start)")
    print("_data_end:   \(data_end)")
    print("_bss_start:  \(bss_start)")
    print("_bss_end:    \(bss_end)")
}
