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
public func startup(bootParamsAddr: UInt) {
    system = System(bootParamsAddr: bootParamsAddr)
    system.initSystem()
    system.runSystem()
    koops("kernel: Shouldnt get here")
}


final class System {
    let systemTables: SystemTables
    let deviceManager: DeviceManager
    let bootParams: BootParams

    init(bootParamsAddr: RawAddress) {
        // Setup GDT/IDT as early as possible to help catch CPU exceptions
        setupGDT()
        setupIDT()
        CPU.getInfo()
        // BootParams must come first to find memory regions for MM
        bootParams = parse(bootParamsAddr: VirtualAddress(bootParamsAddr))
        setupMM(bootParams: bootParams)

        // SystemTables() needs the MM setup so that the memory can be mapped
        systemTables = SystemTables(bootParams: bootParams)
        let freeMemoryRanges = bootParams.memoryRanges.filter {
            $0.type == MemoryType.Conventional
        }
        addPagesToFreePageList(freeMemoryRanges)
        // symbolLookupInit uses a sort() so may require more free memory, do it after all the free
        // RAM has been added to the free list.
        symbolLookupInit(bootParams: bootParams)
        deviceManager = DeviceManager(acpiTables: systemTables.acpiTables)
    }

    fileprivate func initSystem() {
        CPU.getInfo()
        TTY.sharedInstance.setTTY(frameBufferInfo: bootParams.frameBufferInfo)
        deviceManager.initialiseDevices()

        // gitBuildVersion defined in kernel/init/version.swift, created
        // by kernel/Makefile
        print("Version: \(gitBuildVersion)\n")
    }


    fileprivate func runSystem() {
        _ = addTask(name: "IRQ Queue runner", task: mainLoop)
        _ = addTask(name: "KeyboardInput", task: keyboardInput)
        run_first_task()
    }
}


func benchmark(_ function: () -> ()) -> UInt64 {
    let t0 = rdtsc()
    function()
    return rdtsc() - t0
}


fileprivate func mainLoop() {
    let interruptManager = system.deviceManager.interruptManager
    // Idle, woken up by interrupts
    interruptManager.enableIRQs()
    while true {
        hlt()
        interruptManager.queuedIRQsTask()
        yield()
    }
}


fileprivate func keyboardInput() {
    // Try reading from the keyboard otherwise just pause forever
    // (used for testing on macbook where there is no PS/2 keyboard)

    commandShell()
    print("No keyboard!")

    while true {
        hlt()
    }
}
