/*
 * kernel/devices/usb/usb-controlrequest.swift
 *
 * Created by Simon Evans on 20/10/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * USB Control Requests.
 *
 */


extension USB {

    enum DescriptorType: UInt8 {
        case DEVICE = 1
        case CONFIGURATION = 2
        case STRING = 3
        case INTERFACE = 4
        case ENDPOINT = 5
        case DEVICE_QUALIFIER = 6
        case OTHER_SPEED_CONFIGURATION = 7
        case INTERFACE_POWER = 8
        case HID = 0x21
        case ENDPOINT_COMPANION = 0x30
    }

    enum TransferDirection: UInt8 {
        case hostToDevice = 0
        case deviceToHost = 1
    }

    struct ControlRequest: CustomStringConvertible {

        enum RequestCode: UInt8 {
            case GET_STATUS = 0
            case CLEAR_FEATURE = 1
            case SET_FEATURE = 3
            case SET_ADDRESS = 5
            case GET_DESCRIPTOR = 6
            case SET_DESCRIPTOR = 7
            case GET_CONFIGURATION = 8
            case SET_CONFIGURATION = 9
            case GET_INTERFACE = 10
            case SET_INTERFACE = 11
            case SYNCH_FRAME = 12
        }

        enum RequestType: UInt8 {
            case standard = 0
            case klass = 1
            case vendor = 2
            case reserved = 3
        }

        enum Recipient {
            case device
            case interface(UInt8)
            case endpoint(UInt8)
            case other

            var rawValue: UInt8 {
                switch self {
                    case .device:    return 0
                    case .interface: return 1
                    case .endpoint:  return 2
                    case .other:     return 3
                }
            }

            init(rawValue: UInt8, wIndex: UInt16) {
                switch rawValue & 0x3 {
                    case 0: self = .device
                    case 1: self = .interface(UInt8(truncatingIfNeeded: wIndex))
                    case 2: self = .endpoint(UInt8(truncatingIfNeeded: wIndex))
                    case 3: self = .other
                    default: self = .other
                }
            }

            // calculate wIndex used for certain requests
            func zeroInterfaceOrEndpoint(direction: TransferDirection) -> UInt16 {
                let wIndex: UInt16

                switch self {
                    case .device:
                        wIndex = 0

                    case .interface(let interface):
                        wIndex = UInt16(interface)

                    case .endpoint(let endpoint):
                        precondition(endpoint < 16)
                        if case .deviceToHost = direction {
                            wIndex = UInt16(endpoint) | (1 << 8)
                        } else {
                            wIndex = UInt16(endpoint)
                        }

                    case .other: fatalError("Recipient .other not valid")
                }
                return wIndex
            }

            func interface() -> UInt16 {
                guard case .interface(let interface) = self else { fatalError("Recipient is not an interface") }
                return UInt16(interface)
            }

            func endpoint(direction: TransferDirection) -> UInt16 {
                guard case .endpoint(let endpoint) = self else { fatalError("Recipient is not an endpoint") }
                if case .deviceToHost = direction {
                    return UInt16(endpoint) | (1 << 8)
                } else {
                    return UInt16(endpoint)
                }
            }
        }

        enum FeatureSelector: UInt16 {
            case ENDPOINT_HALT = 0
            case DEVICE_REMOTE_WAKEUP = 1
            case TEST_MODE = 2
        }

        struct BMRequestType {
            private let bits: BitArray8
            private let wIndex: UInt16
            var rawValue: UInt8 { bits.rawValue }

            init(direction: TransferDirection, requestType: RequestType, recipient: Recipient) {
                var _bits = BitArray8(0)
                _bits[0...4] = recipient.rawValue
                _bits[5...6] = requestType.rawValue
                _bits[7] = Int(direction.rawValue)
                bits = _bits
                wIndex = 0
            }

            init(rawValue: UInt8, wIndex: UInt16) {
                bits = BitArray8(rawValue)
                self.wIndex = wIndex
            }

            var recipient: Recipient { Recipient(rawValue: UInt8(bits[0...1]), wIndex: wIndex) }
            var requestType: RequestType { RequestType(rawValue: UInt8(bits[5...6]))! }
            var direction: TransferDirection { TransferDirection(rawValue: UInt8(bits[7]))! }
        }


        var description: String {
            let bmreq = BMRequestType(rawValue: request.bmRequestType, wIndex: request.wIndex)
            return "\(RequestCode(rawValue: request.bRequest)!)(\(bmreq.recipient),\(bmreq.requestType),\(bmreq.direction.rawValue)) wValue: \(request.wValue) wIndex: \(request.wIndex) wLength: \(request.wLength)"
        }

