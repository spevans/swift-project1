/*
 * kernel/devices/pci/pcidevice.swift
 *
 * Created by Simon Evans on 27/07/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * PCI Device and access to the PCI Configspace.
 *
 */


final class PCIDevice: BusDevice {

    let deviceFunction: PCIDeviceFunction
    override var description: String { "PCI \(device.fullName) \(deviceFunction.description)" }


    init?(device: Device, deviceFunction: PCIDeviceFunction) {
        guard deviceFunction.vendor != 0xffff else { return nil } // Invalid device
        self.deviceFunction = deviceFunction
        super.init(device: device)
    }

    func initialise() -> Bool {
        self.device.initialised = true
        self.device.enabled = true
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

    func parentPCIDevice(device: Device) -> PCIDevice? {
        return device.parent?.busDevice as? PCIDevice

    }

    // Look for MSI-X, then MSI, then the INTA-D IRQs
    func findInterrupt() -> IRQSetting? {
        #kprint("PCI: Looking for interrupt for device: \(self)")

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
            #kprint("PCI: \(self) has no valid interruptPin")
            return nil
        }
        var slot = self.deviceFunction.slot
        guard var bus = self.device.parent else {
            fatalError("PCIDevice \(self) has no parent so cant find interrupr")
        }
        #kprint("PCI: slot: \(slot) device: \(self.deviceFunction.device) df: \(self.deviceFunction), pin: \(pin)")

        while let parent = self.parentPCIDevice(device: bus), let bridge = parent.deviceFunction.deviceClass?.bridgeSubClass,
              bridge == .isa {   // FIXME, add , !bus.isRootBridge test
            pin = pin.swizzle(slot: slot)
            slot = parent.deviceFunction.slot
            #kprint("PCI: bus: \(bus), interruptPin: \(pin)")
            bus = parent.device
        }

        #kprint("PCI: final slot: \(slot), pin: \(pin)")

        guard let itr = bus.acpiDeviceConfig?.prt else {
            fatalError("PCI: \(bus) cant find an Interrupt Routing Table")
        }

        guard let entry = itr.findEntryByDevice(slot: slot, pin: pin) else {
            #kprint("PCI: \(self): Cant find interrupt routing table entry.")
            return nil
        }

        #kprint("PCI: Found routing entry: \(entry)")

        switch entry.source {
            case .namePath(let namePath, let sourceIndex):
                #kprint("PCI: NamePath: \(namePath)")
                // FIXME, should have better way of walking up the tree
                guard let (node, fullname) = itr.prtAcpiNode.topParent().getGlobalObject(currentScope: AMLNameString(itr.prtAcpiNode.fullname()), name: namePath) else {
                    #kprint("PCI: Cant find object for \(namePath) under \(itr.prtAcpiNode.fullname())")
                    return nil
                }

                #kprint("PCI: Link device: \(fullname), sourceIndex: \(sourceIndex), \(node)")
                guard let lnkDevice = node.device else {
                    #kprint("\(fullname) is not an AMLDefDevice")
                    return nil
                }

                guard let deviceDriver = lnkDevice.deviceDriver as? PCIInterruptLinkDevice else {
                    #kprint("\(fullname) has no attached PCI InterruptLink device")
                    return nil
                }
                #kprint("PCI: devNode: \(fullname) device: \(node.device as Any), LNK Device: \(device), irq:", deviceDriver.irq)
                return deviceDriver.irq

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
