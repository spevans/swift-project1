/*
 * kernel/devices/pci/pcibus.swift
 *
 * Created by Simon Evans on 27/07/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * PCI Bus class.
 *
 */


final class PCIBus: DeviceDriver {
    let interruptRoutingTable: PCIRoutingTable?
    let busId: UInt8
    var resources: [MotherBoardResource] = []
    let isHostBus: Bool

    private(set) var devices: [Device] = []
    override var description: String { "PCIBus: busId: \(asHex(busId)) \(device.fullName)" }

    // Root Bus
    init?(pnpDevice: PNPDevice) {
        isHostBus = true
        // Get the Bus number
        // FIXME: Add method to walk up the tree finding a given node by name
        var busId: UInt8 = 0
        var p: ACPI.ACPIObjectNode? = pnpDevice.device.acpiDeviceConfig?.node
        while let _node = p {
            if let bbnValue = try? _node.baseBusNumber() {
                print("Found _BBN node on parent:", _node.fullname())
                busId = bbnValue
                break
            }
            p = _node.parent
        }
        self.busId = busId

        guard let acpiConfig = pnpDevice.device.acpiDeviceConfig else {
            print("PCI: PCIBus: busId: \(asHex(busId)) \(pnpDevice.device.fullName) has no ACPI config")
            return nil
        }
        print("PCIBus.init \(pnpDevice.device.fullName): busId: \(busId)")
        // FIXME: Determine if root bus
        if let prt = acpiConfig.prt {
            print("PCIBus, have PRT")
            interruptRoutingTable = prt
        } else {
            interruptRoutingTable = nil //PCIRoutingTable(acpi: acpiDevice)
        }
        super.init(device: pnpDevice.device)
        print("PCIBus.init:", self.description)
    }

    init?(pciDevice: PCIDevice) {
        // FIXME for PCI express root port
        guard let busClass = pciDevice.deviceFunction.deviceClass?.bridgeSubClass, busClass == .pci else {
            print("PCIBus: \(pciDevice) is not a PCI-PCI Bridge")
            return nil
        }
        self.busId = pciDevice.deviceFunction.bridgeDevice!.secondaryBusId
        isHostBus = false
        self.interruptRoutingTable = nil
        super.init(device: pciDevice.device)
    }

    // Non PCI Devices (eg ACPIDevice) may get added to this bus as it is in the ACPI device tree under a PCI bus
    func addDevice(_ device: Device) {
        devices.append(device)
    }

    override func initialise() -> Bool {
        print("PCIBus.initialiseDevice:", self)
        // Scan PCI bus for any remaining devices
        for deviceFunction in scanBus() {
            print("Adding \(deviceFunction)")
            // FIXME: Try and find matching ACPI device node
            if let device = self.device(deviceFunction: deviceFunction) {
                addDevice(device)
            } else {
                print("PCIBus: Could not add \(deviceFunction)")
            }

        }
        devices.sort {
            let dev0 = $0.busDevice as? PCIDevice
            let dev1 = $1.busDevice as? PCIDevice

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
            guard let pciDevice = device.busDevice as? PCIDevice else { continue }
            if let deviceClass = pciDevice.deviceFunction.deviceClass {
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


    func device(deviceFunction: PCIDeviceFunction) -> Device? {
        let device = Device(parent: self.device, fullName: deviceFunction.description)
        guard let pciDevice = PCIDevice(device: device, deviceFunction: deviceFunction) else {
            print("PCI: Cant create PCI device for:", deviceFunction)
            return nil
        }
        device.setBusDevice(pciDevice)

        if let busClass = deviceFunction.deviceClass?.bridgeSubClass {
            switch busClass {
                case .isa:
                    guard let driver = ISABus(pciDevice: pciDevice) else {
                        print("PCI: Cant create ISA BUS")
                        return nil
                    }
                    _ = driver.initialise()
                    return device

                case .host:
                    // FIXME - this could be a PCIExpress Root bus
                    print("PCI: Error: Found a PCI Host bus \(pciDevice) on a PCI bus \(self), bridgeDevice:", deviceFunction.bridgeDevice != nil)
                    return nil

                case .pci:
                    guard let driver = PCIBus(pciDevice: pciDevice) else {
                        print("PCI: Cant Create PCBus from:", pciDevice)
                        return nil
                    }
                    _ = driver.initialise()
                    return device

                default:
                    print("PCI Ignoring bus of type \(deviceFunction)")
            }
        }

        return device
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
            guard let pciDevice = device.busDevice as? PCIDevice else { continue }
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
            // currentFuntions has bitX set where functionX is already known
            let pciDev: PCIDeviceFunction
            let currentFunctions: UInt8
            if currentPCIDevices[device] == nil {
                pciDev = PCIDeviceFunction(busId: busId, device: device, function: 0)
                guard pciDev.hasValidVendor, pciDev.hasSubFunction else { continue }
                currentFunctions = 0
            } else {
                currentFunctions = currentPCIDevices[device]!
                // Doesnt return function 0 so check it seperately.
                if currentFunctions & 1 == 0 {
                    pciDev = PCIDeviceFunction(busId: busId, device: device, function: 0)
                    pciDeviceFunctions.append(pciDev)
                }
            }
            for fidx: UInt8 in 1..<8 {
                if (1 << fidx) & currentFunctions == 0 {
                    let dev = PCIDeviceFunction(busId: busId, device: device, function: fidx)
                    if dev.hasValidVendor {
                        pciDeviceFunctions.append(dev)
                    }
                }
            }
        }
        return pciDeviceFunctions
    }
}
