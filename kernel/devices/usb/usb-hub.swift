/*
 * kernel/devices/usb/usb-hub.swift
 *
 * Created by Simon Evans on 22/10/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB Hub
 *
 */


@freestanding(expression)
macro usbhubDebug(_ item: CustomStringConvertible, _ items: CustomStringConvertible...) -> () = #externalMacro(module: "PrintfMacros", type: "DebugMacro")


private let USBHUB_DEBUG = true
internal func _usbhubDebug(_ items: String...) {
    if USBHUB_DEBUG {
        _kprint("UHCI:", terminator: "")
        for item in items {
            _kprint(" ", item, terminator: "")
        }
        _kprint("")
    }
}


final class USBHubDriver: USBDeviceDriver {
    private(set) var hubDescriptor = USB.HUBDescriptor(ports: 0)
    var ports: Int { Int(hubDescriptor.bNbrPorts) }
    private let responseBuffer: MMIOSubRegion

    init?(usbDevice: USBDevice, interface: USB.InterfaceDescriptor? = nil) {
        self.responseBuffer = usbDevice.controlPipe.allocateBuffer(length: 32)
        super.init(driverName: "usb-hub", usbDevice: usbDevice)
        self.setInstanceName(to: "usb-hub-\(usbDevice.bus.busId)-\(usbDevice.address)")
        device.setDriver(self)
    }

    deinit {
        usbDevice.controlPipe.freeBuffer(responseBuffer)
    }

    override func initialise() -> Bool {
        if let _hubDescriptor = getHubDescriptor() {
            self.hubDescriptor = _hubDescriptor
        }  else {
            #kprint("USB-HUB: Cannot get HubDescriptor")
            return false
        }

        #kprintf("USB-Hub: ports: %u powerOn2Good: %u\n",
                 hubDescriptor.bNbrPorts, hubDescriptor.bPwrOn2PwrGood)
        #kprint("USB-Hub: connected:")
        for port in 0..<hubDescriptor.bNbrPorts {
            #kprintf("\t%2u: %s\n", port, hubDescriptor.deviceRemovable[Int(port)])
        }

        // Get Hub Status
        guard getHubStatus() else {
            #kprint("USBHUB: Cannot get hub status")
            return false
        }

