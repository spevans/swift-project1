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
    case hpet(HPET)
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


    private(set) var mcfg: MCFG?
    private(set) var facp: FACP?
    private(set) var madt: MADT?
    private(set) var hpet: HPET?
    private(set) var globalObjects: ACPIObjectNode!
    private(set) var tables: [ACPITable] = []
    private var dsdt: PhysRegion?
    private var ssdts: [PhysRegion] = []
    private var mmioRegions: [MMIORegion] = []

    init?(rsdp: PhysAddress, vendor: String, product: String, memoryRanges: [MemoryRange]) {
        let rsdp = RSDP(rsdp)
        guard let entries = rsdp.xsdt()?.entries ?? rsdp.rsdt()?.entries else {
            print("Cant find a XSDT or RSDT")
            return nil
        }

        guard !entries.isEmpty else {
            print("Cant find any ACPI tables")
            return nil
        }

        var mRanges: [MemoryRange] = []
        // Ensure each table phys address is covered by an MMIORegion
        for entry in entries {
            guard let memoryRange = memoryRanges.findRange(containing: entry) else {
                print("Cant find MemoryRange containing:", entry)
                return nil
            }
            if !mRanges.contains(memoryRange) {
                mRanges.append(memoryRange)
                print("ACPI: using range:", memoryRange)
                let region = PhysRegion(start: memoryRange.start, size: memoryRange.size)
                let mmioRegion = mapRORegion(region: region)
                mmioRegions.append(mmioRegion)
            }
            parseEntry(physAddress: entry, vendor: vendor, product: product)
        }

        if dsdt == nil, let dsdtAddr = facp?.dsdtAddress {
            print("Found DSDT address in FACP: 0x\(asHex(dsdtAddr.value))")
            parseEntry(physAddress: dsdtAddr, vendor: vendor, product: product)
        }
    }

#if TEST
    // Used for testing
    init() {
        mmioRegions.append(MMIORegion(region: PhysRegion(start: PhysAddress(0), size: 1)))
    }
#endif

    func parseAMLTables() {
        print("Parsing AML")
        guard let ptr = dsdt else {
            fatalError("ACPI: No valid DSDT found")
        }
        ssdts.insert(ptr, at: 0) // Put the DSDT first

        let acpiGlobalObjects = ACPI.ACPIObjectNode.createGlobalObjects()
        let parser = AMLParser(globalObjects: acpiGlobalObjects)
        do {
            for buffer in ssdts {
                let amlBuffer = AMLByteBuffer(start: buffer.baseAddress.rawPointer,
                                              count: Int(buffer.size))
                try parser.parse(amlCode: amlBuffer)
            }
        } catch {
            fatalError("parseerror: \(error)")
        }

        dsdt = nil
        ssdts.removeAll()
        //parser.parseMethods()
        globalObjects = parser.acpiGlobalObjects
        print("End of AML code")
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
            print("Header for \(signature) failed to validate")
            return
        }

        print("Found: \(signature)")
        switch signature {
        case "MCFG":
            mcfg = MCFG(rawSDTPtr, vendor: vendor, product: product)
            tables.append(.mcfg(mcfg!))
            for entry in mcfg!.allocations {
                print("MCFG:", entry)
            }

        case "FACP":
            facp = FACP(rawSDTPtr)
            if let _facp = facp {
                print(_facp)
                tables.append(.facp(_facp))
            }

        case "APIC":
            madt = MADT(rawSDTPtr)
            tables.append(.madt(madt!))

        case "HPET":
            hpet = HPET(rawSDTPtr)
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
            print("ACPI: Unknown table: \(header.signature)")
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
            print("ACPI: Entry @ 0x\(asHex(rawSDTPtr.address)) has total length of \(totalLength)")
            return nil
        }
        guard checksum(rawSDTPtr, size: Int(header.length)) == 0 else {
            print("ACPI: \(header.signature) has bad chksum")
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
