/*
 * kernel/devices/usb/uhci-hid.swift
 *
 * Created by Simon Evans on 09/11/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB HID Device Driver for keyboard and mouse.
 *
 */


final class USBHIDDriver {
    private(set) var description = "Unknown HID"
    private let device: USBDevice
    private let interface: USB.InterfaceDescriptor


    // bRequest for Class specific request
    enum HIDRequest: UInt8 {
        case GET_REPORT = 0x1
        case GET_IDLE = 0x2
        case GET_PROTOCOL = 0x3
        case SET_REPORT = 0x9
        case SET_IDLE = 0xA
        case SET_PROTOCOL = 0xB
    }

    enum HIDProtocol: UInt16 {
        case boot = 0x0
        case report = 0x1
    }

    enum HIDInterfaceProtocol: UInt8 {
        case none = 0x0
        case keyboard = 0x1
        case mouse = 0x2
    }

    enum HIDReportRequest: UInt8 {
        case input = 0x1
        case output = 0x2
        case feature = 0x3
    }


    init?(device: USBDevice, interface: USB.InterfaceDescriptor) {
        self.device = device
        self.interface = interface

        guard case .hid = interface.interfaceClass else {
            #kprint("USB-HID: interface is not a HID")
            return nil
        }
    }

    func initialise() -> Bool {

        guard interface.bInterfaceSubClass == 0x1,
              let interfaceProtocol = HIDInterfaceProtocol(rawValue: interface.bInterfaceProtocol) else {
            #kprint("USB-HID: Device has no boot protocol or cannot determine device type (subClass=\(interface.bInterfaceSubClass), protocol=\(interface.bInterfaceProtocol)")
            return false
        }

        switch interfaceProtocol {
            case .none:
                #kprint("USB-HID: Device is not a keyboard or mouse")
                return false
            case .keyboard:
                description = "USB Keyboard"
                // return default keyboard report
            case .mouse:
                description = "USB Mouse"
                // return deault mouse report
        }
        let request = setProtocolRequest(hidProtocol: .boot)
        #kprint("USB-HID: found \(description): set HID to boot protocol, request:", request)
        guard device.sendControlRequest(request: request) else {
            #kprint("USB-HID: Cant set HID Protocol to boot")
            return false
        }

        // Find the INTR endpoint
        guard let intrEndpoint = interface.endpointMatching(transferType: .interrupt) else {
            #kprint("USB-HID: Cant find an interrupt endpoint")
            return false
        }
        #kprint("USB-HID: Interrupt endpoint:", intrEndpoint)


        switch interfaceProtocol {
            case .keyboard:
                #kprint("USB-HID: Found keyboard")
                #if false
                #kprint("USB-HID: ignoring")
                break
                #else
                let idleRequest = setIdleRequest(idleMs: 33)
                #kprint("USB-HID: keyboard setIdle to 33")
                guard device.sendControlRequest(request: idleRequest) else {
                    #kprint("USB-HID: keyboard  Cant set idleRequest")
                    return false
                }
                if system.deviceManager.keyboard != nil {
                    #kprint("USB-HID: Device manager already has a keyboard!")
                }

                // Create a pipe for the interrupt endpoint and add it to the active queues
                guard let intrPipe = device.hub.allocatePipe(device: device, endpointDescriptor: intrEndpoint) else {
                    #kprint("Cannot allocate Interupt pipe")
                    return false
                }
                let hid = USBKeyboard(device: device, interface: interface, intrPipe: intrPipe)
                let keyboard = Keyboard(hid: hid)
                if keyboard.initialise() {
                    #kprint("USB-HID Adding keyboard")
                    system.deviceManager.keyboard = keyboard
                } else {
                    #kprint("USB-HID Cannot initialise keyboard")
                }
                #endif

            case .mouse:
                #kprint("USB-HID: Found mouse")
                #if false
                #kprint("USB-HID: ignoring")
                break
                #else
                let idleRequest = setIdleRequest(idleMs: 0)
                #kprint("USB-HID: mouse setIdle to 0")
                guard device.sendControlRequest(request: idleRequest) else {
                    #kprint("USB-HID:  mouse Cant set idleRequest")
                    return false
                }

                guard let intrPipe = device.hub.allocatePipe(device: device, endpointDescriptor: intrEndpoint) else {
                    #kprint(" mouse Cannot allocate interrupt pipe")
                    return false
                }
                let hid = USBMouse(device: device, interface: interface, intrPipe: intrPipe)
                let mouse = Mouse(hid: hid)
                if mouse.initialise() {
                    #kprint("USB-HID Adding mouse")
                    system.deviceManager.mouse = mouse
                }else {
                    #kprint("USB-HID Cannot initialise mouse")
                }
                #endif
            default:
                break
        }
        return true
    }
/*
    private func getReportAndSetProtocol() -> HIDReport? {

        // Try and get a Report Descriptor
        guard let reportDescriptor = device.sendControlRequestReadData(request: getReportRequest(.input)),
              let report = HIDReport(reportDescriptor) else {
            #kprint("USB-HID: Cannot Get_Report")
            return nil
        }

        // Device supports the Boot protocol, so set the boot protocol for now
        if interface.bInterfaceSubClass == 0x1 {
            guard let interfaceProtocol = HIDInterfaceProtocol(rawValue: interface.bInterfaceProtocol) else {
                #kprint("USB-HID: Device has boot protocol but cannot determine device type (subClass=\(interface.bInterfaceSubClass), protocol=\(interface.bInterfaceProtocol)")
                return nil
            }
            switch interfaceProtocol {
                case .none:
                    #kprint("USB-HID: Device is not a keyboard or mouse")
                    return false
                case .keyboard:
                    description = "USB Keyboard"
                    // return default keyboard report
                case .mouse:
                    description = "USB Mouse"
                    // return deault mouse report
            }
            let request = setProtocolRequest(hidProtocol: .boot)
            #kprint("USB: request:", request)
            guard device.sendControlRequest(request: request) else {
                #kprint("USB: Cant set HID Protocol to", protocolToUse)
                return nil
            }
        }

        #kprint("USB: Setting protocol to boot")
        return report
    }
*/
    // HID Class specific control requests
    private func getReportRequest(report: HIDReportRequest, reportId: UInt8 = 0) -> USB.ControlRequest {
        let recipient = USB.ControlRequest.Recipient.interface(interface.bInterfaceNumber)
        let wLength = interface.endpoint0.wMaxPacketSize
        let wValue = UInt16(report.rawValue) << 8 | UInt16(reportId)
        return USB.ControlRequest.classSpecificRequest(direction: .deviceToHost, recipient: recipient, bRequest: HIDRequest.GET_REPORT.rawValue, wValue: wValue, wLength: wLength)
    }


