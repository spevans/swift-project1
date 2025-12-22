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
    /*private*/ let busDevice: Device   // Could be PCIDevice or PNPDevice, FIXME: should be private
    let busId: UInt8
    let isHostBus: Bool
    private(set) var devices: [Device] = []

#if ACPI
    // Root Bus
    init?(pnpDevice: PNPDevice) {
        // Get the Bus number
        // FIXME: Add method to walk up the tree finding a given node by name
        var busId: UInt8 = 0
        var p: ACPI.ACPIObjectNode? = pnpDevice.acpiNode()
        while let _node = p {
            if let bbnValue = try? _node.baseBusNumber() {
                #kprint("Found _BBN node on parent:", _node.fullname())
                busId = bbnValue
                break
            }
            p = _node.parent
        }
        self.busDevice = pnpDevice
        self.busId = busId
        self.isHostBus = true

        super.init(driverName: "pcibus", device: pnpDevice)
        self.setInstanceName(to: "pcibus\(busId)")
        #kprint("PCIBus.init:", pnpDevice.description, self.description, pnpDevice.description)
    }
#endif

    init?(pciDevice: PCIDevice) {
        // FIXME for PCI express root port
        guard let busClass = pciDevice.deviceFunction.deviceClass?.bridgeSubClass, busClass == .pci else {
            #kprint("PCIBus: \(pciDevice) is not a PCI-PCI Bridge")
            return nil
        }
        self.busDevice = pciDevice
        self.busId = pciDevice.deviceFunction.bridgeDevice!.secondaryBusId
        self.isHostBus = false
        super.init(driverName: "pcibus", device: pciDevice)
        self.setInstanceName(to: "pcibus\(busId)")
    }

    // Non PCI Devices (eg ACPIDevice) may get added to this bus as it is in the ACPI device tree under a PCI bus
    func addDevice(_ device: Device) {
        devices.append(device)
    }

    override func initialise() -> Bool {
        #kprint("PCIBus.initialiseDevice:", self)

#if ACPI
        // Find child nodes that are devices and build a map of _ADR to node
        var adrNodeMap: [AMLInteger : ACPI.ACPIObjectNode] = [:]
        if let pnpDevice = self.busDevice as? PNPDevice {
            let childACPINodes = pnpDevice.acpiNode().childNodes
            for node in childACPINodes.values {
                if node.object.isDevice, let adr = try? node.addressResource() {
                    adrNodeMap[adr] = node
                }
            }
        }
#endif

        // Scan PCI bus for any remaining devices
        for deviceFunction in scanBus() {
            #kprint("PCI: Found \(deviceFunction)")
            // FIXME: Try and find matching ACPI device node

            let newParent: Device
#if ACPI
            if let node = adrNodeMap[AMLInteger(deviceFunction.acpiADR)], let d = node.device {
                #kprint("PCI: Found node", node.fullname(), "with device:", d)
                newParent = d
            } else {
                newParent = self.busDevice
            }
#else
            newParent = self.device
#endif

            guard let pciDevice = self.device(deviceFunction: deviceFunction, newParent: newParent) else {
                #kprint("PCI: Could not add \(deviceFunction)")
                continue
            }
            addDevice(pciDevice)
            // Should a PCI bus be initialised here?
            _ = pciDevice.deviceDriver?.initialise()
        }

        devices.sort {
            guard let dev0 = $0 as? PCIDevice, let dev1 = $1 as? PCIDevice else {
                return false
            }
            return dev0.deviceFunction < dev1.deviceFunction
        }
        return true
    }

    // FIXME: Can this be removed and rolled into the function below?
    // Find PCI Devices matching a specific classCode and optional subClassCode and progInterface
    func devicesMatching(classCode: PCIClassCode? = nil, subClassCode: UInt8? = nil, progInterface: UInt8? = nil, body: (PCIDevice, PCIDeviceClass) -> ()) {
        for device in devices {
            guard let pciDevice = device as? PCIDevice else { continue }
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


    func devicesMatching(_ deviceMatches: Span<PCIDeviceMatch>, body: (PCIDevice) -> ()) {
        for device in self.devices {
            guard let pciDevice = device as? PCIDevice else { continue }
            for matchIdx in deviceMatches.indices {
                if deviceMatches[matchIdx].matches(pciDevice) {
                    body(pciDevice)
                }
                if let bus = device.deviceDriver as? PCIBus {
                    bus.devicesMatching(deviceMatches, body: body)
                }
            }
        }
    }


    func device(deviceFunction: PCIDeviceFunction, newParent: Device) -> PCIDevice? {
        guard let newDevice = PCIDevice(parent: newParent, deviceFunction: deviceFunction) else {
            #kprint("PCI: Cant create PCI device for:", deviceFunction)
            return nil
        }

        // FIXME, should the device had a driver attached here or enumerated elsewhere?
        if let busClass = deviceFunction.deviceClass?.bridgeSubClass {
            switch busClass {
                case .isa:
                    guard let driver = ISABus(pciDevice: newDevice), driver.initialise() else {
                        #kprint("PCI: Cant create ISA BUS")
                        return newDevice
                    }

                case .host:
                    // FIXME - this could be a PCIExpress Root bus
                    #kprint("PCI: Error: Found a PCI Host bus \(newDevice) on a PCI bus \(self)")
                    if let bridgeDevice = newDevice.deviceFunction.bridgeDevice {
                        #kprint("PCI: bridge device, secondary BusId", bridgeDevice.secondaryBusId)
                    }

                case .pci:
                    guard PCIBus(pciDevice: newDevice) != nil else {
                        #kprint("PCI: Cant Create PCBus from:", newDevice)
                        return newDevice
                    }

                default:
                    #kprint("PCI Ignoring bus of type \(deviceFunction)")
            }
        }

        return newDevice
    }

#if ACPI
    // Convert an ACPI _ADR PCI address and busId. Only returns if the PCI device has valid vendor/device codes.
    static func pciDeviceFunctionFor(address: AMLInteger, withBusId busId: UInt8) -> PCIDeviceFunction? {
        let device = UInt8(address >> 16)
        let function = UInt8(truncatingIfNeeded: address)
        let deviceFunction = PCIDeviceFunction(busId: busId, device: device, function: function)
        return deviceFunction.hasValidVendor ? deviceFunction : nil
    }
#endif

    // Scan the PCI bus for devices but ignore any that have already been added to the `devices` array by ACPI
    private func scanBus() -> [PCIDeviceFunction] {
        var pciDeviceFunctions: [PCIDeviceFunction] = []

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
            pciDeviceFunctions.append(pciDevice.deviceFunction)
        }

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
                guard pciDev.hasValidVendor else { continue }
                currentFunctions = 0
            } else {
                currentFunctions = currentPCIDevices[device]!
                // Doesnt return function 0 so check it seperately.
                if currentFunctions & 1 == 0 {
                    pciDev = PCIDeviceFunction(busId: busId, device: device, function: 0)
                    pciDeviceFunctions.append(pciDev)
                }
            }
            for fidx: UInt8 in 0..<8 {
                if (1 << fidx) & currentFunctions == 0 {
                    let dev = PCIDeviceFunction(busId: busId, device: device, function: fidx)
                    if dev.hasValidVendor {
                        pciDeviceFunctions.append(dev)
                    }
                }
            }
        }
        #kprintf("Found %d PCI devices on busId: %2.2x\n", pciDeviceFunctions.count, busId)
        return pciDeviceFunctions
    }
}
