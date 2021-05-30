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

    func initialiseDevice() -> Bool {
        // FIXME: Should the caller be calling it directly, and should this only be called
        // by the device driver?
        guard let acpi = acpiDevice, acpi.initialiseIfPresent() else {
            return false
        }
        self.enabled = true
        return true
    }

    func msiCapability() -> PCICapability.MSI? {
        guard let msiOffset = self.deviceFunction.findOffsetOf(capability: .msi) else {
            return nil
        }

        return PCICapability.MSI(offset: msiOffset, deviceFunction: deviceFunction)
    }

    func msixCapability() -> PCICapability.MSIX? {
        guard let msixOffset = self.deviceFunction.findOffsetOf(capability: .msix) else {
            return nil
        }

        return PCICapability.MSIX(offset: msixOffset, deviceFunction: deviceFunction)
    }

    // Look for MSI-X, then MSI, then the INTA-D IRQs
    func findInterrupt() -> IRQSetting? {
        print("PCI: Looking for interrupt for device: \(self)")

        if let msixCapability = self.msixCapability() {
            fatalError("TODO - implement MSI-X interrupts: \(msixCapability)")
        }

        if let msiCapability = self.msiCapability() {
            fatalError("TODO - implement MSI interrupts: \(msiCapability)")
        }


        // Walk up the PCI busses to find the Root Bridge, where the _PRT Interrupt Routing Table
        // should be. As we walk up the busses, swizzle the intterupt PIN according to
        // 'System Interrupt Mapping' in PCI Express spec section 2.2.8.1.

        guard var pin = self.deviceFunction.interruptPin else {
            print("PCI: \(self) has no valid interruptPin")
            return nil
        }
        var slot = self.deviceFunction.slot
        var bus = self.parentBus as! PCIBus

        print("PCI: slot: \(slot) device: \(self.deviceFunction.device) df: \(self.deviceFunction), pin: \(pin)")

        while let parent = bus.pciDevice?.parentBus as? PCIBus, let busSlot = bus.slot {   // FIXME, add , !bus.isRootBridge test
            pin = pin.swizzle(slot: slot)
            slot = busSlot
            print("PCI: bus: \(bus), interruptPin: \(pin)")
            bus = parent
        }

        print("PCI: final slot: \(slot), pin: \(pin)")

        guard let itr = bus.interruptRoutingTable else {
            fatalError("PCI: \(bus) cant find an Interrupt Routing Table")
        }

        guard let entry = itr.findEntryByDevice(slot: slot, pin: pin) else {
            print("PCI: \(self): Cant find interrupt routing table entry.")
            return nil
        }

        print("PCI: Found routing entry: \(entry)")

        switch entry.source {
            case .namePath(let namePath, let sourceIndex):
                print("PCI: NamePath: \(namePath)")
                // FIXME, should have better way of walking up the tree
                guard let (node, fullname) = itr.prtAcpiNode.topParent().getGlobalObject(currentScope: AMLNameString(itr.prtAcpiNode.fullname()), name: namePath) else {
                    print("PCI: Cant find object for \(namePath) under \(itr.prtAcpiNode.fullname())")
                    return nil
                }

                print("PCI: Link device: \(fullname), sourceIndex: \(sourceIndex), \(node)")
                guard let devNode = node as? AMLDefDevice else {
                    print("\(fullname) is not an AMLDefDevice")
                    return nil
                }

                guard let device = devNode.device?.deviceDriver as? PCIInterruptLinkDevice else {
                    print("\(fullname) has no attached PCI InterruptLink device")
                    return nil
                }
                print("PCI: devNode: \(devNode) device: \(devNode.device as Any), LNK Device: \(device), irq:", device.irq)
                return device.irq

            case .globalSystemInterrupt(let gsi):
                return IRQSetting(gsi: gsi, activeHigh: false, levelTriggered: true, shared: true, wakeCapable: false) // FIXME: try and determine wakeCapable status.
        }
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
