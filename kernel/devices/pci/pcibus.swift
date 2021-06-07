/*
 * kernel/devices/pci/pcibus.swift
 *
 * Created by Simon Evans on 27/07/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * PCI Bus class.
 *
 */


final class PCIHostBus: Device, CustomStringConvertible {
    private(set) var pciBus: PCIBus?                  // The bus (downstream) side of the bridge
    var enabled = false

    unowned let parentBus: Bus
    let acpiDevice: AMLDefDevice?
    let fullName: String
    let busId: UInt8

    var deviceDriver: DeviceDriver? {
        // FIXME, why isnt this just pciBus as? DeviceDriver ??
        guard let bus = pciBus else { return nil }
        return bus as DeviceDriver
    }

    var description: String {
        let desc = pciBus?.description ?? "not initialised"
        return "Host BUS \(desc)"
    }

    init(parentBus: Bus, busId: UInt8, acpiDevice: AMLDefDevice) {
        self.parentBus = parentBus
        self.acpiDevice = acpiDevice
        self.fullName = acpiDevice.fullname()
        self.busId = busId
    }

    func addBus() {
        self.pciBus = PCIBus(busId: busId, device: self, acpiDevice: acpiDevice!)

    }

    func setDriver(_ driver: DeviceDriver) {
        // The PCIBus is a driver already
        fatalError("PCIHostBus already has a driver")
    }

    func initialise() -> Bool {
        guard let acpi = acpiDevice, acpi.initialiseIfPresent() else {
            return false
        }
        self.enabled = true
        return true
    }
}


final class PCIBus: PCIDeviceDriver, Bus, CustomStringConvertible {
    private unowned let device: Device
    let interruptRoutingTable: PCIRoutingTable?
    let busId: UInt8
    var resources: [MotherBoardResource] = []
    let pciConfigSpace: PCIConfigSpace

    var pciDevice: PCIDevice? { device as? PCIDevice }
    var parentBus: Bus? { device.parentBus }
    var acpiDevice: AMLDefDevice? { device.acpiDevice }

    private(set) var devices: [Device] = []
    var slot: UInt8? { pciDevice?.deviceFunction.slot }
    var description: String { "PCIBus: busId: \(asHex(busId)) \(acpiDevice?.fullname() ?? "")" }

    // Root Bus
    init(busId: UInt8, device: Device, acpiDevice: AMLDefDevice) {
        self.busId = busId
        self.device = device
        self.pciConfigSpace = PCIConfigSpace(busId: busId, device: 0, function: 0)

        let name = device.acpiDevice?.fullname() ?? "no name"
        print("PCIBus.init \(name): busId: \(busId)")
        // FIXME: Determine if root bus
        interruptRoutingTable = PCIRoutingTable(acpi: acpiDevice)
        print("PCIBus.init:", self.description)
    }

    init?(pciDevice: PCIDevice) {
        // FIXME for PCI express root port
        guard let busClass = pciDevice.deviceFunction.deviceClass?.bridgeSubClass, busClass == .pci else {
            print("PCIBus: \(pciDevice) is not a PCI-PCI Bridge")
            return nil
        }
        self.busId = pciDevice.deviceFunction.bridgeDevice!.secondaryBusId
        self.device = pciDevice
        self.pciConfigSpace = PCIConfigSpace(busId: busId, device: 0, function: 0)
        self.interruptRoutingTable = nil
    }

    // Non PCI Devices (eg ACPIDevice) may get added to this bus as it is in the ACPI device tree under a PCI bus
    func addDevice(_ device: Device) {
        devices.append(device)
    }

    func initialise() -> Bool {
        print("PCIBus.initialiseDevice:", self)
        if let device = pciDevice {
            guard device.initialise() else { return false }
        }
        // Scan PCI bus for any remaining devices
        for deviceFunction in scanBus() {
            print("Adding \(deviceFunction)")
            if let device = self.device(deviceFunction: deviceFunction, acpiDevice: acpiDevice) {
                addDevice(device)
            } else {
                print("PCIBus: Could not add \(deviceFunction)")
            }

        }
        devices.sort {
            let dev0 = $0 as? PCIDevice
            let dev1 = $1 as? PCIDevice
            if let dev0 = dev0, let dev1 = dev1 {
                return dev0.deviceFunction.deviceFunction < dev1.deviceFunction.deviceFunction
            } else if dev0 != nil {
                return true
            } else if dev1 != nil {
                return false
            } else {
                return $0.fullName < $1.fullName
            }
        }
        return true
    }

    // Find PCI Devices matching a specific classCode and optional subClassCode and progInterface
    func devicesMatching(classCode: PCIClassCode? = nil, subClassCode: UInt8? = nil, progInterface: UInt8? = nil, body: (PCIDevice, PCIDeviceClass) -> ()) {
        for device in devices {
            if let pciDevice = device as? PCIDevice, let deviceClass = pciDevice.deviceFunction.deviceClass {
                if let classCode = classCode {
                    if deviceClass.classCode == classCode {
                        if let subClassCode = subClassCode {
                            if deviceClass.subClassCode != subClassCode { continue }
                            if let progInterface = progInterface, deviceClass.progInterface != progInterface { continue }
                        }
                        body(pciDevice, deviceClass)
                    }
                } else {
                    body(pciDevice, deviceClass)
                }
            }
            if let bus = device.deviceDriver as? PCIBus {
                bus.devicesMatching(classCode: classCode, subClassCode: subClassCode, progInterface: progInterface, body: body)
            }
        }
    }


