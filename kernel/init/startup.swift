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
    setupGDT()
    setupIDT()
    CPU.getInfo()
    setupMM()
    TTY.sharedInstance.setTTY(frameBufferInfo: BootParams.frameBufferInfo)
    printf("Highest Address: %p kernel phys address: %p\n",
        BootParams.highestMemoryAddress, BootParams.kernelAddress)
    BootParams.findTables()
    printSections()
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


func printSections() {
    print("_text_start:", asHex(_text_start_addr()))
    print("_text_end:  ", asHex(_text_end_addr()))
    print("_data_start:", asHex(_data_start_addr()))
    print("_data_end:  ", asHex(_data_end_addr()))
    print("_bss_start: ", asHex(_bss_start_addr()))
    print("_bss_end:   ", asHex(_bss_end_addr()))
}
