/*
 * kernel/devices/acpi/acpi.swift
 *
 * Created by Simon Evans on 24/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * ACPI
 *
 */

typealias SDTPtr = UnsafePointer<acpi_sdt_header>


enum ACPITable {
    case madt(MADT)
    case mcfg(MCFG)
    case boot(BOOT)
    case ecdt(ECDT)
    case facp(FACP)
    case facs(FACS)
    case hpet(HPETTable)
    case sbst(SBST)
    case srat(SRAT)
    case waet(WAET)
}


struct ACPI_SDT: CustomStringConvertible {
    let signature:  String
    let length:     UInt32
    let revision:   UInt8
    let checksum:   UInt8
    let oemId:      String
    let oemTableId: String
    let oemRev:     UInt32
    let creatorId:  String
    let creatorRev: UInt32

    var description: String {
        return "ACPI: \(signature): \(oemId): \(creatorId): \(oemTableId): rev: \(revision)"
    }


    init(ptr: UnsafeRawPointer) {
        signature = String(ptr, maxLength: 4)
        let header = ptr.load(as: acpi_sdt_header.self)
        length = header.length
        revision = header.revision
        checksum = header.checksum
        oemId = String(ptr.advanced(by: 10), maxLength: 6)
        oemTableId = String(ptr.advanced(by: 16), maxLength: 8)
        oemRev = header.oem_revision
        creatorId = String(ptr.advanced(by: 28), maxLength: 4)
        creatorRev = header.creator_rev
    }
}


final class ACPI {


    struct RSDT {
        let entries: [PhysAddress]

        init(_ physAddress: PhysAddress) {
            let headerSize = MemoryLayout<acpi_sdt_header>.size
            let region = PhysRegion(start: physAddress, size: UInt(headerSize))
            var mmioRegion = mapRORegion(region: region)
            defer { unmapMMIORegion(mmioRegion) }
            let subRegion = mmioRegion.mmioSubRegion(containing: physAddress, count: headerSize)!
            let rawPtr = subRegion.baseAddress.rawPointer
            guard let table = ACPI.validateHeader(rawSDTPtr: rawPtr), table.signature == "RSDT" else {
                fatalError("Invalid RSDT table")
            }

            let newRegion = PhysRegion(start: physAddress, size: UInt(table.length))
            mmioRegion = mmioRegion.including(region: newRegion)

            let entryCount = (Int(table.length) - MemoryLayout<acpi_sdt_header>.size) / 4
            let buffer = UnsafeBufferPointer(start: rawPtr.advanced(by: MemoryLayout<acpi_sdt_header>.size)
                .bindMemory(to: UInt32.self, capacity: entryCount), count: entryCount)
            entries = buffer.map { PhysAddress(RawAddress($0)) }
        }
    }


    struct XSDT {
        let entries: [PhysAddress]

        init(_ physAddress: PhysAddress) {
            let headerSize = MemoryLayout<acpi_sdt_header>.size
            let region = PhysRegion(start: physAddress, size: UInt(headerSize))
            var mmioRegion = mapRORegion(region: region)
            defer { unmapMMIORegion(mmioRegion) }
            let subRegion = mmioRegion.mmioSubRegion(containing: physAddress, count: headerSize)!

            let rawPtr = subRegion.baseAddress.rawPointer
            guard let table = ACPI.validateHeader(rawSDTPtr: rawPtr), table.signature == "XSDT" else {
                fatalError("Invalid XSDT table")
            }
            let newRegion = PhysRegion(start: physAddress, size: UInt(table.length))
            mmioRegion = mmioRegion.including(region: newRegion)

            let entryCount = (Int(table.length) - MemoryLayout<acpi_sdt_header>.size) / 8
            let buffer = UnsafeBufferPointer(start: rawPtr.advanced(by: MemoryLayout<acpi_sdt_header>.size)
                .bindMemory(to: UInt64.self, capacity: entryCount), count: entryCount)
            entries = buffer.map { PhysAddress(RawAddress($0)) }
        }
    }


