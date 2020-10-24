/*
 * kernel/devices/usb/usb-hiddescriptor.swift
 *
 * Created by Simon Evans on 27/10/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB HID Descriptor.
 *
 */


extension USB {

    struct HIDDescriptor: CustomStringConvertible {
        private let descriptor: usb_hid_descriptor

        var bLength: UInt8 { descriptor.bLength }
        var bDescriptorType: UInt8 { descriptor.bDescriptorType }
        var bcdHID: UInt16 { descriptor.bcdHID }
        var bCountryCode: UInt8 { descriptor.bCountryCode }
        var bNumDescriptors: UInt8 { descriptor.bNumDescriptors }
        var bReportDescriptorType: UInt8 { descriptor.bReportDescriptorType }
        var wDescriptorLength: UInt16 { descriptor.wDescriptorLength }

        var description: String {
            let version = "\(String(bcdHID >> 8, radix: 16)).\(String(bcdHID & 0xff, radix: 16))"
            return "HID: v\(version) country: \(bCountryCode)"
        }


        init(from iterator: inout UnsafeMutableRawBufferPointer.Iterator) throws {
            // Validate the initial bytes
            guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else { throw ParsingError.packetTooShort }
            guard Int(lengthByte) == MemoryLayout<usb_hid_descriptor>.size else { throw ParsingError.invalidLengthByte }
            guard descriptorByte == USB.DescriptorType.HID.rawValue else { throw ParsingError.invalidDescriptor(descriptorByte) }

            var _descriptor = usb_hid_descriptor()
            try withUnsafeMutableBytes(of: &_descriptor) {
                assert(MemoryLayout<usb_hid_descriptor>.size == $0.count)
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
