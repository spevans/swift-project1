/*
 * kernel/init/bootparams.swift
 *
 * Created by Simon Evans on 24/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Initial setup for available physical memory etc
 * Updated to handle multiple data source eg BIOS, EFI
 *
 */


// The boot parameters also contain information about the framebuffer if present
// so that the TTY driver can be initialised before PCI scanning has taken place
struct FrameBufferInfo: CustomStringConvertible {
    let address:       PhysAddress
    let size:          UInt
    let width:         UInt32
    let height:        UInt32
    let pxPerScanline: UInt32
    let depth:         UInt32
    let redShift:      UInt8
    let redMask:       UInt8
    let greenShift:    UInt8
    let greenMask:     UInt8
    let blueShift:     UInt8
    let blueMask:      UInt8

    var description: String {
        var str = String.sprintf("Framebuffer: %dx%d bpp: %d px per line: %d addr:%p size: %lx\n",
            width, height, depth, pxPerScanline, address,  size);
        str += String.sprintf("Red shift:   %2d Red mask:   %x\n", redShift, redMask);
        str += String.sprintf("Green shift: %2d Green mask: %x\n", greenShift, greenMask);
        str += String.sprintf("Blue shift:  %2d Blue mask:  %x\n", blueShift, blueMask);

        return str
    }

    init(fb: frame_buffer) {
        address = PhysAddress(fb.address.address)
        size = UInt(fb.size)
        width = fb.width
        height = fb.height
        pxPerScanline = fb.px_per_scanline
        depth = fb.depth
        redShift = fb.red_shift
        redMask = fb.red_mask
        greenShift = fb.green_shift
        greenMask = fb.green_mask
        blueShift = fb.blue_shift
        blueMask = fb.blue_mask
    }

    var memoryRange: MemoryRange {
        MemoryRange(type: .FrameBuffer, start: address, size: size)
    }
}


protocol BootParams {
    var memoryRanges: [MemoryRange]  { get }
    var source: String { get }
    var frameBufferInfo: FrameBufferInfo? { get }
    var kernelPhysAddress: PhysAddress { get }
    var symbolTablePtr: UnsafePointer<Elf64_Sym>? { get }
    var symbolTableSize: UInt64 { get }
    var stringTablePtr: UnsafePointer<CChar>? { get }
    var stringTableSize: UInt64 { get }
    func findTables() -> (PhysAddress?, PhysAddress?)
}

/*
 * The boot parameters are parsed in two stages:
 * 1. Read the data in the {bios,efi}_boot_params table and save
 * 2. Parse the tables pointed to by the data in step 1
 *
 * This is required because step 2 requires some pages to be mapped in
 * setupMM(), but setupMM() requires some of the data from step1.
 */
func parse(bootParamsAddr: VirtualAddress) -> BootParams {
    printf("bootparams: parsing bootParams @ 0x%lx\n", bootParamsAddr)
    if (bootParamsAddr == 0) {
        koops("bootParamsAddr is null")
    }
    guard let signature = readSignature(bootParamsAddr) else {
        koops("bootparams: Cant find boot params signature")
    }
    print("bootparams: signature:", signature)

    if (signature == "BIOS") {
        print("bootparams: Found BIOS boot params")
        if let params = BiosBootParams(bootParamsAddr: bootParamsAddr) {
            return params
        }
    } else if (signature == "EFI") {
        print("bootparams: Found EFI boot params")
        if let params = EFIBootParams(bootParamsAddr: bootParamsAddr) {
            return params
        }
    } else {
        print("bootparams: Found unknown boot params: \(signature)")
        stop()
    }
    koops("bootparams: BiosBootParams returned null")
}


struct SystemTables {
    let acpiTables: ACPI
    // vendor and product is the only information needed from the SMBIOS
    let vendor: String
    let product: String

    init(bootParams: BootParams) {
        let (acpiPhysAddress, smbiosPhysAddress) = bootParams.findTables()

        var tmpVendor: String?
        var tmpProduct: String?
        if let physAddress = smbiosPhysAddress {
            let smbios = SMBIOS(physAddress: physAddress)
            tmpVendor = smbios?.dmiBiosVendor
            tmpProduct = smbios?.dmiProductName
        }

        vendor = tmpVendor ?? "generic"
        product = tmpProduct ?? "generic"
        if let physAddress = acpiPhysAddress {
            if let acpi = ACPI(rsdp: physAddress, vendor: vendor, product: product, memoryRanges: bootParams.memoryRanges) {
                acpiTables = acpi
                return
            }
        }
        koops("Cant find ACPI tables")
    }
}


func readSignature(_ address: VirtualAddress) -> String? {
    let signatureSize = 8
    var membuf = MemoryBufferReader(address, size: signatureSize)
    guard let sig = try? membuf.readASCIIZString(maxSize: signatureSize) else {
        return nil
    }
    return sig
}
