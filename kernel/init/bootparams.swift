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

let kb: UInt = 1024
let mb: UInt = 1048576

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
    case MemoryMappedIO             // Umusable
    case MemoryMappedIOPortSpace    // Unusable

    // OS defined values
    case Hole        = 0x80000000   // Used for holes in the map to keep ranges contiguous
    case PageMap     = 0x80000001   // Temporary page maps setup by the boot loader
    case BootData    = 0x80000002   // Other temporary data created by boot code inc BootParams
    case Kernel      = 0x80000003   // The loaded kernel + data + bss
}


struct MemoryEntry: CustomStringConvertible {
    let type: MemoryType
    let start: PhysAddress
    let size: UInt

    var description: String {
        let str = (size >= mb) ? String.sprintf(" %6uMB  ", size / mb) :
                String.sprintf(" %6uKB  ", size / kb)

        return String.sprintf("%12X - %12X \(str) \(type)", start, start + size - 1)
    }
}


protocol BootParamsData {
    var memoryRanges: [MemoryEntry] { get }
    var source: String { get }
}


private func readSignature(address: PhysAddress) -> String? {
    let signatureSize = 8
    let membuf = MemoryBufferReader(address, size: signatureSize)
    guard let sig = try? membuf.readASCIIZString(maxSize: signatureSize) else {
        return nil
    }
    return sig
}


struct BootParams {
    private static var params: BootParamsData?
    static var memoryRanges: [MemoryEntry] = []
    static var source: String { return params == nil ? "" : params!.source }


    static func parse(bootParamsAddr: UInt) {
        kprintf("parsing bootParams @ 0x%lx\n", bootParamsAddr)
        if (bootParamsAddr == 0) {
            koops("bootParamsAddr is null")
        }
        guard let signature = readSignature(bootParamsAddr) else {
            koops("Cant find boot params signature")
        }
        print("signature: \(signature)");

        if (signature == "BIOS") {
            print("Found BIOS boot params")
            params = BiosBootParams(bootParamsAddr: bootParamsAddr)
        } else if (signature == "EFI") {
            print("Found EFI boot params")
            params = EFIBootParams(bootParamsAddr: bootParamsAddr)
        } else {
            print("Found unknown boot params: \(signature)")
            stop()
        }

        guard params != nil else {
            koops("BiosBootParams returned null")
        }
        memoryRanges = params!.memoryRanges

        findHoles()
        for m in memoryRanges {
            print("\(params!.source): \(m)")
        }
    }


    static func highestMemoryAddress() -> PhysAddress {
        let ranges = memoryRanges
        if (ranges.count > 0) {
            let entry = ranges[ranges.count-1]
            return entry.start + entry.size - 1
        } else {
            return 0
        }
    }


    // Find any holes in the memory ranges and add a fake range. This
    // allows finding gaps later on for MMIO space etc
    private static func findHoles() {
        var addr: UInt = 0
        sortRanges()
        for entry in memoryRanges {
            if addr < entry.start {
                let size = entry.start - addr
                memoryRanges.append(MemoryEntry(type: MemoryType.Hole, start: addr,
                        size: size))
            }
            addr = entry.start + entry.size
        }
        sortRanges()
    }


    private static func sortRanges() {
        memoryRanges.sortInPlace({
            $0.start < $1.start
        })
    }
}


// BIOS data from boot/memory.asm
struct BiosBootParams: BootParamsData, CustomStringConvertible {
    enum E820Type: UInt32 {
        case RAM      = 1
        case RESERVED = 2
        case ACPI     = 3
        case NVS      = 4
        case UNUSABLE = 5
    }


    struct E820MemoryEntry: CustomStringConvertible {
        let baseAddr: UInt64
        let length: UInt64
        let type: UInt32

        var description: String {

            var desc = String.sprintf("%12X - %12X %4.4X", baseAddr, baseAddr + length - 1, type)
            let size = UInt(length)
            if (size >= mb) {
                desc += String.sprintf(" %6uMB  ", size / mb)
            } else {
                desc += String.sprintf(" %6uKB  ", size / kb)
            }
            desc += String(E820Type.init(rawValue: type)!)

                return desc
            }
    }

    var memoryRanges: [MemoryEntry] = []
    var source: String { return "E820" }

    var description: String {
        return "BiosBootParams has \(memoryRanges.count) ranges"
    }


