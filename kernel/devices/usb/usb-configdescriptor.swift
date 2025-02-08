/*
 * kernel/devices/usb/usb-configdescriptor.swift
 *
 * Created by Simon Evans on 20/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * USB Configuration Descriptor
 *
 */


extension USB {

    enum ParsingError: Error, CustomStringConvertible {
        case packetTooShort
        case invalidLengthByte
        case invalidDescriptor(UInt8)
        case garbageAtEnd

        var description: String {
            switch self {
            case .packetTooShort:               return "PacketTooShort"
            case .invalidLengthByte:            return "InvalidLengthByte"
            case let .invalidDescriptor(desc):  return "InvalidDescripton: \(String(desc, radix: 16))"
            case .garbageAtEnd:                 return "GarbageAtEnd"
            }
        }
    }

    struct ConfigDescriptor: CustomStringConvertible {

        private struct BMAttributes {
            private let bits: BitArray8

            init(rawValue: UInt8) { bits = BitArray8(rawValue) }

            var remoteWakeup: Bool { bits[5] == 1 }
            var selfPowered: Bool { bits[6] == 1 }
        }

        private let descriptor: usb_standard_config_descriptor
        // Interfaces that were found in the iterator input may have interfaces.count < bNumInterfaces
        let interfaces: [InterfaceDescriptor]


        var bLength:            UInt8 { descriptor.bLength }
        var bDescriptorType:    UInt8 { descriptor.bDescriptorType }
        var wTotalLength:       UInt16 { descriptor.wTotalLength }
        var bNumInterfaces:     UInt8 { descriptor.bNumInterfaces }
        var bConfigurationValue: UInt8 { descriptor.bConfigurationValue }
        var iConfiguration:     UInt8 { descriptor.iConfiguration}
        var bmAttributes:       UInt8 { descriptor.bmAttributes}
        var bMaxPower:          UInt8 { descriptor.bMaxPower }

        var description: String {
            let attributes = BMAttributes(rawValue: bmAttributes)
            var result = "bLength: \(bLength) bDescriptorType: \(bDescriptorType) wTotalLength: \(wTotalLength)"
                + " bNumInterfaces: \(bNumInterfaces) bConfigurationValue: \(bConfigurationValue)"
                + " iConfiguration: \(iConfiguration)"
                + " bmAttributes: remoteWakup: \(attributes.remoteWakeup) selfPowered: \(attributes.selfPowered)"
                + " bMaxPower: \(bMaxPower * 2)mA\n"
            for interface in interfaces {
                result += " +-- \(interface.description)\n"
            }

            return result
        }


        // This will parse either a packet of size(usb_standard_interface_descriptor), sufficient to obtain wTotalLength,
        // or a packet of size wTotalLength which will include all of the sub structures.
        init(from buffer: MMIOSubRegion) throws(ParsingError) {
            guard  buffer.count >= MemoryLayout<usb_standard_interface_descriptor>.size else {
                throw ParsingError.packetTooShort
            }
            var iterator = buffer.makeIterator()
            // Validate the initial bytes
            guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else { throw ParsingError.packetTooShort }
            guard Int(lengthByte) == MemoryLayout<usb_standard_interface_descriptor>.size else { throw ParsingError.invalidLengthByte }
            guard descriptorByte == USB.DescriptorType.CONFIGURATION.rawValue else { throw ParsingError.invalidDescriptor(descriptorByte) }

            var _descriptor = usb_standard_config_descriptor()
            try withUnsafeMutableBytes(of: &_descriptor) { (buffer: UnsafeMutableRawBufferPointer) throws(ParsingError) -> () in
                assert(MemoryLayout<usb_standard_interface_descriptor>.size == buffer.count)
                buffer[0] = lengthByte
                buffer[1] = descriptorByte

                for idx in 2..<buffer.count {
                    // guard let byte = try? iterator.next() // else { return ParsingError.packetTooShort }
                    guard let byte = iterator.next() else { throw ParsingError.packetTooShort }
                    buffer[idx] = byte
                }
            }
            descriptor = _descriptor

            if buffer.count ==  MemoryLayout<usb_standard_interface_descriptor>.size {
                // Short packet, no extra data
                interfaces = []
                return
            }
            // Revalidate length, input buffer length should now be equal to wTotalLength
            guard buffer.count == _descriptor.wTotalLength else { throw ParsingError.packetTooShort }

            // Full packet including sub structures, check buffer length
            guard descriptor.wTotalLength == buffer.count else { throw ParsingError.packetTooShort }

            var _interfaces: [InterfaceDescriptor] = []
            // If there are any interfaces, try and initialise them from any remaining bytes
            for _ in 0..<_descriptor.bNumInterfaces {
                let interface = try InterfaceDescriptor(from: &iterator)
                _interfaces.append(interface)
            }

            // The iterator should now be empty
            guard iterator.next() == nil else { throw ParsingError.garbageAtEnd }
            interfaces = _interfaces
        }
    }
}
