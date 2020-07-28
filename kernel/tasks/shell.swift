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
        if let cmos = system.deviceManager.rtc {
            print(cmos.readTime())
        } else {
            print("Cant find a RTC")
        }
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
            print(path, type(of: node))
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

private struct ShowNodeCommand: ShellCommand {
    let command = "shownode"
    let helpText = "show an ACPI node"

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
        DumpDevCommand(),
        DumpACPICommand(),
        DumpMemCommand(),
        ShowNodeCommand(),
        VMXOnCommand(),
        VMXOffCommand(),
        VMXTestCommand(),
    ]
    return _commands.reduce(into: [:]) { $0[$1.command] = $1 }
}()


// If a keyboard is present, wait and read from it, looping indefinitely
func commandShell() {
    guard let kbd = system.deviceManager.keyboard else {
        print("No keyboard found")
        return
    }

    let tty = TTY.sharedInstance
    print("'help' lists available commands")
    while true {
        let line = tty.readLine(prompt: "> ", keyboard: kbd)
        var parts = line.split(separator: " ")
        if let cmd = parts.first, cmd != "" {
            parts.removeFirst()
            if let command = commands[String(cmd)] {
                command.runCommand(arguments: parts.compactMap { String($0) })
            } else {
                print("Unknown command:", String(cmd))
            }
        }
    }
}

