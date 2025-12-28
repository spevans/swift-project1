/*
 *  xhci-pipe.swift
 *  Kernel
 *
 *  Created by Simon Evans on 03/09/2025.
 */

extension HCD_XHCI {

    // Section 4.5.2 - The initialisers set the fields of an Input Slot Context data structure
    // when it is used for a specific command
    struct SlotContext {
        private(set) var dwords: InlineArray<4, UInt32>

        var address: UInt8 { UInt8(truncatingIfNeeded: dwords[3]) }
        var slotState: Int { Int(dwords[3] >> 27) }

        init(dwords: InlineArray<4, UInt32>) {
            self.dwords = dwords
        }

        // Address Device Command
        init(routeString: UInt32, speed: USB.Speed, interrupter: Int, rootHubPort: UInt8) {
            dwords = [ routeString | (speed.slotContextSpeed << 20) | UInt32(1 << 27),
                       UInt32(rootHubPort) << 16,
                       UInt32(interrupter) << 22,
                       0
                       ]
        }

        // Address Device Command via HighSpeed Hub
        init(routeString: UInt32, speed: USB.Speed,
             interrupter: Int, rootHubPort: UInt8,
             parentPortNumber: UInt8, parentHubSlotId: UInt8) {
            dwords = [ UInt32(1 << 27) | UInt32(1 << 26) | routeString | (speed.slotContextSpeed << 20),
                       UInt32(rootHubPort) << 16,
                       UInt32(parentHubSlotId) | UInt32(parentPortNumber) << 8
                       | UInt32(interrupter) << 22,
                       0]
        }

        // Configure Endpoint Command
        init(contextEntry: Int) {
            dwords = [ UInt32(contextEntry << 27), 0, 0, 0]
        }

        // Configure Endpoint Command and device is hub
        init(contextEntries: Int, numberOfHubPorts: UInt8, ttThinkTime: Int, mtt: Bool) {
            let mttBit = UInt32(mtt ? 1 : 0)  << 25
            let hubBit = UInt32(1 << 26)
            dwords = [ UInt32(contextEntries << 27) | hubBit | mttBit,
                       UInt32(numberOfHubPorts) << 24,
                       UInt32(ttThinkTime) << 16,
                       0]
        }

        // Evaluate Context Command - Section 6.4.3.6
        init(maxExitLatency: Int, interrupter: Int) {
            dwords = [0, UInt32(maxExitLatency), UInt32(interrupter) << 22, 0]
        }
    }

    // Section 4.8.2 / Figure 6-3
    struct EndpointContext {
        private(set) var dwords: InlineArray<4, UInt32> = [0, 0, 0, 0]

        init(endpoint: USB.EndpointDescriptor, dequeuePointer: PhysAddress,
             dequeueCycleState: Bool) {
            let maxPacketSize = UInt32(endpoint.maxPacketSize) << 16
            let cErr: UInt32 = endpoint.transferType == .isochronous ? 0 : 3 << 1
            let epType = endpoint.endpointType << 3
            let dcs: UInt32 = dequeueCycleState ? 1 : 0

            dwords = [0,
                      maxPacketSize | epType | cErr,
                      UInt32(truncatingIfNeeded: dequeuePointer.value & ~0xf) | dcs,
                      UInt32(truncatingIfNeeded: dequeuePointer.value >> 32)]
        }
    }


    func allocatePipe(device: USBDevice,
                      endpointDescriptor: USB.EndpointDescriptor) -> USBPipe? {

        guard let deviceData = device.hcdData as? XHCIDeviceData else {
            #kprint("xhci-pipe: No per device data")
            return nil
        }

        let direction = endpointDescriptor.direction == .hostToDevice ? 0 : 1
        let ep = Int(endpointDescriptor.endpoint)
        let pipeIdx = ep == 0 ? 1 : (ep * 2) + direction
        guard deviceData.pipes[pipeIdx] == nil else {
            #kprintf("xhci-pipe: Pipe already active for endpoint %u\n", endpointDescriptor.endpoint)
            return nil
        }
        let pipe = XHCIPipe(usbDevice: device, endpointDescriptor: endpointDescriptor, deviceData)
        if let pipe {
            if XHCIDebug {
                #kprintf("xhci-pipe: Adding new pipe for epId: %d pipeIdx: %d\n", pipe.epContextSlot, pipeIdx)
            }
            deviceData.pipes[pipe.epContextSlot] = pipe
        }
        return pipe
    }
}

