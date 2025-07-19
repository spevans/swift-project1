/*
 *  i915GTT.swift
 *  Kernel
 *
 *  Created by Simon Evans on 29/07/2025.
 *
 * Graphics Translation Table - virtual memory functions for the i915
 */


extension I915 {
    struct GTT_PTE: CustomStringConvertible {
        let rawValue: UInt32

        var physAddress: PhysAddress {
            PhysAddress(RawAddress(rawValue & 0xffff_f000) | RawAddress(rawValue & 0b11110000) << 28)
        }

        var mappingType: Int {
            Int(rawValue & 0b110) >> 1
        }

        var isValid: Bool {
            rawValue & 1 == 1
        }

        var description: String {
            #sprintf("%8.8x -> phys: %p  type: %d isValid: %d", rawValue, physAddress, mappingType, isValid)
        }

        init(address: PhysAddress, type: Int) {
            var value: UInt32 = UInt32(truncatingIfNeeded: address.value) & 0xffff_f000
            value |= UInt32(truncatingIfNeeded: address.value >> 28) & 0b11110000
            value |= UInt32(type) << 1
            value |= 1
            self.rawValue = value
        }

        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
    }

    func gttPhysAddress() -> PhysAddress {
        let pgtblCtl: UInt32 = mmioRegion.read(fromByteOffset: 0x2020)
        let gttBaseAddress = UInt64(pgtblCtl) & 0xffff_f000 | ((UInt64(pgtblCtl) << 28) & 0xf_0000_0000)
        return PhysAddress(RawAddress(gttBaseAddress))
    }

    func gttSize() -> Int? {
        let pgtblCtl: UInt32 = mmioRegion.read(fromByteOffset: 0x2020)
        let bits = Int(pgtblCtl >> 1) & 0b111
        switch bits {
            case 0: return 512 * 1024
            case 1: return 256 * 1024
            case 2: return 128 * 1024
            case 3: return 1 * 1024 * 1024
            case 4: return 2 * 1024 * 1024
            case 5: return 1_5
            default: return nil
        }
    }


    func gttPte(_ page: Int) -> GTT_PTE? {
        guard let gttSize = self.gttSize(), page < (gttSize / MemoryLayout<UInt32>.size) else {
            return nil
        }
        let rawPte: UInt32 = gttMmioRegion.read(fromByteOffset: page * MemoryLayout<UInt32>.size)
        return GTT_PTE(rawValue: rawPte)
    }

    func gttVirtToPTE(_ virtAddress: UInt32) -> GTT_PTE? {
        let page = Int(virtAddress >> 12)
        return gttPte(page)
    }

    func showGTT() {
        let pgtblCtl: UInt32 = mmioRegion.read(fromByteOffset: 0x2020)
        let gttBaseAddress = UInt64(pgtblCtl) & 0xffff_f000 | ((UInt64(pgtblCtl) << 28) & 0xf_0000_0000)
        let gttSize = ["512KB", "256KB", "128KB", "1MB", "2MB", "1.5MB", "Reserved1", "Reserved2"]
        #kprintf("PGTBL_CTL: 0x%8.8x GTT baseAddress: 0x%x size: %s Enabled: %s\n",
                 pgtblCtl, gttBaseAddress, gttSize[Int(pgtblCtl >> 1) & 0b111], pgtblCtl & 1 == 1)
    }

    func dumpGTTRanges() {
        guard let size = gttSize() else {
            #kprint("Can't determine GTT size")
            return
        }
        let pages = Int(size / MemoryLayout<UInt32>.size)
        #kprintf("Dumping GTT ranges (0x%x - 0x%x)\n", UInt(0), UInt(pages))
        var startAddress: RawAddress? = nil
        var endAddress: RawAddress = 0
        for page in 0..<pages {
            guard let pte = gttPte(page) else { continue }
            if pte.isValid, pte.physAddress != PhysAddress(RawAddress(baseOfStolenMemory)) {
                if startAddress == nil { startAddress = RawAddress(page * 4096) }
                endAddress = RawAddress(page * 4096) + 4095
                continue
            }
            if let startAddress {
                #kprintf("%p - %p   \n", startAddress, endAddress)
            }
            startAddress = nil
        }
    }

    func mapFont(at newAddress: UInt32) -> UInt32? {
        let fontAddress = VirtualAddress(bitPattern: &fontdata_8x16)
        guard let fontPhys = virtualToPhys(address: fontAddress) else {
            #kprint("Failed to get physical address of font")
            return nil
        }

        let fontPages = PhysPageAlignedRegion(start: fontPhys, size: 16 * 256)
        let offset = UInt32(fontPhys - fontPages.baseAddress)

        #kprintf("fontAddress: %p font Physical Address: %p  offset into page: %x\n",
                 fontAddress, fontPhys.value, offset)

        var newAddress = newAddress & 0xffff_0000
        let result = newAddress + offset
        for page in fontPages {
            let gttPage = newAddress >> 12
            #kprintf("Phys Page: %p  gttPage: %x @ %p\n", page.value, gttPage, newAddress)
            let pte = GTT_PTE(address: page, type: 3)
            gttMmioRegion.write(value: pte.rawValue, toByteOffset: Int(gttPage) * MemoryLayout<UInt32>.size)
            newAddress += 4096
        }
        return result
    }

    func copyFont(to address: UInt32, physAddress physGttAddr: RawAddress) -> UInt32? {
        let font = Font(
            width: 8, height: 16, data: UnsafePointer<UInt8>(bitPattern: UInt(bitPattern: &fontdata_8x16))!
        )
        let gttPage = Int(address >> 12)
        guard let pte = gttPte(gttPage) else {
            #kprintf("Faild to get PTE @ 0x%x\n", address)
            return nil
        }

        guard pte.physAddress == PhysAddress(RawAddress(baseOfStolenMemory)) else {
            #kprintf("PTE @ 0x%x is not space, physical address: %p\n", address, pte.physAddress.value)
            return nil
        }
        #kprintf("Mapping 0x%x GTT to Phys 0x%x\n", address, physGttAddr)

        let newPte = GTT_PTE(address: PhysAddress(physGttAddr), type: pte.mappingType)
        gttMmioRegion.write(value: newPte.rawValue, toByteOffset: gttPage * MemoryLayout<UInt32>.size)

        let fontAddress = PhysAddress(RawAddress(fbBaseAddr + UInt64(address)))
        let fontRegion = PhysRegion(start: fontAddress, size: 4096)
        let fontMmio = mapIORegion(region: fontRegion, cacheType: .uncacheable)

        let buffer = UnsafeBufferPointer(start: font.data, count: 4096)
        #kprintf("Writing font to %p\n", fontAddress.value)
        for idx in 0..<4096 {
            let byte = buffer[idx]
            fontMmio.write(value: byte, toByteOffset: idx)
        }
        return address
    }
}
