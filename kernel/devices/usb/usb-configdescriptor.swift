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
            return switch self {
                case .packetTooShort:               "PacketTooShort"
                case .invalidLengthByte:            "InvalidLengthByte"
                case let .invalidDescriptor(desc):  "InvalidDescripton: \(String(desc, radix: 16))"
                case .garbageAtEnd:                 "GarbageAtEnd"
            }
        }
    }

    enum Descriptor: CustomStringConvertible {
        case interface(InterfaceDescriptor)
        case endpoint(EndpointDescriptor)
        case hid(HIDDescriptor)
        case endpointCompanion(EndpointCompanionDescriptor)
        case unknown(UInt8)

        var description: String {
            switch self {
                case .interface: "interface"
                case .endpoint: "endpoint"
                case .hid: "hid"
                case .endpointCompanion: "endpointCompanion"
                case .unknown: "unknown"
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
            + " bMaxPower: \(UInt16(bMaxPower) * 2)mA"
            for interface in interfaces {
                result += "\n +-- \(interface.description)"
            }

            return result
        }


        // This will parse either a packet of size(usb_standard_interface_descriptor), sufficient to obtain wTotalLength,
        // or a packet of size wTotalLength which will include all of the sub structures
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
            self.descriptor = _descriptor

            if buffer.count ==  MemoryLayout<usb_standard_interface_descriptor>.size {
                // Short packet, no extra data
                self.interfaces = []
                return
            }
            // Revalidate length, input buffer length should now be equal to wTotalLength
            guard buffer.count == _descriptor.wTotalLength else { throw ParsingError.packetTooShort }

            // The rest of the Config Descriptor is interface, endpoint and other
            // smaller config descriptors so iterate through each one and append it
            // to the correct data structure.

            // If there are any interfaces, try and initialise them from any remaining bytes
            // Note there could be more than bNumInterfaces due to the presence of alternate interfaces
            var _interfaces: [InterfaceDescriptor] = []
            _interfaces.reserveCapacity(Int(descriptor.bNumInterfaces))

            // The current interface and endpoint is not added to the repective arrays
            // until the next interface or endpoint is seen as they are values so cannot
            // be modified once they have been added into an array.
            var interfaceNumber: UInt8 = 0
            var currentInterface: InterfaceDescriptor? = nil
            var currentEndpoint: EndpointDescriptor? = nil

            func addEndpoint() throws(ParsingError) {
                guard let ep = currentEndpoint else { return }
                if currentInterface != nil {
                    currentInterface?.addEndpoint(ep)
                } else {
                    throw ParsingError.invalidDescriptor(DescriptorType.ENDPOINT.rawValue)
                }
                currentEndpoint = nil
            }

            func addInterface() throws(ParsingError) {
                try addEndpoint()
                if let iface = currentInterface {
                    guard iface.bNumEndpoints == iface.endpoints.count + 1 else {
                        #kprint("USB-DEV: Warning: Interface \(iface.bInterfaceNumber) has an inconsistent number of endpoints (\(iface.endpoints.count + 1) expected, \(iface.bNumEndpoints) found)")
                        throw ParsingError.packetTooShort
                    }
                    _interfaces.append(iface)
                }
                currentInterface = nil
            }


            while let descriptor = try Self.parseDescriptor(from: &iterator) {
                switch descriptor {
                    case .interface(let interface):
                        try addInterface()
                        interfaceNumber = interface.bInterfaceNumber
                        currentInterface = interface

                    case .endpoint(let endpoint):
                        try addEndpoint()
                        currentEndpoint = endpoint

                    case .endpointCompanion(let companion):
                        if currentEndpoint != nil {
                            try currentEndpoint?.addEndpointCompanion(companion)
                        } else {
                            throw ParsingError.invalidDescriptor(DescriptorType.ENDPOINT_COMPANION.rawValue)
                        }

                    case .hid(let hid):
                        guard currentInterface != nil else {
                            throw ParsingError.invalidDescriptor(DescriptorType.HID.rawValue)
                        }
                        try currentInterface?.addHID(hid)

                    case .unknown(let bDescriptorType):
                        throw ParsingError.invalidDescriptor(bDescriptorType)
                }
            }
            // Add the current endpoint and interface
            try addEndpoint()
            try addInterface()
            // Check that there were enough interfaces
            guard interfaceNumber == descriptor.bNumInterfaces - 1 else { throw ParsingError.packetTooShort }

            // The iterator should now be empty
            guard iterator.next() == nil else { throw ParsingError.garbageAtEnd }
            self.interfaces = _interfaces
        }

        static func parseDescriptor(from iterator: inout MMIOSubRegion.Iterator) throws(ParsingError) -> Descriptor? {
            guard let bLength = iterator.next() else { return nil }
            // Validate the initial bytes
            guard let descriptorByte = iterator.next() else {
                throw ParsingError.packetTooShort
            }

            if let descriptorType = DescriptorType(rawValue: descriptorByte) {
                switch descriptorType {
                    case .INTERFACE:
                        return .interface(try InterfaceDescriptor(from: &iterator, length: bLength))

                    case .ENDPOINT:
                        return .endpoint(try EndpointDescriptor(from: &iterator, length: bLength))

                    case .HID:
                        return .hid(try HIDDescriptor(from: &iterator, length: bLength))

                    case .ENDPOINT_COMPANION:
                        return .endpointCompanion(try EndpointCompanionDescriptor(from: &iterator, length: bLength))

                    default:
                        break
                }
            }

            #kprint("usb: Unknown descriptor: \(descriptorByte)")
            for _ in 1...(bLength - 2) {
                guard iterator.next() != nil else {
                    throw ParsingError.packetTooShort
                }
            }
            return .unknown(descriptorByte)
        }
    }
}
