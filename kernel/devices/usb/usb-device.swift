/*
 * kernel/devices/usb/usb-device.swift
 *
 * Created by Simon Evans on 22/10/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB Device.
 *
 */


class USBDevice: BusDevice {
    fileprivate(set) var address: UInt8 = 0 // Default Start Address when not assigned
    private(set) var maxPacketSize0: Int
    let bus: USBBus
    let speed: USB.Speed
    let controlPipe: USBPipe

    var isLowSpeedDevice: Bool { speed == .lowSpeed }

    override var description: String {
        #sprintf("Device %d.%u", bus.busId, address)
    }


    init?(device: Device, bus: USBBus, speed: USB.Speed) {
        self.bus = bus
        self.speed = speed

        // Contol Pipe
        switch speed {
            case .lowSpeed, .fullSpeed:
                self.maxPacketSize0 = 8

            case .highSpeed, .superSpeed:
                self.maxPacketSize0 = 64
        }

        guard let pipe = bus.allocatePipe(USB.EndpointDescriptor(controlEndPoint: 0, maxPacketSize: 8, bInterval: 0)) else {
            #kprint("usb-dev: Failed to allocate pipe")
            return nil
        }
        self.controlPipe = pipe
        device.deviceName = "usbdev \(bus.busId).\(address)"
        super.init(device: device)
    }


    // FIXME: Should these 2 functions return USB.Response?
    func sendControlRequest(request: USB.ControlRequest) -> Bool {
        return sendControlRequestReadData(request: request, into: nil)
    }


    func sendControlRequestReadData(request: USB.ControlRequest, into buffer: MMIOSubRegion? = nil) -> Bool {
        if buffer != nil, request.wLength == 0 {
            fatalError("USBDEV: sendControlRequestReadData wLength is 0!")
        }

        #kprint("USB-DEV: \(self.bus.busId)-\(self.address).0 Sending request:", request)

        let requestBuffer = controlPipe.allocateBuffer(length: MemoryLayout<USB.ControlRequest>.size)
        requestBuffer.storeBytes(of: request, as: USB.ControlRequest.self)
        defer { controlPipe.freeBuffer(requestBuffer) }

        var lastStatus: USBPipe.Status?
        let urb = USB.Request(
            usbDevice: self,
            transferType: .control,
            direction: request.direction,
            pipe: controlPipe,
            completionHandler: { (urb, response) in
                lastStatus = response.status
            },
            setupRequest: requestBuffer,
            buffer: buffer,
            bytesToTransfer: Int(request.wLength)
        )
        bus.submitURB(urb)

        while lastStatus == nil {
            sleep(milliseconds: 10)
        }
        return lastStatus == .finished
    }


    func setAddress(_ newAddress: UInt8) -> Bool {
        #kprintf("%s: Setting address to: %d\n", device.deviceName, newAddress)
        let request = USB.ControlRequest.setAddress(address: newAddress)
        if sendControlRequest(request: request) {
            address = newAddress
            device.deviceName = "usbdev \(bus.busId).\(address)"
            sleep(milliseconds: 10) // Device may require some time before address takes effect
            return true
        }
        #kprintf("%s: Failed to setAddress to %d\n", device.deviceName, newAddress)
        return false
    }


    func getDeviceDescriptor(length: UInt16) -> USB.DeviceDescriptor? {
        let request = USB.ControlRequest.getDescriptor(descriptorType: .DEVICE, descriptorIndex: 0, length: length)
        var infoBuffer = controlPipe.allocateBuffer(length: Int(length))
        infoBuffer.clearBuffer()
        defer { controlPipe.freeBuffer(infoBuffer) }

        guard sendControlRequestReadData(request: request, into: infoBuffer) else {
            #kprint("USBDEV: getDeviceDescriptor: Failed to get descriptor length:", length)
            return nil
        }

        let descriptor = USB.DeviceDescriptor(from: infoBuffer)
        if Int(descriptor.bMaxPacketSize0) > maxPacketSize0 {
            // For Control Pipes update the maxPacketSize0 if new data is available
            #kprintf("USB-DEV: Updating Control Pipe max Packet size from %d to %d\n", maxPacketSize0, descriptor.bMaxPacketSize0)

            // Validate the speeds
            switch (speed, descriptor.bMaxPacketSize0) {
                case (.lowSpeed, 8),
                    (.fullSpeed, 8), (.fullSpeed, 16), (.fullSpeed, 32), (.fullSpeed, 64),
                    (.highSpeed, 64), (.superSpeed, 64):
                    maxPacketSize0 = Int(descriptor.bMaxPacketSize0)
                default: #kprintf("Invalid bMaxPackageSize0 %d for speed %s\n", descriptor.bMaxPacketSize0, speed.description)
            }
        }
        return descriptor
    }


