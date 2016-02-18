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
public func startup(bootParams: UInt, frameBufferInfo: UInt) {
    printf("bootParams: %p frameBufferInfo: %p\n", bootParams, frameBufferInfo)
    BootParams.parse(bootParams)
    printf("Highest Address: %p\n", BootParams.highestMemoryAddress())
    TTY.initTTY(frameBufferInfo)
    CPU.getInfo()
    setupGDT()
    setupIDT()
    if (BootParams.source == "EFI") {
        stop()
    }
    setupMM()
    ACPI.parse()
    PCI.scan()

    printSections()
    print("Hello world")

    // Idle, woken up by interrupts
    while true {
        hlt()
    }

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
