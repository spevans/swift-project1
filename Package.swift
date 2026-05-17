// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Kernel",
    platforms: [.macOS(.v26)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
    ],

    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
        .package(path: "macros/Printf")
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Build most of the kernel to be used in tests. This stub excludes some files for now
        // until they are made arch independant and can be run in userspace if needed.
        .target(name: "Kernel",
                dependencies: [.product(name: "Printf", package: "Printf"),],
                path: "kernel",
                exclude: ["arch",
                          "init",
                          "devices/kbd8042.swift",
                          "devices/ps2keyboard.swift",
                          "devices/ps2mouse.swift",
                          "devices/acpi/acpi-ps2.swift",
                          "devicse/acpi/acpipmtimer",
                          "devices/acpi/acpi-tad.swift",
                          "devices/usb/uhci-buffers.swift",
                          "devices/usb/uhci-hcd.swift",
                          "devices/usb/uhci-pipe.swift",
                          "devices/usb/uhci-queuehead.swift",
                          "devices/usb/uhci-registers.swift",
                          "devices/usb/uhci-transferdescriptor.swift",
                          "devices/usb/xhci-buffers.swift",
                          "devices/usb/xhci-hcd.swift",
                          "devices/usb/xhci-pipe.swift",
                          "devices/usb/xhci-registers.swift",
                          "devices/usb/xhci-ring.swift",
                          "devices/usb/xhci-trb.swift",
                          "devices/usb/hcd-ehci.swift",
                          "devices/devicemanager.swift",
                          "devices/apic.swift",
                          "devices/mtrr.swift",
                          "devices/cmos.swift",
                          "devices/pic8259.swift",
                          "devices/tty",
                          "devices/gpu/i915",
                          "devices/pit8254.swift",
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
                         ],
                cSettings: [.define("TEST")],
                swiftSettings: [.define("TEST"),
                                .define("ACPI"),
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
            dependencies: [  "Kernel", .product(name: "Printf", package: "Printf"), ],
            path: "Tests",
            sources: [
                "ACPIAMLTypeTests.swift",
                "ACPIReadWriteTests.swift",
                "AddressTests.swift",
                "DisplayTests.swift",
                "KlibTests.swift",
                "MemoryRangeTests.swift",
                "PCITests.swift",
                "PageSizeTests.swift",
                "PhysPageRangeTests.swift",
                "StringTests.swift",
                "USBTests.swift",
            ],
            cSettings: [.define("TEST")],
            swiftSettings: [.define("TEST"), .define("ACPI"), .unsafeFlags(["-enable-bare-slash-regex"])]

        )
    ],
    swiftLanguageVersions: [.v5],
)
