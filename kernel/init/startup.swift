/*
 * kernel/init/startup.swift
 *
 * Created by Simon Evans on 12/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Simple test hello world
 *
 */


fileprivate(set) var system: System!

@_silgen_name("startup")
public func startup(bootParams: UInt) {
    system = System(bootParams: bootParams)
    system.runSystem()
    koops("kernel: Shouldnt get here")
}


class System {

    private(set) var interruptManager: InterruptManager
    private(set) var timer: PIT8254
    private(set) var kbd8042: KBD8042?


    init(bootParams: UInt) {
        printf("kernel: bootParams: %p\n", bootParams)
        // BootParams must come first to get framebuffer and kernel address
        BootParams.parse(bootParams)
        setupGDT()
        setupMM()

        // findTables() needs to run after the MM is setup but before the
        // IDT is configured as the interrupts controllers are disabled in
        //setupIDT()
        BootParams.findTables()
        interruptManager = InterruptManager()
        set_interrupt_manager(&interruptManager)
        CPU.getInfo()
        TTY.sharedInstance.setTTY(frameBufferInfo: BootParams.frameBufferInfo)
        printf("kernel: Highest Address: %p kernel phys address: %p\n",
            BootParams.highestMemoryAddress, BootParams.kernelAddress)

        timer = PIT8254(interruptManager: interruptManager)
        initialiseDevices()
        printSections()
    }


    fileprivate func runSystem() {
        _ = addTask(task: mainLoop)
        _ = addTask(task: keyboardInput)
        run_first_task()
    }


    private func initialiseDevices() {
        // Set the timer interrupt for 200Hz
        timer.setChannel(.CHANNEL_0, mode: .MODE_3, hz: 20)
        print(timer)
        PCI.scan()
        kbd8042 = KBD8042(interruptManager: interruptManager)
        TTY.sharedInstance.scrollTimingTest()
    }


    private func printSections() {
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
}


func benchmark(_ function: () -> ()) -> UInt64 {
    let t0 = rdtsc()
    function()
    return rdtsc() - t0
}


fileprivate func mainLoop() {
    let interruptManager = system.interruptManager
    // Idle, woken up by interrupts
    interruptManager.enableIRQs()
    while true {
        hlt()
        interruptManager.queuedIRQsTask()
        yield()
    }
}


fileprivate func keyboardInput() {
    guard let kbd = system.kbd8042?.keyboardDevice else {
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