    struct RSDP {
        let revision: Int
        let rsdtAddress: UInt32
        let xsdtAddress: UInt64

        init(_ physAddress: PhysAddress) {
            let headerSize = UInt(MemoryLayout<rsdp1_header>.size)
            let region = PhysRegion(start: physAddress, size: headerSize)
            var mmioRegion = mapRORegion(region: region)
            defer { unmapMMIORegion(mmioRegion) }
            let subRegion = mmioRegion.mmioSubRegion(containing: physAddress, count: Int(headerSize))!
            let rawPtr = subRegion.baseAddress.rawPointer
            let sig = String(rawPtr, maxLength: 8)
            guard sig == "RSD PTR " else {
                fatalError("findRSRT invalid sig")
            }

            let rsdp1 = rawPtr.load(as: rsdp1_header.self)
            revision = Int(rsdp1.revision)
            if rsdp1.revision == 2 {
                // ACPI 2.0 RSDP
                let headerSize = UInt(MemoryLayout<rsdp2_header>.size)
                let region = PhysRegion(start: physAddress, size: headerSize)
                mmioRegion = mmioRegion.including(region: region)
                let rsdp2 = rawPtr.load(as: rsdp2_header.self)
                rsdtAddress = rsdp2.rsdp1.rsdt_addr
                xsdtAddress = rsdp2.xsdt_addr
            } else {
                rsdtAddress = rsdp1.rsdt_addr
                xsdtAddress = 0
                //let csum = checksum(UnsafePointer<UInt8>(rsdpPtr),
                //size: strideof(RSDP1))
            }
        }

        func rsdt() -> RSDT? {
            guard rsdtAddress != 0 else { return nil }
            return RSDT(PhysAddress(RawAddress(rsdtAddress)))
        }

        func xsdt() -> XSDT? {
            guard xsdtAddress != 0 else { return nil }
            return XSDT(PhysAddress(RawAddress(xsdtAddress)))
        }
    }

    static private(set) var globalObjects: ACPIObjectNode = ACPIObjectNode(name: AMLNameString("\\"),
                                                                           object: AMLObject())
    static var methodArgumentCount: [AMLNameString: Int] = [:]


    private(set) var mcfg: MCFG?
    private(set) var facp: FACP?
    private(set) var madt: MADT?
    private(set) var hpet: HPETTable?
    private(set) var tables: [ACPITable] = []
    private var dsdt: PhysRegion?
    private var ssdts: [PhysRegion] = []
    private var mmioRegions: [MMIORegion] = []

    init?(rsdp: PhysAddress, vendor: String, product: String, memoryRanges: [MemoryRange]) {
        let rsdp = RSDP(rsdp)
        guard let entries = rsdp.xsdt()?.entries ?? rsdp.rsdt()?.entries else {
            #kprint("Cant find a XSDT or RSDT")
            return nil
        }

        guard !entries.isEmpty else {
            #kprint("Cant find any ACPI tables")
            return nil
        }

        var mRanges: [MemoryRange] = []
        // Ensure each table phys address is covered by an MMIORegion
        for entry in entries {
            guard let memoryRange = memoryRanges.findRange(containing: entry) else {
                #kprint("Cant find MemoryRange containing:", entry)
                return nil
            }
            if !mRanges.contains(memoryRange) {
                mRanges.append(memoryRange)
                #kprint("ACPI: using range:", memoryRange)
                let region = PhysRegion(start: memoryRange.start, size: memoryRange.size)
                let mmioRegion = mapRORegion(region: region)
                mmioRegions.append(mmioRegion)
            }
            parseEntry(physAddress: entry, vendor: vendor, product: product)
        }

        if dsdt == nil, let dsdtAddr = facp?.dsdtAddress {
            #kprint("Found DSDT address in FACP: 0x\(asHex(dsdtAddr.value))")
            parseEntry(physAddress: dsdtAddr, vendor: vendor, product: product)
        }
    }

#if TEST
    // Used for testing
    init() {
        mmioRegions.append(MMIORegion(PhysRegion(start: PhysAddress(0), size: 1)))
    }
#endif

