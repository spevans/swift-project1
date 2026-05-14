/*
 * kernel/tasks/shell.swift
 *
 * Created by Simon Evans on 28/07/20.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * Simple command line shell - currently not its own task.
 *
 */


private struct ShellCommand {
    let runCommand: ([String]) -> ()
    let helpText: String

    init(_ command: @escaping ([String]) -> Void, _ helpText: String) {
        self.runCommand = command
        self.helpText = helpText
    }
}

private func helpCommand(arguments: [String]) {
    for (key, command) in commands.sorted(by: { $0.key < $1.key }) {
        let spacing = String(repeating: " ", count: 15 - key.count)
        #kprint(key, spacing, command.helpText)
    }
}

private func echoCommand(arguments: [String]) {
    for arg in arguments {
        #kprint(arg) //, terminator: " ")
    }
    #kprint("")
}

private func dateCommand(arguments: [String]) {
    showDateTime()
}


private func showCPUCommand(arguments: [String]) {

    if let command = arguments.first {

        switch command {
            case "cpuid":
                if arguments.count > 1, let leaf = UInt32(arguments[1]) {
                    if let result = CPU.capabilities.cpuidLeaf(leaf) {
                        #kprintf("eax: 0x%8.8x ebx: 0x%8.8x ecx: 0x%8.8x edx: 0x%8.8x\n",
                                 result.regs.eax, result.regs.ebx, result.regs.ecx, result.regs.edx)
                    } else {
                        #kprintf("Leaf 0x%x not supported\n", leaf)
                    }
                } else {
                    #kprint("usage: showcpu cpuid <leaf>")
                }

            case "rdmsr":
                if arguments.count > 1, let msr = UInt32(arguments[1]) {
                    let (lo, hi) = CPU.readMSR(msr)
                    #kprintf("lo: 0x%8.8x 0x%8.8x 0x%16.16x\n", lo, hi,
                             UInt64(lo) | (UInt64(hi) << 32)
                    )
                } else {
                    #kprint("usage: showcpu rdmsr <msr>")
                }

            default:
                #kprintf("Invalid command '%s'\n", command)
        }
        return
    }

    #kprintf("CPU: vendor: %s brand: %s\nCPU: family: %02xh  Model: %02xh  Stepping: %u  Type: %u\n",
             CPU.cpuId.vendorName, CPU.cpuId.processorBrandString,
             UInt32(cpu.displayFamily), UInt32(cpu.displayModel),
             UInt32(cpu.stepping), UInt32(cpu.processorType))
    #kprint("CPU: Microarchitecture:", cpu.microarchitecture.description,
            cpu.microarchitecture.isPerformanceHybrid ? "(Performance Hybrid)" : "")
    #kprintf("CPU: Frequencies base: %uMHz cpu: %uMHz tsc: %uMHz crystal: %uMHz\n",
             cpu.baseFrequency / 1_000_000, cpu.cpuFrequency / 1_000_000,
             cpu.tscFrequency / 1_000_000, cpu.crystalFrequency / 1_000_000)
    #kprintf("CPUID: maxBasicInput: 0x%x\t maxExtInput: 0x%8.8x\n",
             CPU.cpuId.maxBasicInput, CPU.cpuId.maxExtendedInput)

    if let ts = TimesourceTSC() {
        #kprint("CPU: Timesource:", ts.description)
    } else {
        #kprint("CPU: No timesource")
    }
    if APIC.calibratedFrequency > 0 {
        #kprintf("APIC calibrated frequency: %u %u.%3.3uMhz\n",
                 APIC.calibratedFrequency,
                 APIC.calibratedFrequency / 1_000_000,
                 APIC.calibratedFrequency % 1_000_000)
    }
}

private func dumpPCICommand(arguments: [String]) {
    system.deviceManager.dumpPCIDevices()
}

private func dumpPNPCommand(arguments: [String]) {
    system.deviceManager.dumpPNPDevices()
}

private func dumpUSBCommand(arguments: [String]) {
    system.deviceManager.dumpUSBDevices()
}

private func dumpDevCommand(arguments: [String]) {
    system.deviceManager.dumpDeviceTree()
}

private func dumpACPICommand(arguments: [String]) {
    let name = arguments.first ?? "\\"
    guard let node = ACPI.globalObjects.getObject(name) else {
        #kprint("Error: Cant find node:", name)
        return
    }
    node.walkNode { (path, node) in
        #kprint(path, node)
        return true // walk children
    }
}