fileprivate extension HCD_XHCI {
    final class XHCIPipe: USBPipe {
        private let deviceData: XHCIDeviceData
        private var urb: USB.Request?
        private var transferRing: ProducerRing<TransferTRB>
        private var inputContext: MMIORegion
        let epContextSlot: Int


        init?(usbDevice: USBDevice, endpointDescriptor: USB.EndpointDescriptor,
              _ deviceData: XHCIDeviceData) {
            self.deviceData = deviceData
            self.transferRing = ProducerRing()

            let direction = endpointDescriptor.direction == .hostToDevice ? 0 : 1
            self.epContextSlot = Int(endpointDescriptor.endpoint) == 0 ? 1 : (Int(endpointDescriptor.endpoint) * 2) + direction
            if XHCIDebug {
                #kprintf("xhci-pipe: direction: %d endpointDescriptor.endpoint: %d epContextSlot: %d\n",
                         direction, Int(endpointDescriptor.endpoint), epContextSlot)
            }
            self.inputContext = deviceData.inputDeviceContext()

            super.init(endpointDescriptor: endpointDescriptor)

            /* When opening the first pipe - which is  the control pipe - this signals
             * that the USBDevice.init() has been called so some items need to be setup now
             *
             * 1. Enable the slot and allocate a Device Context for this slot.
             *
             * 2. Allocate an input context. This is reused for any pipes created for
             *    specific endpoints. There are 32slots, 1x slot context 1x control
             *    endpoint 0 context and 30 contexts for the 15 other endpoints (1 per
             *    direction).
             *
             * 3. For each pipe a Transfer Ring needs to be allocated and the input context
             *    setup correctly, both the slot context and the specific endpoint context.
             *
             * 4. For the initial endpoint (control), an Address Device command is sent.
             *    This is sent with BlockSetAddress set true to avoid setting a new address
             *    on the device. This will be sent later when a SET_ADDRESS command is sent.
             *
             *    For other endpoints, a configureEndpoint command is sent.
             *
             */

            if XHCIDebug {
                #kprint("xhci-pipe: opening pipe for endpoint:", endpointDescriptor)
                if endpointDescriptor.endpoint == 0 {
                    #kprint("xhci-pipe: Allocating control endpoint")
                }
            }

            /*
             * Configure the input device context. This context is composed of 33 contexts.
             *
             * Context 0 is the input control context, 2x32 bits 2 bits per remaining
             * contexts.
             * 1 bit to add the context and one to remove it.
             *
             * Context 1 is the slot context which is always setup
             * Context 2 is EP context for the control endpoint (EP0) regardless of direction
             * Context 3-4  are EP contexts for endpoint 1 3=OUT direction 4=IN direction
             *     ...
             * Context 31-32 are for endpoint 15 31=OUT direction 32=IN direction
             */

            let contextSize = deviceData.hcd.allocator.contextSize   // Either 32 or 64 bytes

            // Input Device Context - Data sent to the xHC
            // Set Add for input context and EP context to enable slot context and Control EP0
            let value = UInt32(1 << self.epContextSlot) | 1
            self.inputContext.write(value: value, toByteOffset: 4)

            // Configure the slot context
            let slotCtxOffset = contextSize
            let slotContext: SlotContext
            if endpointDescriptor.endpoint == 0 {
                // For EP0, used for Address Device command
                slotContext = SlotContext(routeString: usbDevice.routeString,
                                          speed: usbDevice.speed,
                                          interrupter: 0, rootHubPort: usbDevice.rootPort)
            } else {

                if let hubDriver = usbDevice.deviceDriver as? USBHubDriver {
                    // Configure endpoint as a Hub
                    // TODO: Get settings
                    if XHCIDebug {
                        #kprintf("xhci-pipe: Configuring endpoint as hub, ports: %d\n",
                                 hubDriver.ports)
                    }
                    slotContext = SlotContext(contextEntries: self.epContextSlot + 1,
                                              numberOfHubPorts: UInt8(hubDriver.ports),
                                              ttThinkTime: hubDriver.hubDescriptor.ttThinkTime,
                                              mtt: hubDriver.multiTT)
                } else {
                    // For all other endpoints used for configure endpoint command
                    slotContext = SlotContext(contextEntry: self.epContextSlot + 1)
                }
            }

            for idx in 0...3 {
                let offset = slotCtxOffset + (idx * 4)
                self.inputContext.write(value: slotContext.dwords[idx], toByteOffset: offset)
            }

            if XHCIDebug {
                #kprintf("xhci-pipe: contextSize: %d contextSlot: %d slotCtxOffet: %d\n",
                         contextSize, contextSize, slotCtxOffset)
                #kprintf("xhci-pipe: slotContext: %8.8x/%8.8x/%8.8x/%8.8x\n",
                         slotContext.dwords[0], slotContext.dwords[1],
                         slotContext.dwords[2], slotContext.dwords[3])
            }

            // Configure the endpoint context
            let epCtxOffset = (epContextSlot + 1) * contextSize // +1 to skip over input context
            // TODO: Setup the endpoint context here and allocate a ring

            let epContext = EndpointContext(endpoint: endpointDescriptor,
                                            dequeuePointer: self.transferRing.ringBaseAddress,
                                            dequeueCycleState: true)
            for idx in 0...3 {
                let offset = epCtxOffset + (idx * 4)
                self.inputContext.write(value: epContext.dwords[idx], toByteOffset: offset)
            }

            let slotId = deviceData.slotId
            let commandTrb = if endpointDescriptor.endpoint == 0 {
                // Call set address but do not allow an address to be set for now as
                // some devices need to remain unaddressed while getting the initial
                // device descriptor.
                CommandTRB.addressDevice(slotId, self.inputContext.baseAddress, blockSetAddress: true)
            } else {
                CommandTRB.configureEndpoint(slotId, self.inputContext.baseAddress)
            }

            if XHCIDebug {
                if endpointDescriptor.endpoint == 0 {
                    #kprintf("xhci-pipe: configuring context slot for EP0 slot: %x address: %p\n",
                             slotId, self.inputContext.baseAddress)
                } else {
                    #kprintf("xhci-pipe: configuring endpoint %d address: %p\n",
                             endpointDescriptor.endpoint, inputContext.baseAddress)
                }
            }

            guard let commandCompletion = deviceData.hcd.writeCommandTRB(commandTrb),
                  commandCompletion.slotId == deviceData.slotId else {
                fatalError("xhci-pipe: Failed to send command TRB or returned slotId is wrong")
            }
        }

        deinit {
            // TODO: - free transfer ring andinput device context
        }

        override func allocateBuffer(length: Int) -> MMIOSubRegion {
            return deviceData.hcd.allocator.allocPhysBuffer(length: length)
        }

        override func freeBuffer(_ buffer: MMIOSubRegion) {
            deviceData.hcd.allocator.freePhysBuffer(buffer)
        }

        override func updateMaxPacketSize(to maxPacketSize: Int) {
            // Configure the endpoint context
            if XHCIDebug {
                #kprintf("xhci-pipe: Updating current packet size on ep: %u to be %d\n", self.endpointDescriptor.endpoint, maxPacketSize)
            }
            let contextSize = deviceData.hcd.allocator.contextSize   // Either 32 or 64 bytes

            guard endpointDescriptor.endpoint == 0 else {
                fatalError("Trying to set maxPacketSize on a non-control endpoint")
            }
            let epCtxOffset = (self.epContextSlot + 1) * contextSize // +1 to skip over input context
            if XHCIDebug {
                // Readback the current packet size (should be 8) as a test for now
                let curPacketSize: UInt16 = self.inputContext.read(fromByteOffset: epCtxOffset + 6)
                #kprintf("xhci-pipe: Read Current max packet size from offset: %d, value is: %u\n", epCtxOffset, curPacketSize)
                guard curPacketSize == 8 else {
                    fatalError("xhci-pipe: Was expecting current Packet size to be 8")
                }
            }
            // Update the maxPacketSize field in the endpoint context
            self.inputContext.write(value: UInt16(maxPacketSize), toByteOffset: epCtxOffset + 6)


            let value = UInt32(1 << self.epContextSlot) | 1
            self.inputContext.write(value: value, toByteOffset: 4)


            // Use maxExitLatency of 0 for now as there are no power managed devices
            let slotContext = SlotContext(maxExitLatency: 0, interrupter: 0)
            let slotCtxOffset = contextSize
            for idx in 0...3 {
                let offset = slotCtxOffset + (idx * 4)
                self.inputContext.write(value: slotContext.dwords[idx], toByteOffset: offset)
            }
            let trb = CommandTRB.evaluateContext(self.deviceData.slotId,
                                                 self.inputContext.baseAddress)
            if XHCIDebug {
                #kprint("xhci-pipe: Sending Evaluate context command")
            }
            guard let commandCompletion = deviceData.hcd.writeCommandTRB(trb),
                  commandCompletion.slotId == deviceData.slotId else {
                fatalError("xhci-pipe: Failed to send command TRB or returned slotId is wrong")
            }
        }

        override func submitURB(_ urb: USB.Request) {
            guard self.urb == nil else {
                fatalError("xhci-pipe: Endpoint already processing URB")
            }

            self.urb = urb
            switch endpointDescriptor.transferType {
                case .control:
                    if XHCIDebug {
                        #kprintf("xhci-pipe: submitting URB on control endpoint: %d\n", self.epContextSlot)
                    }
                    self.submitControlURB(urb)

                case .interrupt:
//                    #kprintf("xhci-pipe: submitting URB on interrupt endpoint: %d\n", self.epContextSlot)
                    self.submitInterruptURB(urb)

                case .bulk, .isochronous:
                    fatalError("xhci-pipe: Failed to process URBs for bulk/ISO yet")
            }
        }


        // Called in interrupt context
        private var gotEvent = false
        fileprivate func processEventTRB(_ trb: EventTRB.Transfer) {
            if false {
                #kprintf("\n**xhci-pipe: event: cc: %d trbp: %p ed: %p ttlen: %u trbt: %d ep: %d sl: %u",
                         trb.completionCode,
                         trb.trbPointer ?? 0,
                         trb.eventData ?? 0,
                         trb.trbTransferLength,
                         trb.trbTypeValue,
                         trb.endpointId,
                         trb.slotId)
                if trb.completionCode != 1 {
                    #kprintf("\n**xhci-pipe, completionCode: %d remaining bytes: %d\n",
                             Int(trb.completionCode), Int(trb.trbTransferLength))
                }
            }
            guard let urb = self.urb else {
                #kprintf("\n**xhci-pipe: Got transfer event %d when no URB is active\n", trb.completionCode)
                return
            }
            gotEvent = true
            self.urb = nil

            let bytesTransferred = urb.bytesToTransfer - Int(trb.trbTransferLength)
