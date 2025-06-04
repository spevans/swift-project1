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
    private(set) var address: UInt8 = 0 // Default Start Address when not assigned
    let bus: USBBus
    let speed: USB.Speed
//    let deviceDescriptor: USB.DeviceDescriptor
    private var _controlPipe: USBPipe?
    override var description: String {
        #sprintf("Device %d.%u", bus.busId, address)
    }


    init(device: Device, bus: USBBus, speed: USB.Speed) {
        self.bus = bus
        self.speed = speed
        device.deviceName = "usbdev"
        super.init(device: device)
        device.setBusDevice(self)
    }

    private func controlPipe() -> USBPipe {
        if let pipe = _controlPipe {
            return pipe
        }
        guard let pipe = bus.allocatePipe(self, USB.EndpointDescriptor(controlEndPoint: 0, maxPacketSize: 8, bInterval: 0)) else {
            fatalError("UHCI: Cant allocate pipe")
        }
        _controlPipe = pipe
        return pipe
    }

    func sendControlRequest(request: USB.ControlRequest) -> Bool {
        let pipe = controlPipe()

        return pipe.send(request: request, withBuffer: nil)
    }


    func sendControlRequestReadData(request: USB.ControlRequest) -> [UInt8]? {
        let pipe = controlPipe()

        guard request.wLength > 0 else {
            fatalError("USBDEV: sendControlRequestReadData wLenggth is 0!")
        }

        let infoBuffer = pipe.allocateBuffer(length: Int(request.wLength))
        defer { pipe.freeBuffer(infoBuffer) }
        guard pipe.send(request: request, withBuffer: infoBuffer) else { return nil }
        var result: [UInt8] = []
        result.reserveCapacity(Int(request.wLength))
        for byte in infoBuffer {
            result.append(byte)
        }
        return result
    }


    func setAddress(_ newAddress: UInt8) -> Bool {
        #kprint("USBDEV: Setting address to:", newAddress)
        let request = USB.ControlRequest.setAddress(address: newAddress)
        if sendControlRequest(request: request) {
            address = newAddress
            sleep(milliseconds: 10) // Device may require some time before address takes effect
            return true
        }
        #kprint("USBDEV: Failed to setAddress(\(newAddress))")
        return false
    }


    func getDeviceConfig(length: UInt16) -> USB.DeviceDescriptor? {
        let pipe = controlPipe()

        let descriptorRequest = USB.ControlRequest.getDescriptor(descriptorType: .DEVICE, descriptorIndex: 0, length: length)
        var infoBuffer = pipe.allocateBuffer(length: Int(length))
        infoBuffer.clearBuffer()
        defer { pipe.freeBuffer(infoBuffer) }

        guard pipe.send(request: descriptorRequest, withBuffer: infoBuffer) else {
            #kprint("USBDEV: getDeviceConfig: Cant get descriptor length:", length)
            return nil
        }

        return USB.DeviceDescriptor(from: infoBuffer)
    }


    func getConfigurationDescriptor() -> USB.ConfigDescriptor? {
        let pipe = controlPipe()

        let length = MemoryLayout<usb_standard_config_descriptor>.size
        let descriptorBuffer = pipe.allocateBuffer(length: length)
        defer { pipe.freeBuffer(descriptorBuffer) }

        let deviceConfigRequest1 = USB.ControlRequest.getDescriptor(descriptorType: .CONFIGURATION, descriptorIndex: 0, length: UInt16(length))
        guard pipe.send(request: deviceConfigRequest1, withBuffer: descriptorBuffer) else {
            return nil
        }

        guard let configDescriptor1 = try? USB.ConfigDescriptor(from: descriptorBuffer) else {
            #kprint("USBDEV: Cant decode CONFIGURATION descriptor packet")
                return nil
        }
        #kprint("USBDEV:", configDescriptor1)
        let infoBuffer = pipe.allocateBuffer(length: Int(configDescriptor1.wTotalLength))
        defer { pipe.freeBuffer(infoBuffer) }


        let deviceConfigRequest2 = USB.ControlRequest.getDescriptor(descriptorType: .CONFIGURATION, descriptorIndex: 0, length: configDescriptor1.wTotalLength)
        guard pipe.send(request: deviceConfigRequest2, withBuffer: infoBuffer) else {
            return nil
        }

        do {
            let configDescriptor2 = try USB.ConfigDescriptor(from: infoBuffer)
            return configDescriptor2
        } catch {
            #kprint("USBDEV: Cant decode CONFIGURATION descriptor packet: ", error)
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
        let sendControlRequest:  (USB.ControlRequest) -> Bool
        let sendControlRequestReadData: (USB.ControlRequest) -> [UInt8]?
    }

    private let hcd: HCDDeviceFunctions

    init(device: Device, bus: USBBus, hcd: HCDDeviceFunctions) {
        self.hcd = hcd
        super.init(device: device, bus: bus, speed: .fullSpeed)
        device.deviceName = "root-hub"
    }

    override func sendControlRequest(request: USB.ControlRequest) -> Bool {
        return hcd.sendControlRequest(request)
    }

    override func sendControlRequestReadData(request: USB.ControlRequest) -> [UInt8]? {
        return hcd.sendControlRequestReadData(request)
    }
}
