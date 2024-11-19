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
    let masterBus: MasterBus

    init(acpiTables: ACPI, systemBusRoot: ACPI.ACPIObjectNode) {
        self.acpiTables = acpiTables
        self.systemBusRoot = systemBusRoot
        self.masterBus = MasterBus(acpiSystemBus: systemBusRoot)
    }

    func walkDeviceTree(bus: Device? = nil, body: (Device) -> Bool) {
        for device in (bus ?? masterBus.device).devices {
            if !body(device) { return }
            if device.isBus {
                walkDeviceTree(bus: device, body: body)
            }
        }
    }
}

final class System {
    let deviceManager: DeviceManager

    init(deviceManager: DeviceManager) {
        self.deviceManager = deviceManager
    }
}

var system: System!


fileprivate struct Resources {
    let ioPorts: [ClosedRange<UInt16>]
    let interrupts: [IRQSetting]
}

fileprivate func extractCRSSettings(_ resources: [AMLResourceSetting]) -> Resources {
    var ioports: [ClosedRange<UInt16>] = []
    var irqs: [IRQSetting] = []

    for resource in resources {
        switch resource {
            case let .ioPortSetting(ioPort): ioports.append(ioPort.ioPorts())
            case let .irqSetting(irq): irqs.append(contentsOf: irq.interrupts())
            default: print("Ignoring resource:", resource)
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

        let region = PhysPageAlignedRegion(data: data)
        let paddr = region.baseAddress
        acpi.parseEntry(physAddress: paddr, vendor: "Foo", product: "Bar")
        offset += data.count
    }

    acpi.parseAMLTables()

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
            return true
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
            return true
        }

        let s5 = acpi.globalObjects.get("\\_S5")
        XCTAssertNotNil(s5)
        guard let defname = s5 as? AMLNamedValue else {
            XCTFail("\\_S5 is not an AMLNamedValue")
            return
        }
        guard let package = defname.value.dataObject?.packageValue else {
            XCTFail("namedObjects[0] is not an AMLDefPackage")
            return
        }
        XCTAssertNotNil(package)
        XCTAssertEqual(package.count, 3)
        let data = package.compactMap { $0.dataRefObject?.integerValue }
        XCTAssertEqual(data, [7, 7, 0])
    }


    func testMethod_PIC() throws {
        let acpi = ACPITests.macbookACPI()
        guard let gpic = acpi.globalObjects.get("\\GPIC") as? AMLNamedValue else {
            XCTFail("Cant find object \\GPIC")
            return
        }
        XCTAssertNotNil(gpic)
        XCTAssertEqual(gpic.value.integerValue, 0)
        try ACPI.invoke(method: "\\_PIC", AMLIntegerData(1))

        guard let gpic2 = acpi.globalObjects.get("\\GPIC") as? AMLNamedValue else {
            XCTFail("Cant find object \\GPIC")
            return
        }
        XCTAssertEqual(gpic2.value.integerValue, 1)

        // Now read the _PRT to check it is using the correct table based on the GPIC value
        guard let pci0 = acpi.globalObjects.get("\\_SB.PCI0")! as? AMLDefDevice else {
            XCTFail("Cant find \\_SB.PCI0")
            return
        }
        guard let prt = pci0.childNode(named: "_PRT") else {
            XCTFail("Cannot find \\_SB.PCI0._PRT")
            return
        }
        let interruptRoutingTable = PCIRoutingTable(prtNode: prt)
        guard let table = interruptRoutingTable?.table else {
            XCTFail("Cant read _PRT")
            return
        }

        XCTAssertEqual(table.count, 19)
        XCTAssertEqual(table.first, PCIRoutingTable.Entry(pciDevice: 1, pin: .intA, source: .globalSystemInterrupt(16)))
        XCTAssertEqual(table.last, PCIRoutingTable.Entry(pciDevice: 31, pin: .intD, source: .globalSystemInterrupt(16)))
    }


    func testMethod_OSI() {
        do {
            let result = try ACPI.invoke(method: "\\_OSI", AMLNameString("Linux"))?.integerValue
            XCTAssertEqual(result, 0)

            let result2 = try ACPI.invoke(method: "\\_OSI", AMLNameString("Darwin"))?.integerValue
            XCTAssertEqual(result2, 0xffffffff)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testMethod_SB_INI() {
        let acpi = ACPITests.macbookACPI()

        do {
            FakePhysMemory.addPhysicalMemory(start: PhysAddress(0xbeed5a98), size: 256)
            try ACPI.invoke(method: "\\_SB._INI")
            guard let osys = acpi.globalObjects.get("\\OSYS") else {
                XCTFail("Cant find object \\OSYS")
                return
            }

            var context = ACPI.AMLExecutionContext(scope: AMLNameString("\\"))
            let x = osys.readValue(context: &context).integerValue
            XCTAssertNotNil(x)
            XCTAssertEqual(x, 10000)

            let ret = try ACPI.invoke(method: "\\OSDW")?.integerValue
            XCTAssertEqual(ret, 1)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func testQEMU910Devices() {
        // Add some dummy external values
        let (acpi, allData) = createACPI(files: ["QEMU-9.1.0-DSDT.aml"])

        defer { allData.deallocate() }
        do {
            guard let prtNode = acpi.globalObjects.get("\\_SB.PCI0._PRT") else {
                throw AMLError.parseError
            }
            guard let prt = PCIRoutingTable(prtNode: prtNode) else {
                XCTFail("Cannot part PRT table")
                throw AMLError.parseError
            }
            XCTAssertEqual(prt.table.count, 128)
        } catch AMLError.invalidMethod(let reason) {
            XCTAssertEqual(reason, "Cant find method: \\_PIC")
        } catch {
            XCTFail("\(error)")
        }

        do {
            guard let sta = acpi.globalObjects.get("\\_SB.LNKA._STA") else {
                XCTFail("Cant find \\_SB.LINK._STA")
                throw AMLError.parseError
            }
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(sta.fullname()))
            let result = sta.readValue(context: &context)
            XCTAssertEqual(result.integerValue, 11)
        } catch {
            XCTFail("\(error)")
        }

        do {
            acpi.globalObjects.add("\\_SB.HPET.VEND", AMLNamedValue(name: AMLNameString("VEND"), value: .init(integer: 0x80860201)))
            acpi.globalObjects.add("\\_SB.HPET.PRD", AMLNamedValue(name: AMLNameString("PRD"), value: .init(integer: 0x00989680)))
            guard let sta = acpi.globalObjects.get("\\_SB.HPET._STA") else {
                XCTFail("Cant find \\_SB.HPET._STA")
                throw AMLError.parseError
            }
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(sta.fullname()))
            let result = sta.readValue(context: &context)
            XCTAssertEqual(result.integerValue, AMLInteger(0xf))
        } catch {
            XCTFail("\(error)")
        }
    }

    func testQEMUDevices() {
        // Add some dummy external values
        let (acpi, allData) = createACPI(files: ["QEMU-DSDT.aml"])
        defer { allData.deallocate() }
        acpi.globalObjects.add("\\_SB.PCI0.P0S", AMLNamedValue(name: AMLNameString("P0S"), value: AMLDataRefObject(integer: 0x44556677)))
        acpi.globalObjects.add("\\_SB.PCI0.P0E", AMLNamedValue(name: AMLNameString("P0E"), value: AMLDataRefObject(integer: 0xAABBCCDD)))
        acpi.globalObjects.add("\\_SB.PCI0.P1S", AMLNamedValue(name: AMLNameString("P1S"), value: AMLDataRefObject(integer: 0x00010000)))
        acpi.globalObjects.add("\\_SB.PCI0.P1E", AMLNamedValue(name: AMLNameString("P1E"), value: AMLDataRefObject(integer: 0x0002FFFF)))
        acpi.globalObjects.add("\\_SB.PCI0.P1L", AMLNamedValue(name: AMLNameString("P1L"), value: AMLDataRefObject(integer: 0x00020000)))
        acpi.globalObjects.add("\\_SB.PCI0.P1V", AMLNamedValue(name: AMLNameString("P1V"), value: AMLDataRefObject(integer: 1)))

        let devices = acpi.globalObjects.getDevices()
        XCTAssertEqual(devices.count, 17)
        var deviceResourceSettings: [(String, String, [AMLResourceSetting])] = []

        // _PIC doesnt exist in QEMU DSDT, so check invoking it fails
        do {
            try ACPI.invoke(method: "\\_PIC", AMLIntegerData(1))
            XCTFail("\\_PIC invokation should not have succeeded")
        } catch AMLError.invalidMethod(let reason) {
            XCTAssertEqual(reason, "Cant find method: \\_PIC")
        } catch {
            XCTFail("\(error)")
        }

        // Find all of the PNP devices and call a closure with the PNP name and resource settings
        devices.forEach { (fullName, node) in
            if let node = node as? AMLDefDevice {
                if let pnpName = node.hardwareId() {
                    #if false // Fails due to lookup of PCI_Region and the underlying PCIDevice isnt setup in the tests
                    if let crs = node.currentResourceSettings() {
                        print("Found PNP device", pnpName, ":", fullName)
                        deviceResourceSettings.append((fullName, pnpName, crs))
                        let node = acpi.globalObjects.get(fullName)
                        XCTAssertNotNil(node)
                        let f2 = node!.fullname()
                        XCTAssertEqual(fullName, f2)
                    }
                    #endif
                }
            }
        }

        #if false // Fails due to lookup of PCI_Region and the underlying PCIDevice isnt setup in the tests
        XCTAssertEqual(deviceResourceSettings.count, 14)

        guard let kbd = deviceResourceSettings.filter( { $0.0.hasSuffix(".KBD") } ).first else {
            XCTFail("Cant find KBD")
            return
        }
        XCTAssertEqual(kbd.2.count, 3)
        #endif

        // Test _PRT
        guard let prt = acpi.globalObjects.get("\\_SB.PCI0._PRT") else {
            XCTFail("Cant get \\_SB.PCI0._PRT")
            return
        }

        guard let prtDataObject = prt.asTermArg() as? AMLDataObject else {
            XCTFail("Cant get _PRT as a DataObject")
            return
        }
        guard let table = prtDataObject.packageValue else {
            XCTFail("Cant get _PRT package")
            return
        }
        print(table)

    }

    func testParsePackageByteStream() throws {
        let (acpi, allData) = createACPI(files: ["QEMU-DSDT.aml"])
        defer { allData.deallocate() }

        // \_SB.PCI0._PRT from QEMU  qemu-system-x86_64  5.2.0
        let testData1: [UInt8] = [
            0x44, 0x52, // PkgLength = 1316  (0x524) 2byte pkg length + 1314 bytes of data
            0x5f, 0x50, 0x52, 0x54, 0x00, 0xa4, 0x12, 0x4b, 0x51, 0x40, 0x12, 0x11, 0x04, 0x0b, 0xff, 0xff,
            0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x11, 0x04, 0x0b,
            0xff, 0xff, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00, 0x12, 0x12,
            0x04, 0x0b, 0xff, 0xff, 0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x42,
            0x00, 0x12, 0x12, 0x04, 0x0b, 0xff, 0xff, 0x0a, 0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c,
            0x4e, 0x4b, 0x43, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x01, 0x00, 0x00, 0x5e, 0x2e, 0x4c,
            0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x53, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x01, 0x00,
            0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x42, 0x00, 0x12, 0x14, 0x04, 0x0c,
            0xff, 0xff, 0x01, 0x00, 0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x43,
            0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x01, 0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43,
            0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x02, 0x00, 0x00, 0x5e,
            0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x42, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff,
            0x02, 0x00, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x12, 0x14,
            0x04, 0x0c, 0xff, 0xff, 0x02, 0x00, 0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e,
            0x4b, 0x44, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x02, 0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c,
            0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x03, 0x00,
            0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x12, 0x13, 0x04, 0x0c,
            0xff, 0xff, 0x03, 0x00, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00,
            0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x03, 0x00, 0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f,
            0x4c, 0x4e, 0x4b, 0x41, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x03, 0x00, 0x0a, 0x03, 0x5e,
            0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x42, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff,
            0x04, 0x00, 0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x13,
            0x04, 0x0c, 0xff, 0xff, 0x04, 0x00, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b,
            0x41, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x04, 0x00, 0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50,
            0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x42, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x04, 0x00, 0x0a,
            0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x12, 0x13, 0x04, 0x0c,
            0xff, 0xff, 0x05, 0x00, 0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00,
            0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x05, 0x00, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c,
            0x4e, 0x4b, 0x42, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x05, 0x00, 0x0a, 0x02, 0x5e, 0x2e,
            0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x05,
            0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x13,
            0x04, 0x0c, 0xff, 0xff, 0x06, 0x00, 0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b,
            0x42, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x06, 0x00, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43,
            0x5f, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x06, 0x00, 0x0a, 0x02,
            0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff,
            0xff, 0x06, 0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00,
            0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x07, 0x00, 0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c,
            0x4e, 0x4b, 0x43, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x07, 0x00, 0x01, 0x5e, 0x2e, 0x4c,
            0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x07, 0x00,
            0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00, 0x12, 0x14, 0x04,
            0x0c, 0xff, 0xff, 0x07, 0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b,
            0x42, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x08, 0x00, 0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43,
            0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x08, 0x00, 0x01, 0x5e,
            0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff,
            0x08, 0x00, 0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x42, 0x00, 0x12,
            0x14, 0x04, 0x0c, 0xff, 0xff, 0x08, 0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c,
            0x4e, 0x4b, 0x43, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x09, 0x00, 0x00, 0x5e, 0x2e, 0x4c,
            0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x09, 0x00,
            0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x42, 0x00, 0x12, 0x14, 0x04, 0x0c,
            0xff, 0xff, 0x09, 0x00, 0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x43,
            0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x09, 0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43,
            0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x0a, 0x00, 0x00, 0x5e,
            0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x42, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff,
            0x0a, 0x00, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x12, 0x14,
            0x04, 0x0c, 0xff, 0xff, 0x0a, 0x00, 0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e,
            0x4b, 0x44, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x0a, 0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c,
            0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x0b, 0x00,
            0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x12, 0x13, 0x04, 0x0c,
            0xff, 0xff, 0x0b, 0x00, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00,
            0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x0b, 0x00, 0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f,
            0x4c, 0x4e, 0x4b, 0x41, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x0b, 0x00, 0x0a, 0x03, 0x5e,
            0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x42, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff,
            0x0c, 0x00, 0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x13,
            0x04, 0x0c, 0xff, 0xff, 0x0c, 0x00, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b,
            0x41, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x0c, 0x00, 0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50,
            0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x42, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x0c, 0x00, 0x0a,
            0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x12, 0x13, 0x04, 0x0c,
            0xff, 0xff, 0x0d, 0x00, 0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00,
            0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x0d, 0x00, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c,
            0x4e, 0x4b, 0x42, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x0d, 0x00, 0x0a, 0x02, 0x5e, 0x2e,
            0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x0d,
            0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x13,
            0x04, 0x0c, 0xff, 0xff, 0x0e, 0x00, 0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b,
            0x42, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x0e, 0x00, 0x01, 0x5e, 0x2e, 0x4c, 0x50, 0x43,
            0x5f, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x0e, 0x00, 0x0a, 0x02,
            0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff,
            0xff, 0x0e, 0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00,
            0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x0f, 0x00, 0x00, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c,
            0x4e, 0x4b, 0x43, 0x00, 0x12, 0x13, 0x04, 0x0c, 0xff, 0xff, 0x0f, 0x00, 0x01, 0x5e, 0x2e, 0x4c,
            0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x12, 0x14, 0x04, 0x0c, 0xff, 0xff, 0x0f, 0x00,
            0x0a, 0x02, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b, 0x41, 0x00, 0x12, 0x14, 0x04,
            0x0c, 0xff, 0xff, 0x0f, 0x00, 0x0a, 0x03, 0x5e, 0x2e, 0x4c, 0x50, 0x43, 0x5f, 0x4c, 0x4e, 0x4b,
            0x42, 0x00 ]

        let testData2: [UInt8] = [
            0x44, 0x0A, // PkgLength = 164  (0xA4) 2byte pkg length + 162 bytes of data
            0x5f, 0x50, 0x52, 0x54, 0x00, 0x70, 0x12, 0x02, 0x80, 0x60, 0x70, 0x00, 0x61, 0xa2, 0x42, 0x09,
            0x95, 0x61, 0x0a, 0x80, 0x70, 0x7a, 0x61, 0x0a, 0x02, 0x00, 0x62, 0x70, 0x7b, 0x72, 0x61, 0x62,
            0x00, 0x0a, 0x03, 0x00, 0x63, 0xa0, 0x10, 0x93, 0x63, 0x00, 0x70, 0x12, 0x09, 0x04, 0x00, 0x00,
            0x4c, 0x4e, 0x4b, 0x44, 0x00, 0x64, 0xa0, 0x24, 0x93, 0x63, 0x01, 0xa0, 0x11, 0x93, 0x61, 0x0a,
            0x04, 0x70, 0x12, 0x09, 0x04, 0x00, 0x00, 0x4c, 0x4e, 0x4b, 0x53, 0x00, 0x64, 0xa1, 0x0d, 0x70,
            0x12, 0x09, 0x04, 0x00, 0x00, 0x4c, 0x4e, 0x4b, 0x41, 0x00, 0x64, 0xa0, 0x11, 0x93, 0x63, 0x0a,
            0x02, 0x70, 0x12, 0x09, 0x04, 0x00, 0x00, 0x4c, 0x4e, 0x4b, 0x42, 0x00, 0x64, 0xa0, 0x11, 0x93,
            0x63, 0x0a, 0x03, 0x70, 0x12, 0x09, 0x04, 0x00, 0x00, 0x4c, 0x4e, 0x4b, 0x43, 0x00, 0x64, 0x70,
            0x7d, 0x79, 0x62, 0x0a, 0x10, 0x00, 0x0b, 0xff, 0xff, 0x00, 0x88, 0x64, 0x00, 0x00, 0x70, 0x7b,
            0x61, 0x0a, 0x03, 0x00, 0x88, 0x64, 0x01, 0x00, 0x70, 0x64, 0x88, 0x60, 0x61, 0x00, 0x75, 0x61,
            0xa4, 0x60,
            ]


        func parsePRT(_ data: [UInt8], _ count: Int) throws -> PCIRoutingTable {
            try data.withUnsafeBytes {
                let byteStream = try AMLByteStream(buffer: $0)

                guard let pci0 = acpi.globalObjects.get("\\_SB.PCI0")! as? AMLDefDevice else {
                    XCTFail("Cant find \\_SB.PCI0")
                    throw AMLError.invalidData(reason: "Cant find \\_SB.PCI0")
                }

                // Delete the current \_SB.PCI0._PRT, parse the data block and insert as the new \_SB.PCI0._PRT
                pci0.removeChildNode(AMLNameString("_PRT"))
                let parser = AMLParser(byteStream: byteStream, scope: AMLNameString("\\_SB.PCI0"),
                                       globalObjects: acpi.globalObjects, parsingMethod: true)
                let m = try parser.parseDefMethod()
                pci0.add("_PRT", m)

                var context = ACPI.AMLExecutionContext(scope: AMLNameString("\\_SB.PCI0._PRT"))
                let termArg = m.readValue(context: &context)
                guard let prt = termArg as? AMLDataObject else {
                    XCTFail("_PRT is not a DataObject")
                    throw AMLError.parseError
                }
                guard let table = prt.packageValue else {
                    XCTFail("_PRT table is not a package")
                    throw AMLError.parseError
                }
                XCTAssertEqual(table.count, count)
                XCTAssertNotNil(table[0].dataRefObject)

                guard let prt = pci0.childNode(named: "_PRT") else {
                    XCTFail("Cannot find \\_SB.PCI0._PRT")
                    throw AMLError.parseError
                }
                guard let pciRT = PCIRoutingTable(prtNode: prt) else {
                    XCTFail("Cant parse PCIRoutingTable")
                    throw AMLError.parseError
                }
                XCTAssertEqual(pciRT.table.count, count)
                return pciRT
            }
        }

        do {
            let table = try parsePRT(testData1, 64).table
            XCTAssertEqual(table[0], PCIRoutingTable.Entry(pciDevice: 0, pin: .intA, source: .namePath(AMLNameString("^LPC.LNKD"), 0)))
            XCTAssertEqual(table[63], PCIRoutingTable.Entry(pciDevice: 15, pin: .intD, source: .namePath(AMLNameString("^LPC.LNKB"), 0)))
        }

        do {
            let table = try parsePRT(testData2, 128).table
            XCTAssertEqual(table[0], PCIRoutingTable.Entry(pciDevice: 0, pin: .intA, source: .namePath(AMLNameString("LNKD"), 0)))
            XCTAssertEqual(table[127], PCIRoutingTable.Entry(pciDevice: 31, pin: .intD, source: .namePath(AMLNameString("LNKB"), 0)))

        }
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

        for node in isa.childNodes {
            if let node = node as? AMLDefDevice {

                let fullNodeName = node.fullname()
                if let pnpName = node.hardwareId(),
                    let crs = node.currentResourceSettings() {
                    print("Configuring \(fullNodeName) : \(pnpName)")
                    let resources = extractCRSSettings(crs)
                    print(resources)
                }
            }
        }

        acpi.globalObjects.walkNode(name: "\\_SB.PCI0.ISA", node: isa) { (path, node) in
            print("ACPI: \(path)")
            return true
        }
    }

    func testVMWare11Devices() throws {

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

        guard let pci0 = acpi.globalObjects.get("\\_SB.PCI0")! as? AMLDefDevice else {
            XCTFail("Cant find \\_SB.PCI0")
            return
        }

        guard let gpic = acpi.globalObjects.get("\\GPIC") as? AMLNamedValue else {
            XCTFail("Cant find object \\GPIC")
            return
        }
        XCTAssertEqual(gpic.value.integerValue, 0)

        do {
            // Read the _PRT to check it is using GPIC=0 form
            guard let prt = acpi.globalObjects.get("\\_SB.PCI0._PRT") else {
                XCTFail("Cannot find \\_SB.PCI0.PRT")
                return
            }
            let interruptRoutingTable = PCIRoutingTable(prtNode: prt)
            guard let table = interruptRoutingTable?.table else {
                XCTFail("Cant read _PRT")
                return
            }
            XCTAssertEqual(table.count, 72)

            XCTAssertEqual(table.first, PCIRoutingTable.Entry(pciDevice: 15, pin: .intA, source: .namePath(AMLNameString("^ISA.LNKA"), 0)))
            XCTAssertEqual(table.last, PCIRoutingTable.Entry(pciDevice: 7, pin: .intD, source: .namePath(AMLNameString("^ISA.LNKD"), 0)))
        }


        // Call \_SB.INI and then \_SB.PCI0.INI
        try ACPI.invoke(method: "\\_PIC", AMLIntegerData(1))
        XCTAssertEqual(gpic.value.integerValue, 1)

        do {
            // Now read the _PRT to check it is using GPIC=1 form
            guard let prt = pci0.childNode(named: "_PRT") else {
                XCTFail("Cannot find \\_SB.PCI0.PRT")
                return
            }
            let interruptRoutingTable = PCIRoutingTable(prtNode: prt)
            guard let table = interruptRoutingTable?.table else {
                XCTFail("Cant read _PRT")
                return
            }
            XCTAssertEqual(table.count, 72)
            XCTAssertEqual(table.first, PCIRoutingTable.Entry(pciDevice: 15, pin: .intA, source: .globalSystemInterrupt(16)))
            XCTAssertEqual(table.last, PCIRoutingTable.Entry(pciDevice: 7, pin: .intD, source: .globalSystemInterrupt(19)))
        }


        do {
            try ACPI.invoke(method: "\\_SB._INI")
        } catch {
            XCTFail("Cant run \\_SB.INI \(error)")
        }

        do {
            try ACPI.invoke(method: "\\_SB.PCI0._INI")
        } catch {
            XCTFail("Cant run \\_SB.PCI0.INI: \(error)")
        }

/*
        let status = pci0.status()
        XCTAssertTrue(status.present)
        XCTAssertTrue(status.enabled)

        if let com3 = acpi.globalObjects.get("\\_SB.PCI0.ISA.CO02") as? AMLDefDevice {
            let sta = com3.status()
            XCTAssertNotNil(sta)
        } else {
            XCTFail("Cant find \\_SB.PIC0.ISA.SIO.CO02")
        }
*/
        // Check DefProcessor
        if let cpu = acpi.globalObjects.get("\\_SB.CP01") {
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(cpu.fullname()))
            let id = (cpu.childNode(named: "CPID")?.readValue(context: &context) as? AMLDataObject)
            XCTAssertEqual(id?.integerValue, 1)
        } else {
            XCTFail("Cant find \\_SB.CP01")
        }

        FakePhysMemory.addPhysicalMemory(start: PhysAddress(0x0ff76040), size: 136)
        FakePhysMemory.addPhysicalMemory(start: PhysAddress(0x20ddd432), size: 4)
        FakePhysMemory.addPhysicalMemory(start: PhysAddress(0x075e3d22), size: 4)
        FakePhysMemory.addPhysicalMemory(start: PhysAddress(0x07ddd432), size: 4)
        FakePhysMemory.addPhysicalMemory(start: PhysAddress(0x00000002), size: 4)
        let scrsMethod = "\\_SB.PCI0.ISA.SCRS"
        if let scrs = try ACPI.invoke(method: scrsMethod, AMLIntegerData(2)) {
            guard let obj = scrs as? AMLDataObject, case .buffer(_) = obj else {
                XCTFail("\(scrsMethod) did not return a buffer")
                throw AMLError.invalidData(reason: "Not a buffer")
            }
        } else {
            XCTFail("Could not execute \(scrsMethod)")
        }

        let com3sMethod = "\\_SB.PCI0.ISA.COM3._CRS"
        if let com3crs = try ACPI.invoke(method: com3sMethod) {
            guard let obj = com3crs as? AMLDataObject, case .buffer(_) = obj else {
                XCTFail("\(com3sMethod) did not return a buffer")
                throw AMLError.invalidData(reason: "Not a buffer")
            }
        } else {
            XCTFail("Could not execute \(com3sMethod)")
        }
    }
}
