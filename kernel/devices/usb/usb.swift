/*
 * kernel/devices/usb/usb.swift
 *
 * Created by Simon Evans on 21/10/2020.
 * Copyright © 2015 - 2020 Simon Evans. All rights reserved.
 *
 * USB Stack.
 *
 */


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
    func submitURB(_ urb: USB.Request) {}
    func pollPipe(_ error: Bool) -> Status { .cancelled }
    func updateMaxPacketSize(to maxPacketSize: Int) {}
}


private var _nextBusId = 1

final class USB {

    let devices: [Device] = []
    // Each HCD is a Bus and also a Root Hub
    private var rootDevices: [HCDRootHub] = []


    init() {
    }


    func nextBusId() -> Int {
        return atomic_inc(&_nextBusId)
    }

    func addRootDevice(_ rootHubDevice: HCDRootHub) -> Bool {
        guard let rootHubDriver = USBHubDriver(usbDevice: rootHubDevice) else {
            #kprint("USB: Failed to add roothub")
            return false
        }
        rootDevices.append(rootHubDevice)
        rootHubDriver.enumerate()
        return true
    }

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
                        XHCIDebug = true
                        _ = HCD_XHCI(pciDevice: pciDevice)
                        XHCIDebug = false

                    default: break
                }
            }
        }
    }
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
            switch self {
                case .lowSpeed, .fullSpeed: return 8
                case .highSpeed: return 64
                default: return 512
            }
        }

        var protocolMajor: Int {
            switch self {
                case .lowSpeed, .fullSpeed, .highSpeed: return 2
                default: return 3
            }
        }
    }
}


// Every USB Host controller is both a Bus and a Root Hub. This defines the functions that a USBDevice
// can use via it's bus
struct USBBus: CustomStringConvertible {
    let busId: Int
    let hcdData: ((USBDevice) -> HCDData)?
    let allocateBuffer: (Int) -> MMIOSubRegion
    let freeBuffer: (MMIOSubRegion) -> ()
    let allocatePipe: (USBDevice, USB.EndpointDescriptor) -> USBPipe?
    let setAddress: (USBDevice) -> UInt8?
    let submitURB: (USB.Request) -> Void
    let description: String

    init (busId: Int,
          hcdData: ((USBDevice) -> HCDData)? = nil,
          allocateBuffer: @escaping (Int) -> MMIOSubRegion,
          freeBuffer: @escaping (MMIOSubRegion) -> (),
          allocatePipe: @escaping (USBDevice, USB.EndpointDescriptor) -> USBPipe?,
          setAddress: @escaping (USBDevice) -> UInt8?,
          submitURB: @escaping (USB.Request) -> Void,
    ) {
        self.description = #sprintf("USBBUS: %d", busId)
        self.busId = busId
        self.hcdData = hcdData
        self.allocateBuffer = allocateBuffer
        self.freeBuffer = freeBuffer
        self.allocatePipe = allocatePipe
        self.setAddress = setAddress
        self.submitURB = submitURB
    }

    func allocateBuffer(length: Int) -> MMIOSubRegion {
        self.allocateBuffer(length)
    }
}

extension USB {
    struct Request {
        let usbDevice: USBDevice

        // FIXME, might be better as .control(SetupRequest, direction, buffer?) .interrupt(buffer) ...
        // FIXME: Could remove pipe, transferType and usbDevice and just do submitURB directly
        //        on the pipe instead of the device

        let transferType: EndpointDescriptor.TransferType
//        let endpointDescriptor: EndpointDescriptor
        let direction: TransferDirection    // Control requests do not use the direction in the Endpoint Descriptor
        let pipe: USBPipe
        let completionHandler: (Request, Response) -> ()
        let setupRequest: MMIOSubRegion?    // Used for control requests
        let buffer: MMIOSubRegion?
        let bytesToTransfer: Int
    }

    struct Response {
        let status: USBPipe.Status
        let bytesTransferred: Int
    }
}
