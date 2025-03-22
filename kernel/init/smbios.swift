/*
 * kernel/init/smbios.swift
 *
 * Created by Simon Evans on 02/03/2016.
 * Copyright © 2016 - 2022 Simon Evans. All rights reserved.
 *
 * Parsing of SMBIOS tables
 */

struct SMBIOS {
    static let DMI_SIG: StaticString = "_DMI_"
    static let SMBIOS_SIG: StaticString = "_SM_"

    let major: UInt8
    let minor: UInt8
    let maxStructureSize: UInt
    let tableLength: Int
    let tableAddress: PhysAddress
    let entryCount: Int

    // DMI information to extract, allows vendor/model to be identified
    private(set) var dmiBiosVendor: String?
    private(set) var dmiBiosVersion: String?
    private(set) var dmiBiosReleaseDate: String?
    private(set) var dmiSystemVendor: String?
    private(set) var dmiProductName: String?
    private(set) var dmiProductVersion: String?
    private(set) var dmiProductSerial: String?
    private(set) var dmiProductUUID: String?
    private(set) var dmiBoardVendor: String?
    private(set) var dmiBoardName: String?
    private(set) var dmiBoardVersion: String?
    private(set) var dmiBoardSerial: String?
    private(set) var dmiChassisVendor: String?
    private(set) var dmiChassisType: String?
    private(set) var dmiChassisVersion: String?
    private(set) var dmiChassisSerial: String?


    private struct SMBiosEntry: CustomStringConvertible {
        let type: UInt8
        let length: UInt8
        let handle: UInt16
        var data: MemoryBufferReader
        let strings: [String]

        var description: String {
            return "Type: \(type) length: \(length) strings: \(strings)"
        }


        // Lookup the string ID at a given offset
        func stringByOffset(_ offset: UInt8) -> String? {
            guard offset >= 4 else {
                return nil
            }
            let index = Int(offset) - 4
            do {
                let idx: UInt8 = try data.readAtIndex(index)
                let stringId = Int(idx)
                guard stringId > 0 && stringId <= strings.count else {
                    return nil
                }
                return strings[stringId - 1]
            } catch {
                #kprint("SMBIOS: error reading id")
                return nil
            }
        }
    }


    init?(physAddress: PhysAddress) {
        let header: smbios_header

        do {
            let headerSize = MemoryLayout<smbios_header>.size
            let headerRegion = PhysRegion(start: physAddress, size: UInt(headerSize))
            let mmioRegion = mapRORegion(region: headerRegion)
            defer { unmapMMIORegion(mmioRegion) }
            let ptr = mmioRegion.baseAddress.rawPointer
            header = ptr.load(fromByteOffset: 0, as: smbios_header.self)

            let anchor = String(ptr, maxLength: 4)
            if (anchor != "_SM_") {
                #kprint("SMBIOS: anchor is \(anchor)")
                return nil
            }

            if Int(header.ep_length) != headerSize {
                #kprint("header length should be", headerSize, "but is",
                    header.ep_length)
                return nil
            }
            maxStructureSize = UInt(header.max_structure_size)
            if header.eps_revision != 0 {
                #kprintf("Unknown EPS revision: %2.2x", header.eps_revision)
                return nil
            }

            let dmi = String(ptr + 16, maxLength: 5)
            if dmi != "_DMI_" {
                #kprint("SMBIOS: DMI anchor is", dmi)
                return nil
            }
        }

        tableLength = Int(header.table_length)
        tableAddress = PhysAddress(RawAddress(header.table_address))
        // FIXME, can the mmioRegion from above be reused if the DMI region is adjcent
        // to the SMBIOS (eg qemu) rather than completely seperate (VMWare)
        let region = PhysRegion(start: tableAddress, size: UInt(tableLength))
        let mmioRegion = mapRORegion(region: region)
        defer { unmapMMIORegion(mmioRegion) }

