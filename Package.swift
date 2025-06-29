// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Kernel",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
    ],

    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .macro(
            name: "PrintfMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "macros/Printf/Sources/PrintfMacros"
        ),
        // Build most of the kernel to be used in tests. This stub excludes some files for now
        // until they are made arch independant and can be run in userspace if needed.
        .target(name: "Kernel",
                dependencies: ["PrintfMacros"],
                path: "kernel",
                exclude: ["arch",
                          "init",
                          "devices/acpi",
                          "devices/pci",
                          "devices/usb",
                          "devices/ISABus.swift",
                          "devices/devicemanager.swift",
                          "devices/bus.swift",
                          "devices/driver.swift",
                          "devices/apic.swift",
                          "devices/mtrr.swift",
                          "devices/kbd8042.swift",
                          "devices/cmos.swift",
                          "devices/pic8259.swift",
                          "devices/device.swift",
                          "devices/tty.swift",
                          "devices/pit8254.swift",
                          "devices/PNPDevice.swift",
                          "devices/qemufwcf.swift",
                          "devices/Timer.swift",
                          "tasks/shell.swift",
                          "tasks/tests.swift",
                          "tasks/tasks.swift",
                          "mm/mapping.swift",
                          "mm/init.swift",
                          "mm/alloc.swift",
                          "mm/page.swift",
                          "mm/PageDirectory.swift",
                          "mm/PageDirectoryPointerTable.swift",
                          "mm/PageMapLevel4Table.swift",
                          "mm/symbols.swift",
                          "klib/kprint.swift",
                         ],
                cSettings: [.define("TEST")],
                swiftSettings: [.define("TEST"),
                                .unsafeFlags([
                                    "-Xfrontend", "-disable-availability-checking",
                                    "-import-objc-header", "include/kernel.h",
                                    "-disable-bridging-pch" // The .pch file doesnt seem valid so disable it for now
                                ]),
                ],
        ),
        // Note that some tests are excluded because getting the ACPI to compile currently causes a compiler crash.
        .testTarget(
            name: "KernelTests",
            dependencies: [ "PrintfMacros", "Kernel" ],
            path: "Tests",
            sources: [
                "AddressTests.swift",
                "KlibTests.swift",
                "MemoryRangeTests.swift",
//              "PCITests.swift",
                "PageSizeTests.swift",
                "PhysPageRangeTests.swift",
                "StringTests.swift",
//              "USBTests.swift",
            ],
            cSettings: [.define("TEST")],
            swiftSettings: [.define("TEST")]

        )
    ],
    swiftLanguageVersions: [.v5],
)
