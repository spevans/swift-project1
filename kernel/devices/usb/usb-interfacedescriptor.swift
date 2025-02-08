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
            switch self {
            case .audio:                return "Audio"
            case .cdcControl:           return "CDC Control"
            case .hid:                  return "hid"
            case .physical:             return "Physical"
            case .image:                return "Image"
            case .printer:              return "Printer"
            case .massStorage:          return "Mass Storage"
            case .cdcData:              return "CDC Data"
            case .smartCard:            return "Smart Card"
            case .contentSecurity:      return "Content Security"
            case .video:                return "Video"
            case .personalHealthcare:   return "Personal Healthcare"
            case .audioVideo:           return "Audio Video"
            case .usbTypeCBridgeClass:  return "USB TypeC Bridge Class"
            case .diagnosticDevice:     return "Diagnostic Device"
            case .wirelessController:   return "Wireless Controller"
            case .miscellaneous:        return "Miscallaneous"
            case .applicationSpecific:  return "Application Specific"
            case .vendorSpecific:       return "Vendor Specific"

            }
        }
    }


    struct InterfaceDescriptor: CustomStringConvertible {
        private let descriptor: usb_standard_interface_descriptor
        // Endpoints that were found in the iterator input may have endpoints.count < bNumEndpoints
        private(set) var endpoint0: EndpointDescriptor
        let endpoints: [EndpointDescriptor]
        let hid: HIDDescriptor?


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
            var result = "ifNum: \(bInterfaceNumber) class: \(ifClass) subClass: 0x\(String(bInterfaceSubClass, radix: 16)) bInterfaceProtocol: 0x\(String(bInterfaceProtocol, radix: 16))\n"
            if let hid = hid {
                result += " +-- \(hid.description)"
            }
            result += "\n +-- \(endpoint0.description)\n"
            for endpoint in endpoints {
                result += " +-- \(endpoint.description)\n"
            }

            return result
        }


        init(from iterator: inout MMIOSubRegion.Iterator) throws(ParsingError) {
            // Validate the initial bytes
            guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else { throw ParsingError.packetTooShort }
            guard Int(lengthByte) == MemoryLayout<usb_standard_interface_descriptor>.size else { throw ParsingError.invalidLengthByte }
            guard descriptorByte == USB.DescriptorType.INTERFACE.rawValue else { throw ParsingError.invalidDescriptor(descriptorByte) }

            var _descriptor = usb_standard_interface_descriptor()
            try withUnsafeMutableBytes(of: &_descriptor) { (buffer: UnsafeMutableRawBufferPointer) throws(ParsingError) -> () in
                assert(MemoryLayout<usb_standard_interface_descriptor>.size == buffer.count)
                buffer[0] = lengthByte
                buffer[1] = descriptorByte

                for idx in 2..<buffer.count {
                    guard let byte = iterator.next() else { throw ParsingError.packetTooShort }
                    buffer[idx] = byte
                }
            }


            // See if there is an optional HID descriptor
            if _descriptor.bInterfaceClass == 0x03 {
                hid = try HIDDescriptor(from: &iterator)
            } else {
                hid = nil
            }

            var _endpoints: [EndpointDescriptor] = []

            // Next should be at least one endpoint, endpoint0
            endpoint0 = try EndpointDescriptor(from: &iterator)
            precondition(_descriptor.bNumEndpoints > 0)
            // If there are any more endpoints, try and initialise them from any remaining bytes
            for _ in 0..<(_descriptor.bNumEndpoints - 1) {
                let endpoint = try EndpointDescriptor(from: &iterator)
                _endpoints.append(endpoint)
            }

            descriptor = _descriptor
            endpoints = _endpoints
        }


        func endpointMatching(transferType: EndpointDescriptor.TransferType) -> EndpointDescriptor? {
            if endpoint0.transferType == transferType { return endpoint0 }
            return endpoints.filter { $0.transferType == transferType }.first
        }
    }
}
