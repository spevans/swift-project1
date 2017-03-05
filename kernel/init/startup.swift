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
    printf("kernel: bootParams: %p\n", bootParams)
    // BootParams must come first to get framebuffer and kernel address
    BootParams.parse(bootParams)
    setupGDT()
    setupMM()
    setupIDT()
    CPU.getInfo()
    TTY.sharedInstance.setTTY(frameBufferInfo: BootParams.frameBufferInfo)
    printf("kernel: Highest Address: %p kernel phys address: %p\n",
        BootParams.highestMemoryAddress, BootParams.kernelAddress)
    BootParams.findTables()
    printSections()
    initialiseDevices()
    print("kernel: Hello world")

    TTY.sharedInstance.scrollTimingTest()
    _ = addTask(task: mainLoop)
    _ = addTask(task: keyboardInput)
    run_first_task()
    koops("kernel: Shouldnt get here")
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


private func keyboardInput() {
    guard let kbd = KBD8042.sharedInstance?.keyboardDevice else {
        koops("No keyboard!")
    }

    let tty = TTY.sharedInstance

    print("> ", terminator: "")
    while true {
        while let char = kbd.readKeyboard() {
            if char.isASCII {
                tty.printChar(CChar(truncatingBitPattern: char.value))
            } else {
                print("\(char) is not ASCII\n")
            }
        }
    }
}


private let timer = PIT8254.sharedInstance
private func initialiseDevices() {
    // Set the timer interrupt for 200Hz
    timer.setChannel(.CHANNEL_0, mode: .MODE_3, hz: 20)
    print(timer)
    PCI.scan()
}


func benchmark(_ function: () -> ()) -> UInt64 {
    let t0 = rdtsc()
    function()
    return rdtsc() - t0
}


func printSections() {
    print("kernel: _text_start:   ", asHex(_text_start_addr))
    print("kernel: _text_end:     ", asHex(_text_end_addr))
    print("kernel: _data_start:   ", asHex(_data_start_addr))
    print("kernel: _data_end:     ", asHex(_data_end_addr))
    print("kernel: _bss_start:    ", asHex(_bss_start_addr))
    print("kernel: _bss_end:      ", asHex(_bss_end_addr))
    print("kernel: _kernel_start: ", asHex(_kernel_start_addr))
    print("kernel: _kernel_end:   ", asHex(_kernel_end_addr))
    print("kernel: _guard_page:   ", asHex(_guard_page_addr))
    print("kernel: _stack_start:  ", asHex(_stack_start_addr))
    print("kernel: initial_pml4:  ", asHex(initial_pml4_addr))
}
