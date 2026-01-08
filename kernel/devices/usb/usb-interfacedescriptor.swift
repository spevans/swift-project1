/*
 * kernel/devices/usb/usb-interfacedescriptor.swift
 *
 * Created by Simon Evans on 22/10/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB Interface Descriptor
 *
 */


extension USB {

    enum InterfaceClass: UInt8, CustomStringConvertible {

        case audio = 0x01
        case cdcControl = 0x02
        case hid = 0x03
        case physical = 0x05
        case image = 0x06
        case printer = 0x07
        case massStorage = 0x08
        case hub = 0x09
        case cdcData = 0x0A
        case smartCard = 0x0B
        case contentSecurity = 0x0D
        case video = 0x0E
        case personalHealthcare = 0x0F
        case audioVideo = 0x10
        case usbTypeCBridgeClass = 0x12
        case diagnosticDevice = 0xDC
        case wirelessController = 0xE0
        case miscellaneous = 0xEF
        case applicationSpecific = 0xFE
        case vendorSpecific = 0xFF

        var description: String {
            return switch self {
                case .audio:                "Audio"
                case .cdcControl:           "CDC Control"
                case .hid:                  "HID"
                case .physical:             "Physical"
                case .image:                "Image"
                case .printer:              "Printer"
                case .massStorage:          "Mass Storage"
                case .hub:                  "Hub"
                case .cdcData:              "CDC Data"
                case .smartCard:            "Smart Card"
                case .contentSecurity:      "Content Security"
                case .video:                "Video"
                case .personalHealthcare:   "Personal Healthcare"
                case .audioVideo:           "Audio Video"
                case .usbTypeCBridgeClass:  "USB TypeC Bridge Class"
                case .diagnosticDevice:     "Diagnostic Device"
                case .wirelessController:   "Wireless Controller"
                case .miscellaneous:        "Miscallaneous"
                case .applicationSpecific:  "Application Specific"
                case .vendorSpecific:       "Vendor Specific"
            }
        }
    }


    struct InterfaceDescriptor: CustomStringConvertible {
        private let descriptor: usb_standard_interface_descriptor
        // Endpoints that were found in the iterator input may have endpoints.count < bNumEndpoints
        private(set) var endpoint0 = EndpointDescriptor()   // Dummy
        private(set) var endpoints: [EndpointDescriptor] = []
        private(set) var hid: HIDDescriptor? = nil
        private var ep0Set: Bool = false

        var bLength: UInt8 { descriptor.bLength }
        var bDescriptorType: UInt8 { descriptor.bDescriptorType }
        var bInterfaceNumber: UInt8 { descriptor.bInterfaceNumber }
        var bAlternateSetting: UInt8 { descriptor.bAlternateSetting }
        var bNumEndpoints: UInt8 { descriptor.bNumEndpoints }
        var bInterfaceClass: UInt8 { descriptor.bInterfaceClass }
        var bInterfaceSubClass: UInt8 { descriptor.bInterfaceSubClass }
        var bInterfaceProtocol: UInt8 { descriptor.bInterfaceProtocol }
        var iInterface: UInt8 { descriptor.iInterface }

        var interfaceClass: InterfaceClass? { InterfaceClass(rawValue: bInterfaceClass) }

        var description: String {
            let ifClass = interfaceClass?.description ?? "unknown"
            var result = "ifNum: \(bInterfaceNumber) class: \(ifClass) subClass: 0x\(String(bInterfaceSubClass, radix: 16)) bInterfaceProtocol: 0x\(String(bInterfaceProtocol, radix: 16)) alt: \(bAlternateSetting)\n"
            if let hid = hid {
                result += "\t+-- \(hid.description)\n"
            }
            result += "\t+-- \(endpoint0.description)\n"
            for endpoint in endpoints {
                result += "\t+-- \(endpoint.description)\n"
            }

            return result
        }

        mutating func addEndpoint(_ endpoint: EndpointDescriptor) {
            if !self.ep0Set {
                self.endpoint0 = endpoint
                self.ep0Set = true
            } else {
                self.endpoints.append(endpoint)
            }
        }

        mutating func addHID(_ hid: HIDDescriptor) throws(ParsingError) {
            guard self.hid == nil else {
                // FIXME: Add better error
                throw ParsingError.garbageAtEnd
            }
        }

        init(from iterator: inout MMIOSubRegion.Iterator, length: UInt8? = nil) throws(ParsingError) {
            let bLength: UInt8
            if let length {
                bLength = length
            } else {
                guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else {
                    throw ParsingError.packetTooShort
                }
                guard descriptorByte == USB.DescriptorType.INTERFACE.rawValue else { throw ParsingError.invalidDescriptor(descriptorByte) }
                bLength = lengthByte
            }
            // Validate the initial bytes
            guard Int(bLength) == MemoryLayout<usb_standard_interface_descriptor>.size else { throw ParsingError.invalidLengthByte }

            var _descriptor = usb_standard_interface_descriptor()
            try withUnsafeMutableBytes(of: &_descriptor) { (buffer: UnsafeMutableRawBufferPointer) throws(ParsingError) -> () in
                assert(MemoryLayout<usb_standard_interface_descriptor>.size == buffer.count)
                buffer[0] = bLength
                buffer[1] = USB.DescriptorType.INTERFACE.rawValue

                for idx in 2..<buffer.count {
                    guard let byte = iterator.next() else { throw ParsingError.packetTooShort }
                    buffer[idx] = byte
                }
            }
            descriptor = _descriptor

            // The rest of the structure will be filled in by the parsing loop
            // int ConfigDescriptor
        }


        func endpointMatching(transferType: EndpointDescriptor.TransferType) -> EndpointDescriptor? {
            if endpoint0.transferType == transferType { return endpoint0 }
            return endpoints.filter { $0.transferType == transferType }.first
        }
    }
}
