/*
 * kernel/devices/usb/usb-bosdecriptor.swift
 * Kernel
 *
 * Created by Simon Evans on 09/01/2026.
 * Copyright © 2026 - 2026 Simon Evans. All rights reserved.
 *
 * USB Binary Device Object Store (BOS) Descriptor
 *
 */

extension USB {

    struct BOSDescriptor: CustomStringConvertible {

        enum CapabilityType: UInt8 {
            case RESERVED = 0x00
            case WIRELESS = 0x01
            case USB2_0_Extension = 0x02
            case SUPERSPEED_USB = 0x03
            case CONTAINER_ID = 0x04
            case PLATFORM = 0x05
            case POWER_DELIVERY = 0x06
            case BATTERY_INFO = 0x07
            case PD_CONSUMER_PORT = 0x08
            case PD_PROVIDER_PORT = 0x09
            case SUPERSPEED_PLUS = 0x0A
            case PRECISTION_TIME_MEAUSREMENT = 0x0B
            case WIRELESS_USB_EX = 0x0C
            case BILLBOARD = 0x0D
            case AUTHENTICATION = 0x0E
            case BILLBOARD_EX = 0x0F
            case CONFIGURATION_SUMMARY = 0x10
        }

        struct GenericCapability {
            let type: CapabilityType
            let bytes: [UInt8]
        }

        let bLength:         UInt8
        let bDescriptorType: UInt8
        let wTotalLength:    UInt16
        let bNumDeviceCaps:  UInt8
        let capabilities: [GenericCapability]

        var description: String {
            "BOS with \(capabilities.count) capabilities"
        }

        init(from buffer: MMIOSubRegion) throws(ParsingError) {
            var iterator = buffer.makeIterator()
            // Validate the initial bytes

            func nextByte() throws(ParsingError) -> UInt8 {
                guard let byte = iterator.next() else { throw ParsingError.packetTooShort }
                return byte
            }

            let lengthByte = try nextByte()
            let descriptorByte = try nextByte()
            guard Int(lengthByte) >= 5 else { throw ParsingError.invalidLengthByte }
            guard descriptorByte
                    == USB.DescriptorType.BINARY_OBJECT_STORE.rawValue else {
                throw ParsingError.invalidDescriptor(descriptorByte)
            }
            self.bLength         = lengthByte
            self.bDescriptorType = descriptorByte
            let totalLengthLo = try nextByte()
            let totalLengthHi = try nextByte()
            let numDeviceCaps = try nextByte()
            self.wTotalLength    = UInt16(totalLengthLo) | (UInt16(totalLengthHi) << 8)
            self.bNumDeviceCaps  = numDeviceCaps

            // Read in any optional capabilities. These will not be here on the
            // first parse as the descriptor will need to be refretched with wTotalLength
            // bytes

            var bytesRead = UInt16(lengthByte) // The bytes already read
            var _capabilities: [GenericCapability] = []
            while let bLengthByte = iterator.next() {
                let descriptorByte = try nextByte()
                let capabilityByte = try nextByte()
                guard descriptorByte == DescriptorType.DEVICE_CAPABILITY.rawValue,
                      bLengthByte > 3 else {
                    throw ParsingError.packetTooShort
                }
                let capability = CapabilityType(rawValue: UInt8(capabilityByte)) ?? .RESERVED
                bytesRead += 3

                switch capability {

                    case .RESERVED:
                        #kprintf("usb-dev: Ignoring unknown BOS capability: %02x\n", capabilityByte)
                        fallthrough

                    default:
                        var bytes: [UInt8] = []
                        bytes.reserveCapacity(Int(bLengthByte - 3))
                        for _ in 0..<(bLengthByte - 3) {
                            bytes.append(try nextByte())
                            bytesRead += 1
                        }
                        let capabilityData = GenericCapability(type: capability, bytes: bytes)
                        if _capabilities.capacity < Int(self.bNumDeviceCaps) {
                            _capabilities.reserveCapacity(Int(self.bNumDeviceCaps))
                        }
                        _capabilities.append(capabilityData)
                }
            }

            self.capabilities = _capabilities
            if _capabilities.count > 0 {
                if bytesRead != wTotalLength {
                    #kprintf("usb-bosdescriptor: expected to read %u bytes, read %u bytes\n",
                            wTotalLength, bytesRead)
                }
            }
        }
    }
}
