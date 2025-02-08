/*
 * kernel/devices/usb/usb-devicequalifier.swift
 *
 * Created by Simon Evans on 22/10/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB Device Qualifier Descriptor.
 *
 */


extension USB {

    struct DeviceQualifier: CustomStringConvertible {
        private let descriptor: usb_device_qualifier

        var description: String {
            let dc = deviceClass?.description ?? "unknown"
            return "bcdUSB: 0x\(String(bcdUSB, radix: 16)) bDeviceClass: \(String(bDeviceClass, radix: 16)) bDeviceSubClass: \(String(bDeviceSubClass, radix: 16))"
                + " bDeviceProtocol: \(String(bDeviceProtocol, radix: 16)) bMaxPacketSize0: \(String(bMaxPacketSize0)) + class: \(dc)"
        }

        var bLength: UInt8 { descriptor.bLength }
        var bDescriptorType: UInt8 { descriptor.bDescriptorType }
        var bcdUSB: UInt16 { descriptor.bcdUSB }
        var bDeviceClass: UInt8 { descriptor.bDeviceClass }
        var bDeviceSubClass: UInt8 { descriptor.bDeviceSubClass }
        var bDeviceProtocol: UInt8 { descriptor.bDeviceProtocol }
        var bMaxPacketSize0: UInt8 { descriptor.bMaxPacketSize0 }
        var bNumConfigurations: UInt8 { descriptor.bNumConfigurations }
        var bReserved: UInt8 { descriptor.bReserved }

        var deviceClass: DeviceClass? { DeviceClass(rawValue: bDeviceClass) }


        init(from buffer: UnsafeRawBufferPointer) throws(ParsingError) {
            guard  buffer.count == MemoryLayout<usb_device_qualifier>.size else {
                throw ParsingError.packetTooShort
            }

            // Validate the initial bytes
            guard Int(buffer[0]) == MemoryLayout<usb_standard_interface_descriptor>.size else { throw ParsingError.invalidLengthByte }
            guard buffer[1] == USB.DescriptorType.CONFIGURATION.rawValue else { throw ParsingError.invalidDescriptor(buffer[1]) }

            var _descriptor = usb_device_qualifier()
            withUnsafeMutableBytes(of: &_descriptor) {
                assert(MemoryLayout<usb_device_qualifier>.size == $0.count)

                for idx in 0..<$0.count {
                    $0[idx] = buffer[0]
                }
            }
            descriptor = _descriptor
        }
    }
}