//            #kprintf("xhci-pipe: bytesToTransfer: %d trbTransferLength: %d bytesTransferred: %d\n",
//                     urb.bytesToTransfer, Int(trb.trbTransferLength), bytesTransferred)
            let status: USBPipe.Status = switch trb.completionCode {
                case 1: .finished

                case 6: .stalled

                case 0:
                    #kprint("xhci-pipe: Invalid completion code")
                    fallthrough

                case 2:
                    #kprint("xhci-pipe: databuffer error")
                    fallthrough

                case 3:
                    #kprint("xhci-pipe: babble detected")
                    fallthrough

                case 4:
                    #kprint("xhci-pipe: transaction error")
                    fallthrough

                case 5:
                    #kprint("xhci-pipe: TRB error")
                    fallthrough

                case 7:
                    #kprint("xhci-pipe: resource error")
                    fallthrough

                case 8:
                    #kprint("xhci-pipe: bandwidth error")
                    fallthrough

                case 13:
                    if XHCIDebug {
                        #kprintf("\n**xhci-pipe: short packet wanted: %d remaining: %d got: %d\n",
                                 urb.bytesToTransfer, Int(trb.trbTransferLength), bytesTransferred)
                    }
                    fallthrough

                default: .timedout
            }
            let response = USB.Response(status: status, bytesTransferred: bytesTransferred)
            if false {
                #kprintf("\n**xhci-pipe: Calling completion whith status: %s bytes xfer: %d\n",
                         status.description, bytesTransferred)
            }
            urb.completionHandler(urb, response)
        }


        private func submitControlURB(_ urb: USB.Request) {
            // FIXME: Should just have the ControlRequest directly in the USB.Request
            guard let setup = urb.setupRequest,
                  let setupRequest = USB.ControlRequest(from: setup) else {
                #kprint("\n**xhci-pipe: invalid setup request packet")
                let response = USB.Response(status: .stalled, bytesTransferred: 0)
                urb.completionHandler(urb, response)
                return
            }

            let trt: Int
            if urb.buffer == nil {
                // No data stage
                trt = 0
            } else {
                // OUT data stage = 2 IN data stage = 3
                trt = urb.direction == .hostToDevice ? 2 : 3
            }


            // Write the first TRB with the cyclebit toggled to what it should be so the
            // xHC will not start executing the TRB until all three are inplace
            // Save the trRingOffset so that the setupTRB can be updated with the cyclebit set
            // correctly.
            let setupTrb = TransferTRB.setupStage(request: setupRequest, interrupter: 0,
                                                  interruptOnComplete: false, trt: trt)

            transferRing.addTRB(setupTrb, enable: false)

            var useDataTRB = true   // First TRB is Data, rest are Normal
            if let buffer = urb.buffer {
                let maxPacketSize0 = urb.usbDevice.maxPacketSize0
                if XHCIDebug {
                    #kprint("xhci-pipe: Adding data TRBs for \(urb.bytesToTransfer) bytes, dir: \(urb.direction)")
                }
                var bytesLeft = Int(urb.bytesToTransfer)
                if buffer.count < Int(urb.bytesToTransfer) {
                    fatalError("xhci-pipe: buffer.count\(buffer.count) is too small for urb.bytesToTransfer\(urb.bytesToTransfer)")
                }
                var bufferIndex: Int = 0
                var totalTDs = (bytesLeft - 1) / Int(maxPacketSize0)  // Round down so last TD has 0
                while bytesLeft > 0 {
                    let dataBuffer: TransferTRB.DataBuffer
                    let length = min(bytesLeft, Int(maxPacketSize0))
                    bytesLeft -= length

                    if urb.direction == .hostToDevice {
                        // OUT data stage
                        if length <= 8 {
                            var inlineBuffer: InlineArray<8, UInt8> = .init(repeating: 0)
                            for idx in 0..<length {
                                inlineBuffer[idx] = buffer[bufferIndex + idx]
                            }
                            dataBuffer = .data(inlineBuffer, UInt32(length))
                        } else {
                            dataBuffer = .address(buffer.baseAddress + bufferIndex, UInt32(length))
                        }
                    } else {
                        // IN data stage
                        dataBuffer = .address(buffer.baseAddress + bufferIndex, UInt32(length))
                    }
                    let chain = bytesLeft > 0
                    let trb: TransferTRB
                    if useDataTRB {
                        trb = TransferTRB.dataStage(dataBuffer, tdSize: totalTDs, interrupter: 0,
                                                    readData: trt == 3,
                                                    interruptOnComplete: false, //!chain,
                                                    chain: chain,
                                                    interruptOnShortPacket: false,
                                                    evaluateNextTRB: true)
                    } else {
                        trb = TransferTRB.normal(dataBuffer, tdSize: totalTDs, interrupter: 0,
                                                 blockInterrupt: false,
                                                 interruptOnComplete: false, //!chain,
                                                 chain: chain, noSnoop: false,
                                                 interruptOnShortPacket: false,
                                                 evaluateNextTrb: true)
                    }
                    let addr = transferRing.addTRB(trb)
                    if XHCIDebug {
                        #kprintf("xhci-pipe: Added %s TRB @ %p of address: %p length: %d tdSize: %d chain: %s 0x%8.8x 0x%8.8x 0x%8.8x 0x%8.8x\n",
                                 useDataTRB ? "DATA  " : "NORMAL", addr.value,
                                 buffer.baseAddress + bufferIndex, length, totalTDs, bytesLeft > 0,
                                 trb.dwords[0], trb.dwords[1], trb.dwords[2], trb.dwords[3])
                    }
                    useDataTRB = false
                    bufferIndex += length
                    totalTDs -= 1
                }
            }


            let statusTrb = TransferTRB.statusStage(interrupter: 0, readData: trt != 3,
                                                    interruptOnComplete: true,
                                                    chain: false, evaluateNextTRB: false)
            let addr = transferRing.addTRB(statusTrb)
            gotEvent = false
            if XHCIDebug {
                #kprintf("xhci-pipe: Added status TRB @ %p\n", addr.value)
                #kprint("xhci-pipe: enabling TRB and ringing doorbell")
            }
            memoryBarrier()
            transferRing.enableTRB()
            deviceData.hcd.doorbells.ring(Int(deviceData.slotId), taskId: 0,
                                          target: UInt8(self.epContextSlot))
            // FIXME: hacky timeout
            var count = 100
            while !gotEvent, count > 0 {
                sleep(milliseconds: 1)
                count -= 1
            }
            if !gotEvent { #kprint("xhci-pipe: timedout waiting for urb") }
            // Needs to be atomic exchange
            guard let urb = self.urb else { return }
            self.urb = nil
            gotEvent = true
            #kprint("xhci-pipe: timeout!")
            let status = USBPipe.Status.timedout
            let response = USB.Response(status: status, bytesTransferred: 0)
            urb.completionHandler(urb, response)
        }


        private func submitInterruptURB(_ urb: USB.Request) {
            guard let buffer = urb.buffer else { return }
            let dataBuffer: TransferTRB.DataBuffer
            if self.endpointDescriptor.direction == .hostToDevice, urb.bytesToTransfer <= 8 {
                var inlineBuffer: InlineArray<8, UInt8> = .init(repeating: 0)
                for idx in 0..<urb.bytesToTransfer {
                    inlineBuffer[idx] = buffer[idx]
                }
                // FIXME: always Use urb.bytesToTransfer and allow for multiple
                dataBuffer = .data(inlineBuffer, UInt32(urb.bytesToTransfer))
            } else {
                dataBuffer = .address(buffer.baseAddress, UInt32(urb.bytesToTransfer))
            }
            let trb = TransferTRB.normal(dataBuffer, tdSize: 0, interrupter: 0, blockInterrupt: false,
                                         interruptOnComplete: true, chain: false, noSnoop: true,
                                         interruptOnShortPacket: true, evaluateNextTrb: false)
            transferRing.addTRB(trb)
//            #kprintf("xhci-pipe: Added Interrupt TRB @ %p\n", addr.value)
            deviceData.hcd.doorbells.ring(Int(deviceData.slotId), taskId: 0,
                                          target: UInt8(self.epContextSlot))
        }
    }
}


