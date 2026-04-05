/*
 * USBTests.swift
 *
 * Created by Simon Evans on 27/10/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 */
import XCTest
@testable import Kernel

class USBTests: XCTestCase {


    func testConfigDescriptor() throws {
        let getDescriptorConfigData = Data([
            0x09, 0x02, 0x3b, 0x00, 0x02, 0x01, 0x01, 0xc0, 0x00, 0x09, 0x04, 0x00, 0x00, 0x01, 0x03, 0x00,
            0x00, 0x01, 0x09, 0x21, 0x10, 0x01, 0x00, 0x01, 0x22, 0x42, 0x00, 0x07, 0x05, 0x81, 0x03, 0x08,
            0x00, 0x01, 0x09, 0x04, 0x01, 0x00, 0x01, 0x03, 0x00, 0x00, 0x01, 0x09, 0x21, 0x10, 0x01, 0x00,
            0x01, 0x22, 0x41, 0x00, 0x07, 0x05, 0x82, 0x03, 0x08, 0x00, 0x01,
            ])

        XCTAssertEqual(getDescriptorConfigData.count, 59)

        let region = PhysRegion(data: getDescriptorConfigData)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let configDescriptor = try USB.ConfigDescriptor(from: mmioRegion)

        print(configDescriptor)

    }


    func testConfigDescriptor2() throws {
        let getDescriptorConfigData = Data([
            0x09, 0x02, 0x19, 0x00, 0x01, 0x01, 0x00, 0xe0, 0x00, 0x09, 0x04, 0x00, 0x00, 0x01, 0x09,
            0x00, 0x00, 0x00, 0x07, 0x05, 0x81, 0x03, 0x02, 0x00, 0x0f
        ])
        XCTAssertEqual(getDescriptorConfigData.count, 25)

        let region = PhysRegion(data: getDescriptorConfigData)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let configDescriptor = try USB.ConfigDescriptor(from: mmioRegion)

        print(configDescriptor)
    }

    func testConfigDescriptor3() throws {
        let getDescriptorConfigData = Data([

            0x09, 0x02, 0xb1, 0x00, 0x02, 0x01, 0x00, 0xe0, 0x32, 0x09, 0x04, 0x00, 0x00, 0x03, 0xe0, 0x01,
            0x01, 0x00, 0x07, 0x05, 0x81, 0x03, 0x40, 0x00, 0x01, 0x07, 0x05, 0x02, 0x02, 0x40, 0x00, 0x01,
            0x07, 0x05, 0x82, 0x02, 0x40, 0x00, 0x01, 0x09, 0x04, 0x01, 0x00, 0x02, 0xe0, 0x01, 0x01, 0x00,
            0x07, 0x05, 0x03, 0x01, 0x00, 0x00, 0x01, 0x07, 0x05, 0x83, 0x01, 0x00, 0x00, 0x01, 0x09, 0x04,
            0x01, 0x01, 0x02, 0xe0, 0x01, 0x01, 0x00, 0x07, 0x05, 0x03, 0x01, 0x09, 0x00, 0x01, 0x07, 0x05,
            0x83, 0x01, 0x09, 0x00, 0x01, 0x09, 0x04, 0x01, 0x02, 0x02, 0xe0, 0x01, 0x01, 0x00, 0x07, 0x05,
            0x03, 0x01, 0x11, 0x00, 0x01, 0x07, 0x05, 0x83, 0x01, 0x11, 0x00, 0x01, 0x09, 0x04, 0x01, 0x03,
            0x02, 0xe0, 0x01, 0x01, 0x00, 0x07, 0x05, 0x03, 0x01, 0x19, 0x00, 0x01, 0x07, 0x05, 0x83, 0x01,
            0x19, 0x00, 0x01, 0x09, 0x04, 0x01, 0x04, 0x02, 0xe0, 0x01, 0x01, 0x00, 0x07, 0x05, 0x03, 0x01,
            0x21, 0x00, 0x01, 0x07, 0x05, 0x83, 0x01, 0x21, 0x00, 0x01, 0x09, 0x04, 0x01, 0x05, 0x02, 0xe0,
            0x01, 0x01, 0x00, 0x07, 0x05, 0x03, 0x01, 0x31, 0x00, 0x01, 0x07, 0x05, 0x83, 0x01, 0x31, 0x00,
            0x01
        ])
        XCTAssertEqual(getDescriptorConfigData.count, 177)

        let region = PhysRegion(data: getDescriptorConfigData)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let configDescriptor = try USB.ConfigDescriptor(from: mmioRegion)
        XCTAssertEqual(configDescriptor.interfaces.count, 7)
        print(configDescriptor)
    }

    func testConfigDescriptor4() throws {
        let getDescriptorConfigData = Data([
            0x09, 0x02, 0x1f, 0x00, 0x01, 0x01, 0x00, 0xe0,
            0x00, 0x09, 0x04, 0x00, 0x00, 0x01, 0x09, 0x00,
            0x00, 0x01, 0x07, 0x05, 0x81, 0x13, 0x02, 0x00,
            0x08, 0x06, 0x30, 0x00, 0x00, 0x02, 0x00
        ])
        XCTAssertEqual(getDescriptorConfigData.count, 31)

        let region = PhysRegion(data: getDescriptorConfigData)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let configDescriptor = try USB.ConfigDescriptor(from: mmioRegion)
        XCTAssertEqual(configDescriptor.interfaces.count, 1)
        print(configDescriptor)
    }

    func testConfigDescriptor5() throws {
        let getDescriptorConfigData = Data([
            0x09, 0x02, 0x2c, 0x00, 0x01, 0x01, 0x00, 0xa0,
            0x70, 0x09, 0x04, 0x00, 0x00, 0x02, 0x08, 0x06,
            0x50, 0x00, 0x07, 0x05, 0x81, 0x02, 0x00, 0x04,
            0x00, 0x06, 0x30, 0x04, 0x00, 0x00, 0x00, 0x07,
            0x05, 0x02, 0x02, 0x00, 0x04, 0x00, 0x06, 0x30,
            0x04, 0x00, 0x00, 0x00
        ])
        XCTAssertEqual(getDescriptorConfigData.count, 44)

        let region = PhysRegion(data: getDescriptorConfigData)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let configDescriptor = try USB.ConfigDescriptor(from: mmioRegion)
        XCTAssertEqual(configDescriptor.interfaces.count, 1)
        let interface = configDescriptor.interfaces[0]
        XCTAssertNotNil(interface.endpoints[0].companion)
        XCTAssertEqual(interface.endpoints.count, 2)
        XCTAssertNotNil(interface.endpoints[1].companion)
        print(configDescriptor)
    }

