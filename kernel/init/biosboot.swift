/*
 * kernel/init/biosboot.swift
 *
 * Created by Simon Evans on 01/04/2017.
 * Copyright © 2015 - 2022 Simon Evans. All rights reserved.
 *
 * Parse the BIOS tables.
 */


struct BiosBootParams: CustomStringConvertible {
    enum E820Type: UInt32, CustomStringConvertible {
    case ram      = 1
    case reserved = 2
    case acpi     = 3
    case nvs      = 4
    case unusable = 5

        var description: String {
            return switch self {
            case .ram:      "RAM"
            case .reserved: "RESERVED"
            case .acpi:     "ACPI"
            case .nvs:      "NVS"
            case .unusable: "UNUSABLE"
            }
        }
    }


    struct E820MemoryRange: CustomStringConvertible {
        let baseAddress: UInt64
        let length: UInt64
        let type: UInt32

        init(_ entry: e820_entry) {
            baseAddress = entry.base_address
            length = entry.length
            type = entry.type
        }

        var description: String {
            var desc = #sprintf("%12X - %12X %4.4X", baseAddress,
                baseAddress + length - 1, type)
            let size = UInt(length)
            if (size >= mb) {
                desc += #sprintf(" %6uMB  ", size / mb)
            } else {
                desc += #sprintf(" %6uKB  ", size / kb)
            }
            if let x = E820Type(rawValue: type) {
                desc += x.description
            } else {
                desc += "type: \(type) is invalid"
            }

            return desc
        }


