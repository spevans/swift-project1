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

// These memory types are just the EFI ones, the BIOS ones are
// actually a subset so these definitions cover both cases
enum MemoryType: UInt32 {
    case Reserved    = 0            // Not usable
    case LoaderCode                 // Usable
    case LoaderData                 // Usable
    case BootServicesData           // Usable
    case BootServicesCode           // Usable
    case RuntimeServicesCode        // Needs to be preserved / Not usable
    case RuntimeServicesData        // Needs to be preserved / Not usable
    case Conventional               // Usable (RAM)
    case Unusable                   // Unusable (RAM with errors)
    case ACPIReclaimable            // Usable after ACPI enabled
    case ACPINonVolatile            // Needs to be preserved / Not usable
    case MemoryMappedIO             // Unusable
    case MemoryMappedIOPortSpace    // Unusable

    // OS defined values
    case Hole         = 0x80000000  // Used for holes in the map to keep ranges contiguous
    case PageMap      = 0x80000001  // Temporary page maps setup by the boot loader
    case BootData     = 0x80000002  // Other temporary data created by boot code inc BootParams
    case Kernel       = 0x80000003  // The loaded kernel + data + bss
    case FrameBuffer  = 0x80000004  // Framebuffer address if it is the top of the address space
    case E820Reserved = 0x80000005  // Ranges marked in E820 map as reserved
}


let kb: UInt = 1024
let mb: UInt = 1048576
let gb = kb * mb

struct MemoryRange: CustomStringConvertible {
    let type: MemoryType
    let start: PhysAddress
    let size: UInt
    var endAddress: PhysAddress { return start.advanced(by: size - 1) }

    var physPageRanges: [PhysPageRange] {
        return PhysPageRange.createRanges(startAddress: start, size: size, pageSizes: [PAGE_SIZE])
    }

    var description: String {
        let str = (size >= mb) ? String.sprintf(" %6uMB  ", size / mb) :
                String.sprintf(" %6uKB  ", size / kb)

        return String.sprintf("%12X - %12X %@ %@", start.value,
            endAddress.value, str, type)
    }
}


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
    func findTables() -> (UnsafePointer<rsdp1_header>?,
        UnsafePointer<smbios_header>?)
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
        let (acpiPtr, smbiosPtr) = bootParams.findTables()

        var tmpVendor: String?
        var tmpProduct: String?
        if let ptr = smbiosPtr {
            let smbios = SMBIOS(ptr: ptr)
            tmpVendor = smbios?.dmiBiosVendor
            tmpProduct = smbios?.dmiProductName
        }

        vendor = tmpVendor ?? "generic"
        product = tmpProduct ?? "generic"
        if let ptr = acpiPtr {
            if let acpi = ACPI(rsdp: ptr, vendor: vendor, product: product) {
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
