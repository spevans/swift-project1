/*
 *  xhci-pipe.swift
 *  Kernel
 *
 *  Created by Simon Evans on 03/09/2025.
 */

extension HCD_XHCI {

    // Section 4.5.2
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

        // Evaluate Context Command
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
            #kprintf("xhci-pipe: Adding new pipe for epId: %d pipeIdx: %d\n", pipe.epContextSlot, pipeIdx)
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
        let epContextSlot: Int


        init?(usbDevice: USBDevice, endpointDescriptor: USB.EndpointDescriptor,
              _ deviceData: XHCIDeviceData) {
            self.deviceData = deviceData
//            self.transferRing = MMIORegion(allocIOPage())
            self.transferRing = ProducerRing()

            let direction = endpointDescriptor.direction == .hostToDevice ? 0 : 1
            self.epContextSlot = Int(endpointDescriptor.endpoint) == 0 ? 1 : (Int(endpointDescriptor.endpoint) * 2) + direction
            #kprintf("xhci-pipe: direction: %d endpointDescriptor.endpoint: %d epContextSlot: %d\n",
                     direction, Int(endpointDescriptor.endpoint), epContextSlot)

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

            #kprint("xhci-pipe: opening pipe for endpoint:", endpointDescriptor)
            if endpointDescriptor.endpoint == 0 {
                #kprint("xhci-pipe: Allocating control endpoint")
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
            let inputContext = deviceData.inputDeviceContext()
            let value = UInt32(1 << self.epContextSlot) | 1
            inputContext.write(value: value, toByteOffset: 4)

            // Configure the slot context
            let slotCtxOffset = contextSize
            let slotContext: SlotContext
            if endpointDescriptor.endpoint == 0 {
                // For EP0, used for Address Device command
                slotContext = SlotContext(routeString: 0, speed: usbDevice.speed,
                                          interrupter: 0, rootHubPort: usbDevice.port)
            } else {

                if let hubDriver = usbDevice.device.deviceDriver as? USBHubDriver {
                    // Configure endpoint as a Hub
                    // TODO: Get settings
                    #kprintf("xhci-pipe: Configuring endpoint as hub, ports: %d\n",
                             hubDriver.ports)
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
                inputContext.write(value: slotContext.dwords[idx], toByteOffset: offset)
            }

            #kprintf("xhci-pipe: contextSize: %d contextSlot: %d slotCtxOffet: %d\n",
                     contextSize, contextSize, slotCtxOffset)
            #kprintf("xhci-pipe: slotContext: %8.8x/%8.8x/%8.8x/%8.8x\n",
                     slotContext.dwords[0], slotContext.dwords[1],
                     slotContext.dwords[2], slotContext.dwords[3])

            // Configure the endpoint context
            let epCtxOffset = (epContextSlot + 1) * contextSize // +1 to skip over input context
            // TODO: Setup the endpoint context here and allocate a ring

            let epContext = EndpointContext(endpoint: endpointDescriptor,
                                            dequeuePointer: self.transferRing.ringBaseAddress,
                                            dequeueCycleState: true)
            for idx in 0...3 {
                let offset = epCtxOffset + (idx * 4)
                inputContext.write(value: epContext.dwords[idx], toByteOffset: offset)
            }

            let slotId = deviceData.slotId
            let commandTrb = if endpointDescriptor.endpoint == 0 {
                // Call set address but do not allow an address to be set for now as
                // some devices need to remain unaddressed while getting the initial
                // device descriptor.
                CommandTRB.addressDevice(slotId, inputContext.baseAddress, blockSetAddress: true)
            } else {
                CommandTRB.configureEndpoint(slotId, inputContext.baseAddress)
            }

            if endpointDescriptor.endpoint == 0 {
                #kprintf("xhci: configuring context slot for EP0 slot: %x address: %p\n",
                         slotId, inputContext.baseAddress)
            } else {
                #kprintf("xhci: configuring endpoint %d address: %p\n",
                         endpointDescriptor.endpoint, inputContext.baseAddress)
            }

            guard let commandCompletion = deviceData.hcd.writeCommandTRB(commandTrb),
                  commandCompletion.slotId == deviceData.slotId else {
                fatalError("Failed to send command TRB or returned slotId is wrong")
            }
            //#kprintf("xhci: Got slotId %d\n", result.slotId)

            #if false
            // Write a NO-OP as a test
            let noopTRB = TransferTRB.noop(interrupter: 0, interruptOnComplete: true, chain: false, evaluateNextTRB: false)

            #kprint("xhci-pipe: writing noopTRB")