    init?(bootParamsAddr: UInt) {
        let sig = readSignature(bootParamsAddr)
        if sig == nil || sig! != "BIOS" {
            print("boot_params are not BIOS")
            return nil
        }
        let membuf = MemoryBufferReader(bootParamsAddr, size: strideof(bios_boot_params))
        membuf.offset = 8       // skip signature

        // FIXME: use bootParamsSize to size a buffer limit
        let bootParamsSize: UInt? = try? membuf.read()
        guard bootParamsSize != nil && bootParamsSize! > 0 else {
            print("bootParamsSize = 0")
            return nil
        }
        if let e820MapAddr: UInt = try? membuf.read() {
            if let e820Entries: UInt = try? membuf.read() {
                memoryRanges = parseE820Table(e820MapAddr, e820Entries)
            }
        }
    }


    // FIXME - still needs to check for overlapping regions
    private func parseE820Table(e820MapAddr: UInt, _ e820Entries: UInt) -> [MemoryEntry] {
        var ranges: [MemoryEntry] = []
        if (e820Entries > 0 && e820MapAddr > 0) {
            let buf = MemoryBufferReader(e820MapAddr,
                size: strideof(E820MemoryEntry) * Int(e820Entries))
            ranges.reserveCapacity(Int(e820Entries))

            for _ in 0..<e820Entries {
                if let entry: E820MemoryEntry = try? buf.read() {
                    if let memEntry = convertEntry(entry) {
                        ranges.append(memEntry)
                    }
                }
            }
        }

        return ranges
    }


    private func convertEntry(entry: E820MemoryEntry) -> MemoryEntry? {
        guard let e820type = E820Type(rawValue: entry.type) else {
            print("Invalid memory type: \(entry.type)")
            return nil
        }
        var type: MemoryType

        switch (e820type) {
        case .RAM:      type = MemoryType.Conventional
        case .RESERVED: type = MemoryType.Reserved
        case .ACPI:     type = MemoryType.ACPIReclaimable
        case .NVS:      type = MemoryType.ACPINonVolatile
        case .UNUSABLE: type = MemoryType.Unusable
        }

        return MemoryEntry(type: type, start: PhysAddress(entry.baseAddr),
            size: UInt(entry.length))
    }
}


struct EFIBootParams: BootParamsData {
    typealias EFIPhysicalAddress = UInt
    typealias EFIVirtualAddress = UInt

    // Physical layout in memory
    struct EFIMemoryDescriptor: CustomStringConvertible {
        private let type: MemoryType
        private let padding: UInt32
        private let physicalStart: EFIPhysicalAddress
        private let virtualStart: EFIVirtualAddress
        private let numberOfPages: UInt64
        private let attribute: UInt64

        var description: String {
            let size = UInt(numberOfPages) * PAGE_SIZE
            let endAddr = physicalStart + size - 1
            return String.sprintf("%12X - %12X %8.8X \(type)", physicalStart,
                endAddr, size)
        }


        init?(descriptor: MemoryBufferReader) {
            let offset = descriptor.offset
            do {
                guard let dt = MemoryType(rawValue: try descriptor.read()) else {
                    throw ReadError.InvalidData
                }
                type = dt
                padding = try descriptor.read()
                physicalStart = try descriptor.read()
                virtualStart = try descriptor.read()
                numberOfPages = try descriptor.read()
                attribute = try descriptor.read()
            } catch {
                printf("Cant read descriptor at offset: %d\n", offset)
                return nil
            }
        }

    }

    var memoryRanges: [MemoryEntry] = []
    var source: String { return "EFI" }


    init?(bootParamsAddr: UInt) {
        let sig = readSignature(bootParamsAddr)
        if sig == nil || sig! != "EFI" {
            print("boot_params are not EFI")
            return nil
        }
        let membuf = MemoryBufferReader(bootParamsAddr,
            size: strideof(efi_boot_params))
        membuf.offset = 8       // skip signature

        do {
            let memoryMapAddr: VirtualAddress = try membuf.read()
            let memoryMapSize: UInt = try membuf.read()
            let descriptorSize: UInt = try membuf.read()
            let descriptorCount = memoryMapSize / descriptorSize

            var descriptors: [EFIMemoryDescriptor] = []
            descriptors.reserveCapacity(Int(descriptorCount))
            memoryRanges.reserveCapacity(Int(descriptorCount))
            let descriptorBuf = MemoryBufferReader(memoryMapAddr,
                size: Int(memoryMapSize))

            for i in 0..<descriptorCount {
                descriptorBuf.offset = Int(descriptorSize * i)
                guard let descriptor = EFIMemoryDescriptor(descriptor: descriptorBuf) else {
                    print("Failed to read descriptor")
                    continue
                }
                descriptors.append(descriptor)
                let entry = MemoryEntry(type: descriptor.type,
                    start: descriptor.physicalStart,
                    size: UInt(descriptor.numberOfPages) * PAGE_SIZE)
                memoryRanges.append(entry)
            }
        } catch {
            koops("Cant read memory map settings")
        }
    }
}
