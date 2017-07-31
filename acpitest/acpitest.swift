//
//  acpitest.swift
//  acpi tests
//
//  Created by Simon Evans on 31/07/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

import XCTest


class acpitest: XCTestCase {


    private var acpi: ACPI!
    var globalObjects: ACPIGlobalObjects!


    private let files = [
        ["vmware/FACP.aml", "vmware/APIC.aml", "vmware/HPET.aml",
         "vmware/SRAT.aml", "vmware/BOOT.aml", "vmware/FACS1.aml",
         "vmware/MCFG.aml", "vmware/WAET.aml", "vmware/DSDT.aml",
         "vmware/FACS2.aml"],
        ["macbook31/APIC.aml",
         "macbook31/FACP.aml",
         "macbook31/MCFG.aml",
         "macbook31/ASF!.aml",
         "macbook31/FACS1.aml",
         "macbook31/SBST.aml",
         "macbook31/HPET.aml",
         "macbook31/FACS2.aml",
         "macbook31/ECDT.aml",
         "macbook31/DSDT.aml",
         "macbook31/SSDT1.aml",
         "macbook31/SSDT2.aml",
         "macbook31/SSDT3.aml",
         "macbook31/SSDT4.aml",
         "macbook31/SSDT5.aml",
         "macbook31/SSDT6.aml",
         "macbook31/SSDT7.aml",
         "macbook31/SSDT8.aml"
        ],
        [ "qemu/QEMU-DSDT.aml"]
    ]


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


    override func setUp() {
        super.setUp()
        if acpi == nil {
            acpi = ACPI()
            let testDir = "/Users/spse/Files/src/acpi/acpi/test_files"
            for file in files[1] {
                let data = openOrQuit(filename: testDir + "/" + file)
                data.withUnsafeBytes({
                    acpi.parseEntry(rawSDTPtr: UnsafeRawPointer($0), vendor: "Foo", product: "Bar")
                })
            }
            _ = acpi.parseAMLTables()
            XCTAssertNotNil(acpi.globalObjects)
            globalObjects = acpi.globalObjects
        }
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    func testPackage_S5() {
        let s5 = globalObjects.get("\\_S5")
        XCTAssertNotNil(s5)
        XCTAssertNotNil(s5!.object!)
        guard let package = s5!.object as? AMLDefPackage else {
            XCTFail("namedObjects[0] is not an AMLDefPackage")
            return
        }
        XCTAssertNotNil(package)
        XCTAssertEqual(package.elements.count, 3)
        let data = package.elements.flatMap { $0.asInteger }
        XCTAssertEqual(data, [7, 7, 0])
    }


    func testMethod_PIC() {
        guard let gpic = globalObjects.getDataRefObject("\\GPIC") else {
            XCTFail("Cant find object \\_PIC")
            return
        }
        XCTAssertNotNil(gpic.asInteger)
        XCTAssertEqual(gpic.asInteger!, 0)
        let invocation = try? AMLMethodInvocation(method: AMLNameString(value: "\\_PIC"),
                                                  AMLByteConst(1)) // APIC
        XCTAssertNotNil(invocation)
        _ = try? acpi.invokeMethod(invocation: invocation!)

        guard let gpic2 = globalObjects.getDataRefObject("\\GPIC") else {
            XCTFail("Cant find object \\_PIC")
            return
        }
        XCTAssertNotNil(gpic2.asInteger)
        XCTAssertEqual(gpic2.asInteger!, 1)
    }


    func testMethod_OSI() {
        do {
            let result = try acpi.invokeMethod(name: "\\_OSI", "Linux")
            XCTAssertNotNil(result?.resultAsInteger)
            XCTAssertEqual(result!.resultAsInteger!, 0)

            let result2 = try acpi.invokeMethod(name: "\\_OSI", "Windows")
            XCTAssertNotNil(result2)
            XCTAssertTrue(result2 is AMLIntegerData)
            XCTAssertEqual(result2!.resultAsInteger!, 0xffffffff)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testMethod_SB_INI() {
        do {
            guard let m = try? AMLMethodInvocation(method: AMLNameString(value: "\\_SB._INI")) else {
                XCTFail("Cant create method invocation")
                return
            }
            _ = try acpi.invokeMethod(invocation: m)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }


    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