    func testConfigDescriptor6() throws {
        let getDescriptorConfigData = Data([
            0x09, 0x02, 0x3b, 0x00, 0x02, 0x01, 0x00, 0xa0, 0x19,
        ])
        XCTAssertEqual(getDescriptorConfigData.count, 9)

        let region = PhysRegion(data: getDescriptorConfigData)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let configDescriptor = try USB.ConfigDescriptor(from: mmioRegion)
        XCTAssertEqual(configDescriptor.interfaces.count, 0)
        print(configDescriptor)
    }

    func testConfigDescriptor7() throws {
        let data = Data([
            0x09, 0x02, 0xd8, 0x00, 0x04, 0x01, 0x00, 0xe0, 0x00, 0x09, 0x04, 0x00, 0x00, 0x03, 0xff, 0x01,
            0x01, 0x00, 0x07, 0x05, 0x81, 0x03, 0x10, 0x00, 0x01, 0x07, 0x05, 0x82, 0x02, 0x40, 0x00, 0x01,
            0x07, 0x05, 0x02, 0x02, 0x40, 0x00, 0x01, 0x09, 0x04, 0x01, 0x00, 0x02, 0xe0, 0x01, 0x01, 0x00,
            0x07, 0x05, 0x83, 0x01, 0x00, 0x00, 0x01, 0x07, 0x05, 0x03, 0x01, 0x00, 0x00, 0x01, 0x09, 0x04,
            0x01, 0x01, 0x02, 0xe0, 0x01, 0x01, 0x00, 0x07, 0x05, 0x83, 0x01, 0x09, 0x00, 0x01, 0x07, 0x05,
            0x03, 0x01, 0x09, 0x00, 0x01, 0x09, 0x04, 0x01, 0x02, 0x02, 0xe0, 0x01, 0x01, 0x00, 0x07, 0x05,
            0x83, 0x01, 0x11, 0x00, 0x01, 0x07, 0x05, 0x03, 0x01, 0x11, 0x00, 0x01, 0x09, 0x04, 0x01, 0x03,
            0x02, 0xe0, 0x01, 0x01, 0x00, 0x07, 0x05, 0x83, 0x01, 0x20, 0x00, 0x01, 0x07, 0x05, 0x03, 0x01,
            0x20, 0x00, 0x01, 0x09, 0x04, 0x01, 0x04, 0x02, 0xe0, 0x01, 0x01, 0x00, 0x07, 0x05, 0x83, 0x01,
            0x40, 0x00, 0x01, 0x07, 0x05, 0x03, 0x01, 0x40, 0x00, 0x01, 0x09, 0x04, 0x01, 0x05, 0x02, 0xe0,
            0x01, 0x01, 0x00, 0x07, 0x05, 0x83, 0x01, 0x40, 0x00, 0x01, 0x07, 0x05, 0x03, 0x01, 0x40, 0x00,
            0x01, 0x09, 0x04, 0x02, 0x00, 0x2 , 0xff, 0xff, 0xff, 0x00, 0x07, 0x05, 0x84, 0x02, 0x20, 0x00,
            0x01, 0x07, 0x05, 0x04, 0x02, 0x20, 0x00, 0x01, 0x09, 0x04, 0x03, 0x00, 0x00, 0xfe, 0x01, 0x01,
            0x00, 0x07, 0x21, 0x07, 0x88, 0x13, 0x40, 0x00
        ])
        XCTAssertEqual(data.count, 216)

        let region = PhysRegion(data: data)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        do {
            let configDescriptor = try USB.ConfigDescriptor(from: mmioRegion)
            XCTAssertEqual(configDescriptor.interfaces.count, 9)
            print(configDescriptor)
        } catch {
            XCTFail("error")
        }
    }

    func testConfigDescriptorForHub() throws {
        do {
            let config = USB.ConfigDescriptor(hubSpeed: .fullSpeed)
            let region = PhysRegion(count: 256)
            var mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
            XCTAssertEqual(config.write(into: &mmioRegion, maxLength: 256), config.wTotalLength)
            let config2 = try USB.ConfigDescriptor(from: mmioRegion)
            XCTAssertEqual(config, config2)

            // Short writes
            for maxLength in 2..<config.wTotalLength {
                XCTAssertEqual(config.write(into: &mmioRegion, maxLength: maxLength), maxLength)
            }
        }

        do {
            let config = USB.ConfigDescriptor(hubSpeed: .highSpeed)
            let region = PhysRegion(count: 256)
            var mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
            XCTAssertEqual(config.write(into: &mmioRegion, maxLength: 256), config.wTotalLength)
            let config2 = try USB.ConfigDescriptor(from: mmioRegion)
            XCTAssertEqual(config, config2)

            // Short writes
            for maxLength in 2..<config.wTotalLength {
                XCTAssertEqual(config.write(into: &mmioRegion, maxLength: maxLength), maxLength)
            }
        }

        do {
            let config = USB.ConfigDescriptor(hubSpeed: .superSpeed_gen1_x1)
            let region = PhysRegion(count: 256)
            var mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
            XCTAssertEqual(config.write(into: &mmioRegion, maxLength: 256), config.wTotalLength)
            let config2 = try USB.ConfigDescriptor(from: mmioRegion)
            XCTAssertEqual(config, config2)

            // Short writes
            for maxLength in 2..<config.wTotalLength {
                XCTAssertEqual(config.write(into: &mmioRegion, maxLength: maxLength), maxLength)
            }
        }
    }

    func testConfigDescriptorIntoShortBuffer() throws {
        let config = USB.ConfigDescriptor(hubSpeed: .fullSpeed)
        for maxLength: UInt16 in 2...10 {
            let region = PhysRegion(count: Int(maxLength))
            var mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
            XCTAssertEqual(config.write(into: &mmioRegion, maxLength: maxLength), maxLength)
            do {
                _ = try USB.ConfigDescriptor(from: mmioRegion)
        //        XCTFail("Decoding should have thrown a USB.ParsingError.packetTooShort")
            } catch {
                XCTAssertEqual(error.description, "PacketTooShort")
            }
        }
    }