        entryCount = Int(header.entry_count)
        if header.bcd_revision != 0 {
            major = header.bcd_revision >> 4
            minor = header.bcd_revision & 0xf
        } else {
            major = header.major_version
            minor = header.minor_version
        }

        #kprint("SMBIOS \(major).\(minor): \(entryCount) entries "
            + "@ \(tableAddress) size: \(tableLength)")

        func str(_ a: String?) -> String {
            return a ?? "nil"
        }

        for entry in parseTables() {
            switch entry.type {

            case 0:     // BIOS information
                dmiBiosVendor = entry.stringByOffset(4)
                dmiBiosVersion = entry.stringByOffset(5)
                dmiBiosReleaseDate = entry.stringByOffset(8)
                #kprint("SMBIOS: BIOS: vendor:", str(dmiBiosVendor),
                    "version:", str(dmiBiosVersion),
                    "date:", str(dmiBiosReleaseDate))

            case 1:     // System information
                dmiSystemVendor = entry.stringByOffset(4)
                dmiProductName = entry.stringByOffset(5)
                dmiProductVersion = entry.stringByOffset(6)
                dmiProductSerial = entry.stringByOffset(7)
                dmiProductUUID = entry.stringByOffset(8)
                #kprint("SMBIOS: system:", str(dmiSystemVendor))
                #kprint("SMBIOS: product:", str(dmiProductName),
                    "version:", str(dmiProductVersion),
                    "serial:", str(dmiProductSerial),
                    "uuid:", str(dmiProductUUID))

            case 2:     // Base board information
                dmiBoardVendor = entry.stringByOffset(4)
                dmiBoardName = entry.stringByOffset(5)
                dmiBoardVersion = entry.stringByOffset(6)
                dmiBoardSerial = entry.stringByOffset(7)
                #kprint("SMBIOS: board: vendor:", str(dmiBoardVendor),
                    "name:", str(dmiBoardName),
                    "version:", str(dmiBoardVersion),
                    "serial:", str(dmiBoardSerial))

            case 3:     // Chassis information
                dmiChassisVendor = entry.stringByOffset(4)
                dmiChassisType = entry.stringByOffset(5)
                dmiChassisVersion = entry.stringByOffset(6)
                dmiChassisSerial = entry.stringByOffset(7)
                #kprint("SMBIOS: chassis: vendor", str(dmiChassisVendor),
                    "type:", str(dmiChassisType), "version:", str(dmiChassisVersion),
                    "serial:", str(dmiChassisSerial))

            default:
                break
            }
        }
        #kprint("SMBIOS scan finished")
    }


    private func parseTables() -> [SMBiosEntry] {
        var entries: [SMBiosEntry] = []
        entries.reserveCapacity(entryCount)

        var buffer = MemoryBufferReader(tableAddress.vaddr, size: tableLength)
        for _ in 1...entryCount {
            do {
                let type: UInt8 = try buffer.read()
                let length: UInt8 = try buffer.read()
                let handle: UInt16 = try buffer.read()
                let tableLength = Int(length) - 4
                guard tableLength >= 0 else {
                    continue
                }
                let data = buffer.subBufferAtOffset(buffer.offset, size: tableLength)
                var stringTable = buffer.subBufferAtOffset(buffer.offset + tableLength)
                let terminator: UInt16 = try stringTable.read()
                var strings: [String] = []
                if terminator != 0 {
                    stringTable.offset = 0
                    repeat {
                        let string = try stringTable.scanASCIIZString()
                        if string != "" {
                            strings.append(string)
                        } else {
                            break
                        }
                    } while(true)
                }
                entries.append(SMBiosEntry(type: type, length: length,
                        handle: handle, data: data, strings: strings))
                buffer.offset = buffer.offset + tableLength + stringTable.offset
            } catch {
                #kprint("SMBIOS: invalid offset")
            }
        }

        return entries
    }
}
