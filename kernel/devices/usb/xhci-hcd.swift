/*
 * kernel/devices/usb/xhci-hcd.swift
 *
 * Created by Simon Evans on 05/10/2020.
 * Copyright © 2015 - 2025 Simon Evans. All rights reserved.
 *
 * XHCI HCD driver.
 *
 */

private var _xhciNumber = 0

final class HCD_XHCI: DeviceDriver {
    private let pciDevice: PCIDevice
    private let mmioRegion: MMIORegion
    private let capabilities: CapabilityRegisters
    private var operationRegs: OperationRegisters
    private var runtimeRegs: RuntimeRegisters
    private let primaryIRQ: IRQSetting
    private var commandRing: ProducerRing<CommandTRB>
    private var lastCommandCompletion: EventTRB.CommandCompletion?
    private var deviceData: InlineArray<128, XHCIDeviceData?> = .init(repeating: nil)

    private var eventRing0: EventRing
    let allocator: XHCIAllocator
    let doorbells: DoorbellRegisters


    init?(pciDevice: PCIDevice) {
        #kprint("xhci: init")
        guard pciDevice.deviceFunction.deviceClass == PCIDeviceClass(
            classCode: .serialBusController,
            subClassCode: PCISerialBusControllerSubClass.usb.rawValue,
            progInterface: PCIUSBProgrammingInterface.xhci.rawValue) else
        {
            #kprint("xhci: \(pciDevice) is not an XHCI Device")
            return nil
        }

        guard pciDevice.deviceFunction.generalDevice != nil else {
            #kprint("xhci: Not a PCI generalDevice")
            return nil
        }

        // Find the Interrupt
        guard let interrupt = pciDevice.requestMSI(vectorStart: 0x60) else {
            #kprintf("xhci: %s: Failed to find interrupt\n", pciDevice.deviceName)
            return nil
        }
        guard let pciIO = pciDevice.ioRegionFor(barIdx: 0), pciIO.bar.isMemory else {
            #kprint("xhci: No IO region for BAR0 or not memory")
            return nil
        }

        self.pciDevice = pciDevice
        self.primaryIRQ = interrupt

        var deviceFunction = pciDevice.deviceFunction
        #kprintf("xhci: Assigned IRQ: %d\n", interrupt.irq)
        deviceFunction.interruptLine = UInt8(interrupt.irq)

        #kprint("xhci: BAR0:", pciIO)
        let region = PhysRegion(start: PhysAddress(RawAddress(pciIO.baseAddress)), size: UInt(pciIO.size))
        self.mmioRegion = mapIORegion(region: region, cacheType: .uncacheable)

        // Capability Registers
        self.capabilities = CapabilityRegisters(mmioRegion)
        #kprintf("xhci: Register Region:\t%s\n\tCapability:\t0x00000000/0x%x\n", region.description, UInt(capabilities.capLength))

        // Operational Registers
        let opRegOffset = (capabilities.capLength + 3) & ~3  // Round to DWORD aligned
        let opRegSize = 0x400 + (capabilities.maxPorts * 0x10)
        let opRegRegion = mmioRegion.mmioSubRegion(offset: opRegOffset, count: opRegSize)
        self.operationRegs = OperationRegisters(mmioRegion: opRegRegion)
        #kprintf("\tOperation:\t0x%8.8x/0x%x\n", UInt(opRegOffset), UInt(opRegSize))

        // Runtime Registers
        let runtimeRegRegion = mmioRegion.mmioSubRegion(offset: Int(capabilities.rtsOff), count: capabilities.runtimeRegisterSize)
        self.runtimeRegs = RuntimeRegisters(mmioRegion: runtimeRegRegion)
        #kprintf("\tRuntime:\t0x%8.8x/0x%x\n", UInt(capabilities.rtsOff), UInt(capabilities.runtimeRegisterSize))

        // Doorbell Registers
        let doorbellRegOffset = Int(capabilities.doorbellOffset)
        let doorbellRegSize = (capabilities.maxSlots + 1) * MemoryLayout<UInt32>.size
        let doorbellRegion = mmioRegion.mmioSubRegion(offset: doorbellRegOffset, count: doorbellRegSize)
        self.doorbells = DoorbellRegisters(doorbellRegion)
        #kprintf("\tDoorbells:\t0x%8.8x/0x%x\n", UInt(doorbellRegOffset), UInt(doorbellRegSize))

        #kprintf("xhci: maxSlots: %d maxIntrs: %d maxPorts: %d scratchPadRestore: %s maxScratchPadBuffers: %d\n",
                 capabilities.maxSlots,
                 capabilities.maxIntrs,
                 capabilities.maxPorts,
                 capabilities.scratchPadRestore,
                 capabilities.maxScratchPadBuffers
        )
        #kprintf("xhci: PageSize: %d 64Address: %s contextSize: %d\n",
                 operationRegs.pageSize,
                 capabilities.has64BitAddressing,
                 capabilities.contextSize)

        // Create Event Ring for the primary interrupter
        let interrupter0mmio = mmioRegion.mmioSubRegion(offset: Int(capabilities.rtsOff) + 0x20, count: 0x20)
        self.eventRing0 = EventRing(interrupter: interrupter0mmio)
        self.commandRing = ProducerRing()

        // Allocator for other buffers and device contexts that get allocated later
        self.allocator = XHCIAllocator(capabilities)
        super.init(driverName: "xhci", device: pciDevice)
        let handler = InterruptHandler(name: "xhci-hcd", handler: xhciInterrupt)
        system.deviceManager.setIrqHandler(handler, forInterrupt: interrupt)
        guard self.initialise() else {
            system.deviceManager.removeIrqHandler(handler, forInterrupt: interrupt)
            return nil
        }
    }


    private func initialise() -> Bool {
        var deviceFunction = self.pciDevice.deviceFunction

        var pciCommand = deviceFunction.command
        pciCommand.ioSpace = false
        pciCommand.memorySpace = true
        pciCommand.interruptDisable = true
        pciCommand.busMaster = true
        deviceFunction.command = pciCommand

        // Get device from BIOS ownership if necessary
        if var legacySupport = capabilities.legacySupport {
            #kprint("xhci: Have leagacy support:", legacySupport.description)
            var count = 20
            while legacySupport.biosOwned && count > 0 {
                legacySupport.osOwned = false
                sleep(milliseconds: 50)
                count -= 1
            }
            if legacySupport.biosOwned {
                #kprint("xhci: Failed to relinquish BIOS ownership")
                return false
            }
            #kprint("xhci: Relinquished BIOS ownership", legacySupport.description)
        }

        // Reset the controller
        // Clear Run/Stop bit
        var cmd = operationRegs.usbCmd
        cmd &= 1
        operationRegs.usbCmd = cmd

        // Wait for HCHalted to be set
        var timeout = 20
        var sts = operationRegs.usbSts
        while !sts.bit(0) && timeout > 0 {
            sleep(milliseconds: 1)
            timeout -= 1
        }
        guard sts.bit(0) else {
            #kprint("xhchi: Reset failed, HCHaled not set")
            return false
        }

        // Set HCReset
        cmd |= 2
        operationRegs.usbCmd = cmd
        // Wait for this bit and usbStatus.controllerNotReady to be 0
        timeout = 20
        while timeout > 0 {
            sleep(milliseconds: 11)
            cmd = operationRegs.usbCmd
            if cmd.bit(1) { continue }
            sts = operationRegs.usbSts
            if sts.bit(11) { continue }
            break
        }
        guard !cmd.bit(1) else {
            #kprint("xhci: Reset failed, HCReset not cleared")
            return false
        }
        guard !sts.bit(11) else {
            #kprint("xhci: Reset failed, controllerNotReady not cleared")
            return false
        }

        #kprint("xhci: Reset complete")

        // Set Max Device Slots in Config
        var config = operationRegs.config
        config &= ~0xff
        config |= UInt32(capabilities.maxSlots)
        operationRegs.config = config
        operationRegs.dcbaap = UInt64(allocator.deviceContextIndexAddress)
        operationRegs.crcr = UInt64(commandRing.ringBaseAddress.value) | 1    // set cycle bit

        // Setup runtime registers
        eventRing0.setupInterrupter()

        // Enable interrupts and set RunStop
        cmd = operationRegs.usbCmd
        cmd |= 1 << 0   // set R/S to 1
        cmd |= 1 << 2   // Set Interrupter Enable
        operationRegs.usbCmd = cmd

        #kprint("xhci: Enabled Interrupts")
        //        deviceFunction.interruptLine = UInt8(interrupt.irq)
        #kprint("xhci: Found HCD:", self.pciDevice.deviceName)

        let busId = system.deviceManager.usb!.nextBusId()
        let usbBus = USBBus(
            busId: busId,
            hcdData: { XHCIDeviceData(hcd: self, device: $0) },
            allocateBuffer: { self.allocator.allocPhysBuffer(length: $0) },
            freeBuffer: { self.allocator.freePhysBuffer($0) },
            allocatePipe: {
                #kprint("USBBus.allocatePipe() called")
                return self.allocatePipe(device: $0, endpointDescriptor: $1)
            },
            setAddress: { usbDevice in self.setAddress(on: usbDevice) },
            submitURB: { urb in urb.pipe.submitURB(urb) },
        )

        guard let rootHubDevice = HCDRootHub(
            parent: self.pciDevice,
            bus: usbBus,
            hcd: HCDRootHub.HCDDeviceFunctions(
                processURB: { self.processURB($0, into: $1) }
            )
        ) else {
            #kprint("xhci: Failed to create root hub device")
            return false
        }
        #kprint("xhci: created rootHubDevice")
        let instance = atomic_inc(&_xhciNumber)
        self.setInstanceName(to: "xhci-hcd\(instance)")
        return system.deviceManager.usb!.addRootDevice(rootHubDevice)
    }

    private func setAddress(on usbDevice: USBDevice) -> UInt8? {
        guard let deviceData = usbDevice.hcdData as? XHCIDeviceData else {
            #kprint("xhci: Failed to get device data")
            return nil
        }
        // Configure the EP0
        let inputContext = deviceData.inputDeviceContext()
        let value = UInt32(1 << 1) | 1
        inputContext.write(value: value, toByteOffset: 4)
        // Configure the EP0 inputContext, used for Address Device command

        let slotCtxOffset = allocator.contextSize   // Offset to Slot 1 (EP0)
        let slotContext = SlotContext(
            routeString: usbDevice.routeString, speed: usbDevice.speed,
            interrupter: 0, rootHubPort: usbDevice.rootPort
        )
        // Set the Input Device Context
        for idx in 0...3 {
            let offset = slotCtxOffset + (idx * 4)
            inputContext.write(value: slotContext.dwords[idx], toByteOffset: offset)
        }

        // Send an Address Device command and SET_ADDRESS to the device
        let trb = CommandTRB.addressDevice(deviceData.slotId, inputContext.baseAddress, blockSetAddress: false)
        #kprint("xhci: setting address")
        guard let _ = writeCommandTRB(trb) else {
            #kprint("Failed to send command TRB")
            return nil
        }

        // Read back the Device Context
        let deviceContext = deviceData.deviceContext
        #kprintf("inputContext: %p   deviceContext address: %p\n",
                 inputContext.baseAddress.value, deviceContext.baseAddress.value)
        var contextData: InlineArray<4, UInt32> = [0, 0, 0, 0]
        // Read from slot 0
        for idx in 0...3 {
            let offset = (idx * 4)
            contextData[idx] = deviceContext.read(fromByteOffset: offset)
        }

        let context = SlotContext(dwords: contextData)
        #kprintf("xhci-setAddress slotState: %d address: %u\n", context.slotState, context.address)
        usbDevice.updateAddress(context.address)
        return context.address
    }


    private func xhciInterrupt() -> Bool {
        var status = self.operationRegs.usbSts
//        #kprintf("*** xhci-irq: Interrupt status: 0x%8.8x\n", status)
        if !status.bit(3) {
            #kprint("*** xhci-irq: no EINT")
            return false
        }

        if status.bit(12) {
            #kprint("*** xhci-irq: host controller error")
            return true
        }

        if status.bit(2) {
            #kprint("*** xhci-irq: serious Host error")
            return true
        }

        // Clear the interrupt
        status |= 8
        self.operationRegs.usbSts = status
        handleEvents()
//            eventRing0.clearInterrupterPending() -- Only needed on PCI INTx IRQ not MSI

//        #kprint("*** xhci-irq: EOI")
        return true
    }


    private func handleEvents() {

        var eventCount = 0
        while let eventTrb = eventRing0.nextTRB() {
            eventCount += 1
            switch eventTrb {
                case .transfer(let trb):
                    let slotId = Int(trb.slotId)
                    let ep = Int(trb.endpointId)
//                    #kprintf("xhci-irq: Got Transfer event for slotId: %d/endpoint: %d, trbPtr: %p\n",
//                             slotId, ep, trb.trbPointer ?? 0)
                    guard let deviceData = self.deviceData[slotId] else {
                        #kprintf("xhci-irq: No active device for slotId: %d\n", slotId)
                        continue
                    }

                    guard deviceData.processTRB(trb, endpointId: ep) else {
                        #kprintf("xhci-irq: No active pipe for endpoint %d\n", ep)
                        continue
                    }

                case .commandCompletion(let trb):
                    if self.lastCommandCompletion != nil {
                        #kprint("xhci-irq: lastCommandCompletion is not nil")
                    }
                    self.lastCommandCompletion = trb

                case .portStatusChange:
                    #kprint("xhci-irq: portStatusChange")

                case .bandwidthRequest:
                    #kprint("xhci-irq: bandwidthRequest")

                case .doorbell:
                    #kprint("xhci-irq: doorbell")

                case .hostController:
                    #kprint("xhci-irq: hostController")

                case .deviceNotification:
                    #kprint("xhci-irq: deviceNotificate")

                case .mfIndexWrap:
                    #kprint("xhci-irq: mfIndexWrap")

                case .invalid(let trbtValue):
                    #kprintf("xhci: Unknown Event TRB type: %d\n", trbtValue)
            }
        }
        eventRing0.updateDequeuePointer()
//        #kprintf("xhci-hcd: Got %d events\n", eventCount)
    }


    func enableSlot() -> (UInt8, MMIORegion) {
        // Get slot ID from HCD and allocate a device context for it
        #kprint("xhci: enabling slot")
        guard let commandCompletion = writeCommandTRB(CommandTRB.enableSlot()) else {
            fatalError("No enableSlot result")
        }
        guard commandCompletion.completionCode == 1, commandCompletion.slotId > 0 else {
            fatalError("Wrong TRB type, got: " + commandCompletion.description)
        }

        let slotId = commandCompletion.slotId
        #kprintf("xhci: Got slotId %d\n", slotId)
        return (slotId, allocator.allocDeviceContext(forSlot: slotId))
    }

    func addDeviceData(_ deviceData: XHCIDeviceData, forSlot slotId: Int) {
        guard self.deviceData[slotId] == nil else {
            fatalError("xhci-pipe: Already have device data for slot \(slotId)")
        }
        self.deviceData[slotId] = deviceData
    }

    // Synchronous for now
    func writeCommandTRB(_ trb: CommandTRB) -> EventTRB.CommandCompletion? {
        lastCommandCompletion = nil
        let currentRingIdx = commandRing.slotIndex
        commandRing.addTRB(trb)
        // ring doorbell
        doorbells.ring(0, taskId: 0, target: 0)
        var count = 10
        // Wait for command response
        while count > 0 {
            count -= 1
            guard let commandCompletion = lastCommandCompletion else {
                sleep(milliseconds: 1)
                continue
            }

            guard let ringIdx = commandRing.ringAddrToIndex(commandCompletion.commandPointer) else {
                #kprint("xhci: Last command completion has invalid ring index for addres:",
                        commandCompletion.commandPointer)
                continue
            }

            guard ringIdx == currentRingIdx else {
                #kprintf("xhci: Bad ringIdx looking for %d got %d\n", currentRingIdx, ringIdx)
                continue
            }

            guard commandCompletion.completionCode == 1 else {
                #kprintf("xhci: Last command completion has bad completion Code: %d\n",
                         commandCompletion.completionCode)
                continue
            }

            return commandCompletion
        }