//            _ = writeTRB(noopTRB)
            transferRing.addTRB(noopTRB)
            #kprint("xhci-pipe: ringing doorbell")
            deviceData.hcd.doorbells.ring(Int(deviceData.slotId), taskId: 0,
                                          target: UInt8(self.epContextSlot))

            if let event = waitForEventTRB(timeout: 100) {
                #kprint("xhci-pipe: Got event")
                EventRing.dumpTRB(event)
            } else {
                fatalError("xhci-pipe: No event received")
            }
            #endif
        }

        deinit {
            // TODO: - free transfer ring
        }

        override func allocateBuffer(length: Int) -> MMIOSubRegion {
            return deviceData.hcd.allocator.allocPhysBuffer(length: length)
        }

        override func freeBuffer(_ buffer: MMIOSubRegion) {
            deviceData.hcd.allocator.freePhysBuffer(buffer)
        }

        override func submitURB(_ urb: USB.Request) {
            guard self.urb == nil else {
                fatalError("xhci-pipe: Endpoint already processing URB")
            }

            self.urb = urb
            switch endpointDescriptor.transferType {
                case .control:
                    #kprintf("xhci-pipe: submitting URB on control endpoint: %d\n", self.epContextSlot)
                    self.submitControlURB(urb)

                case .interrupt:
//                    #kprintf("xhci-pipe: submitting URB on interrupt endpoint: %d\n", self.epContextSlot)
                    self.submitInterruptURB(urb)

                case .bulk, .isochronous:
                    fatalError("Cannot process URBs for bulk/ISO yet")
            }
        }


        // Called in interrupt context
        private var gotEvent = false
        fileprivate func processEventTRB(_ trb: EventTRB.Transfer) {
            guard let urb = self.urb else {
                #kprint("xhci-pipe: Got transfer event when no URB is active")
                return
            }
            gotEvent = true
            self.urb = nil
//            #kprintf("xhci-pipe, completionCode: %d remaining bytes: %d\n",
//                     Int(trb.completionCode), Int(trb.trbTransferLength))

            let bytesTransferred = urb.bytesToTransfer - Int(trb.trbTransferLength)
            let status: USBPipe.Status = switch trb.completionCode {
                case 13:
//                    #kprintf("xhci-pipe: short packet wanted: %d remaining: %d got: %d\n",
//                             urb.bytesToTransfer, Int(trb.trbTransferLength), bytesTransferred)
                    fallthrough

                case 1: .finished

                default: .timedout
            }
            let response = USB.Response(status: status, bytesTransferred: bytesTransferred)
            urb.completionHandler(urb, response)
        }


        private func submitControlURB(_ urb: USB.Request) {
            // FIXME: Should just have the ControlRequest directly in the USB.Request
            guard let setup = urb.setupRequest,
                  let setupRequest = USB.ControlRequest(from: setup) else {
                #kprint("xhci-pipe: invalid setup request packet")
                let response = USB.Response(status: .stalled, bytesTransferred: 0)
                urb.completionHandler(urb, response)
                return
            }

            let trt: Int
            let dataBuffer: TransferTRB.DataBuffer?
            if let buffer = urb.buffer {
                if urb.direction == .hostToDevice {
                    // OUT data stage
                    trt = 2
                    if buffer.count <= 8 {
                        var inlineBuffer: InlineArray<8, UInt8> = .init(repeating: 0)
                        for idx in buffer.indices {
                            inlineBuffer[idx] = buffer[idx]
                        }
                        // TODO: should we always use buffer.count or urb.bytesToTransfer
                        dataBuffer = .data(inlineBuffer, UInt32(buffer.count))
                    } else {
                        dataBuffer = .address(buffer.baseAddress, UInt32(buffer.count))
                    }
                } else {
                    // IN data stage
                    trt = 3
                    dataBuffer = .address(buffer.baseAddress, UInt32(buffer.count))
                }
            } else {
                // No data stage
                trt = 0
                dataBuffer = nil
            }

            // Write the first TRB with the cyclebit toggled to what it should be so the
            // xHC will not start executing the TRB until all three are inplace
            // Save the trRingOffset so that the setupTRB can be updated with the cyclebit set
            // correctly.
//            let setupRingOffset = trRingOffset
            let setupTrb = TransferTRB.setupStage(request: setupRequest, interrupter: 0,
                                                  interruptOnComplete: false, trt: trt)

//            #kprint("xhci-pipe: writing setupTRB")
            transferRing.addTRB(setupTrb, enable: false)

            if let dataBuffer {
                let dataTrb = TransferTRB.dataStage(dataBuffer, tdSize: 0, interrupter: 0,
                                                    readData: trt == 3,
                                                    interruptOnComplete: false,
                                                    chain: false, interruptOnShort: false,
                                                    evaluateNextTRB: true)
//                #kprint("xhci-pipe: writing dataTRB")
                transferRing.addTRB(dataTrb)
            }

            let statusTrb = TransferTRB.statusStage(interrupter: 0, readData: trt != 3,
                                                    interruptOnComplete: true,
                                                    chain: false, evaluateNextTRB: false)
//            #kprint("xhci-pipe: writing statusTRB")
            transferRing.addTRB(statusTrb)

            gotEvent = false
            transferRing.enableTRB()
            deviceData.hcd.doorbells.ring(Int(deviceData.slotId), taskId: 0,
                                          target: UInt8(self.epContextSlot))
            // FIXME: hacky timeout
            var count = 100
            while !gotEvent, count > 0 {
                sleep(milliseconds: 1)
                count -= 1
            }
            // Needs to be atomic exchange
            guard let urb = self.urb else { return }
            self.urb = nil
            gotEvent = true
            #if false
            fatalError("xhci-pipe: timeout!")
            #else
            let status = USBPipe.Status.timedout
            let response = USB.Response(status: status, bytesTransferred: 0)
            urb.completionHandler(urb, response)
            #endif
        }


        private func submitInterruptURB(_ urb: USB.Request) {
            guard let buffer = urb.buffer else { return }
            let dataBuffer: TransferTRB.DataBuffer
            if self.endpointDescriptor.direction == .hostToDevice, urb.bytesToTransfer <= 8 {
                var inlineBuffer: InlineArray<8, UInt8> = .init(repeating: 0)
                for idx in buffer.indices {
                    inlineBuffer[idx] = buffer[idx]
                }
                // TODO: should we always use buffer.count or urb.bytesToTransfer
                dataBuffer = .data(inlineBuffer, UInt32(buffer.count))
            } else {
                dataBuffer = .address(buffer.baseAddress, UInt32(urb.bytesToTransfer))
            }
            let trb = TransferTRB.normal(data: dataBuffer, tdSize: 0, interrupter: 0, blockInterrupt: false,
                                         interruptOnComplete: true, chain: false, noSnoop: true,
                                         interruptOnShortPacket: true, evaluateNextTrb: false)
            transferRing.addTRB(trb)
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

        #kprintf("xhci-pipe: enableSlot returned slotId %d\n", self.slotId)
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
//        #kprintf("xhci-pipe: processing TRB for endpoint: %d\n", endpointId)
        guard let pipe = self.pipes[endpointId] else { return false }
        pipe.processEventTRB(trb)
        return true
    }
}
