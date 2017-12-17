/*
 * kernel/devices/PCI.swift
 *
 * Created by Simon Evans on 28/12/2015.
 * Copyright © 2015 - 2017 Simon Evans. All rights reserved.
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


extension PCIBus {
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
}

protocol PCIDevice {
    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction)
    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpi: ACPIGlobalObjects.ACPIObjectNode, fullName: String)
}


final class UnknownPCIDevice: Device, PCIDevice, CustomStringConvertible {
    let deviceFunction: PCIDeviceFunction
    let acpiName: String?

    var description: String {
        var desc = deviceFunction.description
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

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpi: ACPIGlobalObjects.ACPIObjectNode, fullName: String) {
        self.deviceFunction = deviceFunction
        acpiName = fullName
        super.init()
    }
}


class PCIBusPIO: Bus, PCIBus, CustomStringConvertible {
    private let PCI_CONFIG_ADDRESS: UInt16 = 0xCF8
    private let PCI_CONFIG_DATA:    UInt16 = 0xCFC
    private let baseAddress: UInt32
    let bus: UInt8

    var description: String {
        return String.sprintf("PCIBusPIO @ %8.8X", baseAddress)
    }


    init(parentBus: Bus, acpi: ACPIGlobalObjects.ACPIObjectNode, fullName: String, busID: UInt8) {
        baseAddress = UInt32(busID) << 16 | 0x80000000;
        bus = busID
        super.init(parentBus: parentBus, acpi: acpi, fullName: fullName)
    }


    override func initialiseDevices() {
        print("Initialising:", self)
        let name = fullName
        var adrMap: [UInt32: ACPIGlobalObjects.ACPIObjectNode] = [:]
        let deviceManager = system.deviceManager

        acpi.childNodes.forEach {
            let child = $0
            let fullName = (name == "\\") ? name + child.name :
                name + String(AMLNameString.pathSeparatorChar) + child.name

            var context = ACPI.AMLExecutionContext(scope: AMLNameString(fullName),
                                                   args: [],
                                                   globalObjects: deviceManager.acpiTables.globalObjects)
            if let device = child.object as? AMLDefDevice, let address = device.addressResource(context: &context) {
                debugPrint("Found an _ADR: 0x\(String(address, radix: 16))")
                adrMap[UInt32(address)] = child
            } else {
                processNode(parentBus: self, child, fullName)
            }
        }

        for deviceFunction in scanBus() {
            if let node = adrMap[deviceFunction.acpiADR] {
                let fullName = (name == "\\") ? name + node.name :
                    name + String(AMLNameString.pathSeparatorChar) + node.name
                switch (deviceFunction.vendor, deviceFunction.deviceId) {
                case (0x8086, 0x7000):
                    if let pciDevice = PIIX(parentBus: self, deviceFunction: deviceFunction,
                                            acpi: node, fullName: fullName) {
                        addDevice(pciDevice as Device)
                    }
                default:
                    if let pciDevice = UnknownPCIDevice(parentBus: self, deviceFunction: deviceFunction,
                                                        acpi: node, fullName: fullName) {
                        addDevice(pciDevice as Device)
                    }
                }
            } else {
                if let pciDevice = UnknownPCIDevice(parentBus: self, deviceFunction: deviceFunction) {
                    addDevice(pciDevice as Device)
                }
            }
        }
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
        let word1 = UInt16(truncatingIfNeeded: data)
        let word2 = UInt16(truncatingIfNeeded: (data >> 16))

        return (word1, word2)
    }


    func readConfigBytes(device: UInt8, function: UInt8, offset: UInt)
        -> (UInt8, UInt8, UInt8, UInt8) {

        let data = readConfigLong(device: device, function: function, offset: offset)
        let byte1 = UInt8(truncatingIfNeeded: data)
        let byte2 = UInt8(truncatingIfNeeded: (data >> 8))
        let byte3 = UInt8(truncatingIfNeeded: (data >> 16))
        let byte4 = UInt8(truncatingIfNeeded: (data >> 24))

        return (byte1, byte2, byte3, byte4)
    }
}


class PCIBusMMIO: Bus, PCIBus, CustomStringConvertible {
    private let baseAddress: VirtualAddress
    let bus: UInt8

    var description: String {
        return String.sprintf("PCIBusMMIO @ %p", baseAddress)
    }


    init(parentBus: Bus, acpi: ACPIGlobalObjects.ACPIObjectNode, fullName: String, mmiobase: PhysAddress, busID: UInt8) {
        bus = busID
        let address = mmiobase.advanced(by: UInt(busID) << 20)
        baseAddress = address.vaddr
        super.init(parentBus: parentBus, acpi: acpi, fullName: fullName)
    }


    func readConfigLong(device: UInt8, function: UInt8, offset: UInt)
        -> UInt32 {

        let address = baseAddress | UInt(device) << 15 | UInt(function) << 12 | (offset & 0xfff)
        return UnsafePointer<UInt32>(bitPattern: address)!.pointee
    }


    func readConfigWords(device: UInt8, function: UInt8, offset: UInt)
        -> (UInt16, UInt16) {

        let data = readConfigLong(device: device, function: function, offset: offset)
        let word1 = UInt16(truncatingIfNeeded: data)
        let word2 = UInt16(truncatingIfNeeded: (data >> 16))

        return (word1, word2)
    }


    func readConfigBytes(device: UInt8, function: UInt8, offset: UInt)
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


struct PCI {
    static func createBus(parentBus: Bus, acpi: ACPIGlobalObjects.ACPIObjectNode,
                          fullName: String, busID: UInt8) -> Bus {
        let mcfgTable = system.deviceManager.acpiTables.mcfg
        if let address = mcfgTable?.baseAddressFor(bus: busID) {
            return PCIBusMMIO(parentBus: parentBus, acpi: acpi, fullName: fullName, mmiobase: address, busID: busID)
        } else {
            return PCIBusPIO(parentBus: parentBus, acpi: acpi, fullName: fullName, busID: busID)
        }
    }
}