#if false
        fatalError("xhci: Timedout waiting for event")
#else
        #kprint("xhci: Timedout waiting for event")
        return nil
#endif
    }


    private func noopTest() {
        func show() {
            let usbStatus = operationRegs.usbSts
            let crcr = operationRegs.crcr
            let erdp = eventRing0.getEventRingDequeuePointer()
            let pendingIRQ = eventRing0.interrupterPending()
            // Read ring segment TRB @0

            #kprintf("USBSTS: 0x%8.8x CRCR: %p ERDP: %p pending: %s\n",
                     usbStatus, crcr, erdp, pendingIRQ)
        }

        #kprint("\nxhci: Sending no-op:")
        show()

        // Write a no-op command into the command ring
        if let eventTrb = writeCommandTRB(CommandTRB.noOp()) {
            #kprint("xhci: no-op cmd returned event:", eventTrb.description)
        } else {
            #kprint("xhci: timed out waiting for no-op result")
        }
        #kprint("xhci: no-op test finished")
    }

    override func debug(arguments: [String]) {
        guard let command = arguments.first else {
            return
        }

        switch command {
            case "noop":
                noopTest()

            default:
                #kprintf("Invalid command '%s'\n", command)
        }
    }


    func pollInterrupt() -> Bool {
        return false
    }

    // Fixme this needs to do locking etc
    func submitURB(_ urb: USB.Request) {
        urb.pipe.submitURB(urb)
    }
}