class XHCIDeviceData: HCDData {
    let hcd: HCD_XHCI
    let slotId: UInt8
    let deviceContext: MMIORegion
    private var _inputDeviceContext: MMIORegion?
    private let usbDevice: USBDevice
    fileprivate var pipes: InlineArray<16, HCD_XHCI.XHCIPipe?> = .init(repeating: nil)

    init(hcd: HCD_XHCI, device: USBDevice) {
        self.hcd = hcd
        self.usbDevice = device
        self._inputDeviceContext = nil

        // Do the device setup
        (self.slotId, self.deviceContext) = hcd.enableSlot()

        if XHCIDebug {
            #kprintf("xhci-pipe: enableSlot returned slotId %d\n", self.slotId)
        }
        super.init()
        hcd.addDeviceData(self, forSlot: Int(self.slotId))
    }

    deinit {
        // TODO: Free deviceContext and inputDeviceContext
    }


    func inputDeviceContext() -> MMIORegion {

        if let context = self._inputDeviceContext {
            return context
        }
        let context = hcd.allocator.allocInputDeviceContect()
        self._inputDeviceContext = context
        return context
    }

    func processTRB(_ trb: HCD_XHCI.EventTRB.Transfer, endpointId: Int) -> Bool {
        if false {
            #kprintf("xhci-pipe: processing TRB for endpoint: %d\n", endpointId)
        }
        guard let pipe = self.pipes[endpointId] else { return false }
        pipe.processEventTRB(trb)
        return true
    }
}
