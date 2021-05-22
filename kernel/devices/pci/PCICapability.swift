/*
 * kernel/devices/pci/PCICapabilities.swift
 *
 * Created by Simon Evans on 22/05/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * PCI Express Capabilities
 *
 */

enum PCICapability {

    enum CapabilityID: UInt8 {
        case powerManagement = 0x1
        case agp = 0x2
        case vitalProductData = 0x3
        case slotID = 0x4
        case msi = 0x5
        case pciHotswap = 0x6
        case pciX = 0x7
        case hyperTransport = 0x8
        case vendorSpecific = 0x9
        case debugPort = 0xA
        case compactPciResourceControl = 0xB
        case hotplug = 0xC
        case bridgeVendorDeviceId = 0xD
        case agp8X = 0xE
        case secureDevice = 0xF
        case pciExpress = 0x10
        case msix = 0x11
        case sataDataIndexConf = 0x12
        case advancedFeatures = 0x13
        case enhancedAllocation = 0x14
        case flatteningPortalBridge = 0x15
    }

    enum ExtendedCapabilityID: UInt16 {
        case advancedErrorReporting = 0x1
        case virtualChannel1 = 0x2
        case deviceSerialNumber = 0x3
        case powerBudgeting = 0x4
        case rootComplexLinkDeclaration = 0x5
        case rootComplexInternalLinkDeclaration = 0x6
        case rootComplexEventCollectorEndpoint = 0x7
        case mfvcCapability = 0x8
        case virtualChannel2 = 0x9
        case rcrbHeader = 0xA
        case vendorSpecificCapability = 0xb
        case configAccess = 0xC // NOT USED
        case accessControlServices = 0xD
        case alternatiRoutingIdCapability = 0xE
        case addressTranslationServices = 0xF
        case singleRootIoVirtualisation = 0x10
        case multiRootIoVirtualisation = 0x11
        case multicast = 0x12
        case pageRequestInterface = 0x13
        case reservedAMD = 0x14
        case resizableBAR = 0x15
        case dynamicPowerAllocation = 0x16
        case tphRequester = 0x17
        case latencyTolerenceReporting = 0x18
        case secondaryPCIe = 0x19
        case protocolMux = 0x1A
        case processAddressSpaceId = 0x1B
        case downstreamPortContainment = 0x1D
        case l1PMSubstrates = 0x1E
        case precisionTimeMeasurement = 0x1F
        case vendorSpecific = 0x23
        case dataLinkFeature = 0x25
        case phyicalLayer16GTs = 0x26
    }


    struct MSI {
        struct MessageControl {
            private let bits: BitArray16

            init(bits: UInt16) {
                self.bits = BitArray16(bits)
            }

            var enabled: Bool { Bool(bits[0]) }
            var requestVectors: Int { 1 << bits[1...3] }
            var is64Bit: Bool { Bool(bits[7]) }
            var vectorMaskingCapable: Bool { Bool(bits[8]) }
        }

        private let _messageAddress: UInt64
        private let _maskBits: UInt32
        private let _pendingBits: UInt32
        let messageControl: MessageControl
        let messageData: UInt16

        var messageAddress64: UInt64? {
            messageControl.is64Bit ? _messageAddress : nil
        }
        var messageAddress32: UInt32? {
            !messageControl.is64Bit ? UInt32(truncatingIfNeeded: _messageAddress) : nil
        }
        var maskBits: UInt32? { messageControl.vectorMaskingCapable ? _maskBits : nil }
        var pendingBits: UInt32? { messageControl.vectorMaskingCapable ? _pendingBits : nil }


