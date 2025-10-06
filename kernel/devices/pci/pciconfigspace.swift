/*
 * kernel/devices/pci/pciconfigspace.swift
 *
 * Created by Simon Evans on 27/07/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * Basic PCI config space access using PIO or MMIO.
 *
 */


// For PIO access to PCI configuration space. PCI_CONFIG_DATA is a 32bit register so when reading BYTES or WORDs,
// add the appropiate offset to the port address bytes: (offset & 3), words: (offset & 2).
private let PCI_CONFIG_ADDRESS: UInt16 = 0xCF8
private let PCI_CONFIG_DATA:    UInt16 = 0xCFC

enum PCIConfigSpace: CustomStringConvertible {
    case pio(baseAddress: UInt32)
    case mmio(mmioRegion: MMIORegion)
    case bytes([UInt8])

    var description: String {
        switch self {
            case .pio(let baseAddress): return #sprintf("PCIBusPIO @ %8.8X", baseAddress)
            case .mmio(let mmioRegion): return "PCIBusMMIO @ \(mmioRegion.physicalRegion.baseAddress)"
            case .bytes(let data): return "TestData \(data.count) bytes"
        }
    }

    var size: Int {
        switch self {
            case .pio: return 256
            case .mmio: return 4096
            case .bytes(let array): return array.count
            }
    }

    private func setPIOConfigAddress(baseAddress: UInt32, offset: UInt) {
        let address = baseAddress | UInt32(offset & 0xfc)
        outl(PCI_CONFIG_ADDRESS, address)
    }

    func readConfigByte(atByteOffset offset: UInt) -> UInt8 {
        switch self {
            case .pio(let baseAddress):
                precondition(offset < 256)
                return noInterrupt {
                    setPIOConfigAddress(baseAddress: baseAddress, offset: offset)
                    return inb(PCI_CONFIG_DATA + UInt16(offset & 0x3))
                }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                return mmioRegion.read(fromByteOffset: Int(offset))

            case .bytes(let data):
                return data[Int(offset)]
        }
    }

    func readConfigWord(atByteOffset offset : UInt) -> UInt16 {
        if offset & UInt(0x1) != 0 {
            fatalError("PCIConfigSpace.writeConfigWord offset is not 16bit aligned")
        }
        switch self {
            case .pio(let baseAddress):
            precondition(offset < 256)
            return noInterrupt {
                setPIOConfigAddress(baseAddress: baseAddress, offset: offset)
                return inw(PCI_CONFIG_DATA + UInt16(offset & 0x2))
            }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                return mmioRegion.read(fromByteOffset: Int(offset))

            case .bytes(let data):
                return UInt16(littleEndianBytes: data[Int(offset)...])

        }
    }

    func readConfigDword(atByteOffset offset: UInt) -> UInt32 {
        if offset & UInt(0x3) != 0 {
            fatalError("PCIConfigSpace.writeConfigDword offset is not 32bit aligned")
        }
        switch self {
            case .pio(let baseAddress):
            precondition(offset < 256)
            return noInterrupt {
                setPIOConfigAddress(baseAddress: baseAddress, offset: offset)
                return inl(PCI_CONFIG_DATA)
            }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                return mmioRegion.read(fromByteOffset: Int(offset))

            case .bytes(let data):
                return UInt32(littleEndianBytes: data[Int(offset)...])
        }
    }

    func writeConfigByte(atByteOffset offset: UInt, value: UInt8) {
        switch self {
            case .pio(let baseAddress):
            precondition(offset < 256)
            return noInterrupt {
                setPIOConfigAddress(baseAddress: baseAddress, offset: offset)
                outb(PCI_CONFIG_DATA + UInt16(offset & 0x3), value)
            }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                mmioRegion.write(value: value, toByteOffset: Int(offset))

            case .bytes:
                fatalError()
        }
    }

    func writeConfigWord(atByteOffset offset: UInt, value: UInt16) {
        if offset & UInt(0x1) != 0 {
            fatalError("PCIConfigSpace.writeConfigWord offset is not 16bit aligned")
        }
        switch self {
            case .pio(let baseAddress):
            precondition(offset < 256)
            return noInterrupt {
                setPIOConfigAddress(baseAddress: baseAddress, offset: offset)
                outw(PCI_CONFIG_DATA + UInt16(offset & 0x2), value)
            }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                mmioRegion.write(value: value, toByteOffset: Int(offset))

            case .bytes:
                fatalError()
        }
    }

    func writeConfigDword(atByteOffset offset: UInt, value: UInt32) {
        if offset & UInt(0x3) != 0 {
            fatalError("PCIConfigSpace.writeConfigDword offset is not 32bit aligned")
        }
        switch self {
            case .pio(let baseAddress):
            precondition(offset < 256)
            return noInterrupt {
                setPIOConfigAddress(baseAddress: baseAddress, offset: offset)
                outl(PCI_CONFIG_DATA, value)
            }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                mmioRegion.write(value: value, toByteOffset: Int(offset))

            case .bytes:
                fatalError()
        }
    }
}



private(set) var pciHostBus: PCIBus?
#if ACPI
private var _mcfg: MCFG?

func initPCI(mcfg: MCFG?) {
    if let mcfg = mcfg {
        _mcfg = mcfg
        #kprintf("PCI: Have MCFG with %d entries\n", mcfg.allocations.count)
        for entry in mcfg.allocations {
            let busCount = UInt(entry.endBus - entry.startBus) + 1
            let size = busCount * 32 * 8 * 4096
            let endAddress = entry.baseAddress + size - 1
            #kprintf("PCI: startBus: %2.2x endBus: %2.2x base: %p - %p\n",
                     entry.startBus, entry.endBus, entry.baseAddress.value, endAddress.value)
            let regions = PhysPageAlignedRegion.createRanges(startAddress: entry.baseAddress, endAddress: endAddress, pageSizes: [.init(4096), .init(2 * mb)])
            for region in regions {
                #kprintf("PCI: Mapping region @ %s\n", region.description)
                let mmioRegion = mapIORegion(region: region)
                #kprintf("PCI: MMIORegion: %s\n", mmioRegion.description)
            }
        }
    }
}
#endif

func setPCIHostBus(_ device: Device) {
    guard let bus = device.deviceDriver as? PCIBus, bus.isHostBus else {
        #kprintf("PCI: Device '%s' is not a PCI Host Bus\n", device.deviceName)
        return
    }
    pciHostBus = bus
}

func pciConfigSpace(busId: UInt8, device: UInt8, function: UInt8) -> PCIConfigSpace {
#if ACPI
    if let mmioBaseAddress = _mcfg?.baseAddressFor(bus: busId) {
        let regionAddress = mmioBaseAddress + (UInt(device) << 15 | UInt(function) << 12)
        let pageRange = PhysRegion(start: regionAddress, size: 4096)
        return .mmio(mmioRegion: MMIORegion(pageRange))
    }
#endif

    let address = (UInt32(busId) << 16) | (UInt32(device) << 11) | (UInt32(function) << 8)
    return .pio(baseAddress: address | 0x80000000)
}
