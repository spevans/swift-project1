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
    private(set) var speed: USB.Speed
    private(set) var controlPipe: USBPipe
    private(set) var deviceDescriptor: USB.DeviceDescriptor
    private(set) var bosDescriptor: USB.BOSDescriptor? = nil
    private(set) var configDescriptor: USB.ConfigDescriptor? = nil
    private(set) var manufacturer: String?
    private(set) var product: String?
    private(set) var serialNumber: String?

    let bus: USBBus         // FIXME, could this just be HCDRootHub?
    let rootPort: UInt8     // The port of the HCD this is ultimatley connected to
    let port: UInt8         // The port of the hub this is connected to, if no upstream hub then == rootPort
    let depth: UInt8        // Only needed for hub Root is depth 0
    let routeString: UInt32 // The Route String to this device
    var isLowSpeedDevice: Bool { speed == .lowSpeed }
    var isUSB3Device: Bool { deviceDescriptor.usbMajor == 3 }
    var isHCD: Bool { depth == 0 }


    override var description: String {
        let plus = UInt8(ascii: "+")
        let minus = UInt8(ascii: "-")

        // FIXME: Bodge around #kprintf argument count limit
        let strings = #sprintf("%s %s %s", self.manufacturer ?? "",
                               self.product ?? "",
                               self.serialNumber ?? "")
        let deviceClass = #sprintf("%2.2x/%2.2x", self.deviceDescriptor.bDeviceClass,
                             self.deviceDescriptor.bDeviceSubClass
                             )
        return #sprintf("USB %d.%u HCD%c bus%c %s %d.%d %4.4x:%4.4x class: %s %s",
                        bus.busId, address, self.isHCD ? plus : minus,
                        self.isBus ? plus : minus, self.speed.description,
                        self.deviceDescriptor.usbMajor,
                        self.deviceDescriptor.usbMinor,
                        self.deviceDescriptor.idVendor,
                        self.deviceDescriptor.idProduct,
                        deviceClass, strings)
    }


    init?(parent: Device, bus: USBBus, port: UInt8, depth: UInt8,
          speed: USB.Speed, address: UInt8? = nil) {
        self.bus = bus
        self.port = port
        self.depth = depth
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
        var _routeString = UInt32(bus.physPort(for: _rootPort))
        var parentDevice = parent as? USBDevice
        while let p = parentDevice, !(p.isHCD) {
            _rootPort = p.port
            _routeString <<= 4
            _routeString |= UInt32(bus.physPort(for: _rootPort) & 0xf)
            parentDevice = p.parent as? USBDevice
        }
        self.rootPort = _rootPort
        self.routeString = _routeString >> 4  // Remove the rootPort
        self.deviceDescriptor = USB.DeviceDescriptor.init(usbMajor: speed.usbMajor) // Add dummy for now

        let endPoint = USB.EndpointDescriptor(
            endPoint: 0,
            direction: .hostToDevice,
            // FIXME, might be different for USB3
            maxPacketSize: UInt16(self.maxPacketSize0),
            interval: 0
        )
        self.controlPipe = USBPipe(endpointDescriptor: endPoint) // Dummy until after super call
        super.init(parent: parent,
                   className: "USBDevice",
                   busDeviceName: #sprintf("usbdev-%d.%u", self.bus.busId, self.address)
        )
        self.hcdData = bus.hcdData?(self)
        guard self.initialise() else {
            #kprint("usbdev: Failed to initialise device:", self.description)
            return nil
        }
        #kprint("usbdev: Found:", self.description)
        #kprintf("usbdev: depth: %u, rootPort: %u port: %u speed: %s routeString: %5.5x\n",
                 self.depth, self.rootPort, self.port, self.speed.description,
                 self.routeString)
    }

    // Used by Root HCD
    init?(parent: Device, bus: USBBus, speed: USB.Speed, address: UInt8) {
        self.bus = bus
        self.rootPort = 0
        self.port = 0
        self.routeString = 0
        self.depth = 0
        self.speed = speed
        self.hcdData = nil
        // Contol Pipe
        self.maxPacketSize0 = speed.controlSize
        // HUB Device Descriptor
        self.deviceDescriptor = USB.DeviceDescriptor(usbMajorHub: speed.usbMajor)
        let endPoint = USB.EndpointDescriptor(
            endPoint: 0,
            direction: .hostToDevice,
            // FIXME, might be different for USB3
            maxPacketSize: UInt16(self.maxPacketSize0),
            interval: 0
        )
        self.controlPipe = USBPipe(endpointDescriptor: endPoint) // Dummy until after super call
        super.init(parent: parent,
                   className: "USBDevice",
                   busDeviceName: #sprintf("usbhcd-%d.%u", self.bus.busId, self.address)
        )
        self.setAsBus()
        guard self.initialise() else { return nil }
    }

    private func initialise() -> Bool {
        guard let pipe = self.allocatePipe(self.controlPipe.endpointDescriptor) else {
            #kprint("usbdev: Failed to allocate pipe")
            return false
        }
        self.controlPipe = pipe

        // Get initial 8byte device descriptor
        guard let deviceDescriptor = self.getInitialDeviceDescriptor() else {
            return false
        }

        if USBTrace {
            #kprintf("usbdev: %s deviceDescriptor: %s\n", self.description,
                     deviceDescriptor.description)
        }
        guard deviceDescriptor.bLength != 0 else {
            fatalError("usbdev: info8 returned zero length bLength")
        }

        // Set address of device
        if USBTrace {
            #kprintf("usbdev: %s Setting address of device\n", self.description)
        }
        guard let address = self.bus.setAddress(self) else {
            #kprint("usbdev: Failed to set address of device - ignoring device")
            return false
        }
        if USBTrace {
            #kprintf("usbdev: %s set to address %u\n", self.description, address)
        }

        // Get full DeviceDescriptor
        if USBTrace {
            #kprintf("usbdev: %s Getting full DeviceDescriptor of length: %u\n",
                     self.description, deviceDescriptor.bLength)
        }
        guard let fullDeviceDescriptor = self.getDeviceDescriptor(length: UInt16(deviceDescriptor.bLength)) else {
            if USBTrace {
                #kprint("usbdaev: Failed to get full DeviceDescriptor")
            }
            return false
        }
        if USBTrace {
            #kprint("usbdev: fullDeviceDescriptor:", fullDeviceDescriptor)
        }
        self.deviceDescriptor = fullDeviceDescriptor

        if USBTrace {
            #kprint("\nusbdev: Getting ConfigurationDescriptor")
        }
        guard let _configDescriptor = self.getConfigurationDescriptor() else {
            #usbhubDebug("usbdev: Failed to get device ConfigurationDescriptor of device on port: \(port) - ignoring device")
            return false
        }
        if USBTrace {
            #kprintf("usbdev: configDescriptor: %s\n", _configDescriptor.description)
        }
        self.configDescriptor = _configDescriptor
        if self.isUSB3Device {
            if USBTrace {
                #kprint("usbdev: Getting BOS Descriptor")
            }
            guard let _bosDescriptor = self.getBinaryObjectStore() else {
                #kprintf("usbdev: Failed to get BOS Descriptor of device on port: %u - ignoring device\n", self.port)
                return false
            }
            if USBTrace {
                #kprint("USB: BOS Descriptor", _bosDescriptor)
            }
            self.bosDescriptor = _bosDescriptor
        }
        self.getStrings()

        return true
    }

    private func getInitialDeviceDescriptor() -> USB.DeviceDescriptor? {
        for _ in 1...2 {
            if let deviceDescriptor = self.getDeviceDescriptor(length: 8) {
                return deviceDescriptor
            }
            sleep(milliseconds: 20)
        }
        return nil
    }

    override func info() -> String {
        var result = #sprintf("rootPort: %u port: %u routeString: %5.5x speed: %s",
                              self.rootPort, self.port, self.routeString,
                              self.speed.description)
        result += "\n" + self.deviceDescriptor.description
        return result
    }

    func allocatePipe(_ endpoint: USB.EndpointDescriptor) -> USBPipe? {
        return self.bus.allocatePipe(self, endpoint)
    }

    // FIXME: Should these 2 functions return USB.Response?
    func sendControlRequest(request: USB.ControlRequest) -> Bool {
        return self._sendControlRequestReadData(request, into: nil)
    }

    func sendControlRequestReadData(request: USB.ControlRequest, into buffer: MMIOSubRegion) -> Bool {
        return self._sendControlRequestReadData(request, into: buffer)
    }

    private func _sendControlRequestReadData(_ request: USB.ControlRequest, into buffer: MMIOSubRegion? = nil) -> Bool {
        if buffer != nil, request.wLength == 0 {
            fatalError("usbdev: sendControlRequestReadData wLength is 0!")
        }

        if USBTrace {
            #kprint("USB-DEV: \(self.bus.busId)-\(self.address).0 Sending request:", request)
        }

        let transfer: USB.Request.Transfer = if let buffer {
            .controlWithBuffer(request, buffer, UInt32(request.wLength))
        } else {
            .control(request)
        }

        var lastStatus: USBPipe.Status?
        let urb = USB.Request(
            transfer: transfer,
            completionHandler: { (urb, response) in
                lastStatus = response.status
            },
        )
        self.controlPipe.submitURB(urb)

        while lastStatus == nil {
            sleep(milliseconds: 10)
        }

        if lastStatus == .finished {
            if USBTrace {
                #kprint("USB-DEV sendControlRequestReadData returned finished")
                if let buffer {
                    #kprintf("Dumping %u bytes\n", request.wLength)
                    let dump = buffer.dump(maxBytes: Int(request.wLength))
                    #kprint(dump)
                }
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
        if USBTrace {
            #kprint("Created deviceDescriptor request for info8, length:", request.wLength)
        }

        var infoBuffer = bus.allocateBuffer(length: Int(length))
        infoBuffer.clearBuffer()
        defer { bus.freeBuffer(infoBuffer) }

        guard sendControlRequestReadData(request: request, into: infoBuffer) else {
            #kprint("usbdev: getDeviceDescriptor: Failed to get descriptor length:", length)
            return nil
        }

        let descriptor = USB.DeviceDescriptor(from: infoBuffer)
        if Int(descriptor.bMaxPacketSize0) > maxPacketSize0 {
            // An Enhanced SuperSpeed device shall set the bMaxPacketSize0 field to 09H (see Table 9-11)
            // indicating a 512-byte maximum packet. An Enhanced SuperSpeed device shall not support
            // any other maximum packet sizes for the default control pipe (endpoint 0) control endpoint .
            let newMaxPacketSize0: Int
            if self.isUSB3Device {
                guard descriptor.bMaxPacketSize0 == 0x09 else {
                    // Die for now
                    fatalError("USB-DEV: Device protocol \(descriptor.bDeviceProtocol) has bMaxPacketSize0 \(descriptor.bMaxPacketSize0) which is not supported")
                }
                newMaxPacketSize0 = 512
            } else {
                newMaxPacketSize0 = Int(descriptor.bMaxPacketSize0)
            }

            // For Control Pipes update the maxPacketSize0 if new data is available
            #kprintf("USB-DEV: Updating Control Pipe max Packet size from %d to %d\n", maxPacketSize0, newMaxPacketSize0)

            // Validate the speeds
            switch (speed, newMaxPacketSize0) {
                case (.lowSpeed, 8),
                    (.fullSpeed, 8), (.fullSpeed, 16), (.fullSpeed, 32), (.fullSpeed, 64),
                    (.highSpeed, 64),
                    (.superSpeed_gen1_x1, 512), (.superSpeed_gen1_x2, 512),
                    (.superSpeed_gen2_x1, 512), (.superSpeed_gen2_x2, 512):
                    self.maxPacketSize0 = newMaxPacketSize0
                    self.controlPipe.updateMaxPacketSize(to: self.maxPacketSize0)
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

        let configDescriptor1: USB.ConfigDescriptor
        do {
            configDescriptor1 = try USB.ConfigDescriptor(from: descriptorBuffer)
        } catch {
            #kprint("usbdev: Failed to decode CONFIGURATION descriptor packet1:", error)
            #kprint(descriptorBuffer.dump(maxBytes: descriptorBuffer.count, perLine: 32))
                return nil
        }
        let infoBuffer = bus.allocateBuffer(length: Int(configDescriptor1.wTotalLength))
        defer { bus.freeBuffer(infoBuffer) }

        let deviceConfigRequest2 = USB.ControlRequest.getDescriptor(descriptorType: .CONFIGURATION, descriptorIndex: 0, length: configDescriptor1.wTotalLength)
        guard sendControlRequestReadData(request: deviceConfigRequest2, into: infoBuffer) else {
            #kprint("usbdev: getConfigurationDescriptor request2 failed")
            return nil
        }

        do {
            let configDescriptor2 = try USB.ConfigDescriptor(from: infoBuffer)
            return configDescriptor2
        } catch {
            #kprint("usbdev: Failed to decode CONFIGURATION descriptor packet2:", error)
            #kprint(infoBuffer.dump(maxBytes: infoBuffer.count, perLine: 32))
            return nil
        }
    }

    func setConfiguration(to configuration: UInt8) -> Bool {
        if USBTrace {
            #kprint("usbdev: Setting configuration to:", configuration)
        }
        let request = USB.ControlRequest.setConfiguration(configuration: configuration)
        guard sendControlRequest(request: request) else {
            #kprint("usbdev: Failed to set configuration")
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
            #kprint("usbdev: Failed to decode BOS descriptor packet")
                return nil
        }
        if USBTrace {
            #kprint("usbdev:", bos1)
        }
        let infoBuffer = bus.allocateBuffer(length: Int(bos1.wTotalLength))
        defer { bus.freeBuffer(infoBuffer) }


        let request2 = USB.ControlRequest.getDescriptor(descriptorType: .BINARY_OBJECT_STORE, descriptorIndex: 0, length: bos1.wTotalLength)
        guard sendControlRequestReadData(request: request2, into: infoBuffer) else {
            #kprint("usbdev: getBinaryObjectStore request2 failed")
            return nil
        }

        do {
            return try USB.BOSDescriptor(from: infoBuffer)
        } catch {
            #kprint("usbdev: Failed to decode BOS descriptor packet: ", error)
            return nil
        }
    }

    func getStrings() {

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
            // Remove trailing whitespace
            while let ch = result.last, ch == " " || ch == "\n" {
                result.removeLast()
            }
            return result
        }


        do {
            let manu = self.deviceDescriptor.iManufacturer
            let prod = self.deviceDescriptor.iProduct
            let sern = self.deviceDescriptor.iSerialNumber
            if USBTrace {
                #kprintf("usbdev: iManufacturer: %d iProduct: %d iSerialNumber: %d\n",
                         manu, prod, sern)
                #kprint("usbdev getting language ids")

            }
            guard let langIds = try getStringDescriptor(at: 0) else {
                if USBTrace {
                    #kprint("usbdev: No language IDs found")
                }
                return
            }
            for id in langIds {
                if manu > 0, self.manufacturer == nil, let s = try getStringDescriptor(at: manu, langId: id) {
                    self.manufacturer = toString(s)
                }
                if prod > 0, self.product == nil, let s = try getStringDescriptor(at: prod, langId: id) {
                    self.product = toString(s)
                }
                if sern > 0, self.serialNumber == nil, let s = try getStringDescriptor(at: sern, langId: id) {
                    self.serialNumber = toString(s)
                }
            }
        } catch {
            #kprint("usbdev: Failed to get string descriptors: ", error)
        }
        if USBTrace {
            #kprintf("usbdev: Manufacturer: %s Porduct: %s SerialNumber: %s\n",
                     self.manufacturer ?? "", self.product ?? "", self.serialNumber ?? "")
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
            if USBTrace {
                #kprint("usbdev: getStringDescriptor: Failed to get descriptor length:", length1)
            }
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
            if USBTrace {
                #kprint("usbdev: getStringDescriptor: Failed to get descriptor length:", length2)
            }
            return nil
        }

        return try decodeLanguageDescriptor(from: buffer2)
    }

    // For Descriptor Zero this is an array of lang IDs
    // For a Unicode String descriptor it is an array of UTF16-LE characters
    private func decodeLanguageDescriptor(from buffer: MMIOSubRegion) throws(USB.ParsingError) -> [UInt16]? {
        let bLength = buffer[0]
        guard buffer.count > 2, bLength <= buffer.count, bLength.isMultiple(of: 2) else {
            throw USB.ParsingError.packetTooShort
        }

        guard buffer[1] == USB.DescriptorType.STRING.rawValue else {
            throw USB.ParsingError.packetTooShort
        }

        guard bLength > 2 else { return nil }

        // Number of values (bLength is even, verified above)
        let count = Int(bLength - 2) / 2
        var values: [UInt16] = []

        values.reserveCapacity(count)
        for idx in 1...count {
            let value = UInt16(buffer[2 * idx + 1]) << 8 | UInt16(buffer[2 * idx])
            values.append(value)
        }
        return values
    }
}
