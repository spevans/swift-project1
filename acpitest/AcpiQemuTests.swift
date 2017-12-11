//
//  AcpiQemuTests.swift
//  acpitest
//
//  Created by Simon Evans on 29/11/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//


import XCTest


class AcpiQemuTests: XCTestCase {

    private var acpi: ACPI!
    var globalObjects: ACPIGlobalObjects!


    func openOrQuit(filename: String) -> Data {
        guard let file = try? Data(contentsOf: URL(fileURLWithPath: filename)) else {
            fatalError("Cant open \(filename)")
        }
        return file
    }

    // Mock functions and types
    public func printk(_ format: String, _ arguments: CVarArg...) {
        print(String(format: format, arguments))
    }

    func vaddrFromPaddr(_ addr: UInt) -> UInt {
        return addr
    }

    private func testBundle() -> Bundle {
        for bundle in Bundle.allBundles {
            if let bundleId = bundle.bundleIdentifier, bundleId == "org.si.acpi-tests" {
                return bundle
            }
        }
        fatalError("Cant find test bundle")
    }


    override func setUp() {
        super.setUp()
        if acpi == nil {
            acpi = ACPI()
            guard let testDir = testBundle().resourcePath else {
                fatalError("Cant get resourcePath")
            }
            let data = openOrQuit(filename: testDir + "/QEMU-DSDT.aml")
                data.withUnsafeBytes({
                    acpi.parseEntry(rawSDTPtr: UnsafeRawPointer($0), vendor: "Foo", product: "Bar")
                })
            _ = acpi.parseAMLTables()
            XCTAssertNotNil(acpi.globalObjects)
            globalObjects = acpi.globalObjects
        }
    }


    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    func testDevices() {
        // Add some dummy external values
        acpi.globalObjects.add("\\_SB.PCI0.P0S", AMLDefName(name: AMLNameString("P0S"), value: AMLIntegerData(value: 0x44556677)))
        acpi.globalObjects.add("\\_SB.PCI0.P0E", AMLDefName(name: AMLNameString("P0E"), value: AMLIntegerData(value: 0xAABBCCDD)))
        acpi.globalObjects.add("\\_SB.PCI0.P1S", AMLDefName(name: AMLNameString("P1S"), value: AMLIntegerData(value: 0x00010000)))
        acpi.globalObjects.add("\\_SB.PCI0.P1E", AMLDefName(name: AMLNameString("P1E"), value: AMLIntegerData(value: 0x0002FFFF)))
        acpi.globalObjects.add("\\_SB.PCI0.P1L", AMLDefName(name: AMLNameString("P1L"), value: AMLIntegerData(value: 0x00020000)))
        acpi.globalObjects.add("\\_SB.PCI0.P1V", AMLDefName(name: AMLNameString("P1V"), value: AMLIntegerData(value: 1)))

        let devices = acpi.globalObjects.getDevices()
        XCTAssertEqual(devices.count, 17)
        var deviceResourceSettings: [(String, String, [AMLResourceSetting])] = []

        acpi.globalObjects.pnpDevices() { fullName, pnpName, crs in
            print("Found PNP device", pnpName, ":", fullName)
            deviceResourceSettings.append((fullName, pnpName, crs))
        }

        XCTAssertEqual(deviceResourceSettings.count, 14)

        guard let kbd = deviceResourceSettings.filter( { $0.0.hasSuffix(".KBD") } ).first else {
            XCTFail("Cant find KBD")
            return
        }
        XCTAssertEqual(kbd.2.count, 3)
    }
}