    func getConfigurationDescriptor() -> USB.ConfigDescriptor? {
        let length = MemoryLayout<usb_standard_config_descriptor>.size
        let descriptorBuffer = controlPipe.allocateBuffer(length: length)
        defer { controlPipe.freeBuffer(descriptorBuffer) }

        let deviceConfigRequest1 = USB.ControlRequest.getDescriptor(descriptorType: .CONFIGURATION, descriptorIndex: 0, length: UInt16(length))
        guard sendControlRequestReadData(request: deviceConfigRequest1, into: descriptorBuffer) else {
            #kprint("USB-DEV: getConfigurationDescriptor request1 failed")
            return nil
        }

        guard let configDescriptor1 = try? USB.ConfigDescriptor(from: descriptorBuffer) else {
            #kprint("USBDEV: Failed to decode CONFIGURATION descriptor packet")
                return nil
        }
        #kprint("USBDEV:", configDescriptor1)
        let infoBuffer = controlPipe.allocateBuffer(length: Int(configDescriptor1.wTotalLength))
        defer { controlPipe.freeBuffer(infoBuffer) }


        let deviceConfigRequest2 = USB.ControlRequest.getDescriptor(descriptorType: .CONFIGURATION, descriptorIndex: 0, length: configDescriptor1.wTotalLength)
        guard sendControlRequestReadData(request: deviceConfigRequest2, into: infoBuffer) else {
            #kprint("USB-DEV: getConfigurationDescriptor request2 failed")
            return nil
        }

        do {
            let configDescriptor2 = try USB.ConfigDescriptor(from: infoBuffer)
            return configDescriptor2
        } catch {
            #kprint("USBDEV: Failed to decode CONFIGURATION descriptor packet: ", error)
            return nil
        }
    }

    func setConfiguration(to configuration: UInt8) -> Bool {
        #kprint("USBDEV: Setting configuration to:", configuration)
        let request = USB.ControlRequest.setConfiguration(configuration: configuration)
        guard sendControlRequest(request: request) else {
            #kprint("USBDEV: Failed to set configuration")
            return false
        }
        return true
    }
}


// Host controllers also act as Root Hubs so need to act as a USB Device
// as well.
final class HCDRootHub: USBDevice {

    struct HCDDeviceFunctions {
        let processURB: (USB.Request) -> USB.Response
    }

    private let hcd: HCDDeviceFunctions

    init?(device: Device, bus: USBBus, hcd: HCDDeviceFunctions) {
        self.hcd = hcd
        super.init(device: device, bus: bus, speed: .fullSpeed)
        self.address = 1
        device.deviceName = "root-hub.\(bus.busId).\(address)"
    }


    override func sendControlRequestReadData(request: USB.ControlRequest, into buffer: MMIOSubRegion? = nil) -> Bool {
        let requestBuffer = controlPipe.allocateBuffer(length: MemoryLayout<USB.ControlRequest>.size)
        requestBuffer.storeBytes(of: request, as: USB.ControlRequest.self)
        defer { controlPipe.freeBuffer(requestBuffer) }

        let urb = USB.Request(
            usbDevice: self,
            transferType: .control,
            direction: request.direction,
            pipe: controlPipe,
            completionHandler: { (urb, response) in
                return // Root HUB URBs are processed synchronously
            },
            setupRequest: requestBuffer,
            buffer: buffer,
            bytesToTransfer: Int(request.wLength)
        )

        let response = hcd.processURB(urb)
        urb.completionHandler(urb, response)
        return true
    }
}
