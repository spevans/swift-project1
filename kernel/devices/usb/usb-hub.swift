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
internal func _usbhubDebug(_ item1: String, _ items: String...) {
    if USBHUB_DEBUG {
        _kprint(item1, terminator: "")
        for item in items {
            _kprint(" ", item, terminator: "")
        }
        _kprint("")
    }
}

private var hubNumber = 0

final class USBHubDriver: DeviceDriver {
    private let usbDevice: USBDevice
    private let responseBuffer: MMIOSubRegion
    private(set) var hubDescriptor: USB.HUBDescriptor
    private(set) var multiTT: Bool = false
    var ports: Int { Int(hubDescriptor.bNbrPorts) }


    init?(usbDevice: USBDevice, interface: USB.InterfaceDescriptor? = nil) {
        guard usbDevice.isBus else {
            #kprintf("usbhub: %s is not a bus\n", usbDevice.deviceName)
            return nil
        }
        self.usbDevice = usbDevice
        self.responseBuffer = usbDevice.bus.allocateBuffer(length: 32)
        self.hubDescriptor = USB.HUBDescriptor(isSuperSpeed: usbDevice.speed.isUSB3, ports: 0)
        super.init(driverName: "usb-hub", device: usbDevice)
        let instance = #sprintf("usb-hub%d-%d.%u", atomic_inc(&hubNumber),
                                usbDevice.bus.busId, usbDevice.address)
        self.setInstanceName(to: instance)
        guard self.initialise() else {
            return nil
        }
    }

    deinit {
        self.usbDevice.bus.freeBuffer(self.responseBuffer)
    }

    private func initialise() -> Bool {

        let hubName = self.instanceName + ":"
        // Root Hubs have depth 0 and dont need the depth set, the first
        // hub plugged into a root hub will have usbDevice.depth == 1 but
        // needs to be set as zero
        if self.usbDevice.depth > 0, self.usbDevice.isUSB3Device {
            let hubDepth = self.usbDevice.depth - 1
            #kprintf("%s setting hub depth to %u\n", hubName, hubDepth)
            guard self.setHubDepth(hubDepth) else {
                #kprintf("%s Failed to set hub depth to %u\n", hubName, hubDepth)
                return false
            }
        }

        if let _hubDescriptor = getHubDescriptor() {
            self.hubDescriptor = _hubDescriptor
        }  else {
            #kprint(hubName, "Failed to get HubDescriptor")
            return false
        }

        // Get Hub Status
        guard getHubStatus() else {
            #kprint(hubName, "Failed to get hub status")
            return false
        }

        // Set Configuration
        return true
    }

    func enumerate() {
        let hubName = self.instanceName + ":"
        // Power on the ports then wait for the power to come up
        #kprintf("%s enumerating, have %d ports basePort: %u portCount: %u speed: %s\n",
                 hubName, self.ports, usbDevice.bus.basePort,
                 usbDevice.bus.portCount, usbDevice.speed.description)

        for port in 1...self.ports {

            guard self.powerPort(port) else {
                #kprintf("%s Failed to power on port: %d\n", hubName, port)
                continue
            }
       }
        // FIXME: is this needed for HCDs?

        // Wait for the port to power up
        let potpgt = Int(hubDescriptor.bPwrOn2PwrGood) * 2
        sleep(milliseconds: potpgt)


        for port in 1...self.ports {

            guard var portStatus = self.portStatus(port) else { continue }
            if portStatus.portEnabledChange {
                // Clear connection Status bit
                guard self.clearHubFeature(.C_PORT_ENABLE, port: port) else {
                    #kprintf("%s Failed to clear connection on port: %d\n", hubName, port)
                    continue
                }

                if portStatus.connectStatusChange {
                    // ignore
                } else if portStatus.isEnabled {
                    #kprintf("%s port %d: invalid enable change\n", hubName, port)
                } else {
                    #kprintf("%s port %d: error condition\n", hubName, port)
                    portStatus.connectStatusChange = true
                }
            }

            if portStatus.resetChange {
                _ = self.clearHubFeature(.C_PORT_RESET, port: port)
                portStatus.connectStatusChange = true
            }

            if portStatus.bhResetChange {
                // TODO: for USB3
                //                if self.usbDevice.isUSB3Device {
                _ = self.clearHubFeature(.C_BH_PORT_RESET, port: port)
                //                }
            }

            if portStatus.connectStatusChange {
                guard self.connected(port, portStatus) else { continue }
            } else {
                if USBHUB_DEBUG {
                    #kprintf("%s port %d: not connected\n", self.instanceName, port)
                }
            }
            if portStatus.portLinkStatusChange {
                _ = self.clearHubFeature(.C_PORT_LINK_STATE, port: port)
            }
        }
    }

    private func connected(_ port: Int, _ portStatus: PortStatus) -> Bool {
        let portName = #sprintf("%s port %d:", self.instanceName, port)
        #kprintf("%s wChange: %4.4x wStatus: %4.4x isPowered: %s isPoweredSS: %s\n",
                 portName, portStatus.wPortChange.rawValue,
                 portStatus.wPortStatus.rawValue,
                 portStatus.isPowered, portStatus.isPoweredSS)
        _ = self.clearConnection(port)
        guard portStatus.deviceAttached else {
            #kprint(portName, "no device attached")
            return false
        }
        // Wait for port powerup
        sleep(milliseconds: 100)
        guard resetPort(port) else {
            #kprint(portName, "reset failed")
            return false
        }

        // Get current port status after reset
        guard let portStatus = self.portStatus(port), portStatus.deviceAttached else {
            #kprint(portName, "Device disappeared after reset")
            return false
        }

        let connectedSpeed = portStatus.speed()

        #usbhubDebug("\(portName) New Device speed: \(connectedSpeed)")
        guard let newDevice = USBDevice(parent: self.usbDevice, bus: usbDevice.bus,
                                        port: UInt8(port),
                                        depth: self.usbDevice.depth + 1,
                                        speed: connectedSpeed) else {
            #kprint(portName, "Failed to create USBDevice")
            return false
        }

        guard let configDescriptor = newDevice.configDescriptor else {
            #kprint(portName, "No config descriptor for newDevice")
            return false
        }
        configureDevice(newDevice, newDevice.deviceDescriptor, configDescriptor)
        return true
    }

    private func configureDevice(_ usbDevice: USBDevice, _ deviceDescriptor: USB.DeviceDescriptor, _ configDescriptor: USB.ConfigDescriptor) {

        let portName = #sprintf("%s port %d:", self.instanceName, usbDevice.port)

        // Configure device - set_configuration
        guard usbDevice.setConfiguration(to: configDescriptor.bConfigurationValue) else {
            #usbhubDebug("\(portName) Failed to set configuration")
            return
        }

        guard let deviceClass = USB.DeviceClass(rawValue: deviceDescriptor.bDeviceClass) else {
            #kprintf("%s Unknown device class 0x%2.2x\n", portName, deviceDescriptor.bDeviceClass)
            return
        }

        #usbhubDebug("\(portName) device class:", deviceClass)
        switch deviceClass {
            case .interfaceSpecific:
                for interface in configDescriptor.interfaces {
                    switch interface.interfaceClass {
                        case .hid:
                            #usbhubDebug("\(portName) Found a HID Device, interface: \(interface)")
                            guard USBHIDDriver(device: usbDevice, interface: interface) != nil else {
                                #usbhubDebug("\(portName) Cannot create HID Driver for device")
                                continue
                            }
                        default:
                            let iClass = interface.interfaceClass?.description ?? "nil"
                            #usbhubDebug("\(portName) ignoring non-HID device: \(iClass)")
                    }
                }

            case .hub:
                #kprintf("%s %s: Found a hub\n", portName, usbDevice.description)
                usbDevice.setAsBus()
                if let driver = USBHubDriver(usbDevice: usbDevice) {
                    driver.enumerate()
                } else {
                    #kprint(portName, "Failed to initialise hub")
                }

            default:
                #kprint(portName, "Unsupported device class", deviceClass.description)
        }
    }


    private func getHubDescriptor() -> USB.HUBDescriptor? {

        if USBHUB_DEBUG {
            #kprintf("%s: getHubDescriptor: speed: %s version: %d isUSB3: %s\n",
                     self.instanceName,
                     self.usbDevice.speed.description,
                     self.usbDevice.deviceDescriptor.usbMajor,
                     self.usbDevice.isUSB3Device
            )
        }
        if self.usbDevice.isUSB3Device {
            #kprintf("%s: getHubDescriptor: Device supports Enhanced Hub Descriptor\n",
                     self.instanceName)
            return self.getEnhanchedHubDescriptor()
        }

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
            #kprint(self.instanceName, "Failed to get initial HUB descriptor")
            return nil
        }
        let numPorts = Int(responseBuffer[2])
        if numPorts <= 7 && length == UInt16(responseBuffer[0]) {
            // Got the whole descriptor so just decode it
            return try? USB.HUBDescriptor(hubFrom: responseBuffer)
        }
        #kprintf("%s: Got descr1 nports: %d bDescLength: %u\n", self.instanceName,
                 numPorts, responseBuffer[0])
        let newLength = 9 + (2 * (numPorts / 8))
        let request2 = USB.ControlRequest.classSpecificRequest(
            direction: .deviceToHost,
            recipient: .device,
            bRequest: USB.ControlRequest.RequestCode.GET_DESCRIPTOR.rawValue,
            wValue: UInt16(USB.DescriptorType.HUB.rawValue) << 8 | UInt16(descriptorIndex),
            wLength: UInt16(newLength)
        )
        guard usbDevice.sendControlRequestReadData(request: request2, into: responseBuffer) else {
            #kprint(self.instanceName, "Failed to get Full HUB descriptor")
            return nil
        }
        return try? USB.HUBDescriptor(hubFrom: responseBuffer)
    }

    private func getEnhanchedHubDescriptor() -> USB.HUBDescriptor? {
        let length = UInt16(MemoryLayout<usb_enhanced_ss_hub_descriptor>.size)
        let descriptorIndex = 0
        let request = USB.ControlRequest.classSpecificRequest(
            direction: .deviceToHost,
            recipient: .device,
            bRequest: USB.ControlRequest.RequestCode.GET_DESCRIPTOR.rawValue,
            wValue: UInt16(USB.DescriptorType.SUPER_SPEED_HUB.rawValue) << 8 | UInt16(descriptorIndex),
            wLength: length
        )

        guard usbDevice.sendControlRequestReadData(request: request, into: responseBuffer) else {
            #kprint(self.instanceName, ": Failed to get Enhanced HUB descriptor")
            return nil
        }
        return try? USB.HUBDescriptor(SSHubFrom: responseBuffer)
    }

    private func setHubDepth(_ depth: UInt8) -> Bool {
        let request = USB.ControlRequest.classSpecificRequest(
            direction: .hostToDevice,
            recipient: .device,
            bRequest: 0x0c,
            wValue: UInt16(depth),
            wLength: 0
        )
        return usbDevice.sendControlRequest(request: request)
    }


    private func getHubStatus() -> Bool {
        let request = USB.ControlRequest.getStatus(direction: .hostToDevice, recipient: .device)
        guard usbDevice.sendControlRequestReadData(request: request, into: responseBuffer) else {
            #kprint(self.instanceName, "Failed to get HubStatus")
            return false
        }
        //#kprintf("UBSHUB: status: 0x%2.2x 0x%2.2x\n", responseBuffer[0], responseBuffer[1])
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
            #kprintf("%s: port: %d error powering on port\n", self.instanceName, port)
            return false
        }
        return true
    }

    private func portStatus(_ port: Int) -> PortStatus? {
        guard port > 0, port <= self.ports else {
            #kprintf("%s: port: %d invalid port: %d\n", self.instanceName, port)
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
            #kprintf("%s port %d: Failed to get port status\n", self.instanceName, port)
            return nil
        }
        return PortStatus(from: responseBuffer)
    }

    private func clearHubFeature(_ selector: FEATURE_SELECTOR, port: Int) -> Bool {
        let request = USB.ControlRequest.classSpecificRequest(
            direction: .hostToDevice,
            recipient: .other(UInt16(port)),
            bRequest: HUB_FEATURE.CLEAR_FEATURE.rawValue,
            wValue: selector.rawValue,
            wLength: 0)
        return usbDevice.sendControlRequest(request: request)
    }

    private func setHubFeature(_ selector: FEATURE_SELECTOR, port: Int) -> Bool {
        let request = USB.ControlRequest.classSpecificRequest(
        direction: .hostToDevice,
        recipient: .other(UInt16(port)),
        bRequest: HUB_FEATURE.SET_FEATURE.rawValue,
        wValue: selector.rawValue,
        wLength: 0)
        return usbDevice.sendControlRequest(request: request)
    }

    private func clearConnection(_ port: Int) -> Bool {
        // Clear connection Status bit
        let clearConnReq = USB.ControlRequest.classSpecificRequest(
            direction: .hostToDevice,
            recipient: .other(UInt16(port)),
            bRequest: HUB_FEATURE.CLEAR_FEATURE.rawValue,
            wValue: FEATURE_SELECTOR.C_PORT_CONNECTION.rawValue,
            wLength: 0)
        return usbDevice.sendControlRequest(request: clearConnReq)
    }

    func resetPort(_ port: Int) -> Bool {
        guard port > 0, port <= self.ports else {
            return false
        }

        // Send reset
        guard self.setHubFeature(.PORT_RESET, port: port) else {
            #kprintf("%s port %d: Failed to send port reset\n", self.instanceName, port)
            return false
        }
        // Wait for device to finish resetting
        for _ in 1...10 {
            sleep(milliseconds: 50)
            guard let status = self.portStatus(port) else {
                return false
            }
            guard status.deviceAttached else {
                #kprintf("%s port %d: Device disappeared after reset\n",
                         self.instanceName, port)
                return false
            }
            if status.resetChange {break}
        }

        // Clear port reset
        guard self.clearHubFeature(.C_PORT_RESET, port: port) else {
            #kprintf("%s port %d: Failed to clear reset bit\n",
                     self.instanceName, port)
            return false
        }
        // Wait for device to finish resetting
        sleep(milliseconds: 10)
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
        let wPortStatus: BitArray16
        var wPortChange: BitArray16

        var deviceAttached: Bool { wPortStatus[0] != 0 }    // PORT_CONNECTION
        var isEnabled: Bool { wPortStatus[1] != 0 }         // PORT_ENABLE
        var isSuspended: Bool { wPortStatus[2] != 0 }       // PORT_SUSPEND (USB2.0)
        var isOverCurrent: Bool { wPortStatus[3] != 0 }     // PORT_OVER_CURRENT
        var isInReset: Bool { wPortStatus[4] != 0 }         // PORT_RESET
        var isPowered: Bool { wPortStatus[8] != 0 }         // PORT_POWER    (USB2.0)
        var isPoweredSS: Bool { wPortStatus[9] != 0 }       // PORT_POWER_SS (USB3.0)
        // Speeds here are USB2 Only
        var isLowSpeed: Bool { wPortStatus[9] != 0 }        // PORT_LOW_SPEED
        var isFullSpeed: Bool {
            wPortStatus[9] == 0 && wPortStatus[10] == 0     // FULL_SPEED
        }
        var isHighSpeed: Bool { wPortStatus[10] != 0 }      // PORT_HIGH_SPEED
        var inTestMode: Bool { wPortStatus[11] != 0 }       // PORT_TEST
        var indicator: Bool { wPortStatus[12] == 0 }        // PORT_INDICATOR

        var connectStatusChange: Bool {                     // C_PORT_CONNECTION
            get { wPortChange[0] != 0 }
            set { wPortChange[0] = newValue ? 1 : 0 }
        }
        var portEnabledChange: Bool { wPortChange[1] != 0 }     // C_PORT_ENABLE   (USB2.0)
        var suspendChange: Bool { wPortChange[2] != 0 }         // C_PORT_SUSPEND  (USB2.0)
        var overCurrentChange: Bool { wPortChange[3] != 0 }     // C_PORT_OVER_CURRENT
        var resetChange: Bool { wPortChange[4] != 0 }           // C_PORT_RESET
        var bhResetChange: Bool { wPortChange[5] != 0 }         // C_BH_PORT_RESET  (USB3.0)
        var portLinkStatusChange: Bool { wPortChange[6] != 0 }  // C_PORT_LINK_STATUS (USB3.0)
        var portConfigError: Bool { wPortChange[7] != 0 }       // C_PORT_CONFIG_ERROR (USB3.0)

        @inline(__always)
        init(from buffer: MMIOSubRegion) {
            let word0 = UInt16(buffer[0]) | UInt16(buffer[1]) << 8
            wPortStatus = BitArray16(word0)
            let word1 = UInt16(buffer[2]) | UInt16(buffer[3]) << 8
            wPortChange = BitArray16(word1)
        }

        @inline(__always)
        init(wPortStatus: UInt16, wPortChange: UInt16) {
            self.wPortStatus = BitArray16(wPortStatus)
            self.wPortChange = BitArray16(wPortChange)
        }

        @inline(__always)
        init(deviceAttached: Bool,
             isEnabled: Bool,
             isSuspended: Bool,
             isOverCurrent: Bool,
             isInReset: Bool,
             isPowered: Bool,
             speed: USB.Speed,
             portLinkState: UInt16 = 0, // USB3 only

             currentConnectChange: Bool,
             portEnabledChange: Bool,
             suspendChange: Bool,
             overCurrentIndicatorChanged: Bool,
             resetComplete: Bool) {

            var _wPortStatus = BitArray16()
            _wPortStatus[0] = deviceAttached ? 1 : 0
            _wPortStatus[1] = isEnabled ? 1 : 0
            _wPortStatus[2] = isSuspended ? 1 : 0
            _wPortStatus[3] = isOverCurrent ? 1 : 0
            _wPortStatus[4] = isInReset ? 1 : 0
            _wPortStatus[8] = isPowered ? 1 : 0

            switch speed {
                case .lowSpeed:
                    _wPortStatus[9] = 1

                case .fullSpeed:
                    _wPortStatus[9] = 0
                    _wPortStatus[10] = 0

                case .highSpeed:
                    _wPortStatus[10] = 1

                default:
                    // Highspeed
                    _wPortStatus[9] = isPowered ? 1 : 0
                    _wPortStatus[5...8] = portLinkState
                    break
            }
            self.wPortStatus = _wPortStatus

            var _wPortChange = BitArray16()
            _wPortChange[0] = currentConnectChange ? 1 : 0
            _wPortChange[1] = portEnabledChange ? 1 : 0
            _wPortChange[2] = suspendChange ? 1 : 0
            _wPortChange[3] = overCurrentIndicatorChanged ? 1 : 0
            _wPortChange[4] = resetComplete ? 1 : 0
            self.wPortChange = _wPortChange
        }

        func asBytes(into buffer: inout MMIOSubRegion, maxLength: Int) -> Int {
            let length = min(4, maxLength)
            let word0 = wPortStatus.rawValue
            let word1 = wPortChange.rawValue
            if length > 0 { buffer[0] = UInt8(truncatingIfNeeded: word0) }
            if length > 1 { buffer[1] = UInt8(truncatingIfNeeded: word0 >> 8) }
            if length > 2 { buffer[2] = UInt8(truncatingIfNeeded: word1) }
            if length > 3 { buffer[3] = UInt8(truncatingIfNeeded: word1 >> 8) }
            return length
        }

        func speed() -> USB.Speed {
            if !self.isPowered && self.isPoweredSS {
                // SuperSpeed hub
                return .superSpeed_gen1_x1
            } else {
                if self.isLowSpeed {
                    return .lowSpeed
                } else if self.isHighSpeed {
                    return .highSpeed
                } else {
                    return .fullSpeed
                }
            }
        }
    }
}
