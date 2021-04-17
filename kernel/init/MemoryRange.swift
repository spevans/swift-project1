//
//  kernel/init/MemoryRange.swift
//  project1
//
//  Created by Simon Evans on 10/04/2021.
//  Copyright © 2021 Simon Evans. All rights reserved.
//


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
        precondition(start.isPageAligned)
        return PhysPageRange.createRanges(startAddress: start, endAddress: endAddress, pageSizes: [PAGE_SIZE])
    }

    func physPageRanges(using pageSizes: [UInt]) -> [PhysPageRange]  {
        precondition(start.isPageAligned)
        return PhysPageRange.createRanges(startAddress: start, endAddress: endAddress, pageSizes: pageSizes)
    }

    var description: String {
        let str = (size >= mb) ? String.sprintf(" %6uMB  ", size / mb) :
        String.sprintf(" %6uKB  ", size / kb)

        return String.sprintf("%12X - %12X %@ %@", start.value,  endAddress.value, str, type)
    }
}
