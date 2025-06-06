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
    private(set) var pciIORegions: [PCI_IO_Region] = []

    override var description: String { "PCI \(deviceFunction.description)" }


    init?(device: Device, deviceFunction: PCIDeviceFunction) {
        guard deviceFunction.vendor != 0xffff else { return nil } // Invalid device
        self.deviceFunction = deviceFunction
        super.init(device: device)
    }

    func initialise() -> Bool {
        // FIXME: Should the caller be calling it directly, and should this only be called
        // by the device driver?
        #kprint("PCI: initialise() for \(self)")
        #kprint("PCI: Getting PCI IO Regions")
        self.pciIORegions = self.decodeIORegions()
        self.device.enabled = true
        #kprint("PCI: \(self) enabled")
        return true
    }

    func ioRegionFor(barIdx: UInt) -> PCI_IO_Region? {
        for region in pciIORegions {
            if region.barIdx == barIdx { return region }
        }
        return nil
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

        guard let itr = bus.acpiDeviceConfig?.prt() else {
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
                let nodeDevice = node.device?.description ?? "none"
                #kprint("PCI: devNode: \(fullname) device: \(nodeDevice), LNK Device: \(device), irq:", deviceDriver.irq?.description ?? "none")
                return deviceDriver.irq

            case .globalSystemInterrupt(let gsi):
                return IRQSetting(gsi: gsi, activeHigh: false, levelTriggered: true, shared: true, wakeCapable: false) // FIXME: try and determine wakeCapable status.
        }
    }


    private func decodeIORegions() -> [PCI_IO_Region] {
        let maxBarCount = deviceFunction.headerType == 0 ? 6 : 2
        var regions: [PCI_IO_Region] = []
        var barIdx: UInt = 0
        while barIdx < maxBarCount {
            if let region = decodeIORegion(barIdx) {
                regions.append(region)
                #kprint("PCI: BAR: \(barIdx) Region: base: ", asHex(region.baseAddress), "size: ", asHex(region.size), "IO: ", region.bar.isPort)
                if region.bar.is64Bit {
                    // Skip next bar if current one consumed it
                    barIdx += 1
                }
            }
            barIdx += 1
        }
        return regions
    }

    private func decodeIORegion(_ barIdx: UInt) -> PCI_IO_Region? {

        let offset = 0x10 + (barIdx * 4)
        let command = deviceFunction.command
        // Disable decoding if enbabled while the BAR is overwritten
        if (command.decodeEnabled) {
            var newCommand = command
            newCommand.ioSpace = false
            newCommand.memorySpace = false
            deviceFunction.command = newCommand
        }

        let bar = PCI_BAR(rawValue: deviceFunction.readConfigDword(atByteOffset: offset))
        deviceFunction.writeConfigDword(atByteOffset: offset, value: UInt32.max)
        let barSize = deviceFunction.readConfigDword(atByteOffset: offset)
        deviceFunction.writeConfigDword(atByteOffset: offset, value: bar.rawValue)

        defer {
            // Restore decode enable if originally set
            deviceFunction.command = command
        }

        if barSize == UInt32.max {
            // Invalid BAR
            return nil
        }


        func computeSize(maxSize: UInt64, mask: UInt64) -> UInt64? {
            let size = maxSize & mask
            if size == 0 {
                // Invalid size
                return nil
            }
            // Compute the actual size of the BAR
            return size & ~(size - 1)
        }

        var baseAddress = UInt64(bar.baseAddress)
        var barSize64 = UInt64(barSize)
        if bar.is64Bit {
            let offset = offset + 4
            let baseAddressUpper = deviceFunction.readConfigDword(atByteOffset: offset)
            deviceFunction.writeConfigDword(atByteOffset: offset, value: UInt32.max)
            let barSizeUpper = deviceFunction.readConfigDword(atByteOffset: offset)
            deviceFunction.writeConfigDword(atByteOffset: offset, value: barSizeUpper)
            baseAddress |= UInt64(baseAddressUpper) << 32
            barSize64 |= UInt64(barSizeUpper) << 32

            if let finalSize = computeSize(maxSize: barSize64, mask: 0xffff_ffff_ffff_fff0) {
                return PCI_IO_Region(barIdx: barIdx, bar: bar, upperAddressBits: baseAddressUpper, size: finalSize)
            }
        } else {
            let mask: UInt64 = bar.isPort ? 0xfffc : 0xffff_fff0
            if let finalSize = computeSize(maxSize: barSize64, mask: mask) {
                return PCI_IO_Region(barIdx: barIdx, bar: bar, size: UInt32(finalSize))
            }
        }
        return nil
    }
}


struct PCI_BAR: Equatable {
    let rawValue: UInt32
    var baseAddress: UInt32 { rawValue & ~0b111 }
    var portAddress: UInt16 { UInt16(rawValue & 0xFFFC) }
    var isPort: Bool { rawValue & 1 == 1 }
    var isMemory: Bool { !isPort }
    var is32Bit: Bool { !is64Bit }
    var is64Bit: Bool { rawValue & 4 == 4 }
    var isValid: Bool { rawValue != UInt32.max }

    // Initialised from data in a PCI BAR
    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
}


struct PCI_IO_Region: CustomStringConvertible {
    let barIdx: UInt
    let bar: PCI_BAR
    let upperAddressBits: UInt32    // Used for 64bit addresses
    let size: UInt64                // must be power of 2
    var baseAddress: UInt64 { UInt64(bar.baseAddress) | UInt64(upperAddressBits) << 32 }

    var description: String {
        #sprintf("PCI_IO @ %p/%x", baseAddress, size)
    }

    init(barIdx: UInt, bar: PCI_BAR, size: UInt32) {
        self.barIdx = barIdx
        self.bar = bar
        self.upperAddressBits = 0
        self.size = UInt64(size)
    }

    init(barIdx: UInt, bar: PCI_BAR, upperAddressBits: UInt32, size: UInt64) {
        self.barIdx = barIdx
        self.bar = bar
        self.upperAddressBits = upperAddressBits
        self.size = size
    }
}
