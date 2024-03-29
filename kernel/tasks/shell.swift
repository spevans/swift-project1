/*
 * kernel/tasks/shell.swift
 *
 * Created by Simon Evans on 28/07/20.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * Simple command line shell - currently not its own task.
 */


protocol ShellCommand {
    var command: String { get }
    var helpText: String { get }
    func runCommand(arguments: [String])
}


private struct HelpCommand: ShellCommand {
    let command = "help"
    let helpText = "Show the available commands"

    func runCommand(arguments: [String]) {
        for (key, command) in commands.sorted(by: { $0.key < $1.key }) {
            let spacing = String(repeating: " ", count: 15 - key.count)
            print(key, spacing, command.helpText)
        }
    }
}

private struct EchoCommand: ShellCommand {
    let command = "echo"
    let helpText = "echos the command arguments"

    func runCommand(arguments: [String]) {
        for arg in arguments {
            print(arg, terminator: " ")
        }
        print("")
    }
}

private struct DateCommand: ShellCommand {
    let command = "date"
    let helpText = "Show current CMOS time and date"

    func runCommand(arguments: [String]) {
        dateTest()
    }
}

private struct ShowCPUCommand: ShellCommand {
    let command = "showcpu"
    let helpText = "Show the CPUID information"

    func runCommand(arguments: [String]) {
        CPU.getInfo()
    }
}

private struct DumpBusCommand: ShellCommand {
    let command = "dumpbus"
    let helpText = "Dump the Device Tree"

    func runCommand(arguments: [String]) {
        system.deviceManager.dumpDeviceTree()
    }
}

private struct DumpPCICommand: ShellCommand {
    let command = "dumppci"
    let helpText = "List the PCI devices"

    func runCommand(arguments: [String]) {
        system.deviceManager.dumpPCIDevices()
    }
}

private struct DumpPNPCommand: ShellCommand {
    let command = "dumppnp"
    let helpText = "List the PNP devices"

    func runCommand(arguments: [String]) {
        system.deviceManager.dumpPNPDevices()
    }
}

private struct DumpDevCommand: ShellCommand {
    let command = "dumpdev"
    let helpText = "Dump the known system devices"

    func runCommand(arguments: [String]) {
        system.deviceManager.dumpDevices()
    }
}

private struct DumpACPICommand: ShellCommand {
    let command = "dumpacpi"
    let helpText = "[node] Dump the ACPI tree from an optional node"

    func runCommand(arguments: [String]) {
        let name = arguments.first ?? "\\"
        guard let node = system.deviceManager.acpiTables.globalObjects.get(name) else {
            print("Error: Cant find node:", name)
            return
        }
        node.walkNode { (path, node) in
            print(path, node)
        }
    }
}

struct DumpMemCommand: ShellCommand {
    let command = "dumpmem"
    let helpText = "Dump memory contents: dumpmem <address> <count>"

    func runCommand(arguments: [String]) {

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
}

struct HPETCommand: ShellCommand {
    let command = "hpet"
    let helpText = "Show HPET configuration"

    func runCommand(arguments: [String]) {
        guard let hpet = system.deviceManager.acpiTables.entry(of: HPET.self) else {
            print("No HPET found")
            return
        }
        hpet.showConfiguration()
    }
}

private struct ShowNodeCommand: ShellCommand {
    let command = "shownode"
    let helpText = "Show an ACPI node"

    func runCommand(arguments: [String]) {
        guard let name = arguments.first else {
            print("Error: missing node")
            return
        }
        guard let node = system.deviceManager.acpiTables.globalObjects.get(name) else {
            print("Error: Cant find node:", name)
            return
        }
        print(String(describing: node))

    }
}

private struct SleepTestCommand: ShellCommand {
    let command = "sleeptest"
    let helpText = "Sleep for a specified number of seconds"

    func runCommand(arguments: [String]) {
        guard let arg = arguments.first, let time = Int(arg) else {
            print("Error: missing sleep interval")
            return
        }
        sleepTest(milliseconds: time * 1000)
    }
}

struct TestsCommand: ShellCommand {
    let command = "tests"
    let helpText = "Run selected commands as tests"

    func runCommand(arguments: [String]) {
        dateTest()
        CPU.getInfo()
        print("dumppci")
        system.deviceManager.dumpPCIDevices()
        print("dumppnp")
        system.deviceManager.dumpPNPDevices()
        print("dumpbus")
        system.deviceManager.dumpDeviceTree()
        print("dumpdev")
        system.deviceManager.dumpDevices()
        UptimeCommand().runCommand(arguments: [])
        sleepTest(milliseconds: 10_000)
    }
}

struct UptimeCommand: ShellCommand {
    let command = "uptime"
    let helpText = "Show time since boot"

    func runCommand(arguments: [String]) {
        let ticks = current_ticks()
        let seconds = ticks / 1000
        var ms = String(ticks % 1000)
        while ms.count < 3 { ms = "0" + ms }
        print("Uptime \(seconds).\(ms)")
    }
}

struct VMXOnCommand: ShellCommand {
    let command = "vmxon"
    let helpText = "Enable VMX"

    func runCommand(arguments: [String]) {
        _ = enableVMX()
    }
}

struct VMXOffCommand: ShellCommand {
    let command = "vmxoff"
    let helpText = "Disable VMX"

    func runCommand(arguments: [String]) {
        disableVMX()
    }
}


struct VMXTestCommand: ShellCommand {
    let command = "vmxtest"
    let helpText = "Test VMX"

    func runCommand(arguments: [String]) {
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
}


private let commands: [String: ShellCommand] = {
    let _commands: [ShellCommand] = [
        HelpCommand(),
        EchoCommand(),
        DateCommand(),
        ShowCPUCommand(),
        DumpBusCommand(),
        DumpPCICommand(),
        DumpPNPCommand(),
        DumpDevCommand(),
        DumpACPICommand(),
        DumpMemCommand(),
        HPETCommand(),
        ShowNodeCommand(),
        SleepTestCommand(),
        TestsCommand(),
        UptimeCommand(),
        VMXOnCommand(),
        VMXOffCommand(),
        VMXTestCommand(),
    ]
    return _commands.reduce(into: [:]) { $0[$1.command] = $1 }
}()


// If a keyboard is present, wait and read from it, looping indefinitely
func commandShell() {
    guard let kbd = system.deviceManager.keyboard else {
        print("commandShell: No keyboard found")
        return
    }

    let tty = TTY.sharedInstance
    print("'help' lists available commands")
    while true {
        let line = tty.readLine(prompt: "> ", keyboard: kbd)
        var parts = line.split(separator: " ")
        if let cmd = parts.first, cmd != "" {
            if cmd == "exit" { break }
            parts.removeFirst()
            if let command = commands[String(cmd)] {
                command.runCommand(arguments: parts.compactMap { String($0) })
            } else {
                print("Unknown command:", String(cmd))
            }
        }
    }
}
