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


protocol ACPITable {
}

extension ACPITable {
    func physicalAddress(xAddr: UInt64, addr: UInt32) -> PhysAddress? {
        if xAddr != 0 {
            return PhysAddress(RawAddress(xAddr))
        } else if addr != 0 {
            return PhysAddress(RawAddress(addr))
        } else {
            return nil
        }
    }
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


    init(ptr: UnsafePointer<acpi_sdt_header>) {
        signature = String(ptr, maxLength: 4)
        length = ptr.pointee.length
        revision = ptr.pointee.revision
        checksum = ptr.pointee.checksum
        oemId = String(ptr.advanced(by: 10), maxLength: 6)
        oemTableId = String(ptr.advanced(by: 16), maxLength: 8)
        oemRev = ptr.pointee.oem_revision
        creatorId = String(ptr.advanced(by: 28), maxLength: 4)
        creatorRev = ptr.pointee.creator_rev
    }
}


struct RSDP1: CustomStringConvertible {
    let signature: String
    let checksum:  UInt8
    let oemId:     String
    let revision:  UInt8
    let rsdtAddr:  UInt32
    var rsdt:      UInt { return UInt(rsdtAddr) }

    var description: String {
        return "ACPI: \(signature): \(oemId): rev: \(revision) "
            + "ptr: \(asHex(rsdt))"
    }


    init(ptr: UnsafePointer<rsdp1_header>) {
        signature = String(ptr, maxLength: 8)
        checksum = ptr.pointee.checksum
        oemId = String(ptr.advanced(by: 9), maxLength: 6)
        revision = ptr.pointee.revision
        rsdtAddr = ptr.pointee.rsdt_addr
    }
}


struct RSDP2: CustomStringConvertible {
    let signature: String
    let checksum:  UInt8
    let oemId:     String
    let revision:  UInt8
    let rsdtAddr:  UInt32
    let length:    UInt32
    let xsdtAddr:  UInt64
    let checksum2: UInt8
    var rsdt:      UInt {
        return (xsdtAddr != 0) ? UInt(xsdtAddr) : UInt(rsdtAddr)
    }

    var description: String {
        return "ACPI: \(signature): \(oemId): rev: \(revision) "
            + "ptr: \(asHex(rsdt))"
    }


    init(ptr: UnsafePointer<rsdp2_header>) {
        signature = String(ptr, maxLength: 8)
        checksum = ptr.pointee.rsdp1.checksum
        oemId = String(ptr.advanced(by: 9), maxLength: 6)
        revision = ptr.pointee.rsdp1.revision
        rsdtAddr = ptr.pointee.rsdp1.rsdt_addr
        length = ptr.pointee.length
        xsdtAddr = ptr.pointee.xsdt_addr
        checksum2 = ptr.pointee.checksum
    }
}


struct ACPI {
    private(set) var mcfg: MCFG?
    private(set) var facp: FACP?
    private(set) var madt: MADT?
    private(set) var tables: [ACPITable] = []


    init?(rsdp: UnsafeRawPointer, vendor: String, product: String) {
        let rsdtPtr = findRSDT(rsdp)
        guard let entries = sdtEntries32(rsdtPtr) else {
            print("ACPI: Cant find any entries")
            return nil
        }

        for entry in entries {
            let rawSDTPtr = mkSDTPtr(PhysAddress(RawAddress(entry)))
            parseEntry(rawSDTPtr: rawSDTPtr, vendor: vendor, product: product)
        }
    }


    // Used for testing
    init() {
    }