        // Set Configuration
        return true
    }

    func enumerate() {
        #kprintf("USB-HUB: enumerating, have %d ports\n", self.ports)
        for portIdx in 1...self.ports {

            guard self.powerPort(portIdx) else {
                #kprintf("USBHUB: Cannot power on port: %d\n", portIdx)
                continue
            }

            guard let connectedSpeed = detectConnected(port: portIdx) else {
                #usbhubDebug("\(self)/\(portIdx) has no device")
                continue
            }

            sleep(milliseconds: 100)
            guard resetPort(portIdx) else {
                #usbhubDebug("\(self)/ \(portIdx) reset failed")
                continue
            }

            #usbhubDebug("\(self)/\(portIdx) speed: \(connectedSpeed)")
            let d = Device(parent: self.device)
            guard let newDevice = USBDevice(device: d, bus: usbDevice.bus, speed: connectedSpeed) else {
                #kprint("usb-hub: Failed to create USBDevice")
                continue
            }

            // Get initial 8byte device descriptor
            guard let deviceDescriptor = getInitialDeviceDescriptor(newDevice) else {
                #kprint("\(self)/\(portIdx)-0: Cannot get info8")
                continue
            }
            #kprintf("USB: %s deviceDescriptor: %s\n", newDevice.description, deviceDescriptor.description)
            guard deviceDescriptor.bLength != 0 else {
                fatalError("info8 returned zero length bLength")
            }

            // Set address of device
            guard let address = usbDevice.bus.nextAddress() else {
                fatalError("No more addresses!")
            }

            #kprintf("USB: %s Setting address of device on to %d\n", newDevice.description, address)
            guard newDevice.setAddress(address) else {
                #kprint("\(self)/\(portIdx)-0: Cant set address of device - ignoring device")
                continue
            }
            // Get full DeviceDescriptor
            #usbhubDebug("\(self)/\(portIdx)-\(address) Getting full DeviceDescriptor of length:", deviceDescriptor.bLength)
            guard let _descriptor = newDevice.getDeviceDescriptor(length: UInt16(deviceDescriptor.bLength)) else {
                #usbhubDebug("\(self)/\(portIdx)-\(address) Cant get full DeviceDescriptor")
                continue
            }
            let fullDeviceDescriptor = _descriptor
            #usbhubDebug("\(newDevice.description) fullDeviceDescriptor:", fullDeviceDescriptor)

            #kprintf("USB: %s vendor: %4.4x product: %4.4x manu: %2.2x product: %2.2x\n",
                     newDevice.description,
                     fullDeviceDescriptor.idVendor, fullDeviceDescriptor.idProduct,
                     fullDeviceDescriptor.iManufacturer, fullDeviceDescriptor.iProduct)

            #kprint("\nUSB: \(newDevice.description) Getting ConfigurationDescriptor")
            guard let configDescriptor = newDevice.getConfigurationDescriptor() else {
                #usbhubDebug("\(newDevice.description) Cant get device ConfigurationDescriptor of device on port: \(portIdx) - ignoring device")
                continue
            }
            #usbhubDebug("\(newDevice.description) configDescriptor: \(configDescriptor)")
            configureDevice(newDevice, fullDeviceDescriptor, configDescriptor)
        }
    }

    private func getInitialDeviceDescriptor(_ newDevice: USBDevice) -> USB.DeviceDescriptor? {
        for _ in 1...2 {
            if let deviceDescriptor = newDevice.getDeviceDescriptor(length: 8) {
                return deviceDescriptor
            }
            sleep(milliseconds: 20)
        }
        return nil
    }


    private func configureDevice(_ usbDevice: USBDevice, _ deviceDescriptor: USB.DeviceDescriptor, _ configDescriptor: USB.ConfigDescriptor) {

        // Configure device - set_configuration
        guard usbDevice.setConfiguration(to: configDescriptor.bConfigurationValue) else {
            #usbhubDebug("\(usbDevice.description) Cant set configuration")
            return
        }

        guard let deviceClass = USB.DeviceClass(rawValue: deviceDescriptor.bDeviceClass) else {
            #kprintf("USB: Unknown device class 0x%2.2x\n", deviceDescriptor.bDeviceClass)
            return
        }

        #kprint("USB: device class:", deviceClass.description)
        switch deviceClass {
            case .interfaceSpecific:
                for interface in configDescriptor.interfaces {
                    switch interface.interfaceClass {
                        case .hid:
                            #usbhubDebug("\(usbDevice.description) Found a HID Device, interface: \(interface)")
                            guard let driver = USBHIDDriver(device: usbDevice, interface: interface), driver.initialise() else {
                                #usbhubDebug("\(usbDevice.description) Cannot create HID Driver for device")
                                continue
                            }
                        default:
                            let iClass = interface.interfaceClass?.description ?? "nil"
                            #usbhubDebug("\(usbDevice.description) ignoring non-HID device: \(iClass)")
                    }
                }

            case .hub:
                #kprint("USB: Found a hub")
                if let driver = USBHubDriver(usbDevice: usbDevice) {
                    if driver.initialise() {
                        driver.enumerate()
                    } else {
                        #kprint("Cannot initialise hub")
                    }
                }

            default:
                #kprintf("USB: Unsupported device class %s\n", deviceClass.description)

        }
    }


    private func getHubDescriptor() -> USB.HUBDescriptor? {

        let length: UInt16 = 9 // 9 bytes for the minimal response, upto 7 ports. // + 32x2x8bits for ports bitmaps (255 ports max + 1 reserved bit)
        let descriptorIndex = 0
        let request = USB.ControlRequest.classSpecificRequest(
            direction: .deviceToHost,
            recipient: .device,
            bRequest: USB.ControlRequest.RequestCode.GET_DESCRIPTOR.rawValue,
            wValue: UInt16(USB.DescriptorType.HUB.rawValue) << 8 | UInt16(descriptorIndex),
            wLength: length
        )

        guard usbDevice.sendControlRequestReadData(request: request, into: responseBuffer) else {
            #kprint("USBHUB: getHubConfig: Cannot get HUB descriptor")
            return nil
        }
        let numPorts = Int(responseBuffer[2])
        if numPorts <= 7 && length == UInt16(responseBuffer[0]) {
            // Got the whole descriptor so just decode it
            return try? USB.HUBDescriptor(from: responseBuffer)
        }
        #kprintf("USBHUB: Got descr1 nports: %d bDescLength: %u\n", numPorts, responseBuffer[0])
        let newLength = 9 + (2 * (numPorts / 8))
        let request2 = USB.ControlRequest.classSpecificRequest(
            direction: .deviceToHost,
            recipient: .device,
            bRequest: USB.ControlRequest.RequestCode.GET_DESCRIPTOR.rawValue,
            wValue: UInt16(USB.DescriptorType.HUB.rawValue) << 8 | UInt16(descriptorIndex),
            wLength: UInt16(newLength)
        )
        guard usbDevice.sendControlRequestReadData(request: request2, into: responseBuffer) else {
            #kprint("USBHUB: getHubConfig: Cannot get HUB descriptor2")
            return nil
        }
        return try? USB.HUBDescriptor(from: responseBuffer)
    }

    private func getHubStatus() -> Bool {
        let request = USB.ControlRequest.getStatus(direction: .hostToDevice, recipient: .device)
        guard usbDevice.sendControlRequestReadData(request: request, into: responseBuffer) else {
            #kprint("USBHUB getHubStatus failed")
            return false
        }
        #kprintf("UBSHUB: status: 0x%2.2x 0x%2.2x\n", responseBuffer[0], responseBuffer[1])
        return true
    }

    private func powerPort(_ port: Int) -> Bool {
        guard port > 0 && port <= self.ports else {
            return false
        }
        let request = USB.ControlRequest.classSpecificRequest(
            direction: .hostToDevice,
            recipient: .other(UInt16(port)),
            bRequest: HUB_FEATURE.SET_FEATURE.rawValue,
            wValue: FEATURE_SELECTOR.PORT_POWER.rawValue,
            wLength: 0)
        guard usbDevice.sendControlRequest(request: request) else {
            #kprintf("USB-HUB: error powering on port %d\n", port)
            return false
        }
        // Wait for the port to power up
        let potpgt = Int(hubDescriptor.bPwrOn2PwrGood) * 2
        #kprintf("USB-HUB: Waiting %dms for port to power up\n", potpgt)
        sleep(milliseconds: potpgt)
        return true
    }

    func detectConnected(port: Int) -> USB.Speed? {
        guard port > 0, port <= self.ports else {
            #kprintf("USB-HUB invalid port: %d\n", port)
            return nil
        }
        // Clear connection Status bit
        let clearConnReq = USB.ControlRequest.classSpecificRequest(
            direction: .hostToDevice,
            recipient: .other(UInt16(port)),
            bRequest: HUB_FEATURE.CLEAR_FEATURE.rawValue,
            wValue: FEATURE_SELECTOR.C_PORT_CONNECTION.rawValue,
            wLength: 0)
        guard usbDevice.sendControlRequest(request: clearConnReq) else {
            #kprintf("USB-HUB: Cannot clear connection on port: %d\n", port)
            return nil
        }

        // Get port status
        let portStatusReq = USB.ControlRequest.classSpecificRequest(
            direction: .deviceToHost,
            recipient: .other(UInt16(port)),
            bRequest: HUB_FEATURE.GET_STATUS.rawValue,
            wValue: 0,
            wLength: 4
        )
        guard usbDevice.sendControlRequestReadData(request: portStatusReq, into: responseBuffer) else {
            #kprintf("USB-HUB: Cannot get status of port: %d\n", port)
            return nil
        }
        let portStatus = PortStatus(from: responseBuffer)
        if portStatus.deviceAttached {
            if portStatus.lowSpeedDeviceAttached { return .lowSpeed }
            else if portStatus.highSpeedDeviceAttached { return .highSpeed }
            else { return .fullSpeed }
        }
        return nil
    }

    func resetPort(_ port: Int) -> Bool {
        guard port > 0, port <= self.ports else {
            return false
        }
        let request = USB.ControlRequest.classSpecificRequest(
            direction: .hostToDevice,
            recipient: .other(UInt16(port)),
            bRequest: HUB_FEATURE.SET_FEATURE.rawValue,
            wValue: FEATURE_SELECTOR.PORT_RESET.rawValue,
            wLength: 0)
        guard usbDevice.sendControlRequest(request: request) else {
            #kprintf("USB-HUB: Cant send reset to port %d\n", port)
            return false
        }
        // Get port status
        let portStatusReq = USB.ControlRequest.classSpecificRequest(
            direction: .deviceToHost,
            recipient: .other(UInt16(port)),
            bRequest: HUB_FEATURE.GET_STATUS.rawValue,
            wValue: 0,
            wLength: 4
        )
        guard usbDevice.sendControlRequestReadData(request: portStatusReq, into: responseBuffer) else {
            #kprintf("USB-HUB: Cannot get status of port: %d\n", port)
            return false
        }
        let portStatus = PortStatus(from: responseBuffer)
        if portStatus.resetComplete {
            let request = USB.ControlRequest.classSpecificRequest(
                direction: .hostToDevice,
                recipient: .other(UInt16(port)),
                bRequest: HUB_FEATURE.CLEAR_FEATURE.rawValue,
                wValue: FEATURE_SELECTOR.C_PORT_RESET.rawValue,
                wLength: 0)
            if !usbDevice.sendControlRequest(request: request) {
                #kprintf("USB-HUB: Cant clear reset bit to port %d\n", port)
            }
        }
        return true
    }

    enum HUB_FEATURE: UInt8 {
        case GET_STATUS = 0x0
        case CLEAR_FEATURE = 0x1
        case RESERVED = 0x2
        case SET_FEATURE = 0x3
        case GET_DESCRIPTOR = 0x6
        case SET_DESCRIPTOR = 0x7
        case CLEAR_TT_BUFFER = 0x8
        case RESET_TT = 0x9
        case GET_TT_STATE = 0xA
        case STOP_TT = 0xB
        case SET_HUB_DEPTH = 0xC
        case SET_PORT_ERR_COUNT = 0xD
    }

    enum FEATURE_SELECTOR: UInt16 {
        case PORT_CONNECTION = 0x00
        case PORT_ENABLE = 0x01
        case PORT_SUSPEND = 0x02
        case PORT_OVER_CURRENT = 0x03
        case PORT_RESET = 0x04
        case PORT_LINK_STATE = 0x05
        case PORT_POWER = 0x08
        case PORT_LOW_SPEED = 0x09
        case C_PORT_CONNECTION = 0x10
        case C_PORT_ENABLE = 0x11
        case C_PORT_SUSPEND = 0x12
        case C_PORT_OVER_CURRENT = 0x13
        case C_PORT_RESET = 0x14
        case PORT_TEST = 0x15
        case PORT_INDICATOR = 0x16
        case PORT_U1_TIMEOUT = 0x17
        case PORT_U2_TIMEOUT = 0x18
        case C_PORT_LINK_STATE = 0x19
        case C_PORT_CONFIG_ERROR = 0x1A
        case PORT_REMOTE_WAKE_MASK = 0x1B
        case BH_PORT_RESET = 0x1C
        case C_BH_PORT_RESET = 0x1D
        case FORCE_LINKPM_ACCEPT = 0x1E
    }

    struct PortStatus {
        let statusField: BitArray16
        let changeStatusField: BitArray16

        var deviceAttached: Bool { statusField[0] != 0 }
        var isEnabled: Bool { statusField[1] != 0 }
        var isSuspended: Bool { statusField[2] != 0 }
        var isOverCurrent: Bool { statusField[3] != 0 }
        var isInReset: Bool { statusField[4] != 0 }
        var isPowered: Bool { statusField[8] != 0 }
        var lowSpeedDeviceAttached: Bool { statusField[9] != 0 }
        var fullSpeedDeviceattached: Bool { statusField[9] == 0 && statusField[10] == 0 }
        var highSpeedDeviceAttached: Bool { statusField[10] != 0 }
        var inTestMode: Bool { statusField[11] != 0 }
        var indicatorUsesDefaultColors: Bool { statusField[12] == 0 }

        var currentConnectChange: Bool { changeStatusField[0] != 0 }
        var portEnabled: Bool { changeStatusField[1] != 0 }
        var suspendChange: Bool { changeStatusField[2] != 0 }
        var overCurrentIndicatorChanged: Bool { changeStatusField[3] != 0 }
        var resetComplete: Bool { changeStatusField[4] != 0 }

        @inline(__always)
        init(from buffer: MMIOSubRegion) {
            let word0 = UInt16(buffer[0]) | UInt16(buffer[1] << 8)
            statusField = BitArray16(word0)
            let word1 = UInt16(buffer[2]) | UInt16(buffer[3] << 8)
            changeStatusField = BitArray16(word1)
        }

        @inline(__always)
        init(statusField: UInt16, changeStatusField: UInt16) {
            self.statusField = BitArray16(statusField)
            self.changeStatusField = BitArray16(changeStatusField)
        }

        @inline(__always)
        init(deviceAttached: Bool,
             isEnabled: Bool,
             isSuspended: Bool,
             isOverCurrent: Bool,
             isInReset: Bool,
             isPowered: Bool,
             speed: USB.Speed,

             currentConnectChange: Bool,
             portEnabledChange: Bool,
             suspendChange: Bool,
             overCurrentIndicatorChanged: Bool,
             resetComplete: Bool) {

            var _statusField = BitArray16()
            _statusField[0] = deviceAttached ? 1 : 0
            _statusField[1] = isEnabled ? 1 : 0
            _statusField[2] = isSuspended ? 1 : 0
            _statusField[3] = isOverCurrent ? 1 : 0
            _statusField[4] = isInReset ? 1 : 0
            _statusField[8] = isPowered ? 1 : 0

            switch speed {
                case .lowSpeed:
                    _statusField[9] = 1
                case .fullSpeed:
                    break
                case .highSpeed:
                    _statusField[10] = 1
                case .superSpeed:
                    // FIXME: this isnt supported,
                    break
            }
            self.statusField = _statusField

            var _changeStatusField = BitArray16()
            _changeStatusField[0] = currentConnectChange ? 1 : 0
            _changeStatusField[1] = portEnabledChange ? 1 : 0
            _changeStatusField[2] = suspendChange ? 1 : 0
            _changeStatusField[3] = overCurrentIndicatorChanged ? 1 : 0
            _changeStatusField[4] = resetComplete ? 1 : 0
            self.changeStatusField = _changeStatusField
        }

        func asBytes(into buffer: inout MMIOSubRegion, maxLength: Int) -> Int {
            let length = min(4, maxLength)
            let word0 = statusField.rawValue
            let word1 = changeStatusField.rawValue
            if length > 0 { buffer[0] = UInt8(truncatingIfNeeded: word0) }
            if length > 1 { buffer[1] = UInt8(truncatingIfNeeded: word0 >> 8) }
            if length > 2 { buffer[2] = UInt8(truncatingIfNeeded: word1) }
            if length > 3 { buffer[3] = UInt8(truncatingIfNeeded: word1 >> 8) }
            return length
        }
    }
}
