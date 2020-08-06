//
//  ACPITests.swift
//  acpi tests
//
//  Created by Simon Evans on 31/07/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//

import XCTest

final class DeviceManager {
    let acpiTables: ACPI
    let systemBusRoot: ACPI.ACPIObjectNode

    init(acpiTables: ACPI, systemBusRoot: ACPI.ACPIObjectNode) {
        self.acpiTables = acpiTables
        self.systemBusRoot = systemBusRoot
    }
}

final class System {
    let deviceManager: DeviceManager

    init(deviceManager: DeviceManager) {
        self.deviceManager = deviceManager
    }
}

var system: System!


fileprivate func invokeMethod(name: String, _ args: Any...) throws -> AMLTermArg? {
    var methodArgs: AMLTermArgList = []
    for arg in args {
        if let arg = arg as? String {
            methodArgs.append(AMLDataObject.string(AMLString(arg)))
        } else if let arg = arg as? AMLInteger {
            methodArgs.append(AMLIntegerData(AMLInteger(arg)))
        } else {
            throw AMLError.invalidData(reason: "Bad data: \(arg)")
        }
    }
    let mi = try AMLMethodInvocation(method: AMLNameString(name),
                                     args: methodArgs)
    var context = ACPI.AMLExecutionContext(scope: mi.method)

    return mi.evaluate(context: &context)
}


fileprivate struct Resources {
    let ioPorts: [ClosedRange<UInt16>]
    let interrupts: [UInt8]
}

fileprivate func extractCRSSettings(_ resources: [AMLResourceSetting]) -> Resources {
    var ioports: [ClosedRange<UInt16>] = []
    var irqs: [UInt8] = []

    for resource in resources {
        if let ioPort = resource as? AMLIOPortSetting {
            ioports.append(ioPort.ioPorts())
        } else if let irq = resource as? AMLIrqSetting {
            irqs.append(contentsOf: irq.interrupts())
        } else {
            print("Ignoring resource:", resource)
        }
    }
    return Resources(ioPorts: ioports, interrupts: irqs)
}


fileprivate func createACPI(files: [String]) -> (ACPI, UnsafeMutableRawPointer) {
    let testDir = testBundle().resourcePath!
    let acpi = ACPI()

    var dataBlocks: [Data] = []
    var total = 0
    for file in files {
        print("Processing:", file)
        let data = openOrQuit(filename: testDir + "/" + file)
        dataBlocks.append(data)
        total += data.count
    }

    let allData = UnsafeMutableRawPointer.allocate(byteCount: total, alignment: 1)
    var offset = 0
    for data in dataBlocks {
        let ptr = allData.advanced(by: offset)
        data.withUnsafeBytes {
            ptr.copyMemory(from: $0.baseAddress!, byteCount: data.count)
        }
        acpi.parseEntry(rawSDTPtr: ptr, vendor: "Foo", product: "Bar")
        offset += data.count
    }

    _ = acpi.parseAMLTables()

    guard let (sb, _) = acpi.globalObjects.getGlobalObject(currentScope: AMLNameString("\\"),
                                                           name: AMLNameString("_SB")) else {
                                                            fatalError("No \\_SB system bus node")
    }

    system = System(deviceManager: DeviceManager(acpiTables: acpi, systemBusRoot: sb))

    return (acpi, allData)
}


extension ACPI.ACPIObjectNode {
    func getDevices() -> [(String, ACPI.ACPIObjectNode)] {
        guard let sb = get("\\_SB") else {
            fatalError("No \\_SB system bus node")
        }
        var devices: [(String, ACPI.ACPIObjectNode)] = []
        walkNode(name: "\\_SB", node: sb) { (path, node) in
            if node is AMLDefDevice {
                devices.append((path, node))
            }
        }
        return devices
    }
}


class ACPITests: XCTestCase {
    static var allData: UnsafeMutableRawPointer?
    static var _acpi: ACPI?

    private static func macbookACPI() -> ACPI {
        if let acpi = _acpi { return acpi }
        let files = [
               "macbook31-APIC.aml",
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
           ]
        (_acpi, allData) = createACPI(files: files)
        return _acpi!
    }


    override class func tearDown() {
        super.tearDown()
        _acpi = nil
        if let d = allData {
            d.deallocate()
            allData = nil
        }
    }


