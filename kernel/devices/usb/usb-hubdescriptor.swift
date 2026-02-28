/*
 * kernel/devices/usb/usb-hubdescriptor.swift
 *
 * Created by Simon Evans on 07/06/2025.
 * Copyright © 2025 Simon Evans. All rights reserved.
 *
 * USB Hub Descriptor
 *
 */


extension USB {

    // This covers the USB2 HubDescriptor and the USB3 Enhanced SuperSpeed Hub Descriptor
    struct HUBDescriptor: CustomStringConvertible {

        enum LogicalPowerSwitching {
            case ganged
            case individual
            case reserved

            init(rawValue: UInt16) {
                switch rawValue & 0b11 {
                    case 0b00: self = .ganged
                    case 0b01: self = .individual
                    default: self = .reserved
                }
            }
        }

        enum OverCurrentProtection {
            case global
            case individual
            case none

            init (rawValue: UInt16) {
                switch rawValue & 0b11 {
                    case 0b00: self = .global
                    case 0b01: self = .individual
                    default: self = .none
                }
            }
        }

        let bDescLength: UInt8
        let bDescriptorType: UInt8
        let bNbrPorts: UInt8
        let wHubCharacteristics: UInt16
        let bPwrOn2PwrGood: UInt8
        let bHubContrCurrent: UInt8
        let bHubHdrDecLat: UInt8
        let wHubDelay: UInt16
        let deviceRemovable: [Bool] // FIXME: Should be a BitArray
        let isSuperSpeed: Bool
        let description: String

        // Ignore PortPwrCtrlMask has it should be all ones

        // wHubCharacteristics
        let powerSwitchMode: LogicalPowerSwitching
        let isCompoundDevice: Bool
        let overCurrentProtection: OverCurrentProtection
        let ttThinkTime: Int
        let hasPortIndicators: Bool

        // Extra fields for Superspeed hubs
        let packetHeaderDecodeLatency: UInt8
        let hubDelay: UInt16


        func write(into buffer: inout MMIOSubRegion, maxLength: UInt16) -> UInt16 {

            let length = min(UInt16(self.bDescLength), maxLength)
            if USBTrace {
                #kprintf("write(into:maxLength:) length %u self.bDescLengthL %u isSuperSpeed: %s\n",
                         length, self.bDescLength, self.isSuperSpeed)
            }
            if self.isSuperSpeed {
                let descriptor = usb_enhanced_ss_hub_descriptor(
                    bDescLength: self.bDescLength,
                    bDescriptorType: self.bDescriptorType,
                    bNbrPorts: self.bNbrPorts,
                    wHubCharacteristics: self.wHubCharacteristics,
                    bPwrOn2PwrGood: self.bPwrOn2PwrGood,
                    bHubContrCurrent: self.bHubContrCurrent,
                    bHubHdrDecLat: self.packetHeaderDecodeLatency,
                    wHubDelay: self.hubDelay,
                    deviceRemoveable: 0 // FIXME, compute this
                )
                withUnsafeBytes(of: descriptor) {
                    for idx in 0..<Int(length) {
                        buffer[idx] = $0[idx]
                    }
                }
            } else {
                let descriptor = usb_hub_descriptor(
                    bDescLength: self.bDescLength,
                    bDescriptorType: self.bDescriptorType,
                    bNbrPorts: self.bNbrPorts,
                    wHubCharacteristics: self.wHubCharacteristics,
                    bPwrOn2PwrGood: self.bPwrOn2PwrGood,
                    bHubContrCurrent: self.bHubContrCurrent,
                    deviceRemoveable: 0,    // FIXME, compute this
                    powerPwrCtrlMask: 0xff
                )
                withUnsafeBytes(of: descriptor) {
                    for idx in 0..<Int(length) {
                        buffer[idx] = $0[idx]
                    }
                }
            }
            return length
        }

        // Used by USB2 Root Hubs
        init(isSuperSpeed: Bool, ports: UInt8) {
            self.isSuperSpeed = isSuperSpeed
            if isSuperSpeed {
                self.bDescLength = 12
                self.bDescriptorType = USB.DescriptorType.SUPER_SPEED_HUB.rawValue
                self.bNbrPorts = ports & 0xf
            } else {
                self.bDescLength = 9
                self.bDescriptorType = USB.DescriptorType.HUB.rawValue
                self.bNbrPorts = ports
            }
            self.wHubCharacteristics = 0xa
            self.bPwrOn2PwrGood = 10
            self.bHubContrCurrent = 0
//            self.powerPwrCtrlMask = 0xff
            self.bHubHdrDecLat = 0
            self.wHubDelay = 0

            self.deviceRemovable = .init(repeating: false, count: Int(self.bNbrPorts))
            self.description = "Root Hub"
            self.powerSwitchMode = .individual
            self.isCompoundDevice = false
            self.overCurrentProtection = .individual
            self.ttThinkTime = 0
            self.hasPortIndicators = false

            self.packetHeaderDecodeLatency = 0
            self.hubDelay = 0
        }