// USBHub functions
extension HCD_XHCI {

    var portCount: UInt8 { UInt8(self.capabilities.maxPorts) }

    func processURB(_ setupRequest: USB.ControlRequest, into buffer: MMIOSubRegion?) -> USB.Response {

        let okResponse = USB.Response(status: .finished, bytesTransferred: 0)
        let errorResponse = USB.Response(status: .stalled, bytesTransferred: 0)

        guard let requestCode = setupRequest.requestCode else {
            #kprint("xhci-root: Invalid request code")
            return errorResponse
        }

        let deviceRequest = USB.ControlRequest.BMRequestType(
            direction: .deviceToHost, requestType: .klass, recipient: .device
        ).rawValue

        let toPortRequest = USB.ControlRequest.BMRequestType(
            direction: .hostToDevice, requestType: .klass, recipient: .other(0)
        ).rawValue

        let fromPortRequest = USB.ControlRequest.BMRequestType(
            direction: .deviceToHost, requestType: .klass, recipient: .other(0)
        ).rawValue

        let standardDtoH = USB.ControlRequest.BMRequestType(
            direction: .deviceToHost, requestType: .standard, recipient: .device
        ).rawValue


        func getPort() -> UInt8? {
            guard setupRequest.wIndex > 0
                    && setupRequest.wIndex <= UInt16(self.portCount) else {
                #kprintf("xhci-root: Invalid port %d\n", setupRequest.wIndex)
                return nil
            }
            return UInt8(setupRequest.wIndex)
        }


        switch (setupRequest.bmRequestType, requestCode) {
            case (standardDtoH, .GET_STATUS):
                guard var buffer = buffer else { return errorResponse }
                buffer[0] = 0
                buffer[1] = 0
                return USB.Response(status: .finished, bytesTransferred: 2)

            case (deviceRequest, .GET_DESCRIPTOR):
                // FIXME, use the returned length in a URB response
                guard var buffer = buffer else { return errorResponse }
                let hubDescriptor = USB.HUBDescriptor(ports: self.portCount)
                let length = hubDescriptor.descriptorAsBuffer(wLength: setupRequest.wLength, into: &buffer)
                return USB.Response(status: .finished, bytesTransferred: length)

            case (fromPortRequest, .GET_STATUS):
                guard let port = getPort() else { return errorResponse }
                guard var buffer = buffer else { return errorResponse }
                let portStatus = self.portStatus(port: port)
                let length = portStatus.asBytes(into: &buffer, maxLength: 4)
                return USB.Response(status: .finished, bytesTransferred: length)

            case (toPortRequest, .SET_FEATURE), (toPortRequest, .CLEAR_FEATURE):
                guard let port = getPort() else { return errorResponse }
                guard let feature = USBHubDriver.FEATURE_SELECTOR(rawValue: setupRequest.wValue) else {
                    #kprintf("xhci-root: Invalid FEATURE_SELECTOR: %4.4x\n", setupRequest.wValue)
                    return errorResponse
                }
                var portsc = operationRegs.portSC(port: port) & ~0x80ff_01ff

                switch (requestCode, feature) {
                    case (.SET_FEATURE, .PORT_POWER):
                        return okResponse

                    case (.SET_FEATURE, .PORT_RESET):
                        #kprintf("xhci: Setting port(%u) reset\n", port)
                        portsc |= (1 << 4)
                        operationRegs.portSC(port: port, newValue: portsc)
                        return okResponse

                    case (.CLEAR_FEATURE, .C_PORT_CONNECTION):
                        #kprintf("xhci: Clearing port(%u) connection change\n", port)
                        portsc |= (1 << 17)
                        operationRegs.portSC(port: port, newValue: portsc)
                        return okResponse

                    case (.CLEAR_FEATURE, .C_PORT_RESET):
                        #kprintf("xhci: Clearing port(%u) reset change\n", port)
                        portsc |= (1 << 21)
                        operationRegs.portSC(port: port, newValue: portsc)
                        return okResponse

                    default:
                        #kprintf("xhci-root: Unsupported Port Feature %s request: %2.2x\n",
                                 requestCode.description, setupRequest.wValue)
                        return errorResponse
                }

            default:
                break
        }
        #kprint("xhci-root: Failed to handle request:", setupRequest)
        return errorResponse
    }


    func reset(port: UInt8) -> Bool {
        #kprintf("xhci: Resetting port %u\n", port)
        var portsc = operationRegs.portSC(port: port)
        portsc |= (1 << 4)
        operationRegs.portSC(port: port, newValue: portsc)
        return true
    }

    private func portStatus(port: UInt8) -> USBHubDriver.PortStatus {
        #if false
        // Ignore usb3 ports on macbook for now
        guard port != 3, port < 10 else {
            return USBHubDriver.PortStatus(
                deviceAttached: false,
                isEnabled: false,
                isSuspended: false,
                isOverCurrent: false,
                isInReset: false,
                isPowered: false,
                speed: .unknown,
                currentConnectChange: false,
                portEnabledChange: false,
                suspendChange: false,
                overCurrentIndicatorChanged: false,
                resetComplete: false,
            )}
        #endif
        let status = operationRegs.portSC(port: port)

        let psiv = status.bits(10...13)
        let speed: USB.Speed = switch psiv {
            case 0: .unknown
            case 1: .fullSpeed
            case 2: .lowSpeed
            case 3: .highSpeed
            case 4: .superSpeed_gen1_x1
            case 5: .superSpeed_gen2_x1
            case 6: .superSpeed_gen1_x2
            case 7: .superSpeed_gen2_x2
            default: .unknown
        }


        let portProtocol = self.capabilities.supportedProtocol(port: port)
        if let portProtocol {
       //     #kprintf("xhci: portStatus(%u)\n", port)
            for speedId in portProtocol.speedIds {
                if speedId.psiv == psiv {
                    #kprint("xhci: Found psiv:", speedId)
                    break
                }
            }
        } else {
            #kprintf("xhci: No port protocol for port: %u\n", port)
        }

        return USBHubDriver.PortStatus(
            deviceAttached: status.bit(0),
            isEnabled: status.bit(1),
            isSuspended: false,
            isOverCurrent: status.bit(3),
            isInReset: status.bit(4),
            isPowered: status.bit(9),
            speed: speed,
            currentConnectChange: status.bit(17),
            portEnabledChange: status.bit(18),
            suspendChange: false,
            overCurrentIndicatorChanged: status.bit(20),
            resetComplete: status.bit(21)
        )
    }


    func clearConnectStatus(port: UInt8) {
        var status = operationRegs.portSC(port: port)
        status |= (1 << 17)
        operationRegs.portSC(port: port, newValue: status)
    }
}
