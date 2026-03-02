/*
 * kernel/devices/usb/usb.swift
 *
 * Created by Simon Evans on 21/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * USB Stack.
 *
 */

var USBTrace = false

class USBPipe {
    enum Status: CustomStringConvertible {
        case inprogress
        case cancelled
        case stalled
        case nak
        case finished  // Count of bytes trans
        case timedout

        var description: String {
            switch self {
                case .inprogress:
                    "InProgress"
                case .cancelled:
                    "Cancelled"
                case .stalled:
                    "Stalled"
                case .nak:
                    "NAK"
                case .finished:
                    "Finished"
                case .timedout:
                    "TimedOut"
            }
        }
    }

    let endpointDescriptor: USB.EndpointDescriptor


    init(endpointDescriptor: USB.EndpointDescriptor) {
        self.endpointDescriptor = endpointDescriptor
    }


    func allocateBuffer(length: Int) -> MMIOSubRegion { fatalError("Implement USBPipe.allocateBuffer") }
    func freeBuffer(_ buffer: MMIOSubRegion) {}
    func submitURB(_ urb: consuming USB.Request) {}
    func updateMaxPacketSize(to maxPacketSize: Int) {}
}

private var _nextBusId = 1

final class USB {

    // Each HCD is a Bus and also a Root Hub
    private var rootDevices: [USBDevice] = []


    init() {
    }


    func nextBusId() -> Int {
        return atomic_inc(&_nextBusId)
    }

    func addRootDevice(_ rootHubDevice: USBDevice) -> Bool {
        guard rootHubDevice.isHCD else {
            #kprintf("usb: %s is not an HCD Root Bus\n", rootHubDevice.deviceName)
            return false
        }
        guard let rootHubDriver = USBHubDriver(usbDevice: rootHubDevice) else {
            #kprint("USB: Failed to add roothub")
            return false
        }
        rootDevices.append(rootHubDevice)
        rootHubDriver.enumerate()
        return true
    }

    #if !TEST
    func initialiseDevices(rootPCIBus: PCIBus) {
        // Initialse the Host controllers. EHCI needs to be initialised
        // before UHCI due to the companion controller setup.
        // So do the controllers in the order XHCI, EHCI, UHCI
        for progIf in [PCIUSBProgrammingInterface.xhci, .ehci, .uhci] {
            #kprint("Looking for progIf", progIf.description)
            let deviceMatch: InlineArray<1, _> = [
                PCIDeviceMatch(classCode: .serialBusController,
                               subClassCode: PCISerialBusControllerSubClass.usb.rawValue,
                               programmingInterface: progIf.rawValue)
            ]
            rootPCIBus.devicesMatching(deviceMatch.span) { pciDevice in
                #kprint("USB: Found a USB HCD", pciDevice, " progIf:", progIf)
                guard pciDevice.deviceDriver == nil else { return }

                switch progIf {
                        // FIXME, get the HCDRootDebive from the driver and add it to the
                        // USB core here
                    case .uhci:
                        _ = HCD_UHCI(pciDevice: pciDevice)

                    case .ehci:
                        _ = HCD_EHCI(pciDevice: pciDevice)

                    case .xhci:
                        XHCIDebug = false
                        _ = HCD_XHCI(pciDevice: pciDevice)
                        XHCIDebug = false

                    default: break
                }
            }
        }
    }
    #endif
}


extension USB {
    enum Speed: CustomStringConvertible {
        case unknown
        case lowSpeed
        case fullSpeed
        case highSpeed
        case superSpeed_gen1_x1
        case superSpeed_gen2_x1
        case superSpeed_gen1_x2
        case superSpeed_gen2_x2

        var description: String {
            return switch self {
                case .unknown: "Unknown"
                case .lowSpeed: "LowSpeed 1.5M"
                case .fullSpeed: "FullSpeed 12M"
                case .highSpeed: "HighSpeed 480M"
                case .superSpeed_gen1_x1: "SuperSpeed 5G"
                case .superSpeed_gen1_x2: "SuperSpeed 10G"
                case .superSpeed_gen2_x1: "SuperSpeed+ 10G"
                case .superSpeed_gen2_x2: "SuperSpeed+ 20G"
            }
        }

        var slotContextSpeed: UInt32 {
            return switch self {
                case .unknown: 0
                case .lowSpeed: 2
                case .fullSpeed: 1
                case .highSpeed: 3
                default: 4
            }
        }

        var controlSize: Int {
            return switch self {
                case .unknown: 0
                case .lowSpeed, .fullSpeed: 8
                case .highSpeed: 64
                default: 512
            }
        }

        var usbMajor: UInt8 {
            switch self {
                case .unknown: 0
                case .lowSpeed, .fullSpeed: 1
                case .highSpeed: 2
                default: 3
            }
        }

        var isUSB3: Bool {
            self.usbMajor == 3
        }
    }
}


// Every USB Host controller is both a Bus and a Root Hub. This defines the functions that a USBDevice
// can use via it's bus
final class USBBus: CustomStringConvertible {
    let busId: Int
    let hcdData: ((USBDevice) -> HCDData)?
    let basePort: UInt8
    let portCount: UInt8
    let allocateBuffer: (Int) -> MMIOSubRegion
    let freeBuffer: (MMIOSubRegion) -> ()
    let allocatePipe: (USBDevice, USB.EndpointDescriptor) -> USBPipe?
    let setAddress: (USBDevice) -> UInt8?
    let description: String

    init (busId: Int,
          hcdData: ((USBDevice) -> HCDData)? = nil,
          basePort: UInt8,
          portCount: UInt8,
          allocateBuffer: @escaping (Int) -> MMIOSubRegion,
          freeBuffer: @escaping (MMIOSubRegion) -> (),
          allocatePipe: @escaping (USBDevice, USB.EndpointDescriptor) -> USBPipe?,
          setAddress: @escaping (USBDevice) -> UInt8?,
    ) {
        self.busId = busId
        self.hcdData = hcdData
        self.basePort = basePort
        self.portCount = portCount
        self.allocateBuffer = allocateBuffer
        self.freeBuffer = freeBuffer
        self.allocatePipe = allocatePipe
        self.setAddress = setAddress
        self.description = #sprintf("USBBUS: %d", busId)
    }

    func allocateBuffer(length: Int) -> MMIOSubRegion {
        self.allocateBuffer(length)
    }


    // Convert the usbDevice.port / rootPort to the physical port
    // On XHCI where there are 2 busses (2.0 and 3.0) the physical ports
    // go from 1..x but the per bus ports go from 1..y y+1..x
    func physPort(for port: UInt8) -> UInt8 {
        return self.basePort + (port - 1)
    }
}

extension USB {
    struct Request: ~Copyable {

        enum Transfer {
            // FIXME is TransferDriection needed if it is in the request
            case control(ControlRequest)
            // Send Request, with data buffer and length
            case controlWithBuffer(ControlRequest, MMIOSubRegion, UInt32)
            case interrupt(MMIOSubRegion, UInt32)
            case bulk
            case isochronous

            var bytesToTransfer: UInt32 {
                return switch self {
                    case .controlWithBuffer(_, _, let bytes): bytes
                    case .interrupt(_, let bytes): bytes
                    default: 0
                }
            }
        }

        let transfer: Transfer
        let completionHandler: (consuming Request, Response) -> ()
    }

    struct Response {
        let status: USBPipe.Status
        let bytesTransferred: UInt32
    }
}
