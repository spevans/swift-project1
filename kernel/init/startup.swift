/*
 * kernel/init/startup.swift
 *
 * Created by Simon Evans on 12/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Simple test hello world 
 *
 */


public func startup() {
    TTY.initTTY()
    setupGDT()
    setupIDT()
    //printSections()
    let params = BootParams()
    params.print()
    PCI.scanPCI()
    print("Hello world")
    hlt()
}


func printSections() {
    let text_start = UnsafePointer<CChar>(_text_start_addr)
    let text_end = UnsafePointer<CChar>(_text_end_addr)
    let data_start = UnsafePointer<CChar>(_data_start_addr)
    let data_end = UnsafePointer<CChar>(_data_end_addr)
    let bss_start = UnsafePointer<CChar>(_bss_start_addr)
    let bss_end = UnsafePointer<CChar>(_bss_end_addr)

    TTY.printString("_text_start: \(text_start)\n")
    TTY.printString("_text_end:   \(text_end)\n")
    TTY.printString("_data_start: \(data_start)\n")
    TTY.printString("_data_end:   \(data_end)\n")
    TTY.printString("_bss_start:  \(bss_start)\n")
    TTY.printString("_bss_end:    \(bss_end)\n")
}
