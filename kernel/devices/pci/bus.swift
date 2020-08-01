/*
 * kernel/devices/pci/bus.swift
 *
 * Created by Simon Evans on 27/07/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * PCI Bus class.
 *
 */


final class PCIBus: Bus, PCIDevice, CustomStringConvertible {
    let busID: UInt8
    let deviceFunction: PCIDeviceFunction       // The device side of the bridge
    let pciConfigSpace: PCIConfigSpace          // The bus side of the bridge

    var description: String { "BUS: \(pciConfigSpace.pciConfigAccess) busId: \(busID) \(deviceFunction.description) \(acpi?.fullname() ?? "")" }

    init?(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpi: AMLDefDevice? = nil) {
        busID = deviceFunction.secondaryBusNumber
        self.deviceFunction = deviceFunction
        pciConfigSpace = PCIConfigSpace(busID: busID, device: 0, function: 0)
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
            if busID == 0 && device == deviceFunction.device {
                print("Skipping PCIBus on busID: 0")
                continue
            }
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
        for deviceFunction in scanBus() {
            if let device = self.device(parentBus: self, deviceFunction: deviceFunction) {
                self.addDevice(device)
                if let bus = device as? Bus {
                    bus.initialiseDevices()
                }
            }
        }
    }


    override func device(parentBus: Bus, address: UInt32, acpiNode: AMLDefDevice) -> Device? {
        guard let deviceFunction = PCIDeviceFunction(bus: self, device: UInt8(address >> 16), function: UInt8(address & 0xffff)) else {
            return nil
        }
        return device(parentBus: parentBus, deviceFunction: deviceFunction, acpiNode: acpiNode)
    }


    func device(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpiNode: AMLDefDevice? =  nil) -> Device? {

        if deviceFunction.headerType == 0x1 {
            return PCIBus(parentBus: self, deviceFunction: deviceFunction, acpi: acpiNode)
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
