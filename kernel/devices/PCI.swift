/*
 * kernel/devices/PCI.swift
 *
 * Created by Simon Evans on 28/12/2015.
 * Copyright © 2015 - 2017 Simon Evans. All rights reserved.
 *
 * Basic PCI bus scan routine
 *
 */


class PCIBus: Bus {
    let bus: UInt8

    func readConfigLong(device: UInt8, function: UInt8, offset: UInt) -> UInt32 { fatalError("abstract function") }
    func readConfigWords(device: UInt8, function: UInt8, offset: UInt) -> (UInt16, UInt16)  { fatalError("abstract function") }
    func readConfigBytes(device: UInt8, function: UInt8, offset: UInt) -> (UInt8, UInt8, UInt8, UInt8)  { fatalError("abstract function") }

    init(parentBus: Bus, acpi: ACPI.ACPIObjectNode, busId: UInt8) {
        self.bus = busId
        super.init(parentBus: parentBus, acpi: acpi)
    }

    func scanBus() -> [PCIDeviceFunction] {
        var pciDeviceFunctions: [PCIDeviceFunction] = []
        print("PCI: Scanning bus \(bus)")
        for device: UInt8 in 0..<32 {
            if let pciDev = PCIDeviceFunction(bus: self, device: device, function: 0) {
                pciDeviceFunctions.append(pciDev)
                if let subFuncs = pciDev.subFunctions() {
                    for dev in subFuncs {
                        pciDeviceFunctions.append(dev)
                    }
                }
            }
        }
        for device in pciDeviceFunctions {
            print("PCI: \(device)")
        }
        print("PCI: Scan finished")

        return pciDeviceFunctions
    }


    override func device(parentBus: Bus, address: UInt32, acpiNode: ACPI.ACPIObjectNode) -> Device? {
        guard let deviceFunction = PCIDeviceFunction(bus: self, address: address) else { return nil }

        switch (deviceFunction.vendor, deviceFunction.deviceId) {
            case (0x8086, 0x7000),
                (0x8086, 0x7110):
                if let pciDevice = PIIX(parentBus: parentBus, deviceFunction: deviceFunction, acpi: acpiNode) {
                    return pciDevice
            }
            default:
                if let pciDevice = UnknownPCIDevice(parentBus: parentBus, deviceFunction: deviceFunction, acpi: acpiNode) {
                    return pciDevice
            }
        }
        return nil
    }


    static func createBus(parentBus: Bus, acpi: ACPI.ACPIObjectNode, busID: UInt8) -> Bus {
           let mcfgTable = system.deviceManager.acpiTables.mcfg
           if let address = mcfgTable?.baseAddressFor(bus: busID) {
               return PCIBusMMIO(parentBus: parentBus, acpi: acpi, mmiobase: address, busID: busID)
           } else {
               return PCIBusPIO(parentBus: parentBus, acpi: acpi, busID: busID)
           }
       }
}


protocol PCIDevice {
    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction)
    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpi: ACPI.ACPIObjectNode)
}


final class UnknownPCIDevice: UnknownDevice, PCIDevice {
    let deviceFunction: PCIDeviceFunction
    let acpiName: String?

    override var description: String {
        var desc = "PCI: Unknown device: " + deviceFunction.description
        if let name = acpiName {
            desc.append(": ")
            desc.append(name)
        }
        return desc
    }

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction) {
        self.deviceFunction = deviceFunction
        acpiName = nil
        super.init()
    }

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpi: ACPI.ACPIObjectNode) {
        self.deviceFunction = deviceFunction
        acpiName = acpi.fullname()
        super.init()
    }

    override init?(parentBus: Bus, pnpName: String?, acpiNode: ACPI.ACPIObjectNode? = nil) {
        guard let acpiNode = acpiNode else { return nil }
        guard let address = acpiNode.addressResource() else { return nil }
        guard let deviceFunction = PCIDeviceFunction(bus: parentBus as! PCIBus, address: UInt32(address)) else { return nil }
        self.deviceFunction = deviceFunction
        acpiName = acpiNode.fullname()
        super.init()
    }
}


