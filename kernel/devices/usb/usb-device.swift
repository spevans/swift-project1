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

class USBDevice: Device {
    fileprivate(set) var address: UInt8 = 0 // Default Start Address when not assigned
    private(set) var maxPacketSize0: Int
    private(set) var hcdData: HCDData?   // FIXME, could be an enum but need to fix pointers in enum bug
    private var _controlPipe: USBPipe?
    private(set) var descriptor: USB.DeviceDescriptor
    private(set) var speed: USB.Speed
    private(set) var bosDescriptor: USB.BOSDescriptor? = nil

    let bus: USBBus         // FIXME, could this just be HCDRootHub?
    let rootPort: UInt8     // The port of the HCD this is ultimatley connected to
    let port: UInt8         // The port of the hub this is connected to, if no upstream hub then == rootPort
    let routeString: UInt32 // The Route String to this device
    var isLowSpeedDevice: Bool { speed == .lowSpeed }


    override var description: String {
        #sprintf("USB %d.%u isHCDRootHub: %s",
                 bus.busId, address, self is HCDRootHub)
    }


    init?(parent: Device, bus: USBBus, port: UInt8, speed: USB.Speed,
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

        // Walk up the USB tree to determine the rootPort and routeString
        // for this device
        var _rootPort = port
        var _routeString: UInt32 = 0
        var parentDevice = parent as? USBDevice
        while let p = parentDevice, !(p is HCDRootHub) {
            _rootPort = p.port
            _routeString <<= 4
            _routeString |= UInt32(_rootPort & 0xf)
            parentDevice = p.parent as? USBDevice
        }
        self.rootPort = _rootPort
        self.routeString = _routeString >> 4  // Remove the rootPort
        self.descriptor = USB.DeviceDescriptor.init() // Add dummy for now

        super.init(parent: parent,
                   className: (parent is HCDRootHub) ? "USBDevice" : "HCDRootHub",
                   busDeviceName: #sprintf("usbdev-%d.%u", self.bus.busId, self.address)
        )
        self.hcdData = bus.hcdData?(self)

        #kprintf("usb-device: rootPort: %u port: %u routeString: %5.5x\n",
                 self.rootPort, self.port, self.routeString)
    }

    func setDescriptor(_ descriptor: USB.DeviceDescriptor) {
        self.descriptor = descriptor
    }

    func setBOSDescriptor(_ descriptor: USB.BOSDescriptor) {
        self.bosDescriptor = descriptor
    }

    override func info() -> String {
        var result = #sprintf("rootPort: %u port: %u routeString: %5.5x speed: %s",
                              self.rootPort, self.port, self.routeString,
                              self.speed.description)
        result += "\n" + descriptor.description
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

        if lastStatus == .finished {
            #kprint("USB-DEV sendControlRequestReadData returned finished")
            if let buffer {
                #kprintf("Dumping %u bytes\n", request.wLength)
                let dump = buffer.dump(maxBytes: Int(request.wLength))
                #kprint(dump)
            }
        }


        return lastStatus == .finished
    }


    func setAddress(_ newAddress: UInt8) -> Bool {
        #kprintf("%s: Setting address to: %d\n", self.deviceName, newAddress)
        let request = USB.ControlRequest.setAddress(address: newAddress)
        if sendControlRequest(request: request) {
            self.updateAddress(newAddress)
            sleep(milliseconds: 10) // Device may require some time before address takes effect
            return true
        }
        #kprintf("%s: Failed to setAddress to %d\n", self.deviceName, newAddress)
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
                    self.maxPacketSize0 = Int(descriptor.bMaxPacketSize0)
                    self.getControlPipe()?.updateMaxPacketSize(to: self.maxPacketSize0)
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

    // Only used for USB3
    func getBinaryObjectStore() -> USB.BOSDescriptor? {
        // Get an initial descriptor which will then have the size of the full descriptor.
        let length = 5
        let descriptorBuffer = bus.allocateBuffer(length: length)
        defer { bus.freeBuffer(descriptorBuffer) }

        let request1 = USB.ControlRequest.getDescriptor(descriptorType: .BINARY_OBJECT_STORE, descriptorIndex: 0, length: UInt16(length))
        guard sendControlRequestReadData(request: request1, into: descriptorBuffer) else {
            #kprint("USB-DEV: getBinaryObjectStore request1 failed")
            return nil
        }

        guard let bos1 = try? USB.BOSDescriptor(from: descriptorBuffer) else {
            #kprint("USBDEV: Failed to decode BOS descriptor packet")
                return nil
        }
        #kprint("USBDEV:", bos1)
        let infoBuffer = bus.allocateBuffer(length: Int(bos1.wTotalLength))
        defer { bus.freeBuffer(infoBuffer) }


        let request2 = USB.ControlRequest.getDescriptor(descriptorType: .BINARY_OBJECT_STORE, descriptorIndex: 0, length: bos1.wTotalLength)
        guard sendControlRequestReadData(request: request2, into: infoBuffer) else {
            #kprint("USB-DEV: getBinaryObjectStore request2 failed")
            return nil
        }

        do {
            return try USB.BOSDescriptor(from: infoBuffer)
        } catch {
            #kprint("USBDEV: Failed to decode BOS descriptor packet: ", error)
            return nil
        }
    }

    func showStrings() {

        func toString(_ utf16: [UInt16]) -> String {
            var result = ""
            result.reserveCapacity(utf16.count)
            for codeUnit in utf16 {
                if let scalar = Unicode.Scalar(UInt32(codeUnit)) {
                    result.append(Character(scalar))
                } else {
                    result.append("?")
                }
            }
            return result
        }


        do {
            if USBTrace {
                #kprint("USBDEV getting language ids")
            }
            guard let langIds = try getStringDescriptor(at: 0) else {
                #kprint("USBDEV: No language IDs found")
                return
            }
            #kprint("USBDEV: LangIDS:",
                     langIds.map { $0.hex() }.joined(separator: ", ")
            )
            let manu = self.descriptor.iManufacturer
            let prod = self.descriptor.iProduct
            let sern = self.descriptor.iSerialNumber
            #kprintf("USBDEV: iManufacturer: %d iProduct: %d iSerialNumber: %d\n", manu, prod, sern)
            for id in langIds {
                #kprintf("USBDEV: LangID: 0x%x\n", id)
                if manu > 0, let s = try getStringDescriptor(at: manu, langId: id) {
                    #kprint("USBDEV: Manufacturer:", toString(s))
                }
                if prod > 0, let s = try getStringDescriptor(at: prod, langId: id) {
                    #kprint("USBDEV: Product:     ", toString(s))
                }
                if sern > 0, let s = try getStringDescriptor(at: sern, langId: id) {
                    #kprint("USBDEV: SerialNumber:", toString(s))
                }
            }
        } catch {
            #kprint("USBDEV: Failed to get string descriptors: ", error)
        }
    }


    func getStringDescriptor(at index: UInt8, langId: UInt16 = 0) throws(USB.ParsingError) -> [UInt16]? {
        // Get an  8byte descriptor and then use this to get the ful length if needed
        let length1: UInt16 = 8
        let request1 = USB.ControlRequest.getStringDescriptor(at: index, langId: langId, length: length1)
        var buffer1 = bus.allocateBuffer(length: Int(length1))
        buffer1.clearBuffer()
        defer { bus.freeBuffer(buffer1) }

        guard sendControlRequestReadData(request: request1, into: buffer1) else {
            #kprint("USBDEV: getStringDescriptor: Failed to get descriptor length:", length1)
            return nil
        }
        if buffer1[0] <= length1 {
            return try decodeLanguageDescriptor(from: buffer1)
        }

        let length2 = UInt16(buffer1[0])
        let request2 = USB.ControlRequest.getStringDescriptor(at: index, langId: langId, length: length2)
        var buffer2 = bus.allocateBuffer(length: Int(length2))
        buffer2.clearBuffer()
        defer { bus.freeBuffer(buffer2) }

        guard sendControlRequestReadData(request: request2, into: buffer2) else {
            #kprint("USBDEV: getStringDescriptor: Failed to get descriptor length:", length2)
            return nil
        }

        return try decodeLanguageDescriptor(from: buffer2)
    }

    // For Descriptor Zero this is an array of lang IDs
    // For a Unicode String descriptor it is an array of UTF16-LE characters
    private func decodeLanguageDescriptor(from buffer: MMIOSubRegion) throws(USB.ParsingError) -> [UInt16] {
        guard buffer.count > 2, buffer[0] <= buffer.count, buffer.count.isMultiple(of: 2) else {
            throw USB.ParsingError.packetTooShort
        }

        guard buffer[1] == USB.DescriptorType.STRING.rawValue else {
            throw USB.ParsingError.packetTooShort
        }

        // Number of values
        let count = Int(buffer[0] - 2) / 2
        var values: [UInt16] = []
        values.reserveCapacity(count)
        for idx in 1...count {
            let value = UInt16(buffer[2 * idx + 1]) << 8 | UInt16(buffer[2 * idx])
            values.append(value)
        }
        return values
    }
}


// Host controllers also act as Root Hubs so need to act as a USB Device
// as well.
final class HCDRootHub: USBDevice {

    struct HCDDeviceFunctions {
        let processURB: (USB.ControlRequest, MMIOSubRegion?) -> USB.Response
    }

    private let hcd: HCDDeviceFunctions

    init?(parent: Device, bus: USBBus, hcd: HCDDeviceFunctions) {
        self.hcd = hcd
        super.init(parent: parent, bus: bus, port: 0,
                   speed: .fullSpeed, address: 1)
    }


    override func sendControlRequestReadData(
        request: USB.ControlRequest,
        into buffer: MMIOSubRegion? = nil) -> Bool
    {
        let response = self.hcd.processURB(request, buffer)
        return response.status == .finished
    }
}