        // The request is defined in usb.h so that the structure can be packed.
        private let request: usb_control_request
        var wLength: UInt16 { request.wLength }
        var direction: TransferDirection { BMRequestType(rawValue: request.bmRequestType, wIndex: request.wIndex).direction }

        private init(request: usb_control_request) {
            self.request = request
        }


        static func getStatus(recipient: Recipient) -> ControlRequest {
            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: .deviceToHost, requestType: .standard, recipient: recipient).rawValue,
                bRequest: RequestCode.GET_STATUS.rawValue,
                wValue: 0,
                wIndex: recipient.zeroInterfaceOrEndpoint(direction: .hostToDevice),
                wLength: 2
            ))
        }

        static func clearFeature(recipient: Recipient, selector: FeatureSelector) -> ControlRequest {
            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: .hostToDevice, requestType: .standard, recipient: recipient).rawValue,
                bRequest: RequestCode.CLEAR_FEATURE.rawValue,
                wValue: selector.rawValue,
                wIndex: recipient.zeroInterfaceOrEndpoint(direction: .hostToDevice),
                wLength: 0
            ))
        }

        static func setFeature(recipient: Recipient, selector: FeatureSelector, testMode: UInt8 = 0) -> ControlRequest {
            if case .TEST_MODE = selector, testMode == 0 { fatalError("setFeature: TEST_MODE seelct with reserved testMode") }

            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: .hostToDevice, requestType: .standard, recipient: recipient).rawValue,
                bRequest: RequestCode.SET_FEATURE.rawValue,
                wValue: selector.rawValue,
                wIndex: recipient.zeroInterfaceOrEndpoint(direction: .hostToDevice) | UInt16(testMode) << 8,
                wLength: 0
            ))
        }

        static func setAddress(address: UInt8) -> ControlRequest {
            guard address <= 127 else { fatalError("setAddress \(address) is > 127") }

            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: .hostToDevice, requestType: .standard, recipient: .device).rawValue,
                bRequest: RequestCode.SET_ADDRESS.rawValue,
                wValue: UInt16(address),
                wIndex: 0,
                wLength: 0
            ))
        }

        static func getDescriptor(descriptorType: DescriptorType, descriptorIndex: UInt8, length: UInt16) -> ControlRequest {
            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: .deviceToHost, requestType: .standard, recipient: .device).rawValue,
                bRequest: RequestCode.GET_DESCRIPTOR.rawValue,
                wValue: UInt16(descriptorType.rawValue) << 8 | UInt16(descriptorIndex),
                wIndex: 0,
                wLength: length
            ))
        }

        static func setDescriptor(descriptorType: DescriptorType, descriptorIndex: UInt8, length: UInt16) -> ControlRequest {
            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: .deviceToHost, requestType: .standard, recipient: .device).rawValue,
                bRequest: RequestCode.SET_DESCRIPTOR.rawValue,
                wValue: UInt16(descriptorType.rawValue) << 8 | UInt16(descriptorIndex),
                wIndex: 0,
                wLength: length
            ))
        }

        static func getConfiguration() -> ControlRequest {
            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: .deviceToHost, requestType: .standard, recipient: .device).rawValue,
                bRequest: RequestCode.GET_CONFIGURATION.rawValue,
                wValue: 0,
                wIndex: 0,
                wLength: 1
            ))
        }

        static func setConfiguration(configuration: UInt8) -> ControlRequest {
            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: .hostToDevice, requestType: .standard, recipient: .device).rawValue,
                bRequest: RequestCode.SET_CONFIGURATION.rawValue,
                wValue: UInt16(configuration),
                wIndex: 0,
                wLength: 0
            ))
        }

        static func getInterface(interface: UInt8) -> ControlRequest {
            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: .deviceToHost, requestType: .standard, recipient: .interface(interface)).rawValue,
                bRequest: RequestCode.GET_INTERFACE.rawValue,
                wValue: 0,
                wIndex: UInt16(interface),
                wLength: 1
            ))
        }

        static func setInterface(interface: UInt8, newValue: UInt16) -> ControlRequest {
            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: .hostToDevice, requestType: .standard, recipient: .interface(interface)).rawValue,
                bRequest: RequestCode.SET_INTERFACE.rawValue,
                wValue: newValue,
                wIndex: UInt16(interface),
                wLength: 0
            ))
        }

        static func syncFrame() -> ControlRequest {
            return ControlRequest(request: usb_control_request())
        }

        static func classSpecificRequest(direction: TransferDirection, recipient: Recipient, bRequest: UInt8, wValue: UInt16, wLength: UInt16) -> ControlRequest {
            return ControlRequest(request: usb_control_request(
                bmRequestType: BMRequestType(direction: direction, requestType: .klass, recipient: recipient).rawValue,
                bRequest: bRequest,
                wValue: wValue,
                wIndex: recipient.interface(),
                wLength: wLength
            ))
        }
    }
}
