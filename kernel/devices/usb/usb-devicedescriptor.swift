/*
 * kernel/devices/usb/usb-devicedescriptor.swift
 *
 * Created by Simon Evans on 22/10/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB Device Descriptor.
 *
 */


extension USB {

    enum DeviceClass: UInt8, CustomStringConvertible {
        case interfaceSpecific = 0x00
        case communications = 0x02
        case hub = 0x09
        case billboard = 0x11
        case diagnosticDevice = 0xDC
        case miscellaneous = 0xEF
        case vendorSpecific = 0xFF

        var description: String {
            return switch self {
                case .interfaceSpecific:  "Interface Specific"
                case .communications:     "Communications"
                case .hub:                "Hub"
                case .billboard:          "Billboard"
                case .diagnosticDevice:   "Diagnostic"
                case .miscellaneous:      "Miscellaneous"
                case .vendorSpecific:     "VendorSpecific"
            }
        }
    }

    struct DeviceDescriptor: CustomStringConvertible {
        private let descriptor: usb_standard_device_descriptor

        var description: String {
            let dc = deviceClass?.description ?? "unknown"
            return "bcdUSB: 0x\(String(bcdUSB, radix: 16)) bDeviceClass: \(String(bDeviceClass, radix: 16)) bDeviceSubClass: \(String(bDeviceSubClass, radix: 16))"
                + " bDeviceProtocol: \(String(bDeviceProtocol, radix: 16)) bMaxPacketSize0: \(String(bMaxPacketSize0)) class: \(dc)"
        }

        var bLength: UInt8 { descriptor.bLength }
        var bDescriptorType: DescriptorType { DescriptorType(rawValue: descriptor.bDescriptorType)! }
        var bcdUSB: UInt16 { descriptor.bcdUSB }
        var bDeviceClass: UInt8 { descriptor.bDeviceClass }
        var bDeviceSubClass: UInt8 { descriptor.bDeviceSubClass }
        var bDeviceProtocol: UInt8 { descriptor.bDeviceProtocol }
        var bMaxPacketSize0: UInt8 { descriptor.bMaxPacketSize0 }
        var idVendor: UInt16 { descriptor.idVendor }
        var idProduct: UInt16 { descriptor.idProduct }
        var bcdDevice: UInt16 { descriptor.bcdDevice }
        var iManufacturer: UInt8 { descriptor.iManufacturer }
        var iProduct: UInt8 { descriptor.iProduct }
        var iSerialNumber: UInt8 { descriptor.iSerialNumber }
        var bNumConfigurations: UInt8 { descriptor.bNumConfigurations }

        var deviceClass: DeviceClass? { DeviceClass(rawValue: bDeviceClass) }


        // Pass in a buffer that maybe shorter than a full packet
        init(from buffer: MMIOSubRegion) {
            precondition(buffer.count >= 8)
            precondition(buffer.count <= MemoryLayout<usb_standard_device_descriptor>.size)

            var _descriptor = usb_standard_device_descriptor()
            withUnsafeMutableBytes(of: &_descriptor) {
                for idx in 0..<buffer.count {
                    $0[idx] = buffer[idx]
                }
            }
            descriptor = _descriptor
        }
    }
}
