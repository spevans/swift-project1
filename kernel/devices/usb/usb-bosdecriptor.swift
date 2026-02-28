/*
 * kernel/devices/usb/usb-bosdecriptor.swift
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

        struct Capability {
            let type: CapabilityType
            let bytes: [UInt8]
            var bLength: UInt8 { 3 + UInt8(bytes.count) }

            func write(into buffer: inout MMIOSubRegion, maxLength: UInt16) -> UInt16 {
                let length = min(UInt16(self.bLength), maxLength)
                if length > 0 { buffer[0] = bLength }
                if length > 1 { buffer[1] = DescriptorType.DEVICE_CAPABILITY.rawValue }
                if length > 2 { buffer[2] = type.rawValue }
                if length > 3 {
                    for idx in 3...Int(length - 1) {
                        buffer[idx] = bytes[idx - 3]
                    }
                }
                return length
            }
        }

        let bLength:         UInt8 = 5
        let bDescriptorType: UInt8 = USB.DescriptorType.BINARY_OBJECT_STORE.rawValue
        let capabilities: [Capability]

        var wTotalLength:    UInt16 {
            UInt16(self.bLength) + self.capabilities.reduce(UInt16(0), {
                result, capability in result + UInt16(capability.bLength)
            })
        }
        var bNumDeviceCaps: UInt8 { UInt8(self.capabilities.count) }

        var description: String {
            "BOS with \(capabilities.count) capabilities"
        }


        init(capabilities: [Capability]) {
            self.capabilities = capabilities
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
            guard Int(lengthByte) == 5 else { throw ParsingError.invalidLengthByte }
            guard descriptorByte
                    == USB.DescriptorType.BINARY_OBJECT_STORE.rawValue else {
                throw ParsingError.invalidDescriptor(descriptorByte)
            }
            let totalLengthLo = try nextByte()
            let totalLengthHi = try nextByte()
            let numDeviceCaps = Int(try nextByte())
            let totalLength    = UInt16(totalLengthLo) | (UInt16(totalLengthHi) << 8)

            // Read in any optional capabilities. These will not be here on the
            // first parse as the descriptor will need to be refretched with wTotalLength
            // bytes

            var bytesRead = UInt16(lengthByte) // The bytes already read
            var _capabilities: [Capability] = []
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
                        let capabilityData = Capability(type: capability, bytes: bytes)
                        if _capabilities.capacity < numDeviceCaps {
                            _capabilities.reserveCapacity(numDeviceCaps)
                        }
                        _capabilities.append(capabilityData)
                }
            }

            assert(numDeviceCaps == _capabilities.count)
            self.capabilities = _capabilities
            if _capabilities.count > 0 {
                if bytesRead != wTotalLength {
                    #kprintf("usb-bosdescriptor: expected to read %u bytes, read %u bytes\n",
                            wTotalLength, bytesRead)
                }
            }
            assert(self.wTotalLength == totalLength)
        }

        func write(into buffer: inout MMIOSubRegion, maxLength: UInt16) -> UInt16 {
            let length = min(UInt16(self.bLength), maxLength)

            switch length {
                case 5: buffer[4] = UInt8(self.capabilities.count)
                    fallthrough

                case 4: buffer[3] = UInt8(truncatingIfNeeded: wTotalLength >> 8)
                    fallthrough

                case 3: buffer[2] = UInt8(truncatingIfNeeded: wTotalLength)
                    fallthrough

                case 2: buffer[1] = self.bDescriptorType
                    fallthrough

                case 1: buffer[0] = self.bLength

                default: break
            }
            var offset = length
            guard offset < maxLength else { return offset }
            for capability in self.capabilities {
                var subRegion = buffer.mmioSubRegion(offset: Int(offset))
                offset += capability.write(into: &subRegion, maxLength: maxLength - offset)
                guard offset < maxLength else { break }
            }
            return offset
        }
    }
}
