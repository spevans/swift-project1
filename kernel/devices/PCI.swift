/*
 * kernel/devices/PCI.swift
 *
 * Created by Simon Evans on 28/12/2015.
 * Copyright © 2015 Simon Evans. All rights reserved.
 *
 * Basic PCI bus scan routine
 *
 */


struct PCIDeviceFunction: CustomStringConvertible  {
    let PCI_CONFIG_ADDRESS: UInt16 = 0xCF8
    let PCI_CONFIG_DATA:    UInt16 = 0xCFC

    let bus:               UInt8
    let device:            UInt8
    let function:          UInt8
    let baseAddress:       UInt32

    var vendor:       UInt16 { return readConfigWords(offset: 0).0 }
    var deviceId:     UInt16 { return readConfigWords(offset: 0).1 }
    var classCode:    UInt8 { return readConfigBytes(offset: 0x8).3 }
    var subClassCode: UInt8 { return readConfigBytes(offset: 0x8).2 }
    var headerType:   UInt8 { return readConfigBytes(offset: 0xc).2 }

    var description: String {
        return String.sprintf("%2.2X:%2.2X/%d: %4.4X:%4.4X [%2.2X%2.2X] HT: %2.2X",
            bus, device, function, vendor, deviceId, classCode, subClassCode, headerType)
    }


    init?(bus: UInt8, device: UInt8, function: UInt8) {
        self.bus = bus
        self.device = device
        self.function = function
        baseAddress = UInt32(bus) << 16 | UInt32(device) << 11 | UInt32(function) << 8 | 0x80000000;

        if (vendor == 0xFFFF) {
            return nil
        }
    }


    func readConfigLong(offset offset: UInt8) -> UInt32 {
        let address = baseAddress | UInt32(offset & 0xfc)
        outl(PCI_CONFIG_ADDRESS, address)
        let data = inl(PCI_CONFIG_DATA)

        return data
    }


    func readConfigWords(offset offset: UInt8) -> (UInt16, UInt16) {
        let data = readConfigLong(offset: offset)
        let word1 = UInt16(truncatingBitPattern: data)
        let word2 = UInt16(truncatingBitPattern: (data >> 16))

        return (word1, word2)
    }


    func readConfigBytes(offset offset: UInt8) -> (UInt8, UInt8, UInt8, UInt8) {
        let data = readConfigLong(offset: offset)
        let byte1 = UInt8(truncatingBitPattern: data)
        let byte2 = UInt8(truncatingBitPattern: (data >> 8))
        let byte3 = UInt8(truncatingBitPattern: (data >> 16))
        let byte4 = UInt8(truncatingBitPattern: (data >> 24))

        return (byte1, byte2, byte3, byte4)
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

    static func scan() {
        print("PCI: Scanning bus")
        for device in pciDevices {
            print("PCI: \(device)")
        }
        print("PCI: Scan finished")
    }


    private static func scanAllBuses() -> [PCIDeviceFunction] {
        var devices: [PCIDeviceFunction] = []
        for bus: UInt8 in 0...0 {
            for device: UInt8 in 0..<32 {
                if let pciDev = PCIDeviceFunction(bus: bus, device: device, function: 0) {
                    devices.append(pciDev)
                    if let subFuncs = pciDev.subFunctions() {
                        for dev in subFuncs {
                            devices.append(dev)
                        }
                    }
                }
            }
        }

        return devices
    }
}
