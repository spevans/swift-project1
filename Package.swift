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
        // Build the tests directly using some soruces from the kernel. Currently the kernel wont build as a
        // separate target so this is the easiest way. Note that some tests are excluded because getting the
        // acpi to compile currently causes a compiler crash
        .testTarget(
            name: "KernelTests",
              dependencies: [ "PrintfMacros"],
            path: "Tests",
            sources: [
                "Kernel/klib/BitmapAllocator.swift",
                "Kernel/klib/Extensions.swift",
                "Kernel/klib/PrintfInternal.swift",
                "Kernel/klib/ReservationManager.swift",
                "Kernel/klib/extensions/BinaryInteger+Extras.swift",
                "Kernel/klib/extensions/bitarray.swift",
                "Kernel/klib/extensions/bytearray.swift",
                "Kernel/klib/extensions/dwordarray.swift",
                "Kernel/klib/extensions/integer.swift",
                "Kernel/klib/printf.swift",
                "Kernel/mm/MMIORegion.swift",
                "Kernel/mm/MemoryRegion.swift",
                "Kernel/mm/PageSize.swift",
                "Kernel/mm/PhysPageAlignedRegion.swift",
                "Kernel/mm/PhysRegion.swift",
                "Kernel/mm/address.swift",
/**
                "Kernel/devices/ISABus.swift",
                "Kernel/devices/PNPDevice.swift",
                "Kernel/devices/Timer.swift",
                "Kernel/devices/acpi/ACPIDeviceConfig.swift",
                "Kernel/devices/acpi/ACPIGenericAddressStructure.swift",
                "Kernel/devices/acpi/AMLFieldSettings.swift",
                "Kernel/devices/acpi/AMLObject.swift",
                "Kernel/devices/acpi/acpi.swift",
                "Kernel/devices/acpi/acpiglobalobjects.swift",
                "Kernel/devices/acpi/amlmethod.swift",
                "Kernel/devices/acpi/amlnamedobject.swift",
                "Kernel/devices/acpi/amlnamespacemodifier.swift",
                "Kernel/devices/acpi/amlparser.swift",
                "Kernel/devices/acpi/amlresourcedata.swift",
                "Kernel/devices/acpi/amltype1opcodes.swift",
                "Kernel/devices/acpi/amltype2opcodes.swift",
                "Kernel/devices/acpi/amltypes.swift",
                "Kernel/devices/acpi/amlutils.swift",
                "Kernel/devices/acpi/boot.swift",
                "Kernel/devices/acpi/ecdt.swift",
                "Kernel/devices/acpi/facp.swift",
                "Kernel/devices/acpi/facs.swift",
                "Kernel/devices/acpi/hpet.swift",
                "Kernel/devices/acpi/madt.swift",
                "Kernel/devices/acpi/mcfg.swift",
                "Kernel/devices/acpi/sbst.swift",
                "Kernel/devices/acpi/srat.swift",
                "Kernel/devices/acpi/waet.swift",
                "Kernel/devices/apic.swift",
                "Kernel/devices/bus.swift",
                "Kernel/devices/device.swift",
                "Kernel/devices/driver.swift",
**/
                "Kernel/devices/ioapic.swift",
/**
                "Kernel/devices/pci/PCICapability.swift",
                "Kernel/devices/pci/PCIDeviceFunction.swift",
                "Kernel/devices/pci/PCIInterruptLinkDevice.swift",
                "Kernel/devices/pci/PCIRoutingTable.swift",
                "Kernel/devices/pci/pcibus.swift",
                "Kernel/devices/pci/pciconfigspace.swift",
                "Kernel/devices/pci/pcidevice.swift",
                "Kernel/devices/pci/pcideviceclass.swift",
                "Kernel/devices/usb/usb.swift",
                "Kernel/devices/usb/usb-configdescriptor.swift",
                "Kernel/devices/usb/usb-controlrequest.swift",
                "Kernel/devices/usb/usb-devicedescriptor.swift",
                "Kernel/devices/usb/usb-devicequalifier.swift",
                "Kernel/devices/usb/usb-endpointdescriptor.swift",
                "Kernel/devices/usb/usb-hiddescriptor.swift",
                "Kernel/devices/usb/usb-interfacedescriptor.swift",
                "Kernel/traps/interrupt.swift",
**/
                "Kernel/traps/IRQSetting.swift",
                "AddressTests.swift",
                "FakePhysicalMemory.swift",
                "KlibTests.swift",
                "MemoryRangeTests.swift",
//              "PCITests.swift",
                "PageSizeTests.swift",
                "PhysPageRangeTests.swift",
                "StringTests.swift",
                "TestKPrint.swift",
                "TestUtils.swift",
//              "USBTests.swift",
            ],
            cSettings: [.define("TEST")],
            swiftSettings: [.define("TEST"), .unsafeFlags(["-import-objc-header", "Tests/test.h"])]

        )
    ],
    swiftLanguageVersions: [.v5],
)
