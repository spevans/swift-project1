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
        ["vmware-FACP.aml", "vmware-APIC.aml", "vmware-HPET.aml",
         "vmware-SRAT.aml", "vmware-BOOT.aml", "vmware-FACS1.aml",
         "vmware-MCFG.aml", "vmware-WAET.aml", "vmware-DSDT.aml",
         "vmware-FACS2.aml"],
        ["macbook31-APIC.aml",
         "macbook31-FACP.aml",
         "macbook31-MCFG.aml",
         "macbook31-ASF!.aml",
         "macbook31-FACS1.aml",
         "macbook31-SBST.aml",
         "macbook31-HPET.aml",
         "macbook31-FACS2.aml",
         "macbook31-ECDT.aml",
         "macbook31-DSDT.aml",
         "macbook31-SSDT1.aml",
         "macbook31-SSDT2.aml",
         "macbook31-SSDT3.aml",
         "macbook31-SSDT4.aml",
         "macbook31-SSDT5.aml",
         "macbook31-SSDT6.aml",
         "macbook31-SSDT7.aml",
         "macbook31-SSDT8.aml"
        ],
        [ "QEMU-DSDT.aml"]
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
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    func testFiles() {

        func checkObjects(_ acpi: ACPI) {
            acpi.globalObjects.dumpDevices()
            acpi.globalObjects.runBody(root: "\\") { (name, object) in
                if let method = object as? AMLMethod, method.flags.argCount == 0 {
                    print(name, ":\t", type(of: object), "args: \(method.flags.argCount)")
                    do {
                        if name == "\\_SB.PCI0._CRS" {
                            return
                        }
                        print("Invoking:", name)
                        _ = try acpi.invokeMethod(name: name)
                    } catch {
                        fatalError("Cant invoke '\(name)': \(error)")
                    }
                }
            }


            guard let gpic = acpi.globalObjects.get("\\GPIC") else {
                return
            }
            guard let value = gpic.object as? AMLDataRefObject else {
                return
            }
            print(gpic, value)

            _ = try? acpi.invokeMethod(name: "\\_PIC", 1)
            guard let newValue = gpic.object as? AMLDataRefObject else {
                return
            }
            print(newValue)

        }


        func loadData(_ fileSet: Int) -> ACPI {
            guard let testDir = testBundle().resourcePath else {
                fatalError("Cant get resourcePath")
            }

            let acpi = ACPI()
            for file in files[fileSet] {
                //print("Filename:", file)
                let data = openOrQuit(filename: testDir + "/" + file)
                data.withUnsafeBytes({
                    acpi.parseEntry(rawSDTPtr: UnsafeRawPointer($0), vendor: "Foo", product: "Bar")
                })
            }
            _ = acpi.parseAMLTables()
            return acpi
        }

        var acpis: [ACPI] = Array()
        for fileSet in 0...2 {
            print("Testing fileSet:", fileSet)
            let acpi = loadData(fileSet)
            //checkObjects(acpi)
            acpis.append(acpi)
        }
    }


    func testPackage_S5() {
        let s5 = globalObjects.get("\\_S5")
        XCTAssertNotNil(s5)
        XCTAssertNotNil(s5!.object)
        guard let package = (s5!.object as? AMLDefName)?.value as? AMLDefPackage else {
            XCTFail("namedObjects[0] is not an AMLDefPackage")
            return
        }
        XCTAssertNotNil(package)
        XCTAssertEqual(package.elements.count, 3)
        let data = package.elements.compactMap { ($0 as? AMLIntegerData)?.value }
        XCTAssertEqual(data, [7, 7, 0])
    }


    func testMethod_PIC() {
        guard let gpic = globalObjects.getDataRefObject("\\GPIC") as? AMLIntegerData else {
            XCTFail("Cant find object \\_PIC")
            return
        }
        XCTAssertNotNil(gpic)
        XCTAssertEqual(gpic.value, 0)
        let invocation = try? AMLMethodInvocation(method: AMLNameString("\\_PIC"),
                                                  AMLByteConst(1)) // APIC
        XCTAssertNotNil(invocation)
        var context = ACPI.AMLExecutionContext(scope: invocation!.method,
                                               args: [], globalObjects: acpi.globalObjects)
        _ = try? invocation?.execute(context: &context)

        guard let gpic2 = globalObjects.getDataRefObject("\\GPIC") as? AMLIntegerData else {
            XCTFail("Cant find object \\_PIC")
            return
        }
        XCTAssertEqual(gpic2.value, 1)
    }


    func testMethod_OSI() {
        do {
            let result = try acpi.invokeMethod(name: "\\_OSI", "Linux") as? AMLIntegerData
            XCTAssertNotNil(result)
            XCTAssertEqual(result!.value, 0)

            let result2 = try acpi.invokeMethod(name: "\\_OSI", "Darwin") as? AMLIntegerData
            XCTAssertNotNil(result2)
            XCTAssertEqual(result2!.value, 0xffffffff)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testMethod_SB_INI() {
        do {
            guard let mi = try? AMLMethodInvocation(method: AMLNameString("\\_SB._INI")) else {
                XCTFail("Cant create method invocation")
                return
            }
            var context = ACPI.AMLExecutionContext(scope: mi.method,
                                                   args: [], globalObjects: acpi.globalObjects)
            _ = try? mi.execute(context: &context)
            guard let osys = globalObjects.getDataRefObject("\\OSYS") else {
                XCTFail("Cant find object \\OSYS")
                return
            }

            context = ACPI.AMLExecutionContext(scope: AMLNameString("\\"),
                                               args: [],
                                               globalObjects: globalObjects)
            let x = osys.evaluate(context: &context) as? AMLIntegerData
            XCTAssertNotNil(x)
            XCTAssertEqual(x!.value, 10000)

            let ret = try acpi.invokeMethod(name: "\\OSDW") as? AMLIntegerData
            XCTAssertNotNil(ret)
            XCTAssertEqual(ret!.value, 1)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }
}