    func parseAMLTables(allowNoDsdt: Bool = false) {
//                #kprintf("Parsing AML")
        if let ptr = dsdt {
            ssdts.insert(ptr, at: 0) // Put the DSDT first
        } else {
            guard allowNoDsdt else {
                fatalError("ACPI: No valid DSDT found")
            }
        }

        ACPI.globalObjects = ACPI.ACPIObjectNode.createGlobalObjects()
        do {
            for buffer in ssdts {
                let amlBuffer = AMLByteBuffer(start: buffer.baseAddress.rawPointer,
                                              count: Int(buffer.size))
                let byteStream = try AMLByteStream(buffer: amlBuffer)
                let scope = AMLNameString("\\")
                let parser = AMLParser(byteStream: byteStream, scope: scope,
                                       globalObjects: ACPI.globalObjects, parsingMethod: true)
                let method = AMLMethod(name: scope, flags: AMLMethodFlags(flags: 0), parser: parser)
                var context = ACPI.AMLExecutionContext(scope: scope, args: [], isTopLevel: true)
                try method.execute(context: &context)
                continue
            }
        } catch {
            fatalError("parseerror: \(error)")
        }

        dsdt = nil
        ssdts.removeAll()
//        #kprintf("End of AML code")
    }

    func parseEntry(physAddress: PhysAddress, vendor: String, product: String) {

        let rawSDTPtr = physAddress.rawPointer
        let signature = tableSignature(ptr: rawSDTPtr)
        if signature == "FACS" {
            let facs = FACS(rawSDTPtr)
            tables.append(.facs(facs))
            return
        }

        guard let header = ACPI.validateHeader(rawSDTPtr: rawSDTPtr) else {
            #kprint("Header for \(signature) failed to validate")
            return
        }

//        #kprintf("Found: \(signature)")
        switch signature {
        case "MCFG":
            mcfg = MCFG(rawSDTPtr, vendor: vendor, product: product)
            initPCI(mcfg: mcfg)
            tables.append(.mcfg(mcfg!))
            for entry in mcfg!.allocations {
                #kprint("MCFG:", entry)
            }

        case "FACP":
            facp = FACP(rawSDTPtr)
            if let _facp = facp {
                #kprint(_facp)
                tables.append(.facp(_facp))
            }

        case "APIC":
            madt = MADT(rawSDTPtr)
            tables.append(.madt(madt!))

        case "HPET":
            hpet = HPETTable(rawSDTPtr)
            tables.append(.hpet(hpet!))

        case "ECDT":
            let table = ECDT(rawSDTPtr)
            tables.append(.ecdt(table))

        case "SBST":
            let table = SBST(rawSDTPtr)
            tables.append(.sbst(table))

        case "SRAT":
            let table = SRAT(rawSDTPtr)
            tables.append(.srat(table))

        case "WAET":
            let table = WAET(rawSDTPtr)
            tables.append(.waet(table))

        case "BOOT":
            let table = BOOT(rawSDTPtr)
            tables.append(.boot(table))


        case "DSDT", "SSDT":
            let headerLength = MemoryLayout<acpi_sdt_header>.size
            let totalLength = Int(header.length)
            let amlCodeLength = totalLength - headerLength
            let amlRegion = PhysRegion(start: physAddress + headerLength,
                                              size: UInt(amlCodeLength))
            if header.signature == "DSDT" {
                dsdt = amlRegion
            } else {
                ssdts.append(amlRegion)
            }

        default:
            #kprint("ACPI: Unknown table: \(header.signature)")
        }
    }


    private func tableSignature(ptr: UnsafeRawPointer) -> String {
        var signature = ""
        for idx in 0...3 {
            let byte = ptr.load(fromByteOffset: idx, as: UInt8.self)
            signature += String(UnicodeScalar(byte))
        }
        return signature
    }


