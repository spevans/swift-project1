/*
 * kernel/devices/pci/bus.swift
 *
 * Created by Simon Evans on 27/07/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * PCI Bus class.
 *
 */


class PCIBus: Bus, CustomStringConvertible {
    let busID: UInt8
    let pciConfigSpace: PCIConfigSpace

    var description: String { "\(pciConfigSpace.pciConfigAccess) busId: \(busID)" }

    init(parentBus: Bus, acpi: AMLDefDevice, busId: UInt8) {
        self.busID = busId
        pciConfigSpace = PCIConfigSpace(busID: busID, address: 0)
        super.init(parentBus: parentBus, acpi: acpi)
    }


    // Scan the PCI bus for devices but ignore any that have already been added to the `devices` array by ACPI
    private func scanBus() -> [PCIDeviceFunction] {

        // Get current devices on bus by device number
        var currentPCIDevices: Set<UInt8> = []
        for dev in self.devices {
            if let pciDevice = dev as? PCIDevice {
                currentPCIDevices.insert(pciDevice.deviceFunction.device)
            }
        }

        var pciDeviceFunctions: [PCIDeviceFunction] = []
        print("PCI: Scanning bus \(self)")
        for device: UInt8 in 0..<32 {
            if !currentPCIDevices.contains(device),
                let pciDev = PCIDeviceFunction(bus: self, device: device, function: 0) {
                pciDeviceFunctions.append(pciDev)
                if let subFuncs = pciDev.subFunctions() {
                    for dev in subFuncs {
                        pciDeviceFunctions.append(dev)
                    }
                }
            }
        }
        print("PCI: Scan finished")

        return pciDeviceFunctions
    }


    override func initialiseDevices() {
        super.initialiseDevices()

        print("PCI: Scanning for more devices:")
        for deviceFunction in scanBus() {
            if let device = UnknownPCIDevice(parentBus: self, deviceFunction: deviceFunction) {
                self.addDevice(device)
            }
        }
    }


    override func device(parentBus: Bus, address: UInt32, acpiNode: AMLDefDevice) -> Device? {
        print("PCI.device(adr: 0x\(String(address, radix: 16)), name: \(acpiNode.fullname())")
        guard let deviceFunction = PCIDeviceFunction(bus: self, address: address) else {
            print("PCIDeviceFunction(\(self), 0x\(String(address, radix: 16)) returned nil")
            return nil
        }

        switch (deviceFunction.vendor, deviceFunction.deviceId) {
            case (0x8086, 0x7000),
                (0x8086, 0x7110):
                if let pciDevice = PIIX(parentBus: parentBus, deviceFunction: deviceFunction, acpi: acpiNode) {
                    return pciDevice
            }

            case (0xffff, _): // invalid device
                return nil

            default:
                if let pciDevice = UnknownPCIDevice(parentBus: parentBus, deviceFunction: deviceFunction, acpi: acpiNode) {
                    return pciDevice
            }
        }
        return nil
    }
}