private func dumpMemCommand(arguments: [String]) {
    guard arguments.count == 2,
          let address = arguments[0].parseUInt(),
          let count = arguments[1].parseUInt() else {
            #kprint("Error: dumpmem <address> <count>")
            return
    }
    #kprint("dumpmem 0x\(String(address, radix:16)), \(count)")
    let buffer = UnsafeRawBufferPointer(start: PhysAddress(address).rawPointer, count: Int(count))
    hexDump(buffer: buffer, offset:address)
}

private func timerCommand(arguments: [String]) {
    TimerCore.walkTimers() { timer in
        #kprint(timer)
        return true
    }
}


private func showDevCommand(arguments: [String]) {
    guard let devname = arguments.first else {
        #kprint("Error: missing device name")
        return
    }
    guard let device = system.deviceManager.getDeviceByName(devname) else {
        #kprint("Error: No such device:", devname)
        return
    }
    #kprint("Device:       ", device.deviceName)
    #kprint("Parent Device:", device.parent?.deviceName ?? "none")
    #kprint("Class:        ", device.className)
    #kprint("isBus:        ", device.isBus)
    #kprint("enabled:      ", device.enabled)
    if let pnpDevice = device as? PNPDevice {
        #kprint("\tACPI Node:", pnpDevice.acpiName())
    }
    #kprintf("\t%s\n", device.info())
    if let driver = device.deviceDriver {
        #kprint("\nDriver:", driver.description)
        #kprint("instance:", driver.instanceName)
        #kprintf("\t%s\n", driver.info())
    } else {
        #kprint("\nDriver: none")
    }
}

private func showNodeCommand(arguments: [String]) {
    guard let name = arguments.first else {
        #kprint("Error: missing node")
        return
    }
    guard let node = ACPI.globalObjects.getObject(name) else {
        #kprint("Error: Cant find node:", name)
        return
    }
    #kprint(node.description)
}

private func sleepTestCommand(arguments: [String]) {
    guard let arg = arguments.first, let time = Int(arg) else {
        #kprint("Error: missing sleep interval")
        return
    }
    sleepTest(milliseconds: time * 1000)
}

private func testsCommand(arguments: [String]) {
    showDateTime()
    showCPUCommand(arguments: [])
    #kprint("dumppci")
    system.deviceManager.dumpPCIDevices()
    #kprint("dumppnp")
    system.deviceManager.dumpPNPDevices()
    #kprint("dumpbus")
    system.deviceManager.dumpDeviceTree()
    #kprint("dumpdev")
    system.deviceManager.dumpDeviceTree()
    uptimeCommand(arguments: [])
    sleepTest(milliseconds: 10_000)
}

private func uptimeCommand(arguments: [String]) {
    let ticks = currentTicks()
    #kprintf("Uptime %u.%0.3u\n", ticks / TICKS_PER_SECOND, ticks % TICKS_PER_SECOND)
}

private func vmxOnCommand(arguments: [String]) {
    _ = enableVMX()
}

private func vmxOffCommand(arguments: [String]) {
    disableVMX()
}

private func vmxTestCommand(arguments: [String]) {
    #kprint("enabling vmx")
    _ = enableVMX()
    #kprint("testVMX")
    let result = testVMX()
    switch result {
    case .success(let vmexitReason):
        #kprint("testVMX() success:", vmexitReason)

    case .failure(let vmxError):
        #kprint("textVMX() error:", vmxError)
    }
    disableVMX()
}

private func hidInput(arguments: [String]) {
    let keyboard = system.deviceManager.keyboard
    if keyboard != nil  {
        #kprint("Have keyboard")
    }

    let mouse = system.deviceManager.mouse
    if mouse != nil {
        #kprint("Have mouse")
        mouse?.flushInput()
    }
    if mouse == nil && keyboard == nil {
        #kprint("no mouse or keyboard")
        return
    }
    while true {
        if let event = keyboard?.readHidEvent() ?? mouse?.readHidEvent() {
            switch event {
                case .keyDown(let key):
                    #kprint("Key down:", key.description)
                case .keyUp(let key):
                    #kprint("Key up:", key.description)
                case .buttonDown(let button):
                    #kprint("Button down:", button.description)
                case .buttonUp(let button):
                    #kprint("Button up:", button.description)
                case .xAxisMovement(let value):
                    #kprintf("X-Axis: %d\n", value)
                case .yAxisMovement(let value):
                    #kprintf("Y-Axis: %d\n", value)
                case .zAxisMovement(let value):
                    #kprintf("Z-Axis: %d\n", value)
            }
            if case .keyUp(.KEY_ESCAPE) = event { return }
        } else {
            sleep(milliseconds: 10)
        }
    }
}