        // USB2 Hub Descriptor
        init(hubFrom buffer: MMIOSubRegion) throws(ParsingError) {
            var iterator = buffer.makeIterator()
            // Validate the initial bytes
            guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else {
                throw ParsingError.packetTooShort
            }
            guard Int(lengthByte) >= MemoryLayout<usb_hub_descriptor>.size else {
                throw ParsingError.invalidLengthByte
            }
            guard descriptorByte == USB.DescriptorType.HUB.rawValue else {
                throw ParsingError.invalidDescriptor(descriptorByte)
            }

            var descriptor = usb_hub_descriptor()
            try withUnsafeMutableBytes(of: &descriptor) { (buffer: UnsafeMutableRawBufferPointer)
                throws(ParsingError) -> () in
                buffer[0] = lengthByte
                buffer[1] = descriptorByte

                for idx in 2..<(buffer.count-2) { // Exclude the last two bytes as they are variable lenggth
                    guard let byte = iterator.next() else { throw ParsingError.packetTooShort }
                    buffer[idx] = byte
                }
            }
            self.bDescLength = descriptor.bDescLength
            self.bDescriptorType = descriptor.bDescriptorType
            self.bNbrPorts = descriptor.bNbrPorts
            self.wHubCharacteristics = descriptor.wHubCharacteristics
            self.bPwrOn2PwrGood = descriptor.bPwrOn2PwrGood
            self.bHubContrCurrent = descriptor.bHubContrCurrent
            self.bHubHdrDecLat = 0  // Enhanced Hub only
            self.wHubDelay = 0      // Enhanced Hub only

            self.powerSwitchMode = LogicalPowerSwitching(rawValue: wHubCharacteristics)
            self.isCompoundDevice = wHubCharacteristics.bit(2)
            self.overCurrentProtection = OverCurrentProtection(rawValue: wHubCharacteristics >> 3)
            self.ttThinkTime = (Int((wHubCharacteristics >> 5) & 0b11) + 1) * 8
            self.hasPortIndicators = wHubCharacteristics.bit(7)

            let variableByteCount = (descriptor.bNbrPorts + 8) / 8  // +8 not +7 as bit 0 is reserved so need to account for an extra bit
            var _deviceRemovable: [Bool] = []
            _deviceRemovable.reserveCapacity(Int(descriptor.bNbrPorts))
            // The DeviceRemovable and PortPwrCtrlMask should both be this many bytes long but
            // the PortPwrCtrlMask only needs to be checked for length, the value can be ignored
            var firstByte = true
            var portsRemaining = descriptor.bNbrPorts
            for _ in 0..<variableByteCount {
                guard var byte = iterator.next() else { throw ParsingError.packetTooShort }
                if firstByte { byte >>= 1 } // Bit 0 is reserved
                let maxBit = firstByte ? 7 : 8
                for _ in 1...maxBit {
                    if portsRemaining > 0 {
                        let bit = (byte & 1) == 1
                        _deviceRemovable.append(bit)
                        portsRemaining -= 1
                        byte >>= 1
                    }
                }
                firstByte = false
            }
            self.deviceRemovable = _deviceRemovable

            // Validate the size of the PortPwrCtrlMask
            for _ in 0..<variableByteCount {
                guard iterator.next() != nil else { throw ParsingError.packetTooShort }
            }
            self.isSuperSpeed = false
            self.description = "USB2.0 Hub"
            self.packetHeaderDecodeLatency = 0
            self.hubDelay = 0
        }

        // USB3 Enhanced SuperSpeed Hub Descriptor
        init(SSHubFrom buffer: MMIOSubRegion) throws(ParsingError) {
            let pkSize = MemoryLayout<usb_enhanced_ss_hub_descriptor>.size
            guard buffer.count >= pkSize else {
                throw ParsingError.packetTooShort
            }
            guard Int(buffer[0]) == pkSize else {
                throw ParsingError.invalidLengthByte
            }
            guard Int(buffer[1]) == USB.DescriptorType.SUPER_SPEED_HUB.rawValue else {
                throw ParsingError.invalidDescriptor(buffer[1])
            }

            var descriptor = usb_enhanced_ss_hub_descriptor()
            buffer.loadBytes(into: &descriptor)

            self.bDescLength = descriptor.bDescLength
            self.bDescriptorType = descriptor.bDescriptorType
            self.bNbrPorts = descriptor.bNbrPorts
            self.wHubCharacteristics = descriptor.wHubCharacteristics
            self.bPwrOn2PwrGood = descriptor.bPwrOn2PwrGood
            self.bHubContrCurrent = descriptor.bHubContrCurrent
            self.bHubHdrDecLat = descriptor.bHubHdrDecLat
            self.wHubDelay = descriptor.wHubDelay
            var _removable: [Bool] = .init(repeating: false, count: 16)
            for i in 0..<16 {
                _removable[i] = descriptor.deviceRemoveable.bit(i)
            }
            self.deviceRemovable = _removable
            self.isSuperSpeed = true
            self.description = "USB3.0 Hub"

            self.powerSwitchMode = HUBDescriptor.LogicalPowerSwitching.init(rawValue: wHubCharacteristics)
            self.isCompoundDevice = wHubCharacteristics.bit(2)
            self.overCurrentProtection = HUBDescriptor.OverCurrentProtection.init(rawValue: wHubCharacteristics >> 3)
            self.ttThinkTime = 0
            self.hasPortIndicators = false
            self.packetHeaderDecodeLatency = descriptor.bHubHdrDecLat
            self.hubDelay = descriptor.wHubDelay
        }
    }
}
