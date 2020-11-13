/*
 * kernel/devices/usb/usb-endpointdescriptor.swift
 *
 * Created by Simon Evans on 22/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * USB Endpoint Descriptor.
 *
 */


extension USB {

    struct EndpointDescriptor: CustomStringConvertible {

        enum TransferType: UInt8 {
            case control = 0
            case isochronous = 1
            case bulk = 2
            case interrupt = 3
        }

        enum SynchronizationType: UInt8 {
            case none = 0
            case asynchronous = 1
            case adaptive = 2
            case synchronous = 3
        }

        enum UsageType: UInt8 {
            case data = 0
            case feedback = 1
            case implicitFeedback = 2
            case reserved = 3
        }

        private let descriptor: usb_standard_endpoint_descriptor

        var bEndpointAddress: UInt8 { descriptor.bEndpointAddress }
        var bmAttributes: UInt8 { descriptor.bmAttributes }
        var wMaxPacketSize: UInt16 { descriptor.wMaxPacketSize }
        var bInterval: UInt8 { descriptor.bInterval }

        var bmAttributesBits: BitArray8 { BitArray8(bmAttributes) }

        var endpoint: UInt { UInt(descriptor.bEndpointAddress & 0xf) }
        var direction: TransferDirection { TransferDirection(rawValue: descriptor.bEndpointAddress >> 7)! }
        var transferType: TransferType { TransferType(rawValue: UInt8(bmAttributesBits[0...1]))! }
        var synchronization: SynchronizationType { SynchronizationType(rawValue: UInt8(bmAttributesBits[2...3]))! }
        var usage: UsageType { UsageType(rawValue: UInt8(bmAttributesBits[4...5]))! }
        var maxPacketSize: UInt16 { wMaxPacketSize & 0x7ff }
        var additionalOpportunities: UInt { UInt(wMaxPacketSize & 0x3) }

        var description: String {
            return "endpoint: \(endpoint) dir: \(direction) \(transferType) synch: \(synchronization) \(usage) maxPacketSz: \(maxPacketSize) interval: \(bInterval)"
        }


        private init(endPoint: UInt8, direction: TransferDirection, transfer: TransferType, bmAttributes: UInt8, wMaxPacketSize: UInt16, bInterval: UInt8) {
            precondition(endPoint < 16)
            descriptor = usb_standard_endpoint_descriptor(
            bLength: UInt8(MemoryLayout<usb_standard_endpoint_descriptor>.size),
            bDescriptorType: USB.DescriptorType.ENDPOINT.rawValue,
            bEndpointAddress: direction.rawValue << 7 | endPoint,
            bmAttributes: bmAttributes,
            wMaxPacketSize: wMaxPacketSize,
            bInterval: bInterval)
        }


        // For Control Endpoints
        init(controlEndPoint: UInt8, maxPacketSize: UInt16, bInterval: UInt8) {
            precondition(controlEndPoint < 16)
            precondition(maxPacketSize < 2047)
            descriptor = usb_standard_endpoint_descriptor(
            bLength: UInt8(MemoryLayout<usb_standard_endpoint_descriptor>.size),
            bDescriptorType: USB.DescriptorType.ENDPOINT.rawValue,
            bEndpointAddress: controlEndPoint,
            bmAttributes: 0,
            wMaxPacketSize: maxPacketSize,
            bInterval: bInterval)
        }

        init(from iterator: inout UnsafeMutableRawBufferPointer.Iterator) throws {
            // Validate the initial bytes
            guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else { throw ParsingError.packetTooShort }
            guard Int(lengthByte) == MemoryLayout<usb_standard_endpoint_descriptor>.size else { throw ParsingError.invalidLengthByte }
            guard descriptorByte == USB.DescriptorType.ENDPOINT.rawValue else { throw ParsingError.invalidDescriptor(descriptorByte) }

            var _descriptor = usb_standard_endpoint_descriptor()
            try withUnsafeMutableBytes(of: &_descriptor) {
                assert(MemoryLayout<usb_standard_endpoint_descriptor>.size == $0.count)
                $0[0] = lengthByte
                $0[1] = descriptorByte

                for idx in 2..<$0.count {
                    guard let byte = iterator.next() else { throw ParsingError.packetTooShort }
                    $0[idx] = byte
                }
            }

            descriptor = _descriptor
        }
    }
}