    // MARK: - Device Descriptor Tests

    func testDeviceDescriptorDecoding() throws {
        // USB 2.0 HID keyboard: VID=046D, PID=C31C
        let bytes = Data([
            0x12, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x40,
            0x6D, 0x04, 0x1C, 0xC3, 0x00, 0x01, 0x01, 0x02,
            0x03, 0x01,
        ])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let dd = USB.DeviceDescriptor(from: mmioRegion)

        XCTAssertEqual(dd.bLength, 18)
        XCTAssertEqual(dd.bDescriptorType, USB.DescriptorType.DEVICE)
        XCTAssertEqual(dd.bcdUSB, 0x0200)
        XCTAssertEqual(dd.usbMajor, 2)
        XCTAssertEqual(dd.usbMinor, 0)
        XCTAssertEqual(dd.bDeviceClass, 0x00)
        XCTAssertEqual(dd.deviceClass, .interfaceSpecific)
        XCTAssertEqual(dd.bDeviceSubClass, 0x00)
        XCTAssertEqual(dd.bDeviceProtocol, 0x00)
        XCTAssertEqual(dd.bMaxPacketSize0, 64)
        XCTAssertEqual(dd.idVendor, 0x046D)
        XCTAssertEqual(dd.idProduct, 0xC31C)
        XCTAssertEqual(dd.bcdDevice, 0x0100)
        XCTAssertEqual(dd.iManufacturer, 1)
        XCTAssertEqual(dd.iProduct, 2)
        XCTAssertEqual(dd.iSerialNumber, 3)
        XCTAssertEqual(dd.bNumConfigurations, 1)
    }

    func testDeviceDescriptorShortRead() throws {
        // Only 8 bytes, minimum allowed
        let bytes = Data([0x12, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x40])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let dd = USB.DeviceDescriptor(from: mmioRegion)

        XCTAssertEqual(dd.bLength, 18)
        XCTAssertEqual(dd.bcdUSB, 0x0200)
        XCTAssertEqual(dd.bMaxPacketSize0, 64)
        // Fields beyond the 8 bytes read as zero
        XCTAssertEqual(dd.idVendor, 0)
        XCTAssertEqual(dd.idProduct, 0)
    }

    func testDeviceDescriptorHubInit() {
        let dd = USB.DeviceDescriptor(usbMajorHub: 2)
        XCTAssertEqual(dd.bLength, 18)
        XCTAssertEqual(dd.bcdUSB, 0x0200)
        XCTAssertEqual(dd.deviceClass, .hub)
        XCTAssertEqual(dd.bDeviceProtocol, 0)
        XCTAssertEqual(dd.bMaxPacketSize0, 64)
        XCTAssertEqual(dd.idVendor, 0x1d6b)
        XCTAssertEqual(dd.idProduct, 2)
        XCTAssertEqual(dd.bNumConfigurations, 1)

        let dd3 = USB.DeviceDescriptor(usbMajorHub: 3)
        XCTAssertEqual(dd3.bcdUSB, 0x0300)
        XCTAssertEqual(dd3.bDeviceProtocol, 3)
        XCTAssertEqual(dd3.bMaxPacketSize0, 9)
    }

    func testDeviceDescriptorRoundTrip() throws {
        let original = USB.DeviceDescriptor(usbMajorHub: 2)
        let region = PhysRegion(count: 32)
        var writeRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: 32)
        let bytesWritten = original.write(into: &writeRegion, maxLength: 32)
        XCTAssertEqual(Int(bytesWritten), 18)

