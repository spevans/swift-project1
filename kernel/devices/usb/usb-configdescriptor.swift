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
                case let .invalidDescriptor(desc):  "InvalidDescriptor: \(String(desc, radix: 16))"
                case .garbageAtEnd:                 "GarbageAtEnd"
            }
        }
    }


    struct ConfigDescriptor: Equatable, CustomStringConvertible {

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

        // ConfigDescriptor for a HUB (internal HCD)
        init(hubSpeed: USB.Speed) {
            let interruptEndpoint = EndpointDescriptor(endPoint: 1, direction: .deviceToHost,
                                                       maxPacketSize: 4, interval: 16)
            let interface = InterfaceDescriptor(ifNum: 0, alternate: 0,
                                                ifClass: InterfaceClass.hub.rawValue,
                                                ifSubClass: 0, ifProtocol: 0, stringIndex: 1,
                                                endpoints: [interruptEndpoint],
                                                functionDescriptors: [])
            self.interfaces = [interface]

            let descriptorLength = MemoryLayout<usb_standard_config_descriptor>.size
            var wLength = UInt16(descriptorLength)
            for interface in self.interfaces {
                wLength += UInt16(interface.bLength)
                wLength += interface.endpoints.reduce(UInt16(0), {
                    result, endpoint in result + UInt16(endpoint.bLength)
                })
            }

            self.descriptor = usb_standard_config_descriptor(
                bLength: UInt8(descriptorLength),
                bDescriptorType: USB.DescriptorType.CONFIGURATION.rawValue,
                wTotalLength: wLength,
                bNumInterfaces: 1,
                bConfigurationValue: 1,
                iConfiguration: 0,
                bmAttributes: 0,
                bMaxPower: 0
            )
        }

        // This will parse either a packet of size(usb_standard_interface_descriptor),
        // sufficient to obtain wTotalLength, or a packet of size wTotalLength which
        // will include all of the sub structures.
        init(from buffer: MMIOSubRegion) throws(ParsingError) {
            var iterator = buffer.makeIterator()
            // Validate the initial bytes
            guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else {
                throw ParsingError.packetTooShort
            }
            guard Int(lengthByte) == MemoryLayout<usb_standard_config_descriptor>.size else {
                throw ParsingError.invalidLengthByte
            }
            guard descriptorByte == USB.DescriptorType.CONFIGURATION.rawValue else {
                throw ParsingError.invalidDescriptor(descriptorByte)
            }

            var _configDescriptor = usb_standard_config_descriptor()
            var shortPacket = false
            try withUnsafeMutableBytes(of: &_configDescriptor) { (output: UnsafeMutableRawBufferPointer) throws(ParsingError) -> () in
                assert(MemoryLayout<usb_standard_config_descriptor>.size == output.count)
                output[0] = lengthByte
                output[1] = descriptorByte

                for idx in 2..<output.count {
                    // guard let byte = try? iterator.next() // else { return ParsingError.packetTooShort }
                    guard let byte = iterator.next() else {
                        shortPacket = true
                        return
                    }
                    output[idx] = byte
                }
            }

            self.descriptor = _configDescriptor
            var bytesLeft = min(_configDescriptor.wTotalLength, UInt16(buffer.count))
            if shortPacket || bytesLeft <= UInt16(_configDescriptor.bLength) {
                // Short packet, no extra data
                self.interfaces = []
                return
            }
            bytesLeft -= UInt16(_configDescriptor.bLength)

            // The rest of the Config Descriptor is interface, endpoint and other
            // smaller config descriptors so iterate through each one and append it
            // to the correct data structure.

            var _interfaces: [InterfaceDescriptor] = []
            _interfaces.reserveCapacity(Int(descriptor.bNumInterfaces))
            var interfaceNumber: UInt8 = 0
            var haveInterface = false
            var _interfaceDescriptor = usb_standard_interface_descriptor()
            var _endpoints: [EndpointDescriptor] = []
            var _functionDescriptors: [Array<UInt8>] = []

            // The current interface is not added to the respective arrays
            // until the next interface is seen.
            func addLastInterface() throws(ParsingError) {
                if haveInterface {
                    // Process the last interface before setting up the new one
                    let interface = try InterfaceDescriptor(
                        descriptor: _interfaceDescriptor,
                        endpoints: _endpoints,
                        functionDescriptors: _functionDescriptors
                    )
                    _interfaces.append(interface)
                }
            }

            while bytesLeft > 0 {
                // Validate the initial bytes
                guard let bLength = iterator.next() else {
                    // Should not be possible as bytesLeft > 0
                    fatalError("USB: bytesLeft > 0 but no next byte decoding ConfigDescriptor")
                }
                guard bLength > 2, UInt16(bLength) <= bytesLeft,
                      let descriptorByte = iterator.next() else {
                    throw ParsingError.packetTooShort
                }

                var hasFunctionDescriptor = false
                if let descriptorType = DescriptorType(rawValue: descriptorByte) {
                    switch descriptorType {
                        case .INTERFACE:
                            try addLastInterface()
                            // Now copy the new interface into the descriptor
                            _interfaceDescriptor = usb_standard_interface_descriptor()
                            try withUnsafeMutableBytes(of: &_interfaceDescriptor) { (buffer: UnsafeMutableRawBufferPointer) throws(ParsingError) -> () in
                                buffer[0] = bLength
                                buffer[1] = USB.DescriptorType.INTERFACE.rawValue

                                for idx in 2..<Int(bLength) {
                                    guard let byte = iterator.next() else {
                                        throw ParsingError.packetTooShort
                                    }
                                    buffer[idx] = byte
                                }
                            }
                            haveInterface = true
                            interfaceNumber = _interfaceDescriptor.bInterfaceNumber
                            _endpoints = []
                            _endpoints.reserveCapacity(Int(_interfaceDescriptor.bNumEndpoints))
                            _functionDescriptors = []

                        case .ENDPOINT:
                            let endpoint = try EndpointDescriptor(from: &iterator, length: bLength)
                            _endpoints.append(endpoint)

                        case .ENDPOINT_COMPANION:
                            let companion = try EndpointCompanionDescriptor(from: &iterator, length: bLength)

                            if var currentEndpoint = _endpoints.popLast() {
                                try currentEndpoint.addEndpointCompanion(companion)
                                _endpoints.append(currentEndpoint)
                            } else {
                                throw ParsingError.invalidDescriptor(descriptorByte)
                            }

                        default:
                            hasFunctionDescriptor = true
                            break
                    }
                } else {
                    hasFunctionDescriptor = true
                }
                if hasFunctionDescriptor {
                    var functionDescriptor: [UInt8] = []
                    functionDescriptor.reserveCapacity(Int(bLength))
                    functionDescriptor.append(bLength)
                    functionDescriptor.append(descriptorByte)
                    for _ in 1...(bLength - 2) {
                        guard let byte = iterator.next() else {
                            throw ParsingError.packetTooShort
                        }
                        functionDescriptor.append(byte)
                    }
                    _functionDescriptors.append(functionDescriptor)
                }
                bytesLeft -= UInt16(bLength)
            }

            // Add the current endpoint and interface
            try addLastInterface()
            // Check that there were enough interfaces
            guard interfaceNumber == descriptor.bNumInterfaces - 1 else {
                #kprintf("ConfigDescriptor: not enough interfaces interfaceNumber: %u descriptor.bNumInterfaces: %u\n",
                         interfaceNumber, descriptor.bNumInterfaces)
                throw ParsingError.packetTooShort
            }

            self.interfaces = _interfaces
        }


        func write(into buffer: inout MMIOSubRegion, maxLength: UInt16) -> UInt16 {
            let length = min(UInt16(self.descriptor.bLength), maxLength)
            var offset: UInt16 = 0
            withUnsafeBytes(of: self.descriptor) {
                for idx in 0..<Int(length) {
                    buffer[idx] = $0[idx]
                    offset += 1
                }
            }
            guard offset < maxLength else { return offset }

            for interface in self.interfaces {
                var subRegion = buffer.mmioSubRegion(offset: Int(offset))
                offset += interface.write(into: &subRegion, maxLength: maxLength - offset)
                guard offset < maxLength else { return offset }
            }
            assert(offset == self.descriptor.wTotalLength)
            return offset
        }

        static func ==(lhs: USB.ConfigDescriptor, rhs: USB.ConfigDescriptor) -> Bool {
            lhs.descriptor.bLength == rhs.descriptor.bLength
            && lhs.descriptor.bDescriptorType == rhs.descriptor.bDescriptorType
            && lhs.descriptor.wTotalLength == rhs.descriptor.wTotalLength
            && lhs.descriptor.bNumInterfaces == rhs.descriptor.bNumInterfaces
            && lhs.descriptor.bConfigurationValue == rhs.descriptor.bConfigurationValue
            && lhs.descriptor.iConfiguration == rhs.descriptor.iConfiguration
            && lhs.descriptor.bmAttributes == rhs.descriptor.bmAttributes
            && lhs.descriptor.bMaxPower == rhs.descriptor.bMaxPower
            && lhs.interfaces == rhs.interfaces
        }
    }
}
