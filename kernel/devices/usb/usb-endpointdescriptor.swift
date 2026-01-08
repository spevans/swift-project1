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

        enum TransferType: UInt8, CustomStringConvertible {
            case control = 0
            case isochronous = 1
            case bulk = 2
            case interrupt = 3

            var description: String {
                return switch self {
                case .control:     "control"
                case .isochronous: "isochronous"
                case .bulk:        "bulk"
                case .interrupt:   "interrupt"
                }
            }
        }

        enum SynchronizationType: UInt8, CustomStringConvertible {
            case none = 0
            case asynchronous = 1
            case adaptive = 2
            case synchronous = 3

            var description: String {
                return switch self {
                case .none:         "none"
                case .asynchronous: "asynchronous"
                case .adaptive:     "adaptive"
                case .synchronous:  "synchronous"
                }
            }
        }

        enum UsageType: UInt8, CustomStringConvertible {
            case data = 0
            case feedback = 1
            case implicitFeedback = 2
            case reserved = 3

            var description: String {
                return switch self {
                case .data:             "data"
                case .feedback:         "feedback"
                case .implicitFeedback: "implicitFeedback"
                case .reserved:         "reserved"
                }
            }
        }

        private let descriptor: usb_standard_endpoint_descriptor
        private(set) var companion: EndpointCompanionDescriptor? = nil

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

        // Dummy descriptor for the InterfaceDescriptor
        init() {
            self.init(controlEndPoint: 0, maxPacketSize: 0, bInterval: 0)
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
                bInterval: bInterval
            )
        }

        init(from iterator: inout MMIOSubRegion.Iterator, length: UInt8? = nil) throws(ParsingError) {

            let bLength: UInt8
            if let length {
                bLength = length
            } else {
                // Validate the initial bytes
                guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else {
                    throw ParsingError.packetTooShort
                }
                guard descriptorByte == USB.DescriptorType.ENDPOINT.rawValue else {
                    throw ParsingError.invalidDescriptor(descriptorByte)
                }
                bLength = lengthByte
            }
            guard Int(bLength) == MemoryLayout<usb_standard_endpoint_descriptor>.size else {
                throw ParsingError.invalidLengthByte
            }

            var _descriptor = usb_standard_endpoint_descriptor()
            try withUnsafeMutableBytes(of: &_descriptor) { (buffer: UnsafeMutableRawBufferPointer) throws(ParsingError) -> () in
                assert(MemoryLayout<usb_standard_endpoint_descriptor>.size == buffer.count)
                buffer[0] = bLength
                buffer[1] = USB.DescriptorType.ENDPOINT.rawValue

                for idx in 2..<buffer.count {
                    guard let byte = iterator.next() else { throw ParsingError.packetTooShort }
                    buffer[idx] = byte
                }
            }

            descriptor = _descriptor
        }

        mutating func addEndpointCompanion(_ companion: EndpointCompanionDescriptor) throws(ParsingError) {
            guard self.companion == nil else {
                throw ParsingError.garbageAtEnd
            }
            self.companion = companion
        }

        // Used by XHCI, Table 6-9
        var endpointType: UInt32 {
            return switch (transferType, direction) {
                case (.isochronous, .hostToDevice): 1
                case (.bulk, .hostToDevice): 2
                case (.interrupt, .hostToDevice): 3
                case (.control, _): 4
                case (.isochronous, .deviceToHost): 5
                case (.bulk, .deviceToHost): 6
                case (.interrupt, .deviceToHost): 7
            }
        }
    }

    // 9.6.7 SuperSpeed Endpoint Companion Descriptor
    // Used by SuperSpeed USB3 devices
    struct EndpointCompanionDescriptor {
        let bLength: UInt8
        let bDescriptorType: UInt8
        let bMaxBurst: UInt8
        let bmAttributes: UInt8
        let wBytesPerInterval: UInt16

        init(from iterator: inout MMIOSubRegion.Iterator, length: UInt8? = nil) throws(ParsingError) {

            let bLength: UInt8
            if let length {
                bLength = length
            } else {
                // Validate the initial bytes
                guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else {
                    throw ParsingError.packetTooShort
                }
                guard descriptorByte == USB.DescriptorType.ENDPOINT_COMPANION.rawValue else {
                    throw ParsingError.invalidDescriptor(descriptorByte)
                }
                bLength = lengthByte
            }
            guard Int(bLength) == 6 else {
                throw ParsingError.invalidLengthByte
            }

            guard let bMaxBurst = iterator.next(),let bmAttributes = iterator.next(), let wBytesPerIntervalLow = iterator.next(), let wBytesPerIntervalHigh = iterator.next() else {
                throw ParsingError.packetTooShort
            }

            self.bLength = bLength
            self.bDescriptorType = USB.DescriptorType.ENDPOINT_COMPANION.rawValue

            self.bMaxBurst = bMaxBurst
            self.bmAttributes = bmAttributes
            self.wBytesPerInterval = UInt16(wBytesPerIntervalHigh) << 8 | UInt16(wBytesPerIntervalLow)
        }
    }
}