    mutating func parseEntry(rawSDTPtr: UnsafeRawPointer, vendor: String,
        product: String) {

        let signature = tableSignature(ptr: rawSDTPtr)
        if signature == "FACS" {
            let facs = FACS(rawSDTPtr)
            tables.append(facs)
            return
        }


        guard let header = validateHeader(rawSDTPtr: rawSDTPtr) else {
            return
        }

        print("ACPI: Found: \(signature)")
        switch signature {
        case "MCFG":
            mcfg = MCFG(rawSDTPtr, vendor: vendor, product: product)
            tables.append(mcfg!)

        case "FACP":
            facp = FACP(rawSDTPtr)
            tables.append(facp!)

        case "APIC":
            madt = MADT(rawSDTPtr)
            tables.append(madt!)

        case "HPET":
            let table = HPET(rawSDTPtr)
            tables.append(table)

        case "ECDT":
            let table = ECDT(rawSDTPtr)
            tables.append(table)

        case "SBST":
            let table = SBST(rawSDTPtr)
            tables.append(table)

        case "SRAT":
            let table = SRAT(rawSDTPtr)
            tables.append(table)

        case "WAET":
            let table = WAET(rawSDTPtr)
            tables.append(table)

        case "BOOT":
            let table = BOOT(rawSDTPtr)
            tables.append(table)

        default:
            print("ACPI: Unknown table: \(header.signature)")
        }
    }


    private func tableSignature(ptr: UnsafeRawPointer) -> String {
        let table = ptr.bindMemory(to: UInt8.self, capacity: 4)
        var signature = ""
        for idx in 0...3 {
            let byte: UInt8 = table.advancedBy(bytes: idx).pointee
            let ch = UnicodeScalar(byte)
            ch.write(to: &signature)
        }
        return signature
    }


    private func validateHeader(rawSDTPtr: UnsafeRawPointer) -> ACPI_SDT? {
        let headerLength = MemoryLayout<acpi_sdt_header>.size
        let ptr = rawSDTPtr.bindMemory(to: acpi_sdt_header.self,
                                       capacity: 1)
        let header = ACPI_SDT(ptr: ptr)
        let totalLength = Int(header.length)

        guard totalLength > headerLength else {
            printf("ACPI: Entry @ %p has total length of %u", rawSDTPtr.address,
                totalLength)
            return nil
        }
        guard checksum(ptr, size: Int(ptr.pointee.length)) == 0 else {
            print("ACPI: \(header.signature) has bad chksum")
            return nil
        }
        return header
    }


    private func checksum(_ rawPtr: UnsafeRawPointer, size: Int) -> UInt8 {
        let ptr = rawPtr.bindMemory(to: UInt8.self, capacity: size)
        let region = UnsafeBufferPointer(start: ptr, count: size)
        var csum: UInt8 = 0
        for x in region {
            csum = csum &+ x
        }

        return csum
    }


    private func mkSDTPtr(_ address: PhysAddress) -> UnsafeRawPointer {
        return UnsafeRawPointer(bitPattern: address.vaddr)!
    }


    private func sdtEntries32(_ rawPtr: UnsafeRawPointer)
        -> UnsafeBufferPointer<UInt32>? {
        let ptr = rawPtr.bindMemory(to: acpi_sdt_header.self, capacity: 1)
        let tableSz = MemoryLayout<acpi_sdt_header>.stride
        let entrySz = MemoryLayout<UInt32>.size
        let entryCount = (Int(ptr.pointee.length) - tableSz) / entrySz

        if entryCount > 0 {
            let entryPtr: UnsafePointer<UInt32> =
                UnsafePointer(bitPattern: ptr.advanced(by: 1).address)!
            return UnsafeBufferPointer(start: entryPtr, count: entryCount)
        } else {
            return nil
        }
    }


    private func findRSDT(_ rawPtr: UnsafeRawPointer) -> UnsafeRawPointer {
        var rsdtAddr = RawAddress(0)

        let rsdpPtr = rawPtr.bindMemory(to: rsdp1_header.self, capacity: 1)

        if rsdpPtr.pointee.revision == 1 {
            let rsdp2Ptr = rawPtr.bindMemory(to: rsdp2_header.self, capacity: 1)
            rsdtAddr = RawAddress(rsdp2Ptr.pointee.xsdt_addr)
            if rsdtAddr == 0 {
                rsdtAddr = RawAddress(rsdp2Ptr.pointee.rsdp1.rsdt_addr)
            }
            //let csum = checksum(UnsafePointer<UInt8>(rsdp2Ptr),
            // size: strideof(RSDP2))
        } else {
            rsdtAddr = RawAddress(rsdpPtr.pointee.rsdt_addr)
            //let csum = checksum(UnsafePointer<UInt8>(rsdpPtr),
            //size: strideof(RSDP1))
        }
        return mkSDTPtr(PhysAddress(rsdtAddr))
    }
}
