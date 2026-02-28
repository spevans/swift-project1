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


    struct InterfaceDescriptor: Equatable, CustomStringConvertible {
        private let descriptor: usb_standard_interface_descriptor
        // For certain interfaces there can be interface specific descriptors.
        // These need to be decoded by drivers based on the interface class/subclass
        // and protocol. Just raw bytes are stored for now
        private(set) var functionDescriptors: [Array<UInt8>] = []

        // Endpoints that were found in the iterator input have endpoints.count == bNumEndpoints
        private(set) var endpoints: [EndpointDescriptor] = []

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


        init(ifNum: UInt8, alternate: UInt8, ifClass: UInt8, ifSubClass: UInt8,
             ifProtocol: UInt8, stringIndex: UInt8,
             endpoints: [EndpointDescriptor], functionDescriptors: [Array<UInt8>] ) {

            self.descriptor = usb_standard_interface_descriptor(
                bLength: UInt8(MemoryLayout<usb_standard_interface_descriptor>.size),
                bDescriptorType: DescriptorType.INTERFACE.rawValue,
                bInterfaceNumber: ifNum,
                bAlternateSetting: alternate,
                bNumEndpoints: UInt8(endpoints.count),
                bInterfaceClass: ifClass,
                bInterfaceSubClass: ifSubClass,
                bInterfaceProtocol: ifProtocol,
                iInterface: stringIndex
            )
            self.functionDescriptors = functionDescriptors
            self.endpoints = endpoints
        }

        init(descriptor: usb_standard_interface_descriptor, endpoints: [EndpointDescriptor],
             functionDescriptors: [Array<UInt8>]) {

            self.descriptor = descriptor
            self.functionDescriptors = functionDescriptors
            self.endpoints = endpoints
        }


        var description: String {
            let ifClass = interfaceClass?.description ?? "unknown"
            var result = "ifNum: \(bInterfaceNumber) class: \(ifClass) subClass: 0x\(String(bInterfaceSubClass, radix: 16)) bInterfaceProtocol: 0x\(String(bInterfaceProtocol, radix: 16)) alt: \(bAlternateSetting)\n"
            /*
             if let hid = hid {
             result += "\t+-- \(hid.description)\n"
             }*/
            for endpoint in endpoints {
                result += "\t+-- \(endpoint.description)\n"
            }

            return result
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
            for endpoint in self.endpoints {
                var subRegion = buffer.mmioSubRegion(offset: Int(offset))
                offset += endpoint.write(into: &subRegion,
                                         maxLength: maxLength - offset)
                guard offset < maxLength else { return offset }
            }

            for functionDescriptor in self.functionDescriptors {
                var subRegion = buffer.mmioSubRegion(offset: Int(offset))
                let length = min(functionDescriptor.count, Int(maxLength - offset))
                for index in 0..<length {
                    subRegion[index] = functionDescriptor[index]
                }
                guard offset < maxLength else { return offset }
            }
            return offset
        }


        func endpointMatching(transferType: EndpointDescriptor.TransferType) -> EndpointDescriptor? {
            return endpoints.filter { $0.transferType == transferType }.first
        }

        static func ==(lhs: Self, rhs: Self) -> Bool {
            lhs.descriptor.bLength == rhs.descriptor.bLength
            && lhs.descriptor.bDescriptorType == rhs.descriptor.bDescriptorType
            && lhs.descriptor.bInterfaceNumber == rhs.descriptor.bInterfaceNumber
            && lhs.descriptor.bAlternateSetting == rhs.descriptor.bAlternateSetting
            && lhs.descriptor.bNumEndpoints == rhs.descriptor.bNumEndpoints
            && lhs.descriptor.bInterfaceClass == rhs.descriptor.bInterfaceClass
            && lhs.descriptor.bInterfaceSubClass == rhs.descriptor.bInterfaceSubClass
            && lhs.descriptor.bInterfaceProtocol == rhs.descriptor.bInterfaceProtocol
            && lhs.descriptor.iInterface == rhs.descriptor.iInterface
            && lhs.endpoints == rhs.endpoints
            && lhs.functionDescriptors == rhs.functionDescriptors
        }
    }
}