        init(offset: UInt, configSpace: PCIConfigSpace) {
            var offset = offset + 2
            messageControl = MessageControl(bits: configSpace.readConfigWord(atByteOffset: offset))
            offset += 2

            let messageAddressLow = configSpace.readConfigDword(atByteOffset: offset)
            offset += 4

            var messageAddressHigh: UInt32
            if messageControl.is64Bit {
                messageAddressHigh = configSpace.readConfigDword(atByteOffset: offset)
                offset += 4
            } else {
                messageAddressHigh = 0
            }
            _messageAddress = UInt64(messageAddressHigh) << 32 | UInt64(messageAddressLow)
            messageData = configSpace.readConfigWord(atByteOffset: offset)

            if messageControl.vectorMaskingCapable {
                offset += 4
                _maskBits = configSpace.readConfigDword(atByteOffset: offset)
                _pendingBits = configSpace.readConfigDword(atByteOffset: offset + 4)
            } else {
                _maskBits = 0
                _pendingBits = 0
            }
        }
    }

    struct MSIX {
        struct MessageControl {
            private let bits: BitArray16

            init(bits: UInt16) {
                self.bits = BitArray16(bits)
            }

            var tableSize: Int { Int(bits[0...10]) + 1 }
            var functionMask: Bool { Bool(bits[14]) }
            var enabled: Bool { Bool(bits[15]) }
        }

        private let tableOffsetBIR: UInt32
        private let pbaOffsetBIR: UInt32
        let messageControl: MessageControl
        var tableBAR: Int { Int(tableOffsetBIR & 0b111) }
        var tableOffset: UInt32 { tableOffsetBIR & ~0b111 }
        var pendingBitArrayBAR: Int { Int(pbaOffsetBIR & 0b111) }
        var pendingBitArrayOffset: UInt32 { pbaOffsetBIR & ~0b111 }


        init(offset: UInt, configSpace: PCIConfigSpace) {
            messageControl = MessageControl(bits: configSpace.readConfigWord(atByteOffset: offset + 2))
            tableOffsetBIR = configSpace.readConfigDword(atByteOffset: offset + 4)
            pbaOffsetBIR = configSpace.readConfigDword(atByteOffset: offset + 8)
        }
    }
}


extension PCIDeviceFunction {

    // Returns the offset from the start of the configuration space of the
    // PCI Capability if it exists.
    func findOffsetOf(capability: PCICapability.CapabilityID) -> UInt? {
        guard self.status.hasCapabilities else { return nil }

        var ptr = UInt(self.capabilitiesPtr)
        while ptr != 0 && ptr + 2 < configSpace.pciConfigAccess.size {
            let id = configSpace.readConfigByte(atByteOffset: ptr)
            if let _capability = PCICapability.CapabilityID(rawValue: id), capability == _capability {
                return ptr
            }

            let nextPtr = configSpace.readConfigByte(atByteOffset: ptr + 1)
            if nextPtr <= ptr {
                print("PCI: capabilities, nextPtr \(nextPtr) <= currentPtr \(ptr)")
                break
            }
            print("ID: \(asHex(id)), ptr: \(ptr) nextPTR: \(nextPtr)")
            ptr = UInt(nextPtr)
        }
        return nil
    }


    // Returns the offset from the start of the configuration space of the
    // PCI Extended Capability if it exists.
    func findOffsetOf(extendedCapability: PCICapability.ExtendedCapabilityID) -> UInt? {
        guard self.status.hasCapabilities && configSpace.pciConfigAccess.size > 0x104 else { return nil }

        var ptr = UInt(0x100)
        var id = configSpace.readConfigWord(atByteOffset: ptr)
        while id != 0 {
            if let _extendedCapability = PCICapability.ExtendedCapabilityID(rawValue: id),
               extendedCapability == _extendedCapability {
                return ptr
            }

            let upperWord = configSpace.readConfigWord(atByteOffset: ptr + 2)
            let nextPtr = UInt(upperWord >> 4)
            if nextPtr == 0 || nextPtr < ptr || ptr + 2 > configSpace.pciConfigAccess.size { // terminating, 0 = end
                break
            }
            ptr = nextPtr
            id = configSpace.readConfigWord(atByteOffset: ptr)
        }
        return nil
    }
}
