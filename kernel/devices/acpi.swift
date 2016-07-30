/*
 * kernel/devices/acpi.swift
 *
 * Created by Simon Evans on 24/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * ACPI
 *
 */

typealias SDTPtr = UnsafePointer<acpi_sdt_header>


protocol ACPITable {
    var header: ACPI_SDT { get }
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
        let stringPtr = UnsafePointer<UInt8>(ptr)
        signature = makeString(stringPtr, maxLength: 4)
        length = ptr.pointee.length
        revision = ptr.pointee.revision
        checksum = ptr.pointee.checksum
        oemId = makeString(stringPtr.advancedBy(bytes: 10), maxLength: 6)
        oemTableId = makeString(stringPtr.advancedBy(bytes: 16), maxLength: 8)
        oemRev = ptr.pointee.oem_revision
        creatorId = makeString(stringPtr.advancedBy(bytes: 28), maxLength: 4)
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
        return String.sprintf("ACPI: \(signature): \(oemId): rev: \(revision) ptr: %p", rsdt)
    }


    init(ptr: UnsafePointer<rsdp1_header>) {
        let stringPtr = UnsafePointer<UInt8>(ptr)
        signature = makeString(stringPtr, maxLength: 8)
        checksum = ptr.pointee.checksum
        oemId = makeString(stringPtr.advancedBy(bytes: 9), maxLength: 6)
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
    var rsdt:      UInt { return (xsdtAddr != 0) ? UInt(xsdtAddr) : UInt(rsdtAddr) }

    var description: String {
        return String.sprintf("ACPI: \(signature): \(oemId): rev: \(revision) ptr: %p", rsdt)
    }


    init(ptr: UnsafePointer<rsdp2_header>) {
        let stringPtr = UnsafePointer<UInt8>(ptr)
        signature = makeString(stringPtr, maxLength: 8)
        checksum = ptr.pointee.rsdp1.checksum
        oemId = makeString(stringPtr.advancedBy(bytes: 9), maxLength: 6)
        revision = ptr.pointee.rsdp1.revision
        rsdtAddr = ptr.pointee.rsdp1.rsdt_addr
        length = ptr.pointee.length
        xsdtAddr = ptr.pointee.xsdt_addr
        checksum2 = ptr.pointee.checksum
    }
}


private func makeString(_ ptr: UnsafePointer<Void>, maxLength: Int) -> String {
    let buffer = UnsafeBufferPointer(start: UnsafePointer<UInt8>(ptr),
        count: maxLength)
    var str = ""

    for ch in buffer {
        if (ch != 0) {
            str += String(Character(UnicodeScalar(ch)))
        } else {
            break
        }
    }

    return str
}


struct ACPI {

    private(set) var mcfg: MCFG?
    private(set) var facp: FACP?


    init?(rsdp: UnsafePointer<rsdp1_header>) {

        let rsdtPtr = findRSDT(rsdp)

        guard let entries = sdtEntries32(rsdtPtr) else {
            print("ACPI: Cant find any entries")
            return nil
        }

        for entry in entries {
            let ptr = mkSDTPtr(UInt(entry))
            let header = ACPI_SDT(ptr: ptr)
            guard checksum(UnsafePointer<UInt8>(ptr), size: Int(ptr.pointee.length)) == 0 else {
                printf("ACPI: Entry @ %p has bad chksum\n", ptr)
                continue
            }

            switch header.signature {

            case "MCFG":
                mcfg = MCFG(acpiHeader: header, ptr: UnsafePointer<acpi_sdt_header>(ptr))
                print("ACPI: found MCFG")

            case "FACP":
                facp = FACP(acpiHeader: header, ptr: UnsafePointer<acpi_facp_table>(ptr))
                print("ACPI: found FACP")

            default:
                print("ACPI: Unknown table type: \(header.signature)")
            }
        }
    }


    func checksum(_ ptr: UnsafePointer<UInt8>, size: Int) -> UInt8 {
        let region = UnsafeBufferPointer<UInt8>(start: ptr, count: size)
        var csum: UInt8 = 0
        for x in region {
            csum = csum &+ x
        }

        return csum
    }


    private func mkSDTPtr(_ address: UInt) -> SDTPtr {
        return SDTPtr(bitPattern: vaddrFromPaddr(address))!
    }


    private func sdtEntries32(_ ptr: SDTPtr) -> UnsafeBufferPointer<UInt32>? {
        let entryCount = (Int(ptr.pointee.length) - strideof(acpi_sdt_header.self))
            / sizeof(UInt32.self)

        if entryCount > 0 {
            let entryPtr: UnsafePointer<UInt32> =
                UnsafePointer(bitPattern: ptr.advanced(by: 1).address)!
            return UnsafeBufferPointer(start: entryPtr, count: entryCount)
        } else {
            return nil
        }
    }


    private func findRSDT(_ rsdpPtr: UnsafePointer<rsdp1_header>) -> SDTPtr {
        var rsdtAddr: UInt = 0
        if rsdpPtr.pointee.revision == 1 {
            let rsdp2Ptr = UnsafePointer<rsdp2_header>(rsdpPtr)
            rsdtAddr = UInt(rsdp2Ptr.pointee.xsdt_addr)
            if rsdtAddr == 0 {
                rsdtAddr = UInt(rsdp2Ptr.pointee.rsdp1.rsdt_addr)
            }
            //let csum = checksum(UnsafePointer<UInt8>(rsdp2Ptr), size: strideof(RSDP2))
        } else {
            rsdtAddr = UInt(rsdpPtr.pointee.rsdt_addr)
            //let csum = checksum(UnsafePointer<UInt8>(rsdpPtr), size: strideof(RSDP1))
        }
        return mkSDTPtr(rsdtAddr)
    }
}
