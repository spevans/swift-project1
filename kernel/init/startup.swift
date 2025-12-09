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

// This is global as it is needed when creating elements in System
// TODO: Should System exist or should the members just be globals?
private var memoryRanges: [MemoryRange]! = nil

@_cdecl("startup")
public func startup(bootParamsAddr: UInt) {
    system = System(bootParamsAddr: bootParamsAddr)
    system.initSystem()
    system.runSystem()
    koops("kernel: Shouldnt get here")
}


final class System {
    let systemTables: SystemTables
    let deviceManager: DeviceManager
    let frameBufferInfo: FrameBufferInfo?


    init(bootParamsAddr: RawAddress) {
        // Setup GDT/IDT as early as possible to help catch CPU exceptions
        setupGDT()
        setupIDT()
        CPU.getInfo()
        // BootParams must come first to find memory regions for MM
        let bootParams = parse(bootParamsAddr: VirtualAddress(bootParamsAddr))
        frameBufferInfo = bootParams.frameBufferInfo
        memoryRanges = bootParams.memoryRanges

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
        run_first_task() // This jumps straight into mainLoop
    }

    func showMemoryRanges() {
        for range in memoryRanges {
            #kprint(range)
        }
    }
}

func findMemoryRangeContaining(physAddress: PhysAddress) -> MemoryRange? {
    return memoryRanges.findRange(containing: physAddress)
}

// TODO: need to check for overlaps (especially with holes) and decide
// what to do. This is especially try for MMIO regions added as devices
// are found
func addMemoryRange(_ range: MemoryRange) {
    memoryRanges.insertRange(range)
}


func benchmark(_ function: () -> ()) -> UInt64 {
    return noInterrupt {
        let t0 = rdtsc()
        function()
        return rdtsc() - t0
    }
}


fileprivate func mainLoop() {
    #kprint("TASK: mainLoop task started")
    system.deviceManager.enableIRQs()
    system.deviceManager.initialiseDevices()

    let now = current_ticks()
    #kprintf("Total boot time: %d.%2ds\n", now / 1000, now % 1000)
    addTask(name: "KeyboardInput", task: keyboardInput)

    // Idle, woken up by interrupts
    while true {
        hlt()
    }
}


fileprivate func keyboardInput() {
    // Try reading from the keyboard otherwise just pause forever
    // (used for testing on macbook where there is no PS/2 keyboard)

    #kprint("TASK: keyboardInput task started")
    commandShell()
    #kprint("commandShell exited")

#if false
    if system.deviceManager.keyboard == nil {
        #kprint("Devices:")
        system.deviceManager.dumpDeviceTree()
    }
#endif

    #kprint("HLTing")
    while true {
        hlt()
    }
}
