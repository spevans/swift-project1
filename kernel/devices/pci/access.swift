/*
 * kernel/devices/pci/access.swift
 *
 * Created by Simon Evans on 27/07/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * Basic PCI config space access using PIO or MMIO.
 *
 */


protocol PCIConfigAccessProtocol {
    func readConfigByte(device: UInt8, function: UInt8, offset: UInt) -> UInt8
    func readConfigWord(device: UInt8, function: UInt8, offset: UInt) -> UInt16
    func readConfigDword(device: UInt8, function: UInt8, offset: UInt) -> UInt32
    func writeConfigByte(device: UInt8, function: UInt8, offset: UInt, value: UInt8)
    func writeConfigWord(device: UInt8, function: UInt8, offset: UInt, value: UInt16)
    func writeConfigDword(device: UInt8, function: UInt8, offset: UInt, value: UInt32)
}


struct PCIConfigSpace {
    let pciConfigAccess: PCIConfigAccessProtocol
    let device:     UInt8
    let function:   UInt8


    init(busID: UInt8, device: UInt8, function: UInt8) {
        self.device = device
        self.function = function

        let mcfgTable = system.deviceManager.acpiTables.mcfg
        if let mmioBaseAddress = mcfgTable?.baseAddressFor(bus: busID) {
            pciConfigAccess = PCIMMIOConfigAccess(busID: busID, mmiobase: mmioBaseAddress)
        } else {
            pciConfigAccess = PCIPIOConfigAccess(busID: busID)
        }
    }


    private init(access: PCIConfigAccessProtocol, device: UInt8, function: UInt8) {
        self.pciConfigAccess = access
        self.device = device
        self.function = function
    }

    func configSpaceFor(device newDevice: UInt8, function newFunction: UInt8) -> PCIConfigSpace {
        // Check this is run on the 'base' PCIConfigSpace for the given bus
        precondition(device == 0)
        precondition(function == 0)
        return PCIConfigSpace(access: pciConfigAccess, device: newDevice, function: newFunction)
    }


    // Reading
    func readConfigByte(atByteOffset offset: UInt) -> UInt8 {
        return pciConfigAccess.readConfigByte(device: device, function: function, offset: offset)
    }

    func readConfigWord(atByteOffset offset: UInt) -> UInt16 {
        if offset & UInt(0x1) != 0 {
            fatalError("PCIConfigSpace.readConfigWord(device: \(String(device, radix: 16)), function: \(String(function, radix: 16)), offset: \(String(offset, radix: 16))")
        }
        return pciConfigAccess.readConfigWord(device: device, function: function, offset: offset)
    }

    func readConfigDword(atByteOffset offset: UInt) -> UInt32 {
        if offset & UInt(0x3) != 0 {
            fatalError("PCIConfigSpace.readConfigDword(device: \(String(device, radix: 16)), function: \(String(function, radix: 16)), offset: \(String(offset, radix: 16))")
        }
        return pciConfigAccess.readConfigDword(device: device, function: function, offset: offset)
    }


    // Writing
    func writeConfigByte(atByteOffset offset: UInt, value: UInt8) {
        pciConfigAccess.writeConfigByte(device: device, function: function, offset: offset, value: value)
    }

    func writeConfigWord(atByteOffset offset: UInt, value: UInt16) {
        if offset & UInt(0x1) != 0 {
            fatalError("PCIConfigSpace.writeConfigWord(device: \(String(device, radix: 16)), function: \(String(function, radix: 16)), offset: \(String(offset, radix: 16))")
        }
        pciConfigAccess.writeConfigWord(device: device, function: function, offset: offset, value: value)
    }

    func writeConfigDword(atByteOffset offset: UInt, value: UInt32) {
        if offset & UInt(0x3) != 0 {
            fatalError("PCIConfigSpace.writeConfigDword(device: \(String(device, radix: 16)), function: \(String(function, radix: 16)), offset: \(String(offset, radix: 16))")
        }
        pciConfigAccess.writeConfigDword(device: device, function: function, offset: offset, value: value)
    }
}


