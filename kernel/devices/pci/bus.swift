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

    var description: String { "BUS: \(pciConfigSpace.pciConfigAccess) busId: \(busID) \(deviceFunction.description) \(acpiDevice?.fullname() ?? "")" }

    init(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpiDevice: AMLDefDevice? = nil) {
        busID = deviceFunction.secondaryBusId
        self.deviceFunction = deviceFunction
        pciConfigSpace = PCIConfigSpace(busID: busID, device: 0, function: 0)
        super.init(parentBus: parentBus, acpiDevice: acpiDevice)
    }


    // Scan the PCI bus for devices but ignore any that have already been added to the `devices` array by ACPI
    private func scanBus() -> [PCIDeviceFunction] {
        // Get current devices on bus by device number, key = devicveID (0-0x1F) value = 0 if non-multifunction else bitX = functionX
        var currentPCIDevices: [UInt8: UInt8] = [:]
        for dev in self.devices {
            guard let pciDevice = dev as? PCIDevice else { continue } // FIXME: Shouldnt have non PCIDevices in list
            let devId = pciDevice.deviceFunction.device
            if pciDevice.deviceFunction.function == 0 && !pciDevice.deviceFunction.hasSubFunction {
                currentPCIDevices[devId] = 0
            } else {
                currentPCIDevices[devId] = (currentPCIDevices[devId] ?? 0) | 1 << pciDevice.deviceFunction.function
            }
        }

        var pciDeviceFunctions: [PCIDeviceFunction] = []
        for device: UInt8 in 0..<32 {
            if busID == 0 && device == deviceFunction.device {
                print("Skipping PCIBus on busID: 0")
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
        self.sortDevices {
            guard let dev0 = $0 as? PCIDevice else { return true }
            guard let dev1 = $1 as? PCIDevice else { return true }
            return dev0.deviceFunction.deviceFunction < dev1.deviceFunction.deviceFunction
        }
    }


    override func device(parentBus: Bus, address: UInt32, acpiDevice: AMLDefDevice? = nil) -> Device? {
        guard let deviceFunction = PCIDeviceFunction(bus: self, device: UInt8(address >> 16), function: UInt8(address & 0xffff)) else {
            return nil
        }
        return device(parentBus: parentBus, deviceFunction: deviceFunction, acpiDevice: acpiDevice)
    }


    func device(parentBus: Bus, deviceFunction: PCIDeviceFunction, acpiDevice: AMLDefDevice? = nil) -> Device? {

        if deviceFunction.isBus {
            return PCIBus(parentBus: self, deviceFunction: deviceFunction, acpiDevice: acpiDevice)
        }


        switch (deviceFunction.vendor, deviceFunction.deviceId) {
            case (0x8086, 0x7000),
                (0x8086, 0x7110):
                if let pciDevice = PIIX(parentBus: parentBus, deviceFunction: deviceFunction, acpiDevice: acpiDevice) {
                    return pciDevice
            }

            case (0xffff, _): // invalid device
                return nil

            default:
                if let pciDevice = UnknownPCIDevice(parentBus: parentBus, deviceFunction: deviceFunction, acpiDevice: acpiDevice) {
                    return pciDevice
            }
        }
        return nil
    }
}
