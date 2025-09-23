/*
 * kernel/devices/usb/usb-device.swift
 *
 * Created by Simon Evans on 22/10/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB Device.
 *
 */

class HCDData {
    init() {}
}

class USBDevice: BusDevice {
    fileprivate(set) var address: UInt8 = 0 // Default Start Address when not assigned
    private(set) var maxPacketSize0: Int
    private(set) var hcdData: HCDData?   // FIXME, could be an enum but need to fix pointers in enum bug
    private var _controlPipe: USBPipe?
    private(set) var descriptor: USB.DeviceDescriptor?

    let bus: USBBus // FIXME, could this just be HCDRootHub?
    let port: UInt8
    let speed: USB.Speed

    override var className: String { "USBDevice" }
    var isLowSpeedDevice: Bool { speed == .lowSpeed }


    override var description: String {
        #sprintf("Device %d.%u isUSBDevice: %s isHCDRootHub: %s",
                 bus.busId, address, self.device.busDevice  is USBDevice, self is HCDRootHub)
    }


    init?(device: Device, bus: USBBus, port: UInt8, speed: USB.Speed,
          address: UInt8? = nil) {
        self.bus = bus
        self.port = port
        self.speed = speed
        self.hcdData = nil

        if let address {
            self.address = address
        }
        // Contol Pipe
        self.maxPacketSize0 = speed.controlSize
        super.init(device: device,
                   busDeviceName: #sprintf("usbdev-%d.%u", self.bus.busId, self.address))
        self.hcdData = bus.hcdData?(self)
        #kprintf("usb-device: port: %u rootPort: %u\n",
                 self.port, self.rootPort())
    }

    func setDescriptor(_ descriptor: USB.DeviceDescriptor) {
        self.descriptor = descriptor
    }

    override func info() -> String {
        var result = #sprintf("port: %u rootPort: %u speed: %s",
                 self.port, self.rootPort(), self.speed.description)
        if let descriptor = self.descriptor {
            result += "\n" + descriptor.description
        }
        return result
    }

    func allocatePipe(_ endpoint: USB.EndpointDescriptor) -> USBPipe? {
        return self.bus.allocatePipe(self, endpoint)
    }

    func getControlPipe() -> USBPipe? {
        if _controlPipe == nil {
            let endPoint = USB.EndpointDescriptor(
                controlEndPoint: 0,
                // FIXME, might be different for USB3
                maxPacketSize: 8,
                bInterval: 0
            )
            guard let pipe = self.bus.allocatePipe(self, endPoint) else {
                #kprint("usb-dev: Failed to allocate pipe")
                return nil
            }
            _controlPipe = pipe
        }
        return _controlPipe
    }

    // FIXME: Should these 2 functions return USB.Response?
    func sendControlRequest(request: USB.ControlRequest) -> Bool {
        return sendControlRequestReadData(request: request, into: nil)
    }


    func sendControlRequestReadData(request: USB.ControlRequest, into buffer: MMIOSubRegion? = nil) -> Bool {
        if buffer != nil, request.wLength == 0 {
            fatalError("USBDEV: sendControlRequestReadData wLength is 0!")
        }
        guard let controlPipe = getControlPipe() else { return false }

        #kprint("USB-DEV: \(self.bus.busId)-\(self.address).0 Sending request:", request)

        let requestBuffer = bus.allocateBuffer(length: MemoryLayout<USB.ControlRequest>.size)
        requestBuffer.storeBytes(of: request, as: USB.ControlRequest.self)
        defer { bus.freeBuffer(requestBuffer) }

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
        // FIXME: Could this submit directly on the pipe?
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
            self.updateAddress(newAddress)
            sleep(milliseconds: 10) // Device may require some time before address takes effect
            return true
        }
        #kprintf("%s: Failed to setAddress to %d\n", device.deviceName, newAddress)
        return false
    }

    func updateAddress(_ newAddress: UInt8) {
        self.address = newAddress
        self.busDeviceName = #sprintf("usbdev-%d.%u", self.bus.busId, self.address)
    }


    func getDeviceDescriptor(length: UInt16) -> USB.DeviceDescriptor? {
        let request = USB.ControlRequest.getDescriptor(descriptorType: .DEVICE, descriptorIndex: 0, length: length)
        var infoBuffer = bus.allocateBuffer(length: Int(length))
        infoBuffer.clearBuffer()
        defer { bus.freeBuffer(infoBuffer) }

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
                    (.highSpeed, 64),
                    (.superSpeed_gen1_x1, 64), (.superSpeed_gen1_x2, 64),
                    (.superSpeed_gen2_x1, 64), (.superSpeed_gen2_x2, 64):
                    maxPacketSize0 = Int(descriptor.bMaxPacketSize0)
                default: #kprintf("Invalid bMaxPackageSize0 %d for speed %s\n", descriptor.bMaxPacketSize0, speed.description)
            }
        }
        return descriptor
    }


    func getConfigurationDescriptor() -> USB.ConfigDescriptor? {
        let length = MemoryLayout<usb_standard_config_descriptor>.size
        let descriptorBuffer = bus.allocateBuffer(length: length)
        defer { bus.freeBuffer(descriptorBuffer) }

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
        let infoBuffer = bus.allocateBuffer(length: Int(configDescriptor1.wTotalLength))
        defer { bus.freeBuffer(infoBuffer) }


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

    // Walk up the chain of hubs to find the root hub port that
    // this device is plugged into. The may not be a hub between
    // it and the root
    func rootPort() -> UInt8 {
        var otherDevice: Device? = self.device
        repeat {
            if let parentDevice = otherDevice?.parent?.busDevice as? HCDRootHub {
                return parentDevice.port
            }
            otherDevice = otherDevice?.parent
        } while otherDevice?.busDevice is USBDevice
        fatalError("USBDEV: Failed to determine HCD for \(self.device.deviceName)")
        /*
        #kprintf("USBDEV: Failed to determine root HCD for: %s busDevice: %s parent Busdevice: %s\n",
                 self.device.deviceName, self.device.busDevice?.className() ?? "nil",
                 self.device.parent?.busDevice?.className() ?? "nil")
        return self.port
         */
    }
}


// Host controllers also act as Root Hubs so need to act as a USB Device
// as well.
final class HCDRootHub: USBDevice {

    override var className: String { "HCDRootHub" }

    struct HCDDeviceFunctions {
        let processURB: (USB.ControlRequest, MMIOSubRegion?) -> USB.Response
    }

    private let hcd: HCDDeviceFunctions

    init?(device: Device, bus: USBBus, hcd: HCDDeviceFunctions) {
        self.hcd = hcd
        super.init(device: device, bus: bus, port: 1,
                   speed: .fullSpeed, address: 1)
    }


    override func sendControlRequestReadData(
        request: USB.ControlRequest,
        into buffer: MMIOSubRegion? = nil) -> Bool
    {
        let response = self.hcd.processURB(request, buffer)
        return response.status == .finished
    }

    override func rootPort() -> UInt8 {
        #kprint("rootPort() for HCDRootHub")
        return 0
    }

}
