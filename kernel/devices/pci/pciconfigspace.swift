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


    init(busId: UInt8, device: UInt8, function: UInt8) {
        let mcfgTable = system.deviceManager.acpiTables.mcfg
        if let mmioBaseAddress = mcfgTable?.baseAddressFor(bus: busId) {
            let regionAddress = mmioBaseAddress + (UInt(device) << 15 | UInt(function) << 12)
            let pageRange = PhysRegion(start: regionAddress, size: 4096)
            #kprint("PCIConfigSpace, mapping regions @ \(pageRange) for base address \(mmioBaseAddress), bus: \(busId), \(device)/\(function) => \(regionAddress)")
            self = .mmio(mmioRegion: mapIORegion(region: pageRange))
        } else {
            self = .pio(baseAddress: UInt32(busId) << 16 | 0x80000000)
        }
    }

    func release() {
        if case let .mmio(mmioRegion) = self {
            unmapMMIORegion(mmioRegion)
        }
    }

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

    private func setPIOConfigAddress(baseAddress: UInt32, device: UInt8, function: UInt8, offset: UInt) {
        let address = baseAddress | UInt32(device) << 11 | UInt32(function) << 8 | UInt32(offset & 0xfc)
        outl(PCI_CONFIG_ADDRESS, address)
    }

    func readConfigByte(device: UInt8, function: UInt8, offset: UInt) -> UInt8 {
        switch self {
            case .pio(let baseAddress):
                precondition(offset < 256)
                return noInterrupt {
                    setPIOConfigAddress(baseAddress: baseAddress, device: device, function: function, offset: offset)
                    return inb(PCI_CONFIG_DATA + UInt16(offset & 0x3))
                }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                return mmioRegion.read(fromByteOffset: Int(offset))

            case .bytes(let data):
                return data[Int(offset)]
        }
    }

    func readConfigWord(device: UInt8, function: UInt8, offset: UInt) -> UInt16 {
        if offset & UInt(0x1) != 0 {
            fatalError("PCIConfigSpace.readConfigWord(device: \(String(device, radix: 16)), function: \(String(function, radix: 16)), offset: \(String(offset, radix: 16))")
        }
        switch self {
            case .pio(let baseAddress):
            precondition(offset < 256)
            return noInterrupt {
                setPIOConfigAddress(baseAddress: baseAddress, device: device, function: function, offset: offset)
                return inw(PCI_CONFIG_DATA + UInt16(offset & 0x2))
            }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                return mmioRegion.read(fromByteOffset: Int(offset))

            case .bytes(let data):
                return UInt16(littleEndianBytes: data[Int(offset)...])

        }
    }

    func readConfigDword(device: UInt8, function: UInt8, offset: UInt) -> UInt32 {
        if offset & UInt(0x3) != 0 {
            fatalError("PCIConfigSpace.readConfigDword(device: \(String(device, radix: 16)), function: \(String(function, radix: 16)), offset: \(String(offset, radix: 16))")
        }
        switch self {
            case .pio(let baseAddress):
            precondition(offset < 256)
            return noInterrupt {
                setPIOConfigAddress(baseAddress: baseAddress, device: device, function: function, offset: offset)
                return inl(PCI_CONFIG_DATA)
            }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                return mmioRegion.read(fromByteOffset: Int(offset))

            case .bytes(let data):
                return UInt32(littleEndianBytes: data[Int(offset)...])
        }
    }

    func writeConfigByte(device: UInt8, function: UInt8, offset: UInt, value: UInt8) {
        switch self {
            case .pio(let baseAddress):
            precondition(offset < 256)
            return noInterrupt {
                setPIOConfigAddress(baseAddress: baseAddress, device: device, function: function, offset: offset)
                outb(PCI_CONFIG_DATA + UInt16(offset & 0x3), value)
            }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                mmioRegion.write(value: value, toByteOffset: Int(offset))

            case .bytes:
                fatalError()
        }
    }

    func writeConfigWord(device: UInt8, function: UInt8, offset: UInt, value: UInt16) {
        if offset & UInt(0x1) != 0 {
            fatalError("PCIConfigSpace.writeConfigWord(device: \(String(device, radix: 16)), function: \(String(function, radix: 16)), offset: \(String(offset, radix: 16))")
        }
        switch self {
            case .pio(let baseAddress):
            precondition(offset < 256)
            return noInterrupt {
                setPIOConfigAddress(baseAddress: baseAddress, device: device, function: function, offset: offset)
                outw(PCI_CONFIG_DATA + UInt16(offset & 0x2), value)
            }

            case .mmio(let mmioRegion):
                precondition(offset < 4096)
                mmioRegion.write(value: value, toByteOffset: Int(offset))

            case .bytes:
                fatalError()
        }
    }

    func writeConfigDword(device: UInt8, function: UInt8, offset: UInt, value: UInt32) {
        if offset & UInt(0x3) != 0 {
            fatalError("PCIConfigSpace.writeConfigDword(device: \(String(device, radix: 16)), function: \(String(function, radix: 16)), offset: \(String(offset, radix: 16))")
        }
        switch self {
            case .pio(let baseAddress):
            precondition(offset < 256)
            return noInterrupt {
                setPIOConfigAddress(baseAddress: baseAddress, device: device, function: function, offset: offset)
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
