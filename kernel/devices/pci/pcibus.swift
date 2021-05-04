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
    let pciBus: PCIBus                  // The bus (downstream) side of the bridge

    unowned let parentBus: Bus
    let acpiDevice: AMLDefDevice?
    let fullName: String
    let deviceFunction: PCIDeviceFunction       // The device (upstream) side of the bridge
    var enabled = true

    var deviceDriver: DeviceDriver? { pciBus as DeviceDriver }
    var description: String { "PCI Host BUS \(deviceFunction.description) \(acpiDevice?.fullname() ?? "")" }


    init(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpiDevice: AMLDefDevice) {
        guard deviceFunction.deviceClass?.bridgeSubClass == .host else {
            fatalError("bridgeDevice is nil or not a Host-PCI bridge \(deviceFunction)")
        }

        self.parentBus = parentBus
        self.acpiDevice = acpiDevice
        self.fullName = acpiDevice.fullname()
        self.deviceFunction = deviceFunction
        let configSpace = PCIConfigSpace(busId: 0, device: 0, function: 0)
        self.pciBus = PCIBus(pciConfigSpace: configSpace, deviceFunction: deviceFunction, acpiDevice: acpiDevice)
    }

    func initialiseDevice() {
        pciBus.initialiseDevice()
    }
}


final class PCIBus: PCIDeviceDriver, Bus, CustomStringConvertible {
    private let deviceFunction: PCIDeviceFunction
    private let acpiDevice: AMLDefDevice?
    private let interruptRoutingTable: PCIRoutingTable?

    var resources: [MotherBoardResource] = []
    let pciConfigSpace: PCIConfigSpace

    private(set) var devices: [Device] = []
    var busId: UInt8 { pciConfigSpace.busId }
    var description: String { "PCIBus: \(pciConfigSpace) busId: \(pciConfigSpace.busId) \(deviceFunction.description) \(acpiDevice?.fullname() ?? "")" }


    fileprivate init(pciConfigSpace: PCIConfigSpace, deviceFunction: PCIDeviceFunction, acpiDevice: AMLDefDevice? = nil) {
        self.pciConfigSpace = pciConfigSpace
        self.deviceFunction = deviceFunction
        self.acpiDevice = acpiDevice

        if let acpi = acpiDevice {
            interruptRoutingTable = PCIRoutingTable(acpi: acpi)
        } else {
            print("PCIBus: \(pciConfigSpace) has no ACPI device")
            interruptRoutingTable = nil
        }
    }

    init?(pciDevice: PCIDevice) {

        guard let busClass = pciDevice.deviceFunction.deviceClass?.bridgeSubClass, busClass == .pci else {
            print("PCIBus: \(pciDevice) is not a PCI-PCI Bridge")
            return nil
        }

        let configSpace = PCIConfigSpace(busId: pciDevice.deviceFunction.bridgeDevice!.secondaryBusId, device: 0, function: 0)
        self.pciConfigSpace = configSpace
        self.deviceFunction = pciDevice.deviceFunction
        self.acpiDevice = pciDevice.acpiDevice
        interruptRoutingTable = nil
    }

    // Non PCI Devices (eg ACPIDevice) may get added to this bus as it is in the ACPI device tree under a PCI bus
    func addDevice(_ device: Device) {
        devices.append(device)
    }

