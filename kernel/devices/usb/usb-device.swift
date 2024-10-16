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
    enum Speed: CustomStringConvertible {
        case lowSpeed
        case fullSpeed
        case highSpeed
        case superSpeed

        var description: String {
            switch self {
            case .lowSpeed: return "lowSpeed"
            case .fullSpeed: return "fullSpeed"
            case .highSpeed: return "highSpeed"
            case .superSpeed: return "superSpeed"
            }
        }

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
        if let pipe = _controlPipe {
            return pipe
        }
        guard let pipe = hub.allocatePipe(device: self, endpointDescriptor: USB.EndpointDescriptor(controlEndPoint: 0, maxPacketSize: 8, bInterval: 0)) else {
            fatalError("UHCI: Cant allocate pipe")
        }
        _controlPipe = pipe
        return pipe
    }

    func sendControlRequest(request: USB.ControlRequest) -> Bool {
        print("USBDEV: sendControlRequest:", terminator: " ")
        print(request)
        let pipe = controlPipe()

        return pipe.send(request: request, withBuffer: nil)
    }


    func sendControlRequestReadData(request: USB.ControlRequest) -> [UInt8]? {
//        print("USBDEV: sendControlRequestReadData:", request, "reading \(request.wLength) bytes")
        let pipe = controlPipe()

        guard request.wLength > 0 else {
            fatalError("USBDEV: sendControlRequestReadData wLenggth is 0!")
        }

        let infoBuffer = pipe.allocateBuffer(length: Int(request.wLength))
        defer { pipe.freeBuffer(infoBuffer) }
        guard pipe.send(request: request, withBuffer: infoBuffer) else { return nil }
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
            if controlPipe().send(request: request, withBuffer: nil) {
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
        var infoBuffer = pipe.allocateBuffer(length: Int(length))
        infoBuffer.clearBuffer()
        defer { pipe.freeBuffer(infoBuffer) }

        guard pipe.send(request: descriptorRequest, withBuffer: infoBuffer) else {
            print("USBDEV: getDeviceConfig: Cant get descriptor length:", length)
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
            print("USBDEV: Cant decode CONFIGURATION descriptor packet")
                return nil
        }
        print("USBDEV:", configDescriptor1)
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
            let str: String
            if let error = error as? USB.ParsingError {
                str = error.description
            } else {
                str = "unknown error"
            }
            print("USBDEV: Cant decode CONFIGURATION descriptor packet: ", str)
            return nil
        }
    }

    func setConfiguration(to configuration: UInt8) -> Bool {
        print("USBDEV: Setting configuration to:", configuration)
        let pipe = controlPipe()

        let request = USB.ControlRequest.setConfiguration(configuration: configuration)
        guard pipe.send(request: request, withBuffer: nil) else {
            print("USBDEV: Failed to set configuration")
            return false
        }
        return true
    }
}