    func testPackage_S5() {
        let acpi = ACPITests.macbookACPI()
        acpi.globalObjects.walkNode { (path, node) in
            print("ACPI:", path)
        }

        let s5 = acpi.globalObjects.get("\\_S5")
        XCTAssertNotNil(s5)
        guard let defname = s5 as? AMLDefName else {
            XCTFail("\\_S5 is not an AMLDefName")
            return
        }
        guard let package = defname.value.dataObject?.packageValue else {
            XCTFail("namedObjects[0] is not an AMLDefPackage")
            return
        }
        XCTAssertNotNil(package)
        XCTAssertEqual(package.count, 3)
        let data = package.compactMap { $0.integerValue }
        XCTAssertEqual(data, [7, 7, 0])
    }


    func testMethod_PIC() {
        let acpi = ACPITests.macbookACPI()
        guard let gpic = acpi.globalObjects.get("\\GPIC") as? AMLDefName else {
            XCTFail("Cant find object \\_PIC")
            return
        }
        XCTAssertNotNil(gpic)
        XCTAssertEqual(gpic.value.integerValue, 0)
        let invocation = try? AMLMethodInvocation(method: AMLNameString("\\_PIC"),
                                                  AMLIntegerData(1)) // APIC
        XCTAssertNotNil(invocation)
        var context = ACPI.AMLExecutionContext(scope: invocation!.method)
        _ = invocation?.evaluate(context: &context)

        guard let gpic2 = acpi.globalObjects.get("\\GPIC") as? AMLDefName else {
            XCTFail("Cant find object \\_PIC")
            return
        }
        XCTAssertEqual(gpic2.value.integerValue, 1)
    }