    static private func validateHeader(rawSDTPtr: UnsafeRawPointer) -> ACPI_SDT? {
        let headerLength = MemoryLayout<acpi_sdt_header>.size
        let header = ACPI_SDT(ptr: rawSDTPtr)
        let totalLength = Int(header.length)

        guard totalLength > headerLength else {
            #kprint("ACPI: Entry @ 0x\(asHex(rawSDTPtr.address)) has total length of \(totalLength)")
            return nil
        }
        guard checksum(rawSDTPtr, size: Int(header.length)) == 0 else {
            #kprint("ACPI: \(header.signature) has bad chksum")
            return nil
        }
        return header
    }


    static private func checksum(_ rawPtr: UnsafeRawPointer, size: Int) -> UInt8 {
        let region = UnsafeRawBufferPointer(start: rawPtr, count: size)
        var csum: UInt8 = 0
        for x in region {
            csum = csum &+ x
        }

        return csum
    }
}

extension ACPI {
    func startup() {

        func runMethod(_ node: ACPIObjectNode) -> Bool {
            #kprint("ACPI: Running:", node.fullname())
            guard let method = node.object.methodValue else {
                #kprint(node.fullname(), " is not an _INI method")
                return false
            }
            do {
                #kprint("ACPI: calling", node.fullname())
                var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()))
                try method.execute(context: &context)
                return true
            } catch {
                let str = error.description
                #kprint("ACPI: Error running \(node.name) for", node.fullname(), str)
            }
            return true
        }

        func devStatus(_ parent: ACPIObjectNode?) throws(AMLError) -> AMLDefDevice.DeviceStatus {
            if let sta = parent?.childNode(named: "_STA") {
                var context = ACPI.AMLExecutionContext(scope: AMLNameString(sta.fullname()))
                let result = try sta.readValue(context: &context)
                return AMLDefDevice.DeviceStatus(result.integerValue!)
            } else {
                return .defaultStatus()
            }
        }

        // Find _INI for ACPI devices and run if necessary
        ACPI.globalObjects.findNodes(name: AMLNameString("_INI")) { (fullname, node) in
            // Evaluate _STA if present
            guard let status = try? devStatus(node.parent) else {
                #kprint("ACPI: Can not get _STA status for \(node.fullname())")
                return false
            }
            if status.present {
                // Dont walk child nodes if _INI does not execute OK.
                guard runMethod(node) else { return false }
            }

            if !status.present || !status.enabled {
                // Dont walk child nodes if device not present or not enabled
                return false
            } else {
                return true
            }
        }

        #kprint("ACPI: Finding devices")
        // Keep track of the devices allocated to each node so that the parent device
        // can be determined
        var nameDeviceMap = [ "\\_SB" : system.deviceManager.masterBus.device]
        ACPI.globalObjects.walkNode { (name, node) in
            guard node.object.isDevice else { return true }
            guard node.device == nil else { fatalError("\(name) already has a .device set") }
            guard let status = try? devStatus(node) else {
                #kprint("ACPI: Can not get _STA status for \(name)")
                return false
            }

            if !status.present {
                #kprint("ACPI: Ignoring not present device \(name)")
                return false
            }

            var parentDevice: Device? = nil
            var parent = node.parent
            while let p = parent {
                if let device = nameDeviceMap[p.fullname()] {
                    parentDevice = device
                    break
                }
                parent = p.parent
            }
            if parentDevice == nil { fatalError("Reached top of tree! for \(node.fullname())")}

            let config = ACPIDeviceConfig(node: node)
            let device = Device(parent: parentDevice, acpiDeviceConfig: config)
            node.setDevice(device)
            nameDeviceMap[name] = device
            #if true
            _ = PNPDevice(device: device, acpiDeviceConfig: config)
            #endif
            return true
        }
        #kprint("ACPI: Found all devices")
    }
}