class PCIBusPIO: PCIBus, CustomStringConvertible {
    private let PCI_CONFIG_ADDRESS: UInt16 = 0xCF8
    private let PCI_CONFIG_DATA:    UInt16 = 0xCFC
    private let baseAddress: UInt32

    var description: String {
        return String.sprintf("PCIBusPIO @ %8.8X", baseAddress)
    }


    init(parentBus: Bus, acpi: ACPI.ACPIObjectNode, busID: UInt8) {
        baseAddress = UInt32(busID) << 16 | 0x80000000;
        super.init(parentBus: parentBus, acpi: acpi, busId: busID)
    }



    override func readConfigLong(device: UInt8, function: UInt8, offset: UInt) -> UInt32 {
        let address = baseAddress | UInt32(device) << 11 | UInt32(function) << 8
            | UInt32(offset & 0xfc)
        outl(PCI_CONFIG_ADDRESS, address)
        let data = inl(PCI_CONFIG_DATA)

        return data
    }


    override func readConfigWords(device: UInt8, function: UInt8, offset: UInt)
        -> (UInt16, UInt16) {

        let data = readConfigLong(device: device, function: function, offset: offset)
        let word1 = UInt16(truncatingIfNeeded: data)
        let word2 = UInt16(truncatingIfNeeded: (data >> 16))

        return (word1, word2)
    }


    override func readConfigBytes(device: UInt8, function: UInt8, offset: UInt)
        -> (UInt8, UInt8, UInt8, UInt8) {

        let data = readConfigLong(device: device, function: function, offset: offset)
        let byte1 = UInt8(truncatingIfNeeded: data)
        let byte2 = UInt8(truncatingIfNeeded: (data >> 8))
        let byte3 = UInt8(truncatingIfNeeded: (data >> 16))
        let byte4 = UInt8(truncatingIfNeeded: (data >> 24))

        return (byte1, byte2, byte3, byte4)
    }
}


class PCIBusMMIO: PCIBus, CustomStringConvertible {
    private let baseAddress: VirtualAddress

    var description: String {
        return String.sprintf("PCIBusMMIO @ %p", baseAddress)
    }


    init(parentBus: Bus, acpi: ACPI.ACPIObjectNode, mmiobase: PhysAddress, busID: UInt8) {
        let address = mmiobase.advanced(by: UInt(busID) << 20)
        baseAddress = address.vaddr
        super.init(parentBus: parentBus, acpi: acpi, busId: busID)
    }


    override func readConfigLong(device: UInt8, function: UInt8, offset: UInt)
        -> UInt32 {

        let address = baseAddress | UInt(device) << 15 | UInt(function) << 12 | (offset & 0xfff)
        return UnsafePointer<UInt32>(bitPattern: address)!.pointee
    }


    override func readConfigWords(device: UInt8, function: UInt8, offset: UInt)
        -> (UInt16, UInt16) {

        let data = readConfigLong(device: device, function: function, offset: offset)
        let word1 = UInt16(truncatingIfNeeded: data)
        let word2 = UInt16(truncatingIfNeeded: (data >> 16))

        return (word1, word2)
    }


    override func readConfigBytes(device: UInt8, function: UInt8, offset: UInt)
        -> (UInt8, UInt8, UInt8, UInt8) {

        let data = readConfigLong(device: device, function: function, offset: offset)
        let byte1 = UInt8(truncatingIfNeeded: data)
        let byte2 = UInt8(truncatingIfNeeded: (data >> 8))
        let byte3 = UInt8(truncatingIfNeeded: (data >> 16))
        let byte4 = UInt8(truncatingIfNeeded: (data >> 24))

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
    var acpiADR:    UInt32 { return UInt32(withWords: UInt16(function), UInt16(device)) }

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


    init?(bus: PCIBus, address: UInt32) {
        self.bus = bus
        self.device = UInt8(address >> 16)
        self.function = UInt8(address & 0xffff)

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