        fileprivate func toMemoryRange() -> MemoryRange? {
            guard let e820type = E820Type(rawValue: self.type) else {
                #kprint("bootparams: Invalid memory type: \(self.type)")
                return nil
            }
            var mtype: MemoryType

            switch (e820type) {
            case .ram:      mtype = MemoryType.Conventional
            case .reserved: mtype = MemoryType.E820Reserved
            case .acpi:     mtype = MemoryType.ACPIReclaimable
            case .nvs:      mtype = MemoryType.ACPINonVolatile
            case .unusable: mtype = MemoryType.Unusable
            }

            return MemoryRange(type: mtype,
                               start: PhysAddress(RawAddress(self.baseAddress)),
                               size: UInt(self.length),
                               attributes: [.writeBack]
            )
        }
    }


    private let RSDP_SIG: StaticString = "RSD PTR "

    let source = "E820"
    let memoryRanges: [MemoryRange]
    let frameBufferInfo: FrameBufferInfo? = nil
    let kernelPhysAddress: PhysAddress
    let symbolTablePtr: UnsafePointer<Elf64_Sym>? = nil
    let symbolTableSize: UInt64 = 0
    let stringTablePtr: UnsafePointer<CChar>? = nil
    let stringTableSize: UInt64 = 0

    var description: String {
        return "bootparams: BiosBootParams has \(memoryRanges.count) ranges"
    }


    init?(bootParamsAddr: VirtualAddress) {
        let sig = readSignature(bootParamsAddr)
        if sig == nil || sig! != "BIOS" {
            #kprint("bootparams: boot_params are not BIOS")
            return nil
        }
        var membuf = MemoryBufferReader(bootParamsAddr, size: MemoryLayout<bios_boot_params>.stride)
        do {
            let biosBootParams: bios_boot_params = try membuf.read()
            // FIXME: use bootParamsSize to size a buffer limit
            guard biosBootParams.table_size > 0 else {
                #kprint("bootparams: biosBootParams.table_size = 0")
                return nil
            }
            kernelPhysAddress = PhysAddress(biosBootParams.kernel_phys_addr.address)
            #kprintf("bootParamsSize = %ld kernelPhysAddress: %#x\n",
                biosBootParams.table_size, kernelPhysAddress.value)

            let e820MapAddr = PhysAddress(biosBootParams.e820_map.address)
            let e820Entries = UInt(biosBootParams.e820_entries)
            memoryRanges = BiosBootParams.parseE820Table(kernelPhysAddress,
                e820MapAddr, e820Entries)
        } catch {
            koops("bootparams: Cant read BIOS boot params")
        }
    }


    // This is only called from init() so needs to be static since 'self'
    // isnt fully initialised.
    // FIXME - still needs to check for overlapping regions
    static private func parseE820Table(_ kernelPhysAddress: PhysAddress,
        _ e820MapPhysAddr: PhysAddress, _ e820Entries: UInt) -> [MemoryRange] {

        guard e820Entries > 0 && e820MapPhysAddr.value > 0 else {
            koops("E820: map is empty")
        }

        var ranges: [MemoryRange] = []
        ranges.reserveCapacity(Int(e820Entries))

        var membuf = MemoryBufferReader(e820MapPhysAddr.vaddr,
            size: MemoryLayout<e820_entry>.stride * Int(e820Entries))

        let _kernel_start_addr = VirtualAddress(bitPattern: &_kernel_start)
        let _kernel_end_addr = VirtualAddress(bitPattern: &_kernel_end)

        let kernelSize = UInt(_kernel_end_addr - _kernel_start_addr)
        let kernelPhysEnd = kernelPhysAddress.advanced(by: kernelSize)
        #kprintf("E820: Kernel size: %lx\n", kernelSize)

        for _ in 0..<e820Entries {
            do {
                let e820entry: e820_entry = try membuf.read()
                let entry = E820MemoryRange(e820entry)
                if let memEntry = entry.toMemoryRange() {
                    // Find the entry that covers the memory where the kernel
                    // is loaded and adjust it then add another range for the
                    // kernel
                    if memEntry.start <= kernelPhysAddress
                    && kernelPhysEnd <= memEntry.start + memEntry.size {
                        let range1size = memEntry.start.distance(to: kernelPhysAddress)
                        if range1size > 0 {
                            ranges.append(MemoryRange(type: memEntry.type,
                                                      start: memEntry.start, size: UInt(range1size), attributes: memEntry.attributes))
                        }

                        ranges.append(MemoryRange(type: .Kernel,
                                                  start: kernelPhysAddress, size: kernelSize, attributes: [.writeBack]))
                        let range2end = memEntry.start.advanced(by: memEntry.size)
                        let range2size = kernelPhysEnd.distance(to: range2end)
                        if range2size > 0 {
                            ranges.append(MemoryRange(type: memEntry.type,
                                                      start: kernelPhysEnd, size: UInt(range2size), attributes: memEntry.attributes))
                        }
                    } else {
                        ranges.append(memEntry)
                    }
                }
            } catch {
                #kprint("Error reading E820 tables:")
            }
        }

        // Find any holes in the memory ranges and add a fake range. This
        // allows finding gaps later on for MMIO space etc
        func findHoles(_ ranges: inout [MemoryRange]) {
            var addr = PhysAddress(0)
            sortRanges(&ranges)
            for entry in ranges {
                if addr < entry.start {
                    let size = addr.distance(to: entry.start)
                    ranges.append(MemoryRange(type: MemoryType.Hole, start: addr,
                                              size: UInt(size), attributes: []))
                }
                addr = entry.start.advanced(by: entry.size)
            }
            sortRanges(&ranges)
        }

        func sortRanges(_ ranges: inout [MemoryRange]) {
            ranges.sort(by: { $0.start < $1.start })
        }

        guard ranges.count > 0 else {
            koops("E820: Cant find any memory in the e820 map")
        }

        guard ranges.contains(where: { $0.type == .Kernel }) else {
            koops("E820: Could not find Kernel entry")
        }

        // Add in a range for the VGA framebuffer. This may already exist or may overwrite something that already
        // covers that range.
        // FIXME: Dont overwrite if there is a better mapping already.
        ranges.insertRange(MemoryRange(type: .Reserved, start: PhysAddress(0), size: PAGE_SIZE, attributes: []))
        ranges.insertRange(MemoryRange(type: .FrameBuffer, start: PhysAddress(0xA0000), size: UInt(128 * kb), attributes: [.writeCombining]))
        let apicRegion = APIC.addressRegion()
        let apicRange = MemoryRange(type: .MemoryMappedIO, start: apicRegion.baseAddress, endAddress: apicRegion.endAddress, attributes: [.uncacheable])
        ranges.insertRange(apicRange)
        #kprint("Added APIC into memory ranges")
        for range in ranges {
            #kprint(range.description)
        }
        findHoles(&ranges)

        return ranges
    }


    // The memory mapping should be setup now so individual ROM regions that need to be scanned can be
    // mapped using mapRORegion()
    func findTables() -> (PhysAddress?, PhysAddress?) {
        let rsdp = findRSDP()
        let smbios = findSMBIOS()
        return (rsdp, smbios)
    }


    // Root System Description Pointer
    private func findRSDP() -> PhysAddress? {
        if let region = getEBDA() {
            #kprintf("ACPI: EBDA: %p len: 0x%x\n", region.baseAddress.value, region.size)
            if let rsdp = scanForSignature(RSDP_SIG, inRegion: region) {
                return rsdp
            }
        }
        let region = PhysRegion(start: PhysAddress(0xE0000), size: 0x20000)
        #kprintf("ACPI: Upper: %p len: 0x%x\n", region.baseAddress.value, region.size)
        return scanForSignature(RSDP_SIG, inRegion: region)
    }


    // SMBios table
    private func findSMBIOS() -> PhysAddress? {
        let region = PhysRegion(start: PhysAddress(0xf0000), size: 0x10000)
        return scanForSignature(SMBIOS.SMBIOS_SIG, inRegion: region)
    }


    private func getEBDA() -> PhysRegion? {
        let region = mapRORegion(region: PhysRegion(start: PhysAddress(0x40E), size: 2))
        let ebda: UInt16 = region.read(fromByteOffset: 0)
        unmapMMIORegion(region)

        // Convert realmode segment to linear address
        let rsdpAddr = UInt(ebda) * 16

        if rsdpAddr > 0x400 {
            return PhysRegion(start: PhysAddress(rsdpAddr), size: 1024)
        } else {
            return nil
        }
    }


    private func scanForSignature( _ signature: StaticString, inRegion region: PhysRegion)
    -> PhysAddress? {
        assert(signature.utf8CodeUnitCount != 0)
        assert(signature.isASCII)

        let mmio = mapRORegion(region: region)
        defer { unmapMMIORegion(mmio) }

        let end = mmio.regionSize - MemoryLayout<rsdp1_header>.stride
        let baseAddress = mmio.baseAddress.rawPointer
        for idx in stride(from: 0, to: end, by: 16) {
            if memcmp(signature.utf8Start, baseAddress + idx,
                signature.utf8CodeUnitCount) == 0 {
                return mmio.baseAddress + idx
            }
        }

        return nil
    }
}
