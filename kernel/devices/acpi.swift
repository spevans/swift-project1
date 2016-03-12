/*
 * kernel/devices/acpi.swift
 *
 * Created by Simon Evans on 24/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * ACPI
 *
 */

typealias ScanArea = UnsafeBufferPointer<UInt8>
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
        length = ptr.memory.length
        revision = ptr.memory.revision
        checksum = ptr.memory.checksum
        oemId = makeString(stringPtr.advancedBy(10), maxLength: 6)
        oemTableId = makeString(stringPtr.advancedBy(16), maxLength: 8)
        oemRev = ptr.memory.oem_revision
        creatorId = makeString(stringPtr.advancedBy(28), maxLength: 4)
        creatorRev = ptr.memory.creator_rev
    }
}


public struct RSDP1: CustomStringConvertible {
    let signature: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    let checksum:  UInt8
    let oemId:     (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    let revision:  UInt8
    let rsdtAddr:  UInt32

    var signatureStr: String { return makeString(signature) }
    var oemIdStr:     String { return makeString(oemId) }
    var rsdt:         UInt { return UInt(rsdtAddr) }

    public var description: String {
        return String.sprintf("ACPI: \(signatureStr): \(oemIdStr): rev: \(revision) ptr: %p", rsdt)
    }
}


public struct RSDP2: CustomStringConvertible {
    let signature: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    let checksum:  UInt8
    let oemId:     (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    let revision:  UInt8
    let rsdtAddr:  UInt32
    let length:    UInt32
    let xsdtAddr:  UInt64
    let checksum2: UInt8
    let reserved:  (UInt8, UInt8, UInt8)

    var signatureStr: String { return makeString(signature) }
    var oemIdStr:     String { return makeString(oemId) }
    var rsdt:         UInt { return (xsdtAddr != 0) ? UInt(xsdtAddr) : UInt(rsdtAddr) }

    public var description: String {
        return String.sprintf("ACPI: \(signatureStr): \(oemIdStr): rev: \(revision) ptr: %p", rsdt)
    }
}


private func makeString(ptr: UnsafePointer<Void>, maxLength: Int) -> String {
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


private func makeString(data: Any) -> String {
    var str = ""
    for child in Mirror(reflecting: data).children {
        print("str: \(str)")
        let ch = child.value as! UInt8
        if (ch != 0) {
            str += String(Character(UnicodeScalar(ch)))
        }
    }

    return str
}


struct ACPI {

    private(set) var mcfg: MCFG?
    private(set) var facp: FACP?


    init?(rsdp: UnsafePointer<RSDP1>) {

        let rsdtPtr = findRSDT(rsdp)

        guard let entries = sdtEntries32(rsdtPtr) else {
            print("ACPI: Cant find any entries")
            return nil
        }

        for entry in entries {
            let ptr = mkSDTPtr(UInt(entry))
            let header = ACPI_SDT(ptr: ptr)
            guard checksum(UnsafePointer<UInt8>(ptr), size: Int(ptr.memory.length)) == 0 else {
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


    private func checksum(ptr: UnsafePointer<UInt8>, size: Int) -> UInt8 {
        let region = UnsafeBufferPointer<UInt8>(start: ptr, count: size)
        var csum: UInt8 = 0
        for x in region {
            csum = csum &+ x
        }

        return csum
    }


    private func mkSDTPtr(address: UInt) -> SDTPtr {
        return SDTPtr(bitPattern: vaddrFromPaddr(address))
    }


    private func sdtEntries32(ptr: SDTPtr) -> UnsafeBufferPointer<UInt32>? {
        let entryCount = (Int(ptr.memory.length) - strideof(acpi_sdt_header)) / sizeof(UInt32)
        if entryCount > 0 {
            let entryPtr: UnsafePointer<UInt32> = UnsafePointer(bitPattern: ptr.advancedBy(1).address)
            return UnsafeBufferPointer(start: entryPtr, count: entryCount)
        } else {
            return nil
        }
    }


    private func findRSDT(rsdpPtr: UnsafePointer<RSDP1>) -> SDTPtr {
        var rsdtAddr: UInt = 0
        if rsdpPtr.memory.revision == 1 {
            let rsdp2Ptr = UnsafePointer<RSDP2>(rsdpPtr)
            rsdtAddr = rsdp2Ptr.memory.rsdt
            //let csum = checksum(UnsafePointer<UInt8>(rsdp2Ptr), size: strideof(RSDP2))
        } else {
            rsdtAddr = ptrFromPhysicalPtr(rsdpPtr).memory.rsdt
            rsdtAddr = rsdpPtr.memory.rsdt
            //let csum = checksum(UnsafePointer<UInt8>(rsdpPtr), size: strideof(RSDP1))
            }
        return mkSDTPtr(rsdtAddr)
    }
}