    private func setReportRequest(report: HIDReportRequest, reportId: UInt8 = 0, dataLength: UInt16) -> USB.ControlRequest {
        let recipient = USB.ControlRequest.Recipient.interface(interface.bInterfaceNumber)
        let wValue = UInt16(report.rawValue) << 8 | UInt16(reportId)
        return USB.ControlRequest.classSpecificRequest(direction: .deviceToHost, recipient: recipient, bRequest: HIDRequest.SET_REPORT.rawValue, wValue: wValue, wLength: dataLength)
    }


    private func setProtocolRequest(hidProtocol: HIDProtocol) -> USB.ControlRequest {
        let recipient = USB.ControlRequest.Recipient.interface(interface.bInterfaceNumber)
        return USB.ControlRequest.classSpecificRequest(direction: .hostToDevice, recipient: recipient, bRequest: HIDRequest.SET_PROTOCOL.rawValue, wValue: hidProtocol.rawValue, wLength: 0)
    }

    private func setIdleRequest(idleMs: Int) -> USB.ControlRequest {
        let recipient = USB.ControlRequest.Recipient.interface(interface.bInterfaceNumber)
        let value = UInt16(idleMs / 4) << 8
        return USB.ControlRequest.classSpecificRequest(direction: .hostToDevice, recipient: recipient, bRequest: HIDRequest.SET_IDLE.rawValue, wValue: value, wLength: 0)
    }
}


struct HIDReport {

    init?(_ bytes: [UInt8]) {
        #kprint("HIDReport bytes:")
        hexDump(buffer: bytes)
        return nil
    }
}
