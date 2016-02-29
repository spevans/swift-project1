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
    TTY.initTTY(BootParams.frameBufferInfo)
    printf("Highest Address: %p kernel phys address: %p\n",
        BootParams.highestMemoryAddress, BootParams.kernelAddress)
    setupGDT()
    setupIDT()
    CPU.getInfo()
    setupMM()
    ACPI.parse()
    initialiseDevices()
    print("Hello world")

    enableIRQs()
    // Idle, woken up by interrupts
    while true {
        hlt()
        queuedIRQsTask()
    }

}


private func initialiseDevices() {
    // Set the timer interrupt for 8000Hz
    PIT8254.setChannel(PIT8254.TimerChannel.CHANNEL_0, mode: PIT8254.OperatingMode.MODE_3, hz: 8000)
    PIT8254.showStatus()
    PCI.scan()
}


public func printSections() {
    let text_start = UnsafePointer<Void>(bitPattern: _text_start_addr())
    let text_end = UnsafePointer<Void>(bitPattern: _text_end_addr())
    let data_start = UnsafePointer<Void>(bitPattern: _data_start_addr())
    let data_end = UnsafePointer<Void>(bitPattern: _data_end_addr())
    let bss_start = UnsafePointer<Void>(bitPattern: _bss_start_addr())
    let bss_end = UnsafePointer<Void>(bitPattern: _bss_end_addr())

    TTY.printString("_text_start: \(text_start)\n")
    TTY.printString("_text_end:   \(text_end)\n")
    TTY.printString("_data_start: \(data_start)\n")
    TTY.printString("_data_end:   \(data_end)\n")
    TTY.printString("_bss_start:  \(bss_start)\n")
    TTY.printString("_bss_end:    \(bss_end)\n")
}
