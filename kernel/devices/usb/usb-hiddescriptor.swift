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

    struct HIDDescriptor: Equatable, CustomStringConvertible {
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


        init(from iterator: inout MMIOSubRegion.Iterator, length: UInt8? = nil) throws(ParsingError) {

            let bLength: UInt8
            if let length {
                bLength = length
            } else {
                // Validate the initial bytes
                guard let lengthByte = iterator.next(), let descriptorByte = iterator.next() else { throw ParsingError.packetTooShort }
                guard descriptorByte == USB.DescriptorType.HID.rawValue else { throw ParsingError.invalidDescriptor(descriptorByte) }
                bLength = lengthByte
            }
            guard Int(bLength) == MemoryLayout<usb_hid_descriptor>.size else {
                throw ParsingError.invalidLengthByte
            }

            var _descriptor = usb_hid_descriptor()
            try withUnsafeMutableBytes(of: &_descriptor) { (buffer: UnsafeMutableRawBufferPointer) throws(ParsingError) -> () in
                assert(MemoryLayout<usb_hid_descriptor>.size == buffer.count)
                buffer[0] = bLength
                buffer[1] = USB.DescriptorType.HID.rawValue

                for idx in 2..<buffer.count {
                    guard let byte = iterator.next() else { throw ParsingError.packetTooShort }
                    buffer[idx] = byte
                }
            }

            descriptor = _descriptor
        }

        func write(into buffer: inout MMIOSubRegion, maxLength: UInt16) -> UInt16 {
            let length = min(UInt16(self.descriptor.bLength), maxLength)
            withUnsafeBytes(of: self.descriptor) {
                for idx in 0..<Int(length) {
                    buffer[idx] = $0[idx]
                }
            }
            return length
        }

        static func ==(lhs: Self, rhs: Self) -> Bool {
            lhs.descriptor.bLength == rhs.descriptor.bLength
            && lhs.descriptor.bDescriptorType == rhs.descriptor.bDescriptorType
            && lhs.descriptor.bcdHID == rhs.descriptor.bcdHID
            && lhs.descriptor.bCountryCode == rhs.descriptor.bCountryCode
            && lhs.descriptor.bNumDescriptors == rhs.descriptor.bNumDescriptors
            && lhs.descriptor.bReportDescriptorType == rhs.descriptor.bReportDescriptorType
            && lhs.descriptor.wDescriptorLength == rhs.descriptor.wDescriptorLength
        }
    }
}
