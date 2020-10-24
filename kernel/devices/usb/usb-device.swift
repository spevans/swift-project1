/*
 * kernel/devices/usb/usb-device.swift
 *
 * Created by Simon Evans on 22/10/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB Device.
 *
 */


extension USB {
    enum Speed {
        case lowSpeed
        case fullSpeed
        case highSpeed
        case superSpeed

        var controlSize: Int {
            switch self {
                case .lowSpeed, .fullSpeed: return 8
                case .highSpeed: return 64
                case .superSpeed: return 512
            }
        }
    }
}


final class USBDevice {
    private(set) var address: UInt8 = 0 // Default Start Address when not assigned
    let speed: USB.Speed
    let hub: USBHub
    let port: Int
    private var _controlPipe: USBPipe?


    init(hub: USBHub, port: Int, speed: USB.Speed) {
        self.hub = hub
        self.port = port
        self.speed = speed
    }

    private func controlPipe() -> USBPipe {
        if _controlPipe == nil {
            _controlPipe = hub.allocatePipe(device: self, endpointDescriptor: USB.EndpointDescriptor(controlEndPoint: 0, maxPacketSize: 8, bInterval: 0))
        }
        return _controlPipe!
    }

    func sendControlRequest(request: USB.ControlRequest) -> Bool {
        let requestStr = String(describing: request)
        print("USBDEV: sendControlRequest:", terminator: " ")
        print(requestStr)
        let pipe = controlPipe()

        return pipe.send(request: request, withBuffer: false)
    }


    func sendControlRequestReadData(request: USB.ControlRequest) -> [UInt8]? {
//        print("USBDEV: sendControlRequestReadData:", request, "reading \(request.wLength) bytes")
        let pipe = controlPipe()

        guard request.wLength > 0 else {
            fatalError("USBDEV: sendControlRequestReadData wLenggth is 0!")
        }

        let infoBuffer = pipe.allocateBuffer(length: Int(request.wLength))
        guard pipe.send(request: request, withBuffer: true) else { return nil }
        var result: [UInt8] = []
        result.reserveCapacity(Int(request.wLength))
//        print("USBDEV: reasing \(infoBuffer.count) bytes from response")
        for byte in infoBuffer {
            result.append(byte)
        }
        return result
    }



    func setAddress(_ newAddress: UInt8) -> Bool {
        print("USBDEV: Setting address to:", newAddress)
        let request = USB.ControlRequest.setAddress(address: newAddress)
        for _ in 1...2 {
            if controlPipe().send(request: request, withBuffer: false) {
                address = newAddress
                sleep(milliseconds: 10) // Device may require some time before address takes effect
                return true
            }
            sleep(milliseconds: 5)
        }
        print("USBDEV: Failed to setAddress(\(newAddress))")
        return false
    }


    func getDeviceConfig(length: UInt16) -> USB.DeviceDescriptor? {
        let pipe = controlPipe()

        let descriptorRequest = USB.ControlRequest.getDescriptor(descriptorType: .DEVICE, descriptorIndex: 0, length: length)
        let infoBuffer = pipe.allocateBuffer(length: Int(length))
        // defer { infoBuffer.free() }

        guard pipe.send(request: descriptorRequest, withBuffer: true) else {
            print("USBDEV: getDeviceConfig: Cant get descriptor length:", length)
            return nil
        }

        return USB.DeviceDescriptor(from: infoBuffer)
    }


    func getConfigurationDescriptor() -> USB.ConfigDescriptor? {
        let pipe = controlPipe()

        let length = MemoryLayout<usb_standard_config_descriptor>.size
        var infoBuffer = pipe.allocateBuffer(length: length)
        // defer { infoBuffer.free() }

        let deviceConfigRequest1 = USB.ControlRequest.getDescriptor(descriptorType: .CONFIGURATION, descriptorIndex: 0, length: UInt16(length))
        guard pipe.send(request: deviceConfigRequest1, withBuffer: true) else {
            return nil
        }

        guard let configDescriptor1 =  try? USB.ConfigDescriptor(from: infoBuffer) else {
            print("USBDEV: Cant decode CONFIGURATION descriptor packet")
                return nil
        }
        print("USBDEV:", configDescriptor1)
        infoBuffer = pipe.allocateBuffer(length: Int(configDescriptor1.wTotalLength))

        let deviceConfigRequest2 = USB.ControlRequest.getDescriptor(descriptorType: .CONFIGURATION, descriptorIndex: 0, length: configDescriptor1.wTotalLength)
        guard pipe.send(request: deviceConfigRequest2, withBuffer: true) else {
            return nil
        }

        do {
            let configDescriptor2 = try USB.ConfigDescriptor(from: infoBuffer)
            return configDescriptor2
        } catch {
            print("USBDEV: Cant decode CONFIGURATION descriptor packet:", error)
            return nil
        }
    }

    func setConfiguration(to configuration: UInt8) -> Bool {
        print("USBDEV: Setting configuration to:", configuration)
        let pipe = controlPipe()
    
        let request = USB.ControlRequest.setConfiguration(configuration: configuration)
        guard pipe.send(request: request, withBuffer: false) else {
            print("USBDEV: Failed to set configuration")
            return false
        }
        return true
    }
}
