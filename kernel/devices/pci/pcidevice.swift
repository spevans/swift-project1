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

    private(set) var deviceFunction: PCIDeviceFunction
    private(set) var pciIORegions: [PCI_IO_Region] = []

    override var className: String { "PCIDevice" }

    override var description: String {
        #sprintf("PCI %2.2X:%2.2X/%u: %4.4X:%4.4X",
                 deviceFunction.busId,
                 deviceFunction.device,
                 deviceFunction.function,
                 deviceFunction.vendor,
                 deviceFunction.deviceId)
    }


    init?(device: Device, deviceFunction: PCIDeviceFunction) {
        guard deviceFunction.vendor != 0xffff else { return nil } // Invalid device
        self.deviceFunction = deviceFunction
        let name = #sprintf("pci%2.2X:%2.2X.%u", deviceFunction.busId,
                            deviceFunction.device,
                            deviceFunction.function)
        super.init(device: device, busDeviceName: name)
    }

    func initialise() -> Bool {
        // FIXME: Should the caller be calling it directly, and should this only be called
        // by the device driver?
        self.pciIORegions = self.decodeIORegions()
        self.device.enabled = true
        return true
    }

    override func info() -> String {
        var result = "PCI Device: \(deviceFunction)"
        if pciIORegions.count > 0 {
            for barIdx in pciIORegions.indices {
                result += "\n\tBAR\(barIdx) \(pciIORegions[barIdx].description)"
            }
        }
        if let msi = msiCapability() {
            result += #sprintf("\n\tMSI Capability: request vectors: %d\n", msi.messageControl.requestVectors)
        }
        if let msix = msixCapability() {
            result += #sprintf("\n\tMSI-X Capability: Table BAR: %d, tableOffset: 0x%x maxTableSize: %d PBA_BAR: %d PBA_Offset: 0x%x",
                               msix.tableBAR, msix.tableOffset,
                               msix.messageControl.tableSize,
                               msix.pendingBitArrayBAR, msix.pendingBitArrayOffset
            )
        }

        return result
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

//        if let msixCapability = self.msixCapability() {
//            fatalError("TODO - implement MSI-X interrupts: \(msixCapability)")
 //       }

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

        while let parent = self.parentPCIDevice(device: bus), let bridge = parent.deviceFunction.deviceClass?.bridgeSubClass,
              bridge == .isa {   // FIXME, add , !bus.isRootBridge test
            pin = pin.swizzle(slot: slot)
            slot = parent.deviceFunction.slot
            bus = parent.device
        }

#if !ACPI
        return nil
#else
        guard let itr = (bus.busDevice as? PNPDevice)?.prt() else {
            fatalError("PCI: \(bus) cant find an Interrupt Routing Table")
        }

        guard let entry = itr.findEntryByDevice(slot: slot, pin: pin) else {
            #kprint("PCI: \(self): Cant find interrupt routing table entry.")
            return nil
        }

        switch entry.source {
            case .namePath(let namePath, let sourceIndex):
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
                return deviceDriver.irq

            case .globalSystemInterrupt(let gsi):
                return IRQSetting(gsi: gsi, activeHigh: false, levelTriggered: true, shared: true, wakeCapable: false) // FIXME: try and determine wakeCapable status.
        }
