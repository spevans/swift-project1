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
        // Setup the new page tables and add the free RAM to the free list so that
        // ACPI parsing etc has more memory available.
        setupMM(bootParams: bootParams)

        // SystemTables() needs the MM setup so that the memory can be mapped. This will also parse
        // all of the ACPI tables including the DSDT.
        systemTables = SystemTables(bootParams: bootParams)
        // symbolLookupInit uses a sort() so may require more free memory, do it after all the free
        // RAM has been added to the free list.
        symbolLookupInit(bootParams: bootParams)
        deviceManager = DeviceManager(acpiTables: systemTables.acpiTables)
    }

    fileprivate func initSystem() {
        CPU.getInfo()
        deviceManager.acpiTables.startup()
        deviceManager.initialiseEarlyDevices()

        // gitBuildVersion defined in kernel/init/version.swift, created
        // by kernel/Makefile
        #kprint("Version: \(gitBuildVersion)\n")
    }


    fileprivate func runSystem() {
        addTask(name: "IRQ Queue runner", task: mainLoop)
        addTask(name: "KeyboardInput", task: keyboardInput)
        run_first_task() // This jumps straight into mainLoop
    }
}


func benchmark(_ function: () -> ()) -> UInt64 {
    let t0 = rdtsc()
    function()
    return rdtsc() - t0
}


fileprivate func mainLoop() {
    #kprint("Runing mainLoop, enabling IRQs")
    system.deviceManager.enableIRQs()
    system.deviceManager.initialiseDevices()

    // Idle, woken up by interrupts
    while true {
        hlt()
        yield()
    }
}


fileprivate func keyboardInput() {
    // Try reading from the keyboard otherwise just pause forever
    // (used for testing on macbook where there is no PS/2 keyboard)

    commandShell()
    #kprint("commandShell exited")
    if system.deviceManager.keyboard == nil {
        #kprint("Devices:")
        system.deviceManager.dumpDeviceTree()
    }

    #kprint("HLTing")
    while true {
        hlt()
    }
}