private func deviceDebug(arguments: [String]) {
    guard let deviceName = arguments.first else {
        #kprint("Error: Missing device name")
        return
    }
    guard let device = system.deviceManager.getDeviceByName(deviceName) else {
        #kprintf("Failed to find device '%s'\n", deviceName)
        return
    }
    guard let driver = device.deviceDriver else {
        #kprintf("Device '%s' has no device driver\n", deviceName)
        return
    }
    driver.debug(arguments: Array(arguments[1...]))
}

private func showMCFG(arguments: [String]) {
    if let mcfg = ACPI.mcfg {
        mcfg.showEntries()
    } else {
        #kprint("No MCFG table found")
    }
}


private let commands: [String: ShellCommand] = [
    "help":     ShellCommand(helpCommand, "Show the available commands"),
    "echo":     ShellCommand(echoCommand, "echos the command arguments"),
    "date":     ShellCommand(dateCommand, "Show current CMOS time and date"),
    "showcpu":  ShellCommand(showCPUCommand, "Show the CPUID information"),
    "dumpdev":  ShellCommand(dumpDevCommand, "Dump the known system devices"),
    "dumpacpi": ShellCommand(dumpACPICommand, "[node] Dump the ACPI tree from an optional node"),
    "dumppci":  ShellCommand(dumpPCICommand, "List the PCI devices"),
    "dumppnp":  ShellCommand(dumpPNPCommand, "List the PNP devices"),
    "dumpusb":  ShellCommand(dumpUSBCommand, "List the USB devices"),
    "dumpmem":  ShellCommand(dumpMemCommand, "Dump memory contents: dumpmem <address> <count>"),
    "timer":    ShellCommand(timerCommand, "Show Timer configuration"),
    "showdev":  ShellCommand(showDevCommand, "Show device information, showdev <device>"),
    "shownode": ShellCommand(showNodeCommand, "Show an ACPI node"),
    "sleep":    ShellCommand(sleepTestCommand, "Sleep for a specified number of seconds"),
    "tests":    ShellCommand(testsCommand, "Run selected commands as tests"),
    "uptime":   ShellCommand(uptimeCommand, "Show time since boot"),
    "vmxon":    ShellCommand(vmxOnCommand, "Enable VMX"),
    "vmxoff":   ShellCommand(vmxOffCommand, "Disable VMX"),
    "vmxtest":  ShellCommand(vmxTestCommand, "Test VMX"),
    "hidinput": ShellCommand(hidInput, "Test HID input"),
    "cls"     : ShellCommand({ _ in tty.clearScreen() }, "Clear the screen"),
    "device":   ShellCommand(deviceDebug, "Debug Device"),
    "i915":     ShellCommand(testi915, "Test an i915 display"),
    "memory":   ShellCommand({ _ in system.showMemoryRanges() }, "Show memory ranges"),
    "mcfg":     ShellCommand(showMCFG, "Show ACPI MCFG table"),
    "tty":      ShellCommand({ args in tty.commands(args) }, "Show TTY information"),
    "version":  ShellCommand({ args in #kprint("Version:", gitBuildVersion) }, "Show build version"),
    "reboot":   ShellCommand({ _ in ACPI.reboot() }, "Reboot the system via ACPI"),
    "shutdown": ShellCommand({ _ in ACPI.shutdown() }, "Shut down the system via ACPI"),
]


// If a keyboard is present, wait and read from it, looping indefinitely
func commandShell() {
    guard let kbd = system.deviceManager.keyboard else {
        #kprint("commandShell: No keyboard found")
        return
    }

    #kprint("'help' lists available commands")
    while true {
        let line = readLine(prompt: "> ", keyboard: kbd)
        var parts = line.split(separator: " ")
        if let cmd = parts.first, cmd != "" {
            if cmd == "exit" { break }
            parts.removeFirst()
            if let command = commands[String(cmd)] {
                command.runCommand(parts.compactMap { String($0) })
            } else {
                #kprint("Unknown command:", String(cmd))
            }
        }
    }
}
