/*
 * kernel/init/efiboot.swift
 *
 * Created by Simon Evans on 01/04/2017.
 * Copyright © 2015 - 2022 Simon Evans. All rights reserved.
 *
 * Parse the EFI tables.
 */

struct EFIBootParams {

    typealias EFIPhysicalAddress = UInt
    typealias EFIVirtualAddress = UInt

    // Physical layout in memory
    struct EFIMemoryDescriptor: CustomStringConvertible {
        let type: MemoryType
        let padding: UInt32
        let physicalStart: EFIPhysicalAddress
        let virtualStart: EFIVirtualAddress
        let numberOfPages: UInt64
        let attribute: UInt64

        var description: String {
            let size = UInt(numberOfPages) * PAGE_SIZE
            let endAddr = physicalStart + size - 1
            return #sprintf("%12X - %12X %8.8X ", physicalStart,
                endAddr, size) + "\(type)"
        }


        init?(descriptor: inout MemoryBufferReader) {
            let offset = descriptor.offset
            do {
                guard let dt = MemoryType(rawValue: try descriptor.read()) else {
                    #kprintf("EFI: Cant read descriptor at offset: %d\n", offset)
                    return nil
                }
                type = dt
                padding = try descriptor.read()
                physicalStart = try descriptor.read()
                virtualStart = try descriptor.read()
                numberOfPages = try descriptor.read()
                attribute = try descriptor.read()
            } catch {
                return nil
            }
        }
    }


    private let configTableCount: UInt
    private let configTablePtr: UnsafePointer<efi_config_table_t>

    let source = "EFI"
    let memoryRanges: [MemoryRange]
    let frameBufferInfo: FrameBufferInfo?
    let kernelPhysAddress: PhysAddress
    let symbolTablePtr: UnsafePointer<Elf64_Sym>?
    let symbolTableSize: UInt64
    let stringTablePtr: UnsafePointer<CChar>?
    let stringTableSize: UInt64


    init?(bootParamsAddr: VirtualAddress) {
        let sig = readSignature(bootParamsAddr)
        if sig == nil || sig! != "EFI" {
            #kprint("bootparams: boot_params are not EFI")
            return nil
        }
        var membuf = MemoryBufferReader(bootParamsAddr,
            size: MemoryLayout<efi_boot_params>.stride)
        do {
            let efiBootParams: efi_boot_params = try membuf.read()
            let bootParamsSize = efiBootParams.size
            guard bootParamsSize > 0 else {
                #kprint("bootparams: bootParamsSize = 0")
                return nil
            }
            kernelPhysAddress = PhysAddress(efiBootParams.kernel_phys_addr.address)

            #kprintf("bootparams: bootParamsSize = %ld kernelPhysAddress: %p\n",
                bootParamsSize, kernelPhysAddress.value)

            let memoryMapAddr = VirtualAddress(efiBootParams.memory_map.address)
            let memoryMapSize = efiBootParams.memory_map_size
            let descriptorSize = efiBootParams.memory_map_desc_size

            #kprint("bootparams: reading frameBufferInfo")
            frameBufferInfo = FrameBufferInfo(fb: efiBootParams.fb)

            memoryRanges = EFIBootParams.parseMemoryMap(memoryMapAddr,
                UInt(memoryMapSize), UInt(descriptorSize), frameBufferInfo)

            configTableCount = UInt(efiBootParams.nr_efi_config_entries)
            #kprint("bootparams: reading ctp")
            configTablePtr = efiBootParams.efi_config_table
            #kprintf("bootparams: configTableCount: %ld configTablePtr: %#x\n",
                configTableCount, configTablePtr.address)
            symbolTablePtr = efiBootParams.symbol_table
            symbolTableSize = efiBootParams.symbol_table_size
            stringTablePtr = efiBootParams.string_table
            stringTableSize = efiBootParams.string_table_size
        } catch {
            koops("bootparams: Cant read memory map settings")
        }
    }


    // This is only called from init() so needs to be static since 'self'
    // isnt fully initialised.
    static private func parseMemoryMap(_ memoryMapAddr: VirtualAddress,
        _ memoryMapSize: UInt, _ descriptorSize: UInt,
        _ frameBufferInfo: FrameBufferInfo?) -> [MemoryRange] {

        let descriptorCount = memoryMapSize / descriptorSize

        var ranges: [MemoryRange] = []
        ranges.reserveCapacity(Int(descriptorCount))
        var descriptorBuf = MemoryBufferReader(memoryMapAddr,
            size: Int(memoryMapSize))

        for i in 0..<descriptorCount {
            descriptorBuf.offset = Int(descriptorSize * i)
            guard let descriptor = EFIMemoryDescriptor(descriptor: &descriptorBuf) else {
                #kprint("bootparams: Failed to read descriptor")
                continue
            }
            let entry = MemoryRange(type: descriptor.type,
                start: PhysAddress(descriptor.physicalStart),
                size: UInt(descriptor.numberOfPages) * PAGE_SIZE)
            ranges.append(entry)
        }

        ranges.sort { $0.start < $1.start }
        if let fb = frameBufferInfo {
            ranges.insertRange(fb.memoryRange)
        }
        ranges.sort { $0.start < $1.start }
        return ranges
    }


    func findTables() -> (PhysAddress?, PhysAddress?) {
        let efiTables = EFITables(PhysAddress(RawAddress(bitPattern: configTablePtr)), configTableCount)
        return (efiTables.acpiPhysAddress, efiTables.smbiosPhysAddress)
    }


    // This can only be called after the memory manager has been setup
    // as it relies on calling mapPhysicalRegion()
     struct EFITables {
        struct EFIConfigTableEntry {
            let guid: efi_guid_t
            let table: UnsafeRawPointer
        }

        private let guidACPI1 = efi_guid_t(data1: 0xeb9d2d30, data2: 0x2d88,
            data3: 0x11d3,
            data4: (0x9a, 0x16, 0x00, 0x90, 0x27, 0x3f, 0xc1, 0x4d))
        private let guidSMBIOS = efi_guid_t(data1: 0xeb9d2d31, data2: 0x2d88,
            data3: 0x11d3,
            data4: (0x9a, 0x16, 0x00, 0x90, 0x27, 0x3f, 0xc1, 0x4d))
        private let guidSMBIOS3 = efi_guid_t(data1: 0xf2fd1544, data2: 0x9794,
            data3: 0x4a2c,
            data4: (0x99, 0x2e, 0xe5, 0xbb, 0xcf, 0x20, 0xe3, 0x94))
        private let guidACPI20 = efi_guid_t(data1: 0x8868e871, data2: 0xe4f1,
            data3: 0x11d3,
            data4: (0xbc,0x22,0x00,0x80,0xc7,0x3c,0x88,0x81))

        let acpiPhysAddress: PhysAddress?
        let smbiosPhysAddress: PhysAddress?


        fileprivate init(_ configTableAddress: PhysAddress, _ configTableCount: UInt) {
            let region = PhysRegion(start: configTableAddress, size: configTableCount)
            let mmioRegion = mapRORegion(region: region)
            defer { unmapMMIORegion(mmioRegion) }

            let vaddr = mmioRegion.physAddressRegion.baseAddress.vaddr
            let configTablePtr = UnsafePointer<efi_config_table_t>(bitPattern: vaddr)
            let tables = UnsafeBufferPointer(start: configTablePtr, count: Int(configTableCount))

            var acpiTmpPhysAddress: PhysAddress?
            var smbiosTmpPhysAddress: PhysAddress?
            for table in tables {
                let entry = EFIConfigTableEntry(guid: table.vendor_guid,
                    table: table.vendor_table)
                EFITables.printGUID(entry.guid)

                // Look for Root System Description Pointer and SMBios tables
                if acpiTmpPhysAddress == nil {
                    if let physAddress = EFITables.physAddressFor(entry: entry,
                                                                  ifMatches: guidACPI1) {
                        acpiTmpPhysAddress = physAddress
                        continue
                    }

                    if let physAddress = EFITables.physAddressFor(entry: entry,
                                                                  ifMatches: guidACPI20) {
                        acpiTmpPhysAddress = physAddress
                        continue
                    }
                }
                if smbiosTmpPhysAddress == nil {
                    if let physAddress = EFITables.physAddressFor(entry: entry,
                                                                  ifMatches: guidSMBIOS3) {
                        smbiosTmpPhysAddress = physAddress
                        continue
                    }
                    if let physAddress = EFITables.physAddressFor(entry: entry,
                                                                  ifMatches: guidSMBIOS) {
                        smbiosTmpPhysAddress = physAddress
                    }
                }
            }

            acpiPhysAddress = acpiTmpPhysAddress
            smbiosPhysAddress = smbiosTmpPhysAddress
        }

        static private func printGUID(_ guid: efi_guid_t) {
            #kprintf("EFI: { %#8.8x, %#8.4x, %#4.4x, { %#2.2x,%#2.2x,%#2.2x,%#2.2x,%#2.2x,%#2.2x,%#2.2x,%#2.2x }}\n",
                guid.data1, guid.data2, guid.data3, guid.data4.0, guid.data4.1,
                guid.data4.2, guid.data4.3, guid.data4.4, guid.data4.5,
                guid.data4.6, guid.data4.7)
        }

        static private func physAddressFor(entry: EFIConfigTableEntry,
            ifMatches guid2: efi_guid_t) -> PhysAddress? {
            if matchGUID(entry.guid, guid2) {
                return PhysAddress(entry.table.address)
            } else {
                return nil
            }
        }

        static private func matchGUID(_ guid1: efi_guid_t, _ guid2: efi_guid_t)
            -> Bool {
            return (guid1.data1 == guid2.data1) && (guid1.data2 == guid2.data2)
            && (guid1.data3 == guid2.data3)
            && guid1.data4.0 == guid2.data4.0 && guid1.data4.1 == guid2.data4.1
            && guid1.data4.2 == guid2.data4.2 && guid1.data4.3 == guid2.data4.3
            && guid1.data4.4 == guid2.data4.4 && guid1.data4.5 == guid2.data4.5
            && guid1.data4.6 == guid2.data4.6 && guid1.data4.7 == guid2.data4.7
        }
    }
}
