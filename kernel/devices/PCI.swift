/*
 * kernel/devices/PCI.swift
 *
 * Created by Simon Evans on 28/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Basic PCI bus scan routine
 *
 */


protocol PCIBus {
    var bus: UInt8 { get }
    func readConfigLong(device: UInt8, function: UInt8, offset: UInt) -> UInt32
    func readConfigWords(device: UInt8, function: UInt8, offset: UInt) -> (UInt16, UInt16)
    func readConfigBytes(device: UInt8, function: UInt8, offset: UInt) -> (UInt8, UInt8, UInt8, UInt8)
}


struct PCIBusPIO: PCIBus, CustomStringConvertible {
    private let PCI_CONFIG_ADDRESS: UInt16 = 0xCF8
    private let PCI_CONFIG_DATA:    UInt16 = 0xCFC
    private let baseAddress: UInt32
    let bus: UInt8
    let description: String


    init?(bus: UInt8) {
        self.bus = bus
        baseAddress = UInt32(bus) << 16 | 0x80000000;
        description = String.sprintf("PCIBusPIO @ %8.8X", baseAddress)
    }


    func readConfigLong(device: UInt8, function: UInt8, offset: UInt) -> UInt32 {
        let address = baseAddress | UInt32(device) << 11 | UInt32(function) << 8
            | UInt32(offset & 0xfc)
        outl(PCI_CONFIG_ADDRESS, address)
        let data = inl(PCI_CONFIG_DATA)

        return data
    }


    func readConfigWords(device: UInt8, function: UInt8, offset: UInt)
        -> (UInt16, UInt16) {

        let data = readConfigLong(device: device, function: function, offset: offset)
        let word1 = UInt16(truncatingBitPattern: data)
        let word2 = UInt16(truncatingBitPattern: (data >> 16))

        return (word1, word2)
    }


    func readConfigBytes(device: UInt8, function: UInt8, offset: UInt)
        -> (UInt8, UInt8, UInt8, UInt8) {

        let data = readConfigLong(device: device, function: function, offset: offset)
        let byte1 = UInt8(truncatingBitPattern: data)
        let byte2 = UInt8(truncatingBitPattern: (data >> 8))
        let byte3 = UInt8(truncatingBitPattern: (data >> 16))
        let byte4 = UInt8(truncatingBitPattern: (data >> 24))

        return (byte1, byte2, byte3, byte4)
    }
}


struct PCIBusMMIO: PCIBus, CustomStringConvertible {
    private let baseAddress: VirtualAddress
    let bus:         UInt8
    let description: String


    init?(mmiobase: PhysAddress, bus: UInt8) {
        self.bus = bus
        let address = mmiobase.advanced(by: UInt(bus) << 20)
        baseAddress = address.vaddr
        description = String.sprintf("PCIBusMMIO @ %p", address.value)
    }


    func readConfigLong(device: UInt8, function: UInt8, offset: UInt)
        -> UInt32 {

        let address = baseAddress | UInt(device) << 15 | UInt(function) << 12 | (offset & 0xfff)
        return UnsafePointer<UInt32>(bitPattern: address)!.pointee
    }


    func readConfigWords(device: UInt8, function: UInt8, offset: UInt)
        -> (UInt16, UInt16) {

        let data = readConfigLong(device: device, function: function, offset: offset)
        let word1 = UInt16(truncatingBitPattern: data)
        let word2 = UInt16(truncatingBitPattern: (data >> 16))

        return (word1, word2)
    }


    func readConfigBytes(device: UInt8, function: UInt8, offset: UInt)
        -> (UInt8, UInt8, UInt8, UInt8) {

        let data = readConfigLong(device: device, function: function, offset: offset)
        let byte1 = UInt8(truncatingBitPattern: data)
        let byte2 = UInt8(truncatingBitPattern: (data >> 8))
        let byte3 = UInt8(truncatingBitPattern: (data >> 16))
        let byte4 = UInt8(truncatingBitPattern: (data >> 24))

        return (byte1, byte2, byte3, byte4)
    }
}


struct PCIDeviceFunction: CustomStringConvertible {

    let bus:        PCIBus
    let device:     UInt8
    let function:   UInt8

    var vendor:       UInt16 { return readConfigWords(0).0 }
    var deviceId:     UInt16 { return readConfigWords(0).1 }
    var classCode:    UInt8 { return readConfigBytes(0x8).3 }
    var subClassCode: UInt8 { return readConfigBytes(0x8).2 }
    var headerType:   UInt8 { return readConfigBytes(0xc).2 }

    var description: String {
        let fmt: StaticString =
            "%2.2X:%2.2X/%u: %4.4X:%4.4X [%2.2X%2.2X] HT: %2.2X %@"
        return String.sprintf(fmt, bus.bus, device, function, vendor, deviceId,
            classCode, subClassCode, headerType, bus)
    }


    init?(bus: PCIBus, device: UInt8, function: UInt8) {
        self.bus = bus
        self.device = device
        self.function = function

        if (vendor == 0xFFFF) {
            return nil
        }
    }


    func readConfigLong(_ offset: UInt) -> UInt32 {
        return bus.readConfigLong(device: device, function: function,
            offset: offset)
    }


    func readConfigWords(_ offset: UInt) -> (UInt16, UInt16) {
        return bus.readConfigWords(device: device, function: function,
            offset: offset)
    }


    func readConfigBytes(_ offset: UInt) -> (UInt8, UInt8, UInt8, UInt8) {
        return bus.readConfigBytes(device: device, function: function,
            offset: offset)
    }


    func subFunctions() -> [PCIDeviceFunction]? {
        var functions: [PCIDeviceFunction] = []
        if (headerType & 0x80) == 0x80 {
            for fidx: UInt8 in 1..<8 {
                if let dev = PCIDeviceFunction(bus: bus, device: device, function: fidx) {
                    functions.append(dev)
                }
            }
        }

        return functions.count > 0 ? functions : nil
    }
}


// Singleton that will be initialised by PCI.scan()
private let pciDevices = PCI.scanAllBuses()


struct PCI {

    static var mcfgTable: MCFG?

    static func scan(mcfgTable: MCFG?) {
        PCI.mcfgTable = mcfgTable

        print("PCI: Scanning bus")
        for device in pciDevices {
            print("PCI: \(device)")
        }
        print("PCI: Scan finished")
    }


    // FIXME: should do something better then a bruteforce scan
    fileprivate static func scanAllBuses() -> [PCIDeviceFunction] {
        var devices: [PCIDeviceFunction] = []
        for bus in 0...255 {
            if let pciBus = findPciBus(UInt8(bus)) {
                for device: UInt8 in 0..<32 {
                    if let pciDev = PCIDeviceFunction(bus: pciBus,
                        device: device, function: 0) {
                        devices.append(pciDev)
                        if let subFuncs = pciDev.subFunctions() {
                            for dev in subFuncs {
                                devices.append(dev)
                            }
                        }
                    }
                }
            }
        }

        return devices
    }


    // See if the bus can be accessed using MMCONFIG or PIO
    private static func findPciBus(_ bus: UInt8) -> PCIBus? {
        if let address = mcfgTable?.baseAddressForBus(bus) {
            return PCIBusMMIO(mmiobase: address, bus: bus)
        } else {
            return PCIBusPIO(bus: bus)
        }
    }
}
