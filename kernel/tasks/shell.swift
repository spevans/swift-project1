/*
 * kernel/tasks/shell.swift
 *
 * Created by Simon Evans on 28/07/20.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * Simple command line shell - currently not its own task.
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
        print(key, spacing, command.helpText)
    }
}

private func echoCommand(arguments: [String]) {
    for arg in arguments {
        print(arg, terminator: " ")
    }
    print("")
}

private func dateCommand(arguments: [String]) {
    dateTest()
}

private func showCPUCommand(arguments: [String]) {
    CPU.getInfo()
}

private func dumpBusCommand(arguments: [String]) {
    system.deviceManager.dumpDeviceTree()
}

private func dumpPCICommand(arguments: [String]) {
    system.deviceManager.dumpPCIDevices()
}

private func dumpPNPCommand(arguments: [String]) {
    system.deviceManager.dumpPNPDevices()
}

private func dumpDevCommand(arguments: [String]) {
    system.deviceManager.dumpDeviceTree()
}

private func dumpACPICommand(arguments: [String]) {
    let name = arguments.first ?? "\\"
    guard let node = ACPI.globalObjects.getObject(name) else {
        print("Error: Cant find node:", name)
        return
    }
    node.walkNode { (path, node) in
        print(path, node)
        return true // walk children
    }
}

private func dumpMemCommand(arguments: [String]) {
    guard arguments.count == 2,
          let address = arguments[0].parseUInt(),
          let count = arguments[1].parseUInt() else {
        print("Error: dumpmem <address> <count>")
        return
    }
    print("dumpmem 0x\(String(address, radix:16)), \(count)")
    let buffer = UnsafeRawBufferPointer(start: PhysAddress(address).rawPointer, count: Int(count))
    hexDump(buffer: buffer, offset:address)
}

private func timerCommand(arguments: [String]) {
    guard let timer = system.deviceManager.timer else {
        print("No timer found")
        return
    }
    print(timer)
}

private func showNodeCommand(arguments: [String]) {
    guard let name = arguments.first else {
        print("Error: missing node")
        return
    }
    guard let node = ACPI.globalObjects.getObject(name) else {
        print("Error: Cant find node:", name)
        return
    }
    print(node.description)
}

private func sleepTestCommand(arguments: [String]) {
    guard let arg = arguments.first, let time = Int(arg) else {
        print("Error: missing sleep interval")
        return
    }
    sleepTest(milliseconds: time * 1000)
}

private func testsCommand(arguments: [String]) {
    dateTest()
    CPU.getInfo()
    print("dumppci")
    system.deviceManager.dumpPCIDevices()
    print("dumppnp")
    system.deviceManager.dumpPNPDevices()
    print("dumpbus")
    system.deviceManager.dumpDeviceTree()
    print("dumpdev")
    system.deviceManager.dumpDeviceTree()
    uptimeCommand(arguments: [])
    sleepTest(milliseconds: 10_000)
}

private func uptimeCommand(arguments: [String]) {
    let ticks = current_ticks()
    let seconds = ticks / 1000
    var ms = String(ticks % 1000)
    while ms.count < 3 { ms = "0" + ms }
    print("Uptime \(seconds).\(ms)")
}

private func vmxOnCommand(arguments: [String]) {
    _ = enableVMX()
}

private func vmxOffCommand(arguments: [String]) {
    disableVMX()
}

private func vmxTestCommand(arguments: [String]) {
    print("enabling vmx")
    _ = enableVMX()
    print("testVMX")
    let result = testVMX()
    switch result {
    case .success(let vmexitReason):
        print("testVMX() success:", vmexitReason)

    case .failure(let vmxError):
        print("textVMX() error:", vmxError)
    }
    disableVMX()
}

private let commands: [String: ShellCommand] = [
    "help":     ShellCommand(helpCommand, "Show the available commands"),
    "echo":     ShellCommand(echoCommand, "echos the command arguments"),
    "date":     ShellCommand(dateCommand, "Show current CMOS time and date"),
    "showcpu":  ShellCommand(showCPUCommand, "Show the CPUID information"),
    "dumpbus":  ShellCommand(dumpBusCommand, "Dump the Device Tree"),
    "dumppci":  ShellCommand(dumpPCICommand, "List the PCI devices"),
    "dumppnp":  ShellCommand(dumpPNPCommand, "List the PNP devices"),
    "dumpdev":  ShellCommand(dumpDevCommand, "Dump the known system devices"),
    "dumpacpi": ShellCommand(dumpACPICommand, "[node] Dump the ACPI tree from an optional node"),
    "dumpmem":  ShellCommand(dumpMemCommand, "Dump memory contents: dumpmem <address> <count>"),
    "timer":    ShellCommand(timerCommand, "Show Timer configuration"),
    "shownode": ShellCommand(showNodeCommand, "Show an ACPI node"),
    "sleep":    ShellCommand(sleepTestCommand, "Sleep for a specified number of seconds"),
    "tests":    ShellCommand(testsCommand, "Run selected commands as tests"),
    "uptime":   ShellCommand(uptimeCommand, "Show time since boot"),
    "vmxon":    ShellCommand(vmxOnCommand, "Enable VMX"),
    "vmxoff":   ShellCommand(vmxOffCommand, "Disable VMX"),
    "vmxtest":  ShellCommand(vmxTestCommand, "Test VMX"),
]


// If a keyboard is present, wait and read from it, looping indefinitely
func commandShell() {
    guard let kbd = system.deviceManager.keyboard else {
        print("commandShell: No keyboard found")
        return
    }

    print("'help' lists available commands")
    while true {
        let line = readLine(prompt: "> ", keyboard: kbd)
        var parts = line.split(separator: " ")
        if let cmd = parts.first, cmd != "" {
            if cmd == "exit" { break }
            parts.removeFirst()
            if let command = commands[String(cmd)] {
                command.runCommand(parts.compactMap { String($0) })
            } else {
                print("Unknown command:", String(cmd))
            }
        }
    }
}