    func testMethod_OSI() {
        do {
            let result = try invokeMethod(name: "\\_OSI", "Linux")?.integerValue
            XCTAssertNotNil(result)
            XCTAssertEqual(result, 0)

            let result2 = try invokeMethod(name: "\\_OSI", "Darwin")?.integerValue
            XCTAssertNotNil(result2)
            XCTAssertEqual(result2, 0xffffffff)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testMethod_SB_INI() {
        let acpi = ACPITests.macbookACPI()

        do {
            guard let mi = try? AMLMethodInvocation(method: AMLNameString("\\_SB._INI")) else {
                XCTFail("Cant create method invocation")
                return
            }
            var context = ACPI.AMLExecutionContext(scope: mi.method)
            _ = mi.evaluate(context: &context)
            guard let osys = acpi.globalObjects.get("\\OSYS") else {
                XCTFail("Cant find object \\OSYS")
                return
            }

            context = ACPI.AMLExecutionContext(scope: AMLNameString("\\"))
            let x = osys.readValue(context: &context).integerValue
            XCTAssertNotNil(x)
            XCTAssertEqual(x, 10000)

            let ret = try invokeMethod(name: "\\OSDW")?.integerValue
            XCTAssertNotNil(ret)
            XCTAssertEqual(ret, 1)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }


    func testQEMUDevices() {
        // Add some dummy external values
        let (acpi, allData) = createACPI(files: ["QEMU-DSDT.aml"])
        defer { allData.deallocate() }
        acpi.globalObjects.add("\\_SB.PCI0.P0S", AMLDefName(name: AMLNameString("P0S"), value: AMLDataRefObject(integer: 0x44556677)))
        acpi.globalObjects.add("\\_SB.PCI0.P0E", AMLDefName(name: AMLNameString("P0E"), value: AMLDataRefObject(integer: 0xAABBCCDD)))
        acpi.globalObjects.add("\\_SB.PCI0.P1S", AMLDefName(name: AMLNameString("P1S"), value: AMLDataRefObject(integer: 0x00010000)))
        acpi.globalObjects.add("\\_SB.PCI0.P1E", AMLDefName(name: AMLNameString("P1E"), value: AMLDataRefObject(integer: 0x0002FFFF)))
        acpi.globalObjects.add("\\_SB.PCI0.P1L", AMLDefName(name: AMLNameString("P1L"), value: AMLDataRefObject(integer: 0x00020000)))
        acpi.globalObjects.add("\\_SB.PCI0.P1V", AMLDefName(name: AMLNameString("P1V"), value: AMLDataRefObject(integer: 1)))

        let devices = acpi.globalObjects.getDevices()
        XCTAssertEqual(devices.count, 17)
        var deviceResourceSettings: [(String, String, [AMLResourceSetting])] = []



        // Find all of the PNP devices and call a closure with the PNP name and resource settings
        devices.forEach { (fullName, node) in
            if let node = node as? AMLDefDevice {
                if let pnpName = node.hardwareId() {
                    if let crs = node.currentResourceSettings() {
                        print("Found PNP device", pnpName, ":", fullName)
                        deviceResourceSettings.append((fullName, pnpName, crs))
                        let node = acpi.globalObjects.get(fullName)
                        XCTAssertNotNil(node)
                        let f2 = node!.fullname()
                        XCTAssertEqual(fullName, f2)
                    }
                }
            }
        }

        XCTAssertEqual(deviceResourceSettings.count, 14)

        guard let kbd = deviceResourceSettings.filter( { $0.0.hasSuffix(".KBD") } ).first else {
            XCTFail("Cant find KBD")
            return
        }
        XCTAssertEqual(kbd.2.count, 3)
    }


    func testVMWareDevices() {


        let (acpi, allData) = createACPI(files: [
            "vmware-APIC.aml",
            "vmware-FACP.aml",
            "vmware-FACS2.aml",
            "vmware-FACS1.aml",
            "vmware-HPET.aml",
            "vmware-SRAT.aml",
            "vmware-BOOT.aml",
            "vmware-MCFG.aml",
            "vmware-WAET.aml",
            "vmware-DSDT.aml",
        ])
        defer { allData.deallocate()}

        let fullName = "\\_SB.PCI0.ISA"
        guard let isa = acpi.globalObjects.get(fullName) else {
            XCTFail("Cant find \(fullName)")
            return
        }

        for (_, node) in isa.childNodes {
            if let node = node as? AMLDefDevice {

                let fullNodeName = node.fullname()
                if let pnpName = node.pnpName(),
                    let crs = node.currentResourceSettings() {
                    print("Configuring \(fullNodeName) : \(pnpName)")
                    let resources = extractCRSSettings(crs)
                    print(resources)
                }
            }
        }

        acpi.globalObjects.walkNode(name: "\\_SB.PCI0.ISA", node: isa) { (path, node) in
            print("ACPI: \(path)")
        }
    }

    func testVMWare11Devices() {

        let (acpi, allData) = createACPI(files: [
            "vmware11-APIC.aml",
            "vmware11-dmar.aml",
            "vmware11-facp.aml",
            "vmware11-facs.aml",
            "vmware11-hpet.aml",
            "vmware11-srat.aml",
            "vmware11-wsmt.aml",
            "vmware11-mcfg.aml",
            "vmware11-waet.aml",
            "vmware11-dsdt.aml",
        ])
        defer { allData.deallocate()}


        // Call \_SB.INI and then \_SB.PCI0.INI
        do {
            _ = try invokeMethod(name: "\\_PIC", AMLInteger(1))
        } catch {
            XCTFail("Cant set _PIC to GPIC \(error)")
        }

        do {
            _ = try invokeMethod(name: "\\_SB._INI")
        } catch {
            XCTFail("Cant run \\_SB.INI \(error)")
        }

        do {
            _ = try invokeMethod(name: "\\_SB.PCI0._INI")
        } catch {
            XCTFail("Cant run \\_SB.PCI0.INI: \(error)")
        }


        let fullName = "\\_SB.PCI0"
        guard let pci0 = acpi.globalObjects.get(fullName) else {
            XCTFail("Cant find \(fullName)")
            return
        }

        guard let device = pci0 as? AMLDefDevice else {
            XCTFail("PCI0 is not an AMLDefDevice")
            return
        }

        let status = device.status()
        XCTAssertTrue(status.present)
        XCTAssertTrue(status.enabled)


        if let com3 = acpi.globalObjects.get("\\_SB.PCI0.ISA.CO02") as? AMLDefDevice {
            let sta = com3.status()
            XCTAssertNotNil(sta)
        } else {
            XCTFail("Cant find \\_SB.PIC0.ISA.SIO.CO02")
        }


        if let pci0 = acpi.globalObjects.get("\\_SB.PCI0") as? AMLDefDevice {
            let resources = pci0.currentResourceSettings()
            XCTAssertNotNil(resources)
            print(resources!)
        } else {
            XCTFail("Cant get \\_SB.PCI0._CRS")
        }

        // Check DefProcessor
        if let cpu = acpi.globalObjects.get("\\_SB.CP01") {
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(cpu.fullname()))
            let id = (cpu.childNode(named: "CPID")?.readValue(context: &context) as? AMLDataObject)
            XCTAssertEqual(id?.integerValue, 1)
        } else {
            XCTFail("Cant find \\_SB.CP01")
        }
    }
}

