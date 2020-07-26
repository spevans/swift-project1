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
    func readConfigDword(device: UInt8, function: UInt8, offset: UInt) -> UInt32
    func readConfigWords(device: UInt8, function: UInt8, offset: UInt) -> (UInt16, UInt16)
    func readConfigBytes(device: UInt8, function: UInt8, offset: UInt) -> (UInt8, UInt8, UInt8, UInt8)
    func writeConfigDword(device: UInt8, function: UInt8, offset: UInt, value: UInt32)
    func writeConfigWord(device: UInt8, function: UInt8, offset: UInt, value: UInt16)
    func writeConfigByte(device: UInt8, function: UInt8, offset: UInt, value: UInt8)
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

    init(busID: UInt8, address: UInt32) {
        self.init(busID: busID, device: UInt8(address >> 16), function: UInt8(address & 0xff))
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

    func readConfigDword(atOffset offset: UInt) -> UInt32 {
        return pciConfigAccess.readConfigDword(device: device, function: function, offset: offset)
    }

    func readConfigWords(_ offset: UInt) -> (UInt16, UInt16) {
        return pciConfigAccess.readConfigWords(device: device, function: function,  offset: offset)
    }

    func readConfigWord(atOffset offset: UInt) -> UInt16 {
        let words = readConfigWords(offset & ~1)
        return (offset & 1) == 1 ? words.1 : words.0
    }

    func readConfigBytes(_ offset: UInt) -> (UInt8, UInt8, UInt8, UInt8) {
        return pciConfigAccess.readConfigBytes(device: device, function: function, offset: offset)
    }

    func readConfigByte(atOffset offset: UInt) -> UInt8 {
        let bytes = readConfigBytes(offset & ~3)
        switch offset & 3 {
            case 0: return bytes.0
            case 1: return bytes.1
            case 2: return bytes.2
            default: return bytes.3
        }
    }

    func writeConfigDword(atOffset offset: UInt, value: UInt32) {
        pciConfigAccess.writeConfigDword(device: device, function: function, offset: offset, value: value)
    }

    func writeConfigWord(atOffset offset: UInt, value: UInt16) {
        pciConfigAccess.writeConfigWord(device: device, function: function, offset: offset, value: value)
    }

    func writeConfigByte(atOffset offset: UInt, value: UInt8) {
        pciConfigAccess.writeConfigByte(device: device, function: function, offset: offset, value: value)
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


        func readConfigDword(device: UInt8, function: UInt8, offset: UInt)
            -> UInt32 {

                let address = baseAddress | UInt(device) << 15 | UInt(function) << 12 | (offset & 0xfff)
                return UnsafePointer<UInt32>(bitPattern: address)!.pointee
        }


        func readConfigWords(device: UInt8, function: UInt8, offset: UInt)
            -> (UInt16, UInt16) {

                let data = readConfigDword(device: device, function: function, offset: offset)
                let word1 = UInt16(truncatingIfNeeded: data)
                let word2 = UInt16(truncatingIfNeeded: (data >> 16))

                return (word1, word2)
        }


        func readConfigBytes(device: UInt8, function: UInt8, offset: UInt)
            -> (UInt8, UInt8, UInt8, UInt8) {

                let data = readConfigDword(device: device, function: function, offset: offset)
                let byte1 = UInt8(truncatingIfNeeded: data)
                let byte2 = UInt8(truncatingIfNeeded: (data >> 8))
                let byte3 = UInt8(truncatingIfNeeded: (data >> 16))
                let byte4 = UInt8(truncatingIfNeeded: (data >> 24))

                return (byte1, byte2, byte3, byte4)
        }

        func writeConfigByte(device: UInt8, function: UInt8, offset: UInt, value: UInt8) {
            let address = configAddress(device: device, function: function, offset: offset)
            address.storeBytes(of: value, as: UInt8.self)
        }

        func writeConfigWord(device: UInt8, function: UInt8, offset: UInt, value: UInt16) {
            let address = configAddress(device: device, function: function, offset: offset)
            address.storeBytes(of: value, as: UInt16.self)
        }

        func writeConfigDword(device: UInt8, function: UInt8, offset: UInt, value: UInt32) {
            let address = configAddress(device: device, function: function, offset: offset)
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


        func readConfigDword(device: UInt8, function: UInt8, offset: UInt) -> UInt32 {
            let address = baseAddress | UInt32(device) << 11 | UInt32(function) << 8
                | UInt32(offset & 0xfc)
            outl(PCI_CONFIG_ADDRESS, address)
            let data = inl(PCI_CONFIG_DATA)

            return data
        }


        func readConfigWords(device: UInt8, function: UInt8, offset: UInt)
            -> (UInt16, UInt16) {

                let data = readConfigDword(device: device, function: function, offset: offset)
                let word1 = UInt16(truncatingIfNeeded: data)
                let word2 = UInt16(truncatingIfNeeded: (data >> 16))

                return (word1, word2)
        }


        func readConfigBytes(device: UInt8, function: UInt8, offset: UInt)
            -> (UInt8, UInt8, UInt8, UInt8) {

                let data = readConfigDword(device: device, function: function, offset: offset)
                let byte1 = UInt8(truncatingIfNeeded: data)
                let byte2 = UInt8(truncatingIfNeeded: (data >> 8))
                let byte3 = UInt8(truncatingIfNeeded: (data >> 16))
                let byte4 = UInt8(truncatingIfNeeded: (data >> 24))

                return (byte1, byte2, byte3, byte4)
        }

        func writeConfigByte(device: UInt8, function: UInt8, offset: UInt, value: UInt8) {
            fatalError("\(self).writeConfigByte called")
        }

        func writeConfigWord(device: UInt8, function: UInt8, offset: UInt, value: UInt16) {
            fatalError("\(self).writeConfigWord called")
        }

        func writeConfigDword(device: UInt8, function: UInt8, offset: UInt, value: UInt32) {
            fatalError("\(self).writeConfigDword called")
        }
    }
}