    func device(acpiDevice: AMLDefDevice) -> Device? {
        // Is it a normal PCI Device
        if let address = acpiDevice.addressResource() {// (address >> 16) != 0 { // _ADR slot == 0 is either the Root PCI bus or not a PCI device
            guard let deviceFunction = PCIBus.pciDeviceFunctionFor(address: address, withBusId: self.busId) else {
                // Inactive or missing PCI device
                return nil
            }
            return device(deviceFunction: deviceFunction, acpiDevice: acpiDevice)
        }

        let pnpName = acpiDevice.deviceId
        if let pnpName = pnpName {
            return PNPDevice(parentBus: self, acpiDevice: acpiDevice, pnpName: pnpName)
        } else {
            let pnpName = acpiDevice.pnpName()
            print("PCI: Cant add device \(acpiDevice.fullname()) with pnpName:", pnpName ?? "nil")
            return nil
        }
    }


    func device(deviceFunction: PCIDeviceFunction, acpiDevice: AMLDefDevice?) -> Device? {
        guard let pciDevice = PCIDevice(parentBus: self, deviceFunction: deviceFunction, acpiDevice: acpiDevice) else {
            print("PCI: Cant create PCI device for:", deviceFunction)
            return nil
        }

        if let busClass = deviceFunction.deviceClass?.bridgeSubClass {
            switch busClass {
                case .isa:
                    if let driver = ISABus(pciDevice: pciDevice) {
                        print("ISABus setting driver")
                        pciDevice.setDriver(driver)
                    }
                    return pciDevice

                case .host:
                    // FIXME - this could be a PCIExpress Root bus
                    print("PCI: Error: Found a PCI Host bus \(pciDevice) on a PCI bus \(self), bridgeDevice:", deviceFunction.bridgeDevice as Any)
                    return nil

                case .pci:
                    guard let driver = PCIBus(pciDevice: pciDevice) else {
                        print("PCI: Cant Crete PCBus from:", pciDevice)
                        return nil
                    }
                    pciDevice.setDriver(driver)
                    return pciDevice

                default:
                    print("PCI Ignoring bus of type \(deviceFunction)")
            }
        }

        return pciDevice
    }



    // Convert an ACPI _ADR PCI address and busId. Only returns if the PCI device has valid vendor/device codes.
    static func pciDeviceFunctionFor(address: AMLInteger, withBusId busId: UInt8) -> PCIDeviceFunction? {
        let device = UInt8(address >> 16)
        let function = UInt8(truncatingIfNeeded: address)
        let deviceFunction = PCIDeviceFunction(busId: busId, device: device, function: function)
        return deviceFunction.hasValidVendor ? deviceFunction : nil
    }

    // Scan the PCI bus for devices but ignore any that have already been added to the `devices` array by ACPI
    private func scanBus() -> [PCIDeviceFunction] {
        // Get current devices on bus by device number, key = devicveID (0-0x1F) value = 0 if non-multifunction else bitX = functionX
        var currentPCIDevices: [UInt8: UInt8] = [:]
        for device in devices {
            guard let pciDevice = device as? PCIDevice else { continue }
            let devId = pciDevice.deviceFunction.device
            if pciDevice.deviceFunction.function == 0 && !pciDevice.deviceFunction.hasSubFunction {
                currentPCIDevices[devId] = 0
            } else {
                currentPCIDevices[devId] = (currentPCIDevices[devId] ?? 0) | 1 << pciDevice.deviceFunction.function
            }
        }

        var pciDeviceFunctions: [PCIDeviceFunction] = []
        for device: UInt8 in 0..<32 {
            if let curDevices = currentPCIDevices[device], curDevices == 0 {
                // Already found this non-multifunction device
                continue
            }
            let currentFunctions = currentPCIDevices[device] ?? 0   // currentFuntions has bitX set where functionX is already known

            let pciDev = PCIDeviceFunction(busId: busId, device: device, function: 0)
            if pciDev.hasValidVendor {
                // Doesnt return function 0 so check it seperately.
                if currentFunctions & 1 == 0 {
                    pciDeviceFunctions.append(pciDev)
                }

                if pciDev.hasSubFunction {
                    for fidx: UInt8 in 1..<8 {
                        let dev = PCIDeviceFunction(busId: busId, device: device, function: fidx)
                        if dev.hasValidVendor,  (1 << dev.function) & currentFunctions == 0 {
                            pciDeviceFunctions.append(dev)
                        }
                    }
                }
            }
        }
        return pciDeviceFunctions
    }
}