#endif
    }


    // Request MSI or MSI-X interrupts vectors, preferring MSI-X.
    // Returns the count of vectors actually available which may be less than the number requested
    // Vectors are contiguous.
    func requestMSI(vectorStart: UInt8, requested: Int = 1) -> IRQSetting? {
        guard requested > 0 else { return nil }

        // APIC values
        let messageAddress: UInt64 = 0xFEE0_0000   // 0xFEE, Destination ID = 0 RH=0 DM=0
        let messageData: UInt32 = UInt32(vectorStart) // Delivery Mode: Fixed TriggerMode: Edge

        let msi = msiCapability()

        // Prefer MSI-X to MSI
        if let msix = msixCapability() {
            #kprint("msi: getting ioregion")
            guard let msiIORegion = self.ioRegionFor(barIdx: UInt(msix.tableBAR)),
                msiIORegion.bar.isMemory else {
                #kprintf("PCI-MSI: Bar: %u is not a memory bar\n", msix.tableBAR)
                return nil
            }
            let msiBar = msiIORegion.bar
            let region = PhysRegion(start: PhysAddress(RawAddress(msiBar.baseAddress)),
                                    size: UInt(msiIORegion.size))
            let mmioRegion = mapIORegion(region: region, cacheType: .uncacheable)
            #kprint("MSI region:", region)
            let tableRegion = mmioRegion.mmioSubRegion(offset: Int(msix.tableOffset),
                                                       count: msix.messageControl.tableSize)

            #kprint("reading current msix entry")
            let curEntry = PCICapability.MSIX.TableEntry(
                dword0: tableRegion.read(fromByteOffset: 0x0),
                dword1: tableRegion.read(fromByteOffset: 0x4),
                dword2: tableRegion.read(fromByteOffset: 0x8),
                dword3: tableRegion.read(fromByteOffset: 0xC),
            )
            #kprint("PCI-MSIX: Current MSIX table entry:", curEntry)

            let entry = PCICapability.MSIX.TableEntry(
                messageAddress: messageAddress, messageData: messageData, vectorControl: 0)
            #kprint("PCI-MSIX: New MSIX table entry:", entry)

            tableRegion.write(value: entry.dword0, toByteOffset: 0x0)
            tableRegion.write(value: entry.dword1, toByteOffset: 0x4)
            tableRegion.write(value: entry.dword2, toByteOffset: 0x8)
            tableRegion.write(value: entry.dword3, toByteOffset: 0xC)

            // Enable the MSI-X interrupts
            msix.setMessageControl(enable: true, mask: false) 

            return IRQSetting(irq: vectorStart - 40, activeHigh: true,
                              levelTriggered: false, shared: false,
                              wakeCapable: false)
        } else if let msi = msi {
            var available = 0
            if requested < msi.messageControl.requestVectors {
                // Round up to next power of 2
                if requested.nonzeroBitCount != 1 {
                    available = 1 << ((Int.bitWidth - 1) - (requested << 1).leadingZeroBitCount)
                } else {
                    available = requested
                }
            }

            guard msi.setMessage(address: messageAddress, data: UInt16(messageData), vectorCount: available) else {
                #kprintf("PCI-MSI: Failed to set MSI interrupt for %d vectors\n", available)
                return nil
            }

            #kprintf("PCI-MSI: requested: %d available: %d\n", requested, available)
            return IRQSetting(irq: vectorStart - 40, activeHigh: true,
                              levelTriggered: false, shared: false,
                              wakeCapable: false)
        } else {
            #kprint("PCI-MSI: No MSI or MSI-X available")
            return nil
        }
    }



    private func decodeIORegions() -> [PCI_IO_Region] {
        let maxBarCount = deviceFunction.headerType == 0 ? 6 : 2
        var regions: [PCI_IO_Region] = []
        var barIdx: UInt = 0
        while barIdx < maxBarCount {
            if let region = decodeIORegion(barIdx) {
                regions.append(region)
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
        // Set the BAR to all ones then readback to find the size mask
        deviceFunction.writeConfigDword(atByteOffset: offset, value: UInt32.max)
        let barSize = deviceFunction.readConfigDword(atByteOffset: offset)
        // Restore the original BAR
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
            // Save current BAR, set to all ones, read back the mask, then restore the original value
            let baseAddressUpper = deviceFunction.readConfigDword(atByteOffset: offset)
            deviceFunction.writeConfigDword(atByteOffset: offset, value: UInt32.max)
            let barSizeUpper = deviceFunction.readConfigDword(atByteOffset: offset)
            deviceFunction.writeConfigDword(atByteOffset: offset, value: baseAddressUpper)
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
    // TODO: This should probably be UInt
    let size: UInt64                // must be power of 2
    // TODO: thse address should probably be RawAddress or PhysAddress
    var baseAddress: UInt64 { UInt64(bar.baseAddress) | UInt64(upperAddressBits) << 32 }

    var description: String {
        #sprintf("PCI_IO @ %p/%x %dbit io: %s isValid: %s", baseAddress, size,
                 bar.is64Bit ? 64 : 3, bar.isPort ? "port" : "memory", bar.isValid)
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

struct PCIDeviceMatch {
    let vendorDeviceId: (UInt32, UInt32)?
    let function: UInt8?
    let classCode: PCIClassCode?
    let subClassCode: UInt8?
    let programmingInterface: UInt8?

    init(vendor: UInt32, deviceId: UInt32, function: UInt8? = nil) {
        self.vendorDeviceId = (vendor, deviceId)
        self.function = function
        self.classCode = nil
        self.subClassCode = nil
        self.programmingInterface = nil
    }

    init(classCode: PCIClassCode, subClassCode: UInt8, programmingInterface: UInt8) {
        self.vendorDeviceId = nil
        self.function = nil
        self.classCode = classCode
        self.subClassCode = subClassCode
        self.programmingInterface = programmingInterface
    }

    func matches(_ device: PCIDevice) -> Bool {
        let deviceFunction = device.deviceFunction
        if let vendorDeviceId = self.vendorDeviceId {
            guard deviceFunction.vendor == vendorDeviceId.0,
                  deviceFunction.deviceId == vendorDeviceId.1 else {
                return false
            }
        }
        if let function = self.function, deviceFunction.function != function {
            return false
        }

        if let classCode = self.classCode?.rawValue, deviceFunction.classCode != classCode {
            return false
        }

        if let subClassCode = self.subClassCode, deviceFunction.subClassCode != subClassCode {
            return false
        }

        if let interface = self.programmingInterface, deviceFunction.progInterface != interface {
            return false
        }
        return true
    }

#if !TEST
    static func matches(_ matches: Span<PCIDeviceMatch>, device: PCIDevice) -> Bool {
        for matchIdx in matches.indices {
            if matches[matchIdx].matches(device) { return true }
        }
        return false
    }
#endif
}