extension PCIConfigSpace {
    fileprivate struct PCIMMIOConfigAccess: PCIConfigAccessProtocol, CustomStringConvertible {

        private let baseAddress: VirtualAddress

        var description: String { String.sprintf("PCIBusMMIO @ %p", baseAddress) }

        init(busID: UInt8, mmiobase: PhysAddress) {
            let address = mmiobase.advanced(by: UInt(busID) << 20)
            baseAddress = address.vaddr
        }

        private func configAddress(device: UInt8, function: UInt8, offset: UInt) -> UnsafeMutableRawPointer {
            let address = baseAddress | UInt(device) << 15 | UInt(function) << 12 | (offset & 0xfff)
            return UnsafeMutableRawPointer(bitPattern: address)!
        }


        // Reading
        func readConfigByte(device: UInt8, function: UInt8, offset: UInt) -> UInt8 {
            let address = configAddress(device: device, function: function, offset: offset)
            return address.load(as: UInt8.self)
        }

        func readConfigWord(device: UInt8, function: UInt8, offset: UInt) -> UInt16 {
            precondition(offset & 0x1 == 0)
            let address = configAddress(device: device, function: function, offset: offset)
            return address.load(as: UInt16.self)
        }

        func readConfigDword(device: UInt8, function: UInt8, offset: UInt) -> UInt32 {
            precondition(offset & 0x3 == 0)
            let address = configAddress(device: device, function: function, offset: offset)
            return address.load(as: UInt32.self)
        }

        // Writing
        func writeConfigByte(device: UInt8, function: UInt8, offset: UInt, value: UInt8) {
            let address = configAddress(device: device, function: function, offset: offset)
            print("PCIMMIO.writeConfigByte 0x\(String(address.address, radix: 16)) = \(value)")
            address.storeBytes(of: value, as: UInt8.self)
        }

        func writeConfigWord(device: UInt8, function: UInt8, offset: UInt, value: UInt16) {
            precondition(offset & 0x1 == 0)
            let address = configAddress(device: device, function: function, offset: offset)
            print("PCIMMIO.writeConfigByte 0x\(String(address.address, radix: 16)) = \(value)")
            address.storeBytes(of: value, as: UInt16.self)
        }

        func writeConfigDword(device: UInt8, function: UInt8, offset: UInt, value: UInt32) {
            precondition(offset & 0x3 == 0)
            let address = configAddress(device: device, function: function, offset: offset)
            print("PCIMMIO.writeConfigByte 0x\(String(address.address, radix: 16)) = \(value)")
            address.storeBytes(of: value, as: UInt32.self)
        }
    }


    fileprivate struct PCIPIOConfigAccess: PCIConfigAccessProtocol, CustomStringConvertible {
        private let PCI_CONFIG_ADDRESS: UInt16 = 0xCF8
        private let PCI_CONFIG_DATA:    UInt16 = 0xCFC
        private let baseAddress: UInt32

        var description: String {
            return String.sprintf("PCIBusPIO @ %8.8X", baseAddress)
        }


        init(busID: UInt8) {
            baseAddress = UInt32(busID) << 16 | 0x80000000;
        }

        private func setConfigAddress(device: UInt8, function: UInt8, offset: UInt) {
            let address = baseAddress | UInt32(device) << 11 | UInt32(function) << 8 | UInt32(offset & 0xfc)
            outl(PCI_CONFIG_ADDRESS, address)
        }


        // Reading
        func readConfigByte(device: UInt8, function: UInt8, offset: UInt) -> UInt8 {
            return noInterrupt {
                setConfigAddress(device: device, function: function, offset: offset)
                return inb(PCI_CONFIG_DATA + UInt16(offset & 0x3))
            }
        }

        func readConfigWord(device: UInt8, function: UInt8, offset: UInt) -> UInt16 {
            precondition(offset & 0x1 == 0)
            return noInterrupt {
                setConfigAddress(device: device, function: function, offset: offset)
                return inw(PCI_CONFIG_DATA + UInt16(offset & 0x2))
            }
        }

        func readConfigDword(device: UInt8, function: UInt8, offset: UInt) -> UInt32 {
            precondition(offset & 0x3 == 0)
            return noInterrupt {
                setConfigAddress(device: device, function: function, offset: offset)
                return inl(PCI_CONFIG_DATA)
            }
        }


        // Writing
        func writeConfigByte(device: UInt8, function: UInt8, offset: UInt, value: UInt8) {
            return noInterrupt {
                setConfigAddress(device: device, function: function, offset: offset)
                return outb(PCI_CONFIG_DATA + UInt16(offset & 0x3), value)
            }
        }

        func writeConfigWord(device: UInt8, function: UInt8, offset: UInt, value: UInt16) {
            precondition(offset & 0x1 == 0)
            return noInterrupt {
                setConfigAddress(device: device, function: function, offset: offset)
                return outw(PCI_CONFIG_DATA + UInt16(offset & 0x2), value)
            }
        }

        func writeConfigDword(device: UInt8, function: UInt8, offset: UInt, value: UInt32) {
            precondition(offset & 0x3 == 0)
            return noInterrupt {
                setConfigAddress(device: device, function: function, offset: offset)
                return outl(PCI_CONFIG_DATA, value)
            }
        }
    }
}
