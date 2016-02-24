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
typealias SDTPtr = UnsafePointer<ACPI_SDT>

// Singleton that will be initialised by ACPI.parse()
private let acpiTables = ACPI.parseTables()


protocol ACPITable {
    var header: ACPI_SDT { get }

}

public struct ACPI_SDT: CustomStringConvertible {
    let signature:  (UInt8, UInt8, UInt8, UInt8)
    let length:     UInt32
    let revision:   UInt8
    let checksum:   UInt8
    let oemId:      (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    let oemTableId: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    let oemRev:     UInt32
    let creatorId:  (UInt8, UInt8, UInt8, UInt8)
    let creatorRev: UInt32

    var signatureStr:  String { return makeString(signature)  }
    var oemIdStr:      String { return makeString(oemId)      }
    var creatorIdStr:  String { return makeString(creatorId)  }
    var oemTableIdStr: String { return makeString(oemTableId) }

    public var description: String {
        return "ACPI: \(signatureStr): \(oemIdStr): \(creatorIdStr): \(oemTableIdStr): rev: \(revision)"
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


public struct MCFG: ACPITable {
    struct ConfigBaseAddress: CustomStringConvertible {
        let baseAddress: UInt64
        let segmentGroup: UInt16
        let startBus: UInt8
        let endBus: UInt8
        let reserved: UInt32

        var description: String {
            return String.sprintf("MCFG: base:%p segment: %u start:%u end: %u", baseAddress, segmentGroup,
                startBus, endBus)
        }
    }


    let header: ACPI_SDT
    let reserved: UInt64 = 0
    let allocations: [ConfigBaseAddress]


    init(ptr: SDTPtr) {
        header = ptr.memory
        let headerSize = strideof(ACPI_SDT) + sizeof(UInt64) // 8 is for reserved bytes
        let itemLen = Int(header.length) - headerSize
        let itemCnt = itemLen / strideof(ConfigBaseAddress)
        var items:[ConfigBaseAddress] = []
        let dataPtr: UnsafePointer<ConfigBaseAddress> = ptr.advancedBy(bytes: headerSize)
        let dataBuffer = UnsafeBufferPointer(start: dataPtr, count: itemCnt)

        for idx in 0..<itemCnt {
            items.append(dataBuffer[idx])
            print("ACPI: MCFG: \(dataBuffer[idx])")
        }
        allocations = items
    }
}


private func makeString(data: Any) -> String {
     var str = ""
   for child in Mirror(reflecting: data).children {
       let ch = child.value as! UInt8
        if (ch != 0) {
            str += String(Character(UnicodeScalar(ch)))
        }
    }
    return str
}


struct ACPI {

    static func parse() {
        printf("ACPI: Found %d ACPI tables\n", acpiTables.count)
    }


    static func findTable(sig: String) -> ACPITable? {
        for table in acpiTables {
            if table.header.signatureStr == sig {
                return table
            }
        }

        return nil
    }


    static private func parseTables() -> [ACPITable] {
        var result: [ACPITable] = []

        guard let rsdtPtr = findRSDT() else {
            print("ACPI: Cant find RSDT")
            return result
        }

        guard let entries = sdtEntries32(rsdtPtr) else {
            print("ACPI: Cant find any entries")
            return result
        }

        for entry in entries {
            let ptr = mkSDTPtr(entry)

            guard checksum(UnsafePointer<UInt8>(ptr), size: Int(ptr.memory.length)) == 0 else {
                printf("ACPI: Entry @ %p has bad chksum\n", ptr)
                continue
            }

            let sig = ptr.memory.signatureStr
            switch sig {

            case "MCFG":
                let mcfg = MCFG(ptr: ptr)
                result.append(mcfg)

            default:
                print("ACPI: Unknown table type: \(sig)")
            }
        }

        return result
    }


    static private func checksum(ptr: UnsafePointer<UInt8>, size: Int) -> UInt8 {
        let region = UnsafeBufferPointer<UInt8>(start: ptr, count: size)
        var csum: UInt8 = 0
        for x in region {
            csum = csum &+ x
        }

        return csum
    }


    static private func mkSDTPtr(address: UInt) -> SDTPtr {
        return SDTPtr(bitPattern: vaddrFromPaddr(address))
    }


    static private func mkSDTPtr(address: UInt32) -> SDTPtr {
        return SDTPtr(bitPattern: vaddrFromPaddr(UInt(address)))
    }


    static private func mkSDTPtr(address: UInt64) -> SDTPtr {
        return SDTPtr(bitPattern: vaddrFromPaddr(UInt(address)))
    }


    static private func sdtEntries32(ptr: SDTPtr) -> UnsafeBufferPointer<UInt32>? {
        let entryCount = (Int(ptr.memory.length) - strideof(ACPI_SDT)) / sizeof(UInt32)
        if entryCount > 0 {
            let entryPtr: UnsafePointer<UInt32> = UnsafePointer(bitPattern: ptr.advancedBy(1).ptrToUint)
            return UnsafeBufferPointer(start: entryPtr, count: entryCount)
        } else {
            return nil
        }
    }


    static private func findRSDT() -> SDTPtr? {
        if let rsdpPtr = BootParams.findRSDP() {
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

        return nil;
    }
}