    func initialiseDevice() {
        // Look for devices in ACPI tree
        initialiseDevices(acpiDevice: acpiDevice)
        // Scan PCI bus for any remaining devices
        for deviceFunction in scanBus() {
            if let device = self.device(deviceFunction: deviceFunction, acpiDevice: acpiDevice) {
                addDevice(device)
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


    func device(acpiDevice: AMLDefDevice, pnpName: String? = nil) -> Device? {
        // Is it a normal PCI Device
        if let address = acpiDevice.addressResource() {
            guard let deviceFunction = PCIBus.pciDeviceFunctionFor(address: address, withBusId: self.busId) else {
                // Inactive or missing PCI device
                return nil
            }
            return device(deviceFunction: deviceFunction, acpiDevice: acpiDevice)
        } else if let pnpName = pnpName {
            return ACPIDevice(parentBus: self, pnpName: pnpName, acpiDevice: acpiDevice)
        } else {
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
                    pciDevice.pciDeviceDriver = ISABus(pciDevice: pciDevice)
                    return pciDevice

                case .host:
                    print("PCI: Error: Found a PCI Host bus on a PCI bus, bridgeDevice:", deviceFunction.bridgeDevice as Any)
                    print(pciDevice)
                    return nil

                case .pci:
                    let configSpace = PCIConfigSpace(busId: pciDevice.deviceFunction.bridgeDevice!.secondaryBusId, device: 0, function: 0)
                    pciDevice.pciDeviceDriver = PCIBus(pciConfigSpace: configSpace, deviceFunction: deviceFunction, acpiDevice: acpiDevice)
                    return pciDevice

                default:
                    print("PCI Ignoring bus of type \(deviceFunction)")
            }
        }

        if let driverType = pciDriverById(vendor: deviceFunction.vendor, device: deviceFunction.deviceId) {
            print("Found driver type: \(driverType) for \(deviceFunction)")
            if let driver = driverType.init(pciDevice: pciDevice) {
                pciDevice.pciDeviceDriver = driver
            }
        }

        return pciDevice
    }


    func findInterruptFor(pciDevice: PCIDevice) -> IRQSetting? {
        print("PCI: Looking for interrupt for device: \(pciDevice)")


        guard let itr = interruptRoutingTable else {
            print("No interrupt routing table found")
            return nil
        }
        guard let entry = itr.findEntryByDevice(pciDevice: pciDevice) else {
            print("Cant find interrupt routing table entry for \(pciDevice)")
            return nil
        }

        print("PCI: Found routing entry \(entry), pin: \(entry.pin)")

        if case .string(let namePath) = entry.source {
            print("NamePath: \(namePath)")
            // FIXME, should have better way of walking up the tree
            guard let (node, fullname) = itr.prtAcpiNode.topParent().getGlobalObject(currentScope: AMLNameString(itr.prtAcpiNode.fullname()), name: namePath) else {
                print("PCI: Cant find object for \(namePath) under \(itr.prtAcpiNode.fullname())")
                return nil
            }

            print("Link device:", fullname, node)
            guard let devNode = node as? AMLDefDevice else {
                print("\(fullname) is not an AMLDefDevice")
                return nil
            }

            guard let device = devNode.device?.deviceDriver as? PCIInterruptLinkDevice else {
                print("\(fullname) has no attached PCI InterruptLink device")
                return nil
            }
            print("devNode: \(devNode) device: \(devNode.device as Any), LNK Device: \(device), irq:", device.irq)
            return device.irq
        }
        return nil
    }

    // Convert an ACPI _ADR PCI address and busId. Only returns if the PCI device has valid vendor/device codes.
    static func pciDeviceFunctionFor(address: AMLInteger, withBusId busId: UInt8) -> PCIDeviceFunction? {
        let device = UInt8(address >> 16)
        let function = UInt8(truncatingIfNeeded: address)
        return PCIDeviceFunction(busId: busId, device: device, function: function)
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
            if pciConfigSpace.busId == 0 && device == deviceFunction.device {
                print("PCI: scanbus: Skipping \(deviceFunction) PCIBus on busId: 0")
                continue
            }

            if let curDevices = currentPCIDevices[device], curDevices == 0 {
                // Already found this non-multifunction device
                continue
            }
            let currentFunctions = currentPCIDevices[device] ?? 0   // currentFuntions has bitX set where functionX is already known

            if let pciDev = PCIDeviceFunction(bus: self, device: device, function: 0) {
                if currentFunctions & 1 == 0 { // subFunctions() doesnt return function 0 so check it seperately.
                    pciDeviceFunctions.append(pciDev)
                }
                if let subFuncs = pciDev.subFunctions() {
                    for dev in subFuncs {
                        if (1 << dev.function) & currentFunctions == 0 {
                            pciDeviceFunctions.append(dev)
                        }
                    }
                }
            }
        }

        return pciDeviceFunctions
    }
}