        let readRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(bytesWritten))
        let decoded = USB.DeviceDescriptor(from: readRegion)

        XCTAssertEqual(decoded.bLength, original.bLength)
        XCTAssertEqual(decoded.bDescriptorType, original.bDescriptorType)
        XCTAssertEqual(decoded.bcdUSB, original.bcdUSB)
        XCTAssertEqual(decoded.bDeviceClass, original.bDeviceClass)
        XCTAssertEqual(decoded.bDeviceSubClass, original.bDeviceSubClass)
        XCTAssertEqual(decoded.bDeviceProtocol, original.bDeviceProtocol)
        XCTAssertEqual(decoded.bMaxPacketSize0, original.bMaxPacketSize0)
        XCTAssertEqual(decoded.idVendor, original.idVendor)
        XCTAssertEqual(decoded.idProduct, original.idProduct)
        XCTAssertEqual(decoded.bcdDevice, original.bcdDevice)
        XCTAssertEqual(decoded.iManufacturer, original.iManufacturer)
        XCTAssertEqual(decoded.iProduct, original.iProduct)
        XCTAssertEqual(decoded.iSerialNumber, original.iSerialNumber)
        XCTAssertEqual(decoded.bNumConfigurations, original.bNumConfigurations)
    }

    func testDeviceDescriptorWriteClipsToMaxLength() {
        let dd = USB.DeviceDescriptor(usbMajorHub: 2)
        let region = PhysRegion(count: 8)
        var writeRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: 8)
        let bytesWritten = dd.write(into: &writeRegion, maxLength: 8)
        XCTAssertEqual(Int(bytesWritten), 8)
    }

    // MARK: - Endpoint Descriptor Tests

    func testEndpointDescriptorInterruptIn() throws {
        // EP1 IN, interrupt, 8-byte packets, 10ms interval
        let bytes = Data([0x07, 0x05, 0x81, 0x03, 0x08, 0x00, 0x0A])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        let ep = try USB.EndpointDescriptor(from: &iterator)

        XCTAssertEqual(ep.bLength, 7)
        XCTAssertEqual(ep.bEndpointAddress, 0x81)
        XCTAssertEqual(ep.bmAttributes, 0x03)
        XCTAssertEqual(ep.wMaxPacketSize, 8)
        XCTAssertEqual(ep.bInterval, 10)
        XCTAssertEqual(ep.endpoint, 1)
        XCTAssertEqual(ep.direction, .deviceToHost)
        XCTAssertEqual(ep.transferType, .interrupt)
        XCTAssertEqual(ep.synchronization, .none)
        XCTAssertEqual(ep.usage, .data)
        XCTAssertEqual(ep.maxPacketSize, 8)
        XCTAssertNil(ep.companion)
    }

    func testEndpointDescriptorBulkOut() throws {
        // EP2 OUT, bulk, 512-byte packets
        let bytes = Data([0x07, 0x05, 0x02, 0x02, 0x00, 0x02, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        let ep = try USB.EndpointDescriptor(from: &iterator)

        XCTAssertEqual(ep.endpoint, 2)
        XCTAssertEqual(ep.direction, .hostToDevice)
        XCTAssertEqual(ep.transferType, .bulk)
        XCTAssertEqual(ep.maxPacketSize, 512)
        XCTAssertEqual(ep.bInterval, 0)
    }

    func testEndpointDescriptorIsochIn() throws {
        // EP3 IN, isochronous synchronous, 1023-byte packets, 1ms interval
        // bmAttributes: bits[1:0]=01(isoch), bits[3:2]=11(synchronous), bits[5:4]=00(data)
        let bytes = Data([0x07, 0x05, 0x83, 0x0D, 0xFF, 0x03, 0x01])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        let ep = try USB.EndpointDescriptor(from: &iterator)

        XCTAssertEqual(ep.endpoint, 3)
        XCTAssertEqual(ep.direction, .deviceToHost)
        XCTAssertEqual(ep.transferType, .isochronous)
        XCTAssertEqual(ep.synchronization, .synchronous)
        XCTAssertEqual(ep.maxPacketSize, 0x3FF)
    }

    func testEndpointDescriptorRoundTrip() throws {
        let original = USB.EndpointDescriptor(endPoint: 3, direction: .deviceToHost,
                                              maxPacketSize: 64, interval: 1)
        let region = PhysRegion(count: 16)
        var writeRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: 16)
        let bytesWritten = original.write(into: &writeRegion, maxLength: 16)
        XCTAssertEqual(Int(bytesWritten), 7)

        let readRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(bytesWritten))
        var iterator = readRegion.makeIterator()
        let decoded = try USB.EndpointDescriptor(from: &iterator)
        XCTAssertEqual(original, decoded)
    }

    func testEndpointDescriptorControlRoundTrip() throws {
        let original = USB.EndpointDescriptor(endPoint: 0, direction: .hostToDevice,
                                              maxPacketSize: 64, interval: 0)
        let region = PhysRegion(count: 16)
        var writeRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: 16)
        let bytesWritten = original.write(into: &writeRegion, maxLength: 16)
        XCTAssertEqual(Int(bytesWritten), 7)

        let readRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(bytesWritten))
        var iterator = readRegion.makeIterator()
        let decoded = try USB.EndpointDescriptor(from: &iterator)
        XCTAssertEqual(original, decoded)
    }

    func testEndpointDescriptorEndpointType() throws {
        func makeEP(transferType: UInt8, direction: USB.TransferDirection) throws -> UInt32 {
            // Manually construct bmAttributes for isochronous/bulk/interrupt
            let bytes = Data([0x07, 0x05,
                               UInt8(direction.rawValue << 7) | 1,
                               transferType, 0x40, 0x00, 0x00])
            let region = PhysRegion(data: bytes)
            let mmio = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
            var iter = mmio.makeIterator()
            return try USB.EndpointDescriptor(from: &iter).endpointType
        }

        XCTAssertEqual(try makeEP(transferType: 0x01, direction: .hostToDevice), 1) // isoch out
        XCTAssertEqual(try makeEP(transferType: 0x02, direction: .hostToDevice), 2) // bulk out
        XCTAssertEqual(try makeEP(transferType: 0x03, direction: .hostToDevice), 3) // interrupt out
        XCTAssertEqual(try makeEP(transferType: 0x01, direction: .deviceToHost), 5) // isoch in
        XCTAssertEqual(try makeEP(transferType: 0x02, direction: .deviceToHost), 6) // bulk in
        XCTAssertEqual(try makeEP(transferType: 0x03, direction: .deviceToHost), 7) // interrupt in
    }

    func testEndpointDescriptorErrorPacketTooShort() {
        let bytes = Data([0x07, 0x05, 0x81]) // Only 3 bytes, need 7
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        do {
            _ = try USB.EndpointDescriptor(from: &iterator)
            XCTFail("Expected packetTooShort error")
        } catch USB.ParsingError.packetTooShort {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testEndpointDescriptorErrorWrongDescriptorType() {
        // bDescriptorType = 0x04 (INTERFACE) instead of 0x05 (ENDPOINT)
        let bytes = Data([0x07, 0x04, 0x81, 0x03, 0x08, 0x00, 0x0A])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        do {
            _ = try USB.EndpointDescriptor(from: &iterator)
            XCTFail("Expected invalidDescriptor error")
        } catch USB.ParsingError.invalidDescriptor(0x04) {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testEndpointDescriptorErrorInvalidLength() {
        // bLength = 8 (wrong for endpoint descriptor; should be 7)
        let bytes = Data([0x08, 0x05, 0x81, 0x03, 0x08, 0x00, 0x0A, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        do {
            _ = try USB.EndpointDescriptor(from: &iterator)
            XCTFail("Expected invalidLengthByte error")
        } catch USB.ParsingError.invalidLengthByte {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - EndpointCompanionDescriptor Tests

    func testEndpointCompanionDescriptorDecoding() throws {
        // SS endpoint companion: maxBurst=2, no stream, 32 bytes per interval
        let bytes = Data([0x06, 0x30, 0x02, 0x00, 0x20, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        let companion = try USB.EndpointCompanionDescriptor(from: &iterator)

        XCTAssertEqual(companion.bLength, 6)
        XCTAssertEqual(companion.bDescriptorType, USB.DescriptorType.ENDPOINT_COMPANION.rawValue)
        XCTAssertEqual(companion.bMaxBurst, 2)
        XCTAssertEqual(companion.bmAttributes, 0)
        XCTAssertEqual(companion.wBytesPerInterval, 0x0020)
    }

    func testEndpointCompanionDescriptorRoundTrip() throws {
        // Parse the companion, write it, parse again, compare
        let bytes = Data([0x06, 0x30, 0x04, 0x05, 0x00, 0x04])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        let companion = try USB.EndpointCompanionDescriptor(from: &iterator)

        // Embed it in an endpoint and round-trip through the config descriptor
        // bytes[2..5] are read, verify field values match result from re-encoding
        XCTAssertEqual(companion.bMaxBurst, 4)
        XCTAssertEqual(companion.bmAttributes, 5)
        XCTAssertEqual(companion.wBytesPerInterval, 0x0400)
    }

    func testEndpointCompanionDescriptorErrorWrongType() {
        // bDescriptorType = 0x05 (ENDPOINT) instead of 0x30 (ENDPOINT_COMPANION)
        let bytes = Data([0x06, 0x05, 0x02, 0x00, 0x20, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        do {
            _ = try USB.EndpointCompanionDescriptor(from: &iterator)
            XCTFail("Expected invalidDescriptor error")
        } catch USB.ParsingError.invalidDescriptor(0x05) {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testEndpointCompanionDescriptorErrorInvalidLength() {
        // bLength = 7 (wrong; should be 6)
        let bytes = Data([0x07, 0x30, 0x02, 0x00, 0x20, 0x00, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        do {
            _ = try USB.EndpointCompanionDescriptor(from: &iterator)
            XCTFail("Expected invalidLengthByte error")
        } catch USB.ParsingError.invalidLengthByte {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - HID Descriptor Tests

    func testHIDDescriptorDecoding() throws {
        // HID 1.10, no country, 1 report descriptor, 66 bytes
        let bytes = Data([0x09, 0x21, 0x10, 0x01, 0x00, 0x01, 0x22, 0x42, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        let hid = try USB.HIDDescriptor(from: &iterator)

        XCTAssertEqual(hid.bLength, 9)
        XCTAssertEqual(hid.bDescriptorType, USB.DescriptorType.HID.rawValue)
        XCTAssertEqual(hid.bcdHID, 0x0110)
        XCTAssertEqual(hid.bCountryCode, 0)
        XCTAssertEqual(hid.bNumDescriptors, 1)
        XCTAssertEqual(hid.bReportDescriptorType, 0x22)
        XCTAssertEqual(hid.wDescriptorLength, 66)
    }

    func testHIDDescriptorRoundTrip() throws {
        let bytes = Data([0x09, 0x21, 0x10, 0x01, 0x21, 0x01, 0x22, 0x41, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        let original = try USB.HIDDescriptor(from: &iterator)

        let writeRegion = PhysRegion(count: 16)
        var writeMMIO = MMIOSubRegion(baseAddress: writeRegion.baseAddress, count: 16)
        let bytesWritten = original.write(into: &writeMMIO, maxLength: 16)
        XCTAssertEqual(Int(bytesWritten), 9)

        let readMMIO = MMIOSubRegion(baseAddress: writeRegion.baseAddress, count: Int(bytesWritten))
        var readIterator = readMMIO.makeIterator()
        let decoded = try USB.HIDDescriptor(from: &readIterator)
        XCTAssertEqual(original, decoded)
    }

    func testHIDDescriptorErrorWrongType() {
        // bDescriptorType = 0x04 (INTERFACE) instead of 0x21 (HID)
        let bytes = Data([0x09, 0x04, 0x10, 0x01, 0x00, 0x01, 0x22, 0x42, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        do {
            _ = try USB.HIDDescriptor(from: &iterator)
            XCTFail("Expected invalidDescriptor error")
        } catch USB.ParsingError.invalidDescriptor(0x04) {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testHIDDescriptorErrorInvalidLength() {
        // bLength = 8 (wrong; sizeof(usb_hid_descriptor) = 9)
        let bytes = Data([0x08, 0x21, 0x10, 0x01, 0x00, 0x01, 0x22, 0x42])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        var iterator = mmioRegion.makeIterator()
        do {
            _ = try USB.HIDDescriptor(from: &iterator)
            XCTFail("Expected invalidLengthByte error")
        } catch USB.ParsingError.invalidLengthByte {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - Interface Descriptor Tests

    func testInterfaceDescriptorDecoding() throws {
        // HID keyboard interface: class=HID(3), subClass=Boot(1), protocol=Keyboard(1)
        let bytes: [UInt8] = [0x09, 0x04, 0x00, 0x00, 0x01, 0x03, 0x01, 0x01, 0x00]
        var interfaceDescriptor = usb_standard_interface_descriptor()
        withUnsafeMutableBytes(of: &interfaceDescriptor) { buffer in
            for idx in 0..<min(bytes.count, buffer.count) {
                buffer[idx] = bytes[idx]
            }
        }

        let iface = try USB.InterfaceDescriptor(descriptor: interfaceDescriptor,
                                                endpoints: [], functionDescriptors: [])

        XCTAssertEqual(iface.bLength, 9)
        XCTAssertEqual(iface.bDescriptorType, USB.DescriptorType.INTERFACE.rawValue)
        XCTAssertEqual(iface.bInterfaceNumber, 0)
        XCTAssertEqual(iface.bAlternateSetting, 0)
        XCTAssertEqual(iface.bNumEndpoints, 1)
        XCTAssertEqual(iface.bInterfaceClass, 0x03)
        XCTAssertEqual(iface.interfaceClass, .hid)
        XCTAssertEqual(iface.bInterfaceSubClass, 0x01)
        XCTAssertEqual(iface.bInterfaceProtocol, 0x01)
        XCTAssertEqual(iface.iInterface, 0)
    }

    func testInterfaceDescriptorMassStorage() throws {
        // Mass storage interface: class=8, subClass=6(SCSI), protocol=0x50(BOT)
        let bytes: [UInt8] = [0x09, 0x04, 0x00, 0x00, 0x02, 0x08, 0x06, 0x50, 0x00]
        var interfaceDescriptor = usb_standard_interface_descriptor()
        withUnsafeMutableBytes(of: &interfaceDescriptor) { buffer in
            for idx in 0..<min(bytes.count, buffer.count) {
                buffer[idx] = bytes[idx]
            }
        }

        let iface = try USB.InterfaceDescriptor(descriptor: interfaceDescriptor,
                                                endpoints: [], functionDescriptors: [])

        XCTAssertEqual(iface.bNumEndpoints, 2)
        XCTAssertEqual(iface.interfaceClass, .massStorage)
        XCTAssertEqual(iface.bInterfaceSubClass, 0x06)
        XCTAssertEqual(iface.bInterfaceProtocol, 0x50)
    }

    func testInterfaceDescriptorErrorWrongType() {
        // bDescriptorType = 0x05 (ENDPOINT) instead of 0x04 (INTERFACE)
        let bytes: [UInt8] = [0x09, 0x05, 0x00, 0x00, 0x01, 0x03, 0x01, 0x01, 0x00]
        var interfaceDescriptor = usb_standard_interface_descriptor()
        withUnsafeMutableBytes(of: &interfaceDescriptor) { buffer in
            for idx in 0..<min(bytes.count, buffer.count) {
                buffer[idx] = bytes[idx]
            }
        }
        do {
            _ = try USB.InterfaceDescriptor(descriptor: interfaceDescriptor,
                                            endpoints: [], functionDescriptors: [])
            XCTFail("Expected invalidDescriptor error")
        } catch USB.ParsingError.invalidDescriptor(0x05) {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testInterfaceDescriptorErrorInvalidLength() {
        // bLength = 8 (wrong; sizeof(usb_standard_interface_descriptor) = 9)
        let bytes: [UInt8] = [0x08, 0x04, 0x00, 0x00, 0x01, 0x03, 0x01, 0x01]
        var interfaceDescriptor = usb_standard_interface_descriptor()
        withUnsafeMutableBytes(of: &interfaceDescriptor) { buffer in
            for idx in 0..<min(bytes.count, buffer.count) {
                buffer[idx] = bytes[idx]
            }
        }
        do {
            _ = try USB.InterfaceDescriptor(descriptor: interfaceDescriptor,
                                            endpoints: [], functionDescriptors: [])
            XCTFail("Expected invalidLengthByte error")
        } catch USB.ParsingError.invalidLengthByte {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - Hub Descriptor Tests

    func testHubDescriptorUSB2Decoding() throws {
        // 4-port USB2 hub: individual power switching, individual OC protection
        let bytes = Data([0x09, 0x29, 0x04, 0x09, 0x00, 0x0A, 0x00, 0x00, 0xFF])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let hub = try USB.HUBDescriptor(hubFrom: mmioRegion)

        XCTAssertEqual(hub.bDescLength, 9)
        XCTAssertEqual(hub.bDescriptorType, USB.DescriptorType.HUB.rawValue)
        XCTAssertEqual(hub.bNbrPorts, 4)
        XCTAssertEqual(hub.wHubCharacteristics, 0x0009)
        XCTAssertEqual(hub.bPwrOn2PwrGood, 10)
        XCTAssertEqual(hub.bHubContrCurrent, 0)
        XCTAssertFalse(hub.isSuperSpeed)
        XCTAssertEqual(hub.deviceRemovable.count, 4)
        XCTAssertTrue(hub.deviceRemovable.allSatisfy { !$0 })
    }

    func testHubDescriptorUSB2DeviceRemovable() throws {
        // 4-port hub: ports 1 and 3 are removable
        // deviceRemoveable byte: bit0 reserved, bit1=port1, bit2=port2, bit3=port3, bit4=port4
        // ports 1 and 3 removable == bits 1 and 3 set == 0b00001010 = 0x0A
        let bytes = Data([0x09, 0x29, 0x04, 0x09, 0x00, 0x0A, 0x00, 0x0A, 0xFF])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let hub = try USB.HUBDescriptor(hubFrom: mmioRegion)

        XCTAssertEqual(hub.deviceRemovable.count, 4)
        XCTAssertTrue(hub.deviceRemovable[0])   // port 1 removable
        XCTAssertFalse(hub.deviceRemovable[1])  // port 2 not removable
        XCTAssertTrue(hub.deviceRemovable[2])   // port 3 removable
        XCTAssertFalse(hub.deviceRemovable[3])  // port 4 not removable
    }

    func testHubDescriptorUSB2ErrorWrongType() {
        // bDescriptorType = 0x2A (SUPER_SPEED_HUB) instead of 0x29 (HUB)
        let bytes = Data([0x09, 0x2A, 0x04, 0x09, 0x00, 0x0A, 0x00, 0x00, 0xFF])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        do {
            _ = try USB.HUBDescriptor(hubFrom: mmioRegion)
            XCTFail("Expected invalidDescriptor error")
        } catch USB.ParsingError.invalidDescriptor(0x2A) {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testHubDescriptorRootHubUSB2RoundTrip() throws {
        let original = USB.HUBDescriptor(isSuperSpeed: false, ports: 4)
        XCTAssertEqual(original.bDescLength, 9)
        XCTAssertFalse(original.isSuperSpeed)
        XCTAssertEqual(original.bNbrPorts, 4)

        let region = PhysRegion(count: 64)
        var writeRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: 64)
        let bytesWritten = original.write(into: &writeRegion, maxLength: 64)
        XCTAssertEqual(Int(bytesWritten), Int(original.bDescLength))

        let readRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(original.bDescLength))
        let decoded = try USB.HUBDescriptor(hubFrom: readRegion)

        XCTAssertEqual(decoded.bDescLength, original.bDescLength)
        XCTAssertEqual(decoded.bDescriptorType, original.bDescriptorType)
        XCTAssertEqual(decoded.bNbrPorts, original.bNbrPorts)
        XCTAssertEqual(decoded.wHubCharacteristics, original.wHubCharacteristics)
        XCTAssertEqual(decoded.bPwrOn2PwrGood, original.bPwrOn2PwrGood)
        XCTAssertEqual(decoded.bHubContrCurrent, original.bHubContrCurrent)
        XCTAssertFalse(decoded.isSuperSpeed)
    }

    func testHubDescriptorRootHubUSB3RoundTrip() throws {
        let original = USB.HUBDescriptor(isSuperSpeed: true, ports: 4)
        XCTAssertEqual(original.bDescLength, 12)
        XCTAssertTrue(original.isSuperSpeed)
        XCTAssertEqual(original.bNbrPorts, 4)

        let region = PhysRegion(count: 64)
        var writeRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: 64)
        let bytesWritten = original.write(into: &writeRegion, maxLength: 64)
        XCTAssertEqual(Int(bytesWritten), Int(original.bDescLength))

        let readRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(original.bDescLength))
        let decoded = try USB.HUBDescriptor(SSHubFrom: readRegion)

        XCTAssertEqual(decoded.bDescLength, original.bDescLength)
        XCTAssertEqual(decoded.bDescriptorType, original.bDescriptorType)
        XCTAssertEqual(decoded.bNbrPorts, original.bNbrPorts)
        XCTAssertEqual(decoded.wHubCharacteristics, original.wHubCharacteristics)
        XCTAssertEqual(decoded.bPwrOn2PwrGood, original.bPwrOn2PwrGood)
        XCTAssertEqual(decoded.bHubContrCurrent, original.bHubContrCurrent)
        XCTAssertTrue(decoded.isSuperSpeed)
    }

    func testHubDescriptorUSB3Decoding() throws {
        // USB3 SuperSpeed hub: 2 ports, 12 bytes
        // struct: bDescLength(1)+bDescriptorType(1)+bNbrPorts(1)+wHubChars(2)+bPwrOn2PwrGood(1)+
        //         bHubContrCurrent(1)+bHubHdrDecLat(1)+wHubDelay(2)+deviceRemoveable(2) = 12
        let bytes = Data([0x0C, 0x2A, 0x02, 0x09, 0x00, 0x32, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let hub = try USB.HUBDescriptor(SSHubFrom: mmioRegion)

        XCTAssertEqual(hub.bDescLength, 12)
        XCTAssertEqual(hub.bDescriptorType, USB.DescriptorType.SUPER_SPEED_HUB.rawValue)
        XCTAssertEqual(hub.bNbrPorts, 2)
        XCTAssertEqual(hub.wHubCharacteristics, 0x0009)
        XCTAssertEqual(hub.bPwrOn2PwrGood, 50)
        XCTAssertEqual(hub.bHubContrCurrent, 0)
        XCTAssertEqual(hub.packetHeaderDecodeLatency, 0)
        XCTAssertEqual(hub.hubDelay, 4)
        XCTAssertTrue(hub.isSuperSpeed)
    }

    func testHubDescriptorUSB3ErrorWrongType() {
        let bytes = Data([0x0C, 0x29, 0x02, 0x09, 0x00, 0x32, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        do {
            _ = try USB.HUBDescriptor(SSHubFrom: mmioRegion)
            XCTFail("Expected invalidDescriptor error")
        } catch USB.ParsingError.invalidDescriptor(0x29) {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - BOS Descriptor Tests

    func testBOSDescriptorDecodingHeaderOnly() throws {
        // BOS header only (no capabilities), wTotalLength=5
        let bytes = Data([0x05, 0x0F, 0x05, 0x00, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let bos = try USB.BOSDescriptor(from: mmioRegion)

        XCTAssertEqual(bos.bLength, 5)
        XCTAssertEqual(bos.bDescriptorType, USB.DescriptorType.BINARY_OBJECT_STORE.rawValue)
        XCTAssertEqual(bos.capabilities.count, 0)
        XCTAssertEqual(bos.wTotalLength, 5)
        XCTAssertEqual(bos.bNumDeviceCaps, 0)
    }

    func testBOSDescriptorDecodingWithUSB2Extension() throws {
        // BOS with one USB2 Extension capability (bLength=7, type=0x02, 4 data bytes)
        let bytes = Data([
            0x05, 0x0F, 0x0C, 0x00, 0x01,       // BOS header: wTotalLength=12, 1 cap
            0x07, 0x10, 0x02, 0x00, 0x00, 0x40, 0x00, // USB2 Extension cap
        ])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let bos = try USB.BOSDescriptor(from: mmioRegion)

        XCTAssertEqual(bos.capabilities.count, 1)
        XCTAssertEqual(bos.capabilities[0].type, .USB2_0_Extension)
        XCTAssertEqual(bos.capabilities[0].bytes, [0x00, 0x00, 0x40, 0x00])
        XCTAssertEqual(bos.wTotalLength, 12)
        XCTAssertEqual(bos.bNumDeviceCaps, 1)
    }

    func testBOSDescriptorDecodingWithMultipleCapabilities() throws {
        // BOS with USB2 Extension + SuperSpeed USB capabilities
        let bytes = Data([
            0x05, 0x0F, 0x16, 0x00, 0x02,               // BOS header: wTotalLength=22, 2 caps
            0x07, 0x10, 0x02, 0x00, 0x00, 0x40, 0x00,   // USB2 Extension
            0x0A, 0x10, 0x03, 0x00, 0x0E, 0x00, 0x01, 0x0A, 0xFF, 0x07, // SuperSpeed USB
        ])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let bos = try USB.BOSDescriptor(from: mmioRegion)

        XCTAssertEqual(bos.capabilities.count, 2)
        XCTAssertEqual(bos.capabilities[0].type, .USB2_0_Extension)
        XCTAssertEqual(bos.capabilities[1].type, .SUPERSPEED_USB)
        XCTAssertEqual(bos.wTotalLength, 22)
    }

    func testBOSDescriptorRoundTrip() throws {
        let original = USB.BOSDescriptor(capabilities: [
            .init(type: .USB2_0_Extension, bytes: [0x00, 0x00, 0x40, 0x00]),
            .init(type: .SUPERSPEED_USB, bytes: [0x00, 0x0E, 0x00, 0x01, 0x0A, 0xFF, 0x07]),
        ])
        XCTAssertEqual(original.capabilities.count, 2)
        XCTAssertEqual(original.wTotalLength, 5 + 7 + 10)

        let region = PhysRegion(count: 64)
        var writeRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: 64)
        let bytesWritten = original.write(into: &writeRegion, maxLength: 64)
        XCTAssertEqual(Int(bytesWritten), Int(original.wTotalLength))

        let readRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(bytesWritten))
        let decoded = try USB.BOSDescriptor(from: readRegion)

        XCTAssertEqual(decoded.bLength, original.bLength)
        XCTAssertEqual(decoded.bDescriptorType, original.bDescriptorType)
        XCTAssertEqual(decoded.wTotalLength, original.wTotalLength)
        XCTAssertEqual(decoded.bNumDeviceCaps, original.bNumDeviceCaps)
        XCTAssertEqual(decoded.capabilities.count, original.capabilities.count)
        XCTAssertEqual(decoded.capabilities[0].type, original.capabilities[0].type)
        XCTAssertEqual(decoded.capabilities[0].bytes, original.capabilities[0].bytes)
        XCTAssertEqual(decoded.capabilities[1].type, original.capabilities[1].type)
        XCTAssertEqual(decoded.capabilities[1].bytes, original.capabilities[1].bytes)
    }

    func testBOSDescriptorRoundTripHeaderOnly() throws {
        let original = USB.BOSDescriptor(capabilities: [])
        XCTAssertEqual(original.wTotalLength, 5)
        XCTAssertEqual(original.bNumDeviceCaps, 0)

        let region = PhysRegion(count: 16)
        var writeRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: 16)
        let bytesWritten = original.write(into: &writeRegion, maxLength: 16)
        XCTAssertEqual(Int(bytesWritten), 5)

        let readRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(bytesWritten))
        let decoded = try USB.BOSDescriptor(from: readRegion)
        XCTAssertEqual(decoded.capabilities.count, 0)
        XCTAssertEqual(decoded.wTotalLength, 5)
    }

    func testBOSDescriptorErrorWrongType() {
        // bDescriptorType = 0x01 (DEVICE) instead of 0x0F (BOS)
        let bytes = Data([0x05, 0x01, 0x05, 0x00, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        do {
            _ = try USB.BOSDescriptor(from: mmioRegion)
            XCTFail("Expected invalidDescriptor error")
        } catch USB.ParsingError.invalidDescriptor(0x01) {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    func testBOSDescriptorErrorInvalidLength() {
        // bLength = 4 (wrong; BOS header is always 5 bytes)
        let bytes = Data([0x04, 0x0F, 0x05, 0x00, 0x00])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        do {
            _ = try USB.BOSDescriptor(from: mmioRegion)
            XCTFail("Expected invalidLengthByte error")
        } catch USB.ParsingError.invalidLengthByte {
            // expected
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - Config Descriptor Field Assertion Tests

    func testConfigDescriptor1Fields() throws {
        // Two-interface HID keyboard/mouse config
        let bytes = Data([
            0x09, 0x02, 0x3b, 0x00, 0x02, 0x01, 0x01, 0xc0, 0x00,
            0x09, 0x04, 0x00, 0x00, 0x01, 0x03, 0x00, 0x00, 0x01,
            0x09, 0x21, 0x10, 0x01, 0x00, 0x01, 0x22, 0x42, 0x00,
            0x07, 0x05, 0x81, 0x03, 0x08, 0x00, 0x01,
            0x09, 0x04, 0x01, 0x00, 0x01, 0x03, 0x00, 0x00, 0x01,
            0x09, 0x21, 0x10, 0x01, 0x00, 0x01, 0x22, 0x41, 0x00,
            0x07, 0x05, 0x82, 0x03, 0x08, 0x00, 0x01,
        ])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let config = try USB.ConfigDescriptor(from: mmioRegion)

        XCTAssertEqual(config.bLength, 9)
        XCTAssertEqual(config.bDescriptorType, USB.DescriptorType.CONFIGURATION.rawValue)
        XCTAssertEqual(config.wTotalLength, 0x003B)
        XCTAssertEqual(config.bNumInterfaces, 2)
        XCTAssertEqual(config.bConfigurationValue, 1)
        XCTAssertEqual(config.iConfiguration, 1)
        XCTAssertEqual(config.bmAttributes, 0xC0)
        XCTAssertEqual(config.bMaxPower, 0)
        XCTAssertEqual(config.interfaces.count, 2)

        let iface0 = config.interfaces[0]
        XCTAssertEqual(iface0.bInterfaceNumber, 0)
        XCTAssertEqual(iface0.interfaceClass, .hid)
        XCTAssertEqual(iface0.functionDescriptors.count, 1)
        XCTAssertEqual(iface0.endpoints[0].endpoint, 1)
        XCTAssertEqual(iface0.endpoints[0].direction, .deviceToHost)
        XCTAssertEqual(iface0.endpoints[0].transferType, .interrupt)
        XCTAssertEqual(iface0.endpoints[0].maxPacketSize, 8)
        XCTAssertEqual(iface0.endpoints[0].bInterval, 1)

        let iface1 = config.interfaces[1]
        XCTAssertEqual(iface1.bInterfaceNumber, 1)
        XCTAssertEqual(iface1.interfaceClass, .hid)
        XCTAssertEqual(iface0.functionDescriptors.count, 1)   // same bug
        XCTAssertEqual(iface1.endpoints[0].endpoint, 2)
    }

    func testConfigDescriptorWithEndpointCompanionFields() throws {
        // Mass storage with SuperSpeed endpoint companions
        let bytes = Data([
            0x09, 0x02, 0x2c, 0x00, 0x01, 0x01, 0x00, 0xa0,
            0x70, 0x09, 0x04, 0x00, 0x00, 0x02, 0x08, 0x06,
            0x50, 0x00, 0x07, 0x05, 0x81, 0x02, 0x00, 0x04,
            0x00, 0x06, 0x30, 0x04, 0x00, 0x00, 0x00, 0x07,
            0x05, 0x02, 0x02, 0x00, 0x04, 0x00, 0x06, 0x30,
            0x04, 0x00, 0x00, 0x00
        ])
        let region = PhysRegion(data: bytes)
        let mmioRegion = MMIOSubRegion(baseAddress: region.baseAddress, count: Int(region.size))
        let config = try USB.ConfigDescriptor(from: mmioRegion)

        XCTAssertEqual(config.bNumInterfaces, 1)
        XCTAssertEqual(config.interfaces.count, 1)

        let iface = config.interfaces[0]
        XCTAssertEqual(iface.endpoints.count, 2)
        XCTAssertEqual(iface.interfaceClass, .massStorage)
        XCTAssertEqual(iface.bInterfaceSubClass, 0x06)
        XCTAssertEqual(iface.bInterfaceProtocol, 0x50)

        // EP1 IN bulk with companion
        let ep0 = iface.endpoints[0]
        XCTAssertEqual(ep0.endpoint, 1)
        XCTAssertEqual(ep0.direction, .deviceToHost)
        XCTAssertEqual(ep0.transferType, .bulk)
        XCTAssertNotNil(ep0.companion)
        XCTAssertEqual(ep0.companion?.bMaxBurst, 4)

        // EP2 OUT bulk with companion
        let ep1 = iface.endpoints[1]
        XCTAssertEqual(ep1.endpoint, 2)
        XCTAssertEqual(ep1.direction, .hostToDevice)
        XCTAssertEqual(ep1.transferType, .bulk)
        XCTAssertNotNil(ep1.companion)
        XCTAssertEqual(ep1.companion?.bMaxBurst, 4)
    }

}



