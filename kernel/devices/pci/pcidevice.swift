/*
 * kernel/devices/pci/pcidevice.swift
 *
 * Created by Simon Evans on 27/07/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * PCI Device and access to the PCI Configspace.
 *
 */


final class PCIDevice: Device, CustomStringConvertible {
    unowned let parentBus: Bus
    let acpiDevice: AMLDefDevice?
    let fullName: String
    var enabled = false
    let deviceFunction: PCIDeviceFunction
    private(set) var pciDeviceDriver: PCIDeviceDriver?
    var deviceDriver: DeviceDriver? { pciDeviceDriver }

    var description: String { "PCI \(fullName) \(deviceFunction.description)" }

    init?(parentBus: PCIBus, deviceFunction: PCIDeviceFunction, acpiDevice: AMLDefDevice? = nil) {
        guard deviceFunction.vendor != 0xffff else { return nil } // Invalid device
        self.parentBus = parentBus
        self.deviceFunction = deviceFunction
        self.acpiDevice = acpiDevice
        self.fullName = acpiDevice?.fullname() ?? "PCI Device"
    }

    func setDriver(_ driver: DeviceDriver) {
        if let deviceDriver = deviceDriver {
            fatalError("\(self) already has a device driver: \(deviceDriver)")
        }

        guard let pciDriver = driver as? PCIDeviceDriver else {
            fatalError("\(self): \(driver) is not for a PCI Device")
        }
        pciDeviceDriver = pciDriver
    }

    func initialiseDevice() {
        // FIXME: Should the caller be calling it directly, and should this only be called
        // by the device driver?
        pciDeviceDriver?.initialiseDevice()
    }

    func msiCapability() -> PCICapability.MSI? {
        guard let msiOffset = self.deviceFunction.findOffsetOf(capability: .msi) else {
            return nil
        }

        return PCICapability.MSI(offset: msiOffset, configSpace: deviceFunction.configSpace)
    }

    func msixCapability() -> PCICapability.MSIX? {
        guard let msixOffset = self.deviceFunction.findOffsetOf(capability: .msix) else {
            return nil
        }

        return PCICapability.MSIX(offset: msixOffset, configSpace: deviceFunction.configSpace)
    }

}

// Base Address Register pointing to I/O space
struct PCIIOBar {
    let ioPort: UInt16

    init?(bar: UInt32) {
        guard bar & 1 == 1 else { return nil }
        let _ioPort = bar & 0xFFFC  // Bit 1 is reserved
        guard _ioPort > 0, _ioPort <= UInt16.max else { return nil }
        ioPort = UInt16(_ioPort)
    }
}

struct PCIMemoryBar {
    private let bits: BitArray32

    init?(bar: UInt32) {
        guard bar & 1 == 0 else { return nil }
        bits = BitArray32(bar)
    }

    var locatable: Int { Int(bits[1...2]) }
    var isPrefetchable: Bool { Bool(bits[3])}
    var baseAddress: UInt32 { bits.rawValue & 0xFFF0 }
}
