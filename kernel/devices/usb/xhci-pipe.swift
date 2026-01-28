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

        // 6.2.2.1 Address Device Command Usage
        // Create a slotContext for the Address Device Command taking into account
        // LowSpeed/FullSpeed devices on a HighSpeed hub.
        init(for usbDevice: USBDevice) {
            var parentPortNumber: UInt8 = 0
            var parentHubSlotId: UInt8 = 0
            let mtt: Bool = false   // TODO: Enable MTT interface on parent hub

            // For LS/FS device, walk up the tree to find the first HS Hub (if any)
            // and use this to determine the parent port settings

            if usbDevice.speed == .lowSpeed || usbDevice.speed == .fullSpeed {
                parentPortNumber = usbDevice.bus.physPort(for: usbDevice.port)
                var parent: Device? = usbDevice.parent
                var foundParent = false
                while let p = parent as? USBDevice, !p.isHCD {
                    if p.speed == .highSpeed {
                        guard let parentDeviceData = p.hcdData as? XHCIDeviceData else {
                            fatalError("XHCI: Parent of device does not have XHCIDeviceData")
                        }
                        parentHubSlotId = parentDeviceData.slotId
                        foundParent = true
                        break
                    } else {
                        parent = p.parent
                        parentPortNumber = usbDevice.bus.physPort(for: p.port)
                    }
                }
                if !foundParent {
                    // Reset this as it should only be zero is a HS hub was found upstream
                    parentPortNumber = 0
                }
            }

            let contextEntries: UInt32 = 1
            let interrupter: UInt32 = 0
            let physRootPort = usbDevice.bus.physPort(for: usbDevice.rootPort)
            self.dwords = [
                (contextEntries << 27) | UInt32(mtt ? 1 : 0)  << 25 | (usbDevice.speed.slotContextSpeed << 20) | usbDevice.routeString ,
                UInt32(physRootPort) << 16,
                (interrupter) << 22 | UInt32(parentPortNumber) << 8 | UInt32(parentHubSlotId),
                0
            ]
        }

        // 6.2.2.2 Configure Endpoint Command Usage
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

        init(endpoint: USB.EndpointDescriptor,
             speed: USB.Speed,
             dequeuePointer: PhysAddress,
             dequeueCycleState: Bool) {

            // DWord 0
            // Compute the interval in multiples of 125us. Section 6.2.3.6 Interval
            // bInterval is UInt8
            let interval: UInt32
            switch (speed, endpoint.transferType) {
                case (_, .control), (_, .bulk), (.lowSpeed, .isochronous):
                    interval = 0

                case (.fullSpeed, .interrupt), (.lowSpeed, .interrupt):
                    // input 1-255, output 3-10
                    interval = UInt32(max(endpoint.bInterval, 1).highestBitSet + 2)

                case (.fullSpeed, .isochronous):
                    // input 1-16 (1-32768ms) output 3-18
                    interval = UInt32(min(max(endpoint.bInterval, 1), 16) + 2)

                case (_, .interrupt), (_, .isochronous):
                    // input 1-16 (125-4095us) output 0-15
                    interval = UInt32(min(max(endpoint.bInterval, 1), 16) - 1)
            }

            // FIXME for SS Bulk endpoints
            let maxPStreams: UInt32 = 0
            let lsa: UInt32 = 0
            let dword0 = (interval << 16) | (lsa << 15) | (maxPStreams << 10)

            // DWord 1
            let maxPacketSize = endpoint.maxPacketSize
            let cErr: UInt32 = endpoint.transferType == .isochronous ? 0 : 3 << 1
            let epType = endpoint.endpointType << 3
            let dword1 = UInt32(maxPacketSize) << 16 | epType | cErr

            let dcs: UInt32 = dequeueCycleState ? 1 : 0

            dwords = [dword0, dword1,
                      UInt32(truncatingIfNeeded: dequeuePointer.value & ~0xf) | dcs,
                      UInt32(truncatingIfNeeded: dequeuePointer.value >> 32)]
        }
    }


    func allocatePipe(usbDevice: USBDevice,
                      endpointDescriptor: USB.EndpointDescriptor) -> USBPipe? {

        guard let deviceData = usbDevice.hcdData as? XHCIDeviceData else {
            #kprint("xhci-pipe: No per device data")
            return nil
        }

        let direction = endpointDescriptor.direction == .hostToDevice ? 0 : 1
        let ep = Int(endpointDescriptor.endpoint)
        let pipeIdx = ep == 0 ? 1 : (ep * 2) + direction
        guard deviceData.pipes[pipeIdx - 1] == nil else {
            #kprintf("xhci-pipe: Pipe already active for endpoint %u\n", endpointDescriptor.endpoint)
            return nil
        }
        let pipe = XHCIPipe(usbDevice: usbDevice, endpointDescriptor: endpointDescriptor, deviceData)
        if let pipe {
            if XHCIDebug {
                #kprintf("xhci-pipe: Adding new pipe for ep: %d dir: %s epId: %d pipeIdx: %d\n",
                         ep, endpointDescriptor.direction.description, pipe.epContextSlot, pipeIdx)
            }
            deviceData.pipes[pipe.epContextSlot - 1] = pipe
        }
        return pipe
    }
}

fileprivate extension HCD_XHCI {
    final class XHCIPipe: USBPipe {
        private let deviceData: XHCIDeviceData
        private(set) var maxPacketSize0: Int
        private var transferRing: ProducerRing<TransferTRB>
        private var inputContext: MMIORegion
        private var urb: USB.Request?
        private var expectedTRB = PhysAddress(0)
        let epContextSlot: Int  // 1 - 31


        init?(usbDevice: USBDevice, endpointDescriptor: USB.EndpointDescriptor,
              _ deviceData: XHCIDeviceData) {
            self.deviceData = deviceData
            self.maxPacketSize0 = usbDevice.maxPacketSize0
            self.transferRing = ProducerRing()

            let direction = endpointDescriptor.direction == .hostToDevice ? 0 : 1
            self.epContextSlot = Int(endpointDescriptor.endpoint) == 0 ? 1 : (Int(endpointDescriptor.endpoint) * 2) + direction
            if XHCIDebug {
                #kprintf("xhci-pipe: direction: %d endpointDescriptor.endpoint: %d epContextSlot: %d\n",
                         direction, Int(endpointDescriptor.endpoint), epContextSlot)
            }
            self.inputContext = deviceData.inputDeviceContext

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
             * The first context the input control context, 2x32 bits 2 bits per remaining
             * contexts.
             * 1 bit to add the context and one to remove it.
             * This control context is followed by:
             * Device Context 0 is the slot context which is always setup
             * Device Context 1 is EP context for the control endpoint (EP0) regardless of direction
             * Device Context 2-3  are EP contexts for endpoint 1 2=OUT direction 3=IN direction
             *     ...
             * Device Context 30-31 are for endpoint 15 30=OUT direction 31=IN direction
             */

            let contextSize = deviceData.hcd.allocator.contextSize   // Either 32 or 64 bytes

            // Input Device Context - Data sent to the xHC
            // Set Add for input context and EP context to enable slot context and Control EP0
            let value = UInt32(1 << self.epContextSlot) | 1
            self.inputContext.write(value: value, toByteOffset: 4)

            // Configure the slot context
            let slotCtxOffset = contextSize
            let slotContext: SlotContext
            // Include the current slot as it will not be in the array of pipes yet
            let contextEntries = max(self.deviceData.maxDCI(), self.epContextSlot)

            if endpointDescriptor.endpoint == 0 {
                if XHCIDebug {
                    #kprintf("xhci-pipe: Configuring EP0 routeString: 0x%6.6x rootPort: %u\n",
                             usbDevice.routeString, usbDevice.rootPort
                    )
                }
                // For EP0, used for Address Device command
                slotContext = SlotContext(for: usbDevice)
            } else {

                if let hubDriver = usbDevice.deviceDriver as? USBHubDriver {
                    // Configure endpoint as a Hub
                    // TODO: Get settings
                    if XHCIDebug {
                        #kprintf("hub, ports: %d ttThinkTime: %d speed: %s\n",
                                 hubDriver.ports, hubDriver.hubDescriptor.ttThinkTime,
                                 usbDevice.speed.description
                        )
                    }
                    let isHighSpeed = usbDevice.speed == .highSpeed
                    slotContext = SlotContext(
                        contextEntries: contextEntries,
                        numberOfHubPorts: UInt8(hubDriver.ports),
                        ttThinkTime: isHighSpeed ? hubDriver.hubDescriptor.ttThinkTime : 0,
                        mtt: isHighSpeed ? hubDriver.multiTT : false
                    )
                } else {
                    // For all other endpoints used for configure endpoint command
                    slotContext = SlotContext(contextEntry: contextEntries)
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

            let epContext = EndpointContext(
                endpoint: endpointDescriptor,
                speed: usbDevice.speed,
                dequeuePointer: self.transferRing.ringBaseAddress,
                dequeueCycleState: true
            )
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

            guard let commandCompletion = deviceData.hcd.writeCommandTRB(commandTrb) else {
                fatalError("xhci-pipe: Failed to send command TRB")
            }
            guard commandCompletion.slotId == deviceData.slotId else {
                fatalError("xhci-pipe: slotId \(commandCompletion.slotId) is wrong \(deviceData.slotId)")
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
            // Use an Evaluate Context Command
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
            self.maxPacketSize0 = maxPacketSize
        }

        override func submitURB(_ urb: consuming USB.Request) {
            guard self.urb == nil else {
                fatalError("xhci-pipe: Endpoint already processing URB")
            }

            let transfer = urb.transfer
            self.urb = consume urb
            if XHCIDebug {
                #kprintf("xhci-pipe Set urb for %d/%d to valid URB: %s\n",
                         self.deviceData.slotId, self.epContextSlot, self.urb != nil)
            }

            switch transfer {
                case .control(let request):
                    self.submitControl(request, nil, 0)

                case .controlWithBuffer(let request, let buffer, let bytes):
                    self.submitControl(request, buffer, bytes)

                case .interrupt(let buffer, let bytesToTransfer):
                    self.submitInterrupt(buffer, bytesToTransfer)

                case .bulk, .isochronous:
                    fatalError("xhci-pipe: Failed to process URBs for bulk/ISO yet")
            }
        }


        // Called in interrupt context
        private var gotEvent = false
        fileprivate func processEventTRB(_ trb: EventTRB.Transfer) {

            if let trbPointer = trb.trbPointer, self.expectedTRB.value != UInt(trbPointer) {
                #kprintf("xhci-pipe: %d/%d Got unexpected TRB, expecting %p got %p\n",
                         trb.slotId, trb.endpointId, self.expectedTRB, trbPointer)
                return
            }
            self.expectedTRB = PhysAddress(0)

            if XHCIDebug {
                if trb.completionCode != 1 {
                    #kprintf("\n**xhci-pipe, completionCode: %d remaining bytes: %d\n",
                         Int(trb.completionCode), Int(trb.trbTransferLength))
                }
                #kprintf("**xhci-pipe: event: cc: %d trbp: %p ed: %p ttlen: %u trbt: %d ep: %d sl: %u urb: %s\n",
                         trb.completionCode,
                         trb.trbPointer ?? 0,
                         trb.eventData ?? 0,
                         trb.trbTransferLength,
                         trb.trbTypeValue,
                         trb.endpointId,
                         trb.slotId,
                         self.urb != nil
                )
            }
            guard let urb = self.urb.take() else {
                #kprintf("\n**xhci-pipe: %d/%d Got transfer event %d when no URB is active\n",
                         trb.slotId, trb.endpointId, trb.completionCode)
                return
            }
            if XHCIDebug {
                #kprintf("**xhci-pipe: Set urb to nil for %d/%d: %s\n",
                         self.deviceData.slotId, self.epContextSlot, self.urb == nil
                )
            }
            gotEvent = true

            let bytesTransferred = urb.transfer.bytesToTransfer - trb.trbTransferLength
//            #kprintf("xhci-pipe: bytesToTransfer: %d trbTransferLength: %d bytesTransferred: %d\n",
//                     urb.bytesToTransfer, Int(trb.trbTransferLength), bytesTransferred)
            let status: USBPipe.Status
            switch trb.completionCode {
                case 1:
                    status = .finished

                case 6:
                    status = .stalled

                case 0:
                    #kprint("xhci-pipe: Invalid completion code")
                    status = .timedout

                case 2:
                    #kprint("xhci-pipe: databuffer error")
                    status = .timedout

                case 3:
                    #kprint("xhci-pipe: babble detected")
                    status = .timedout

                case 4:
                    #kprint("xhci-pipe: transaction error")
                    status = .timedout

                case 5:
                    #kprint("xhci-pipe: TRB error")
                    status = .timedout

                case 7:
                    #kprint("xhci-pipe: resource error")
                    status = .timedout

                case 8:
                    #kprint("xhci-pipe: bandwidth error")
                    status = .timedout

                case 13:
                    if XHCIDebug {
                        #kprintf("\n**xhci-pipe: short packet wanted: %d remaining: %d got: %d\n",
                                 urb.transfer.bytesToTransfer,
                                 Int(trb.trbTransferLength), bytesTransferred)
                    }
                    status = .timedout

                default:
                    status = .timedout
            }
            let response = USB.Response(status: status, bytesTransferred: bytesTransferred)
            if false {
                #kprintf("\n**xhci-pipe: Calling completion whith status: %s bytes xfer: %d\n",
                         status.description, bytesTransferred)
            }
            let handler = urb.completionHandler
            handler(urb, response)
        }


        private func submitControl(
            _ request: USB.ControlRequest, _ buffer: MMIOSubRegion?,  _ bytesToTransfer: UInt32)
        {
            let direction = request.direction
            let trt: Int
            if buffer == nil {
                // No data stage
                trt = 0
            } else {
                // OUT data stage = 2 IN data stage = 3
                trt = direction == .hostToDevice ? 2 : 3
            }

            // Write the first TRB with the cyclebit toggled to what it should be so the
            // xHC will not start executing the TRB until all three are inplace
            // Save the trRingOffset so that the setupTRB can be updated with the cyclebit set
            // correctly.
            let setupTrb = TransferTRB.setupStage(request: request, interrupter: 0,
                                                  interruptOnComplete: false, trt: trt)

            let setupAddr = transferRing.addTRB(setupTrb, enable: false)
            if XHCIDebug {
                #kprintf("xhci-pipe: Added SETUP  TRB @ %p  0x%8.8x 0x%8.8x 0x%8.8x 0x%8.8x\n",
                         setupAddr,
                         setupTrb.dwords[0], setupTrb.dwords[1], setupTrb.dwords[2], setupTrb.dwords[3]
                )
            }
            var useDataTRB = true   // First TRB is Data, rest are Normal
            if let buffer {
                if XHCIDebug {
                    #kprintf("xhci-pipe: Adding data TRBs for %d bytes, dir: %s maxPacketSize0: %d\n",
                             bytesToTransfer, direction.description, self.maxPacketSize0)
                }
                if buffer.count < Int(bytesToTransfer) {
                    fatalError("xhci-pipe: buffer.count\(buffer.count) is too small for urb.bytesToTransfer\(bytesToTransfer)")
                }
                var bytesLeft = bytesToTransfer
                var bufferIndex: UInt32 = 0
                var totalTDs = (bytesLeft - 1) / UInt32(self.maxPacketSize0)
                totalTDs += 1
                while bytesLeft > 0 {
                    totalTDs -= 1   // Last TD has 0, subtracting now avoids underflow (if done at end of loop)
                    let dataBuffer: TransferTRB.DataBuffer
                    let length = min(bytesLeft, UInt32(self.maxPacketSize0))
                    bytesLeft -= length

                    if direction == .hostToDevice {
                        // OUT data stage
                        if length <= 8 {
                            var inlineBuffer: InlineArray<8, UInt8> = .init(repeating: 0)
                            for idx in 0..<length {
                                inlineBuffer[Int(idx)] = buffer[Int(bufferIndex + idx)]
                            }
                            dataBuffer = .data(inlineBuffer, length)
                        } else {
                            dataBuffer = .address(buffer.baseAddress + UInt(bufferIndex), length)
                        }
                    } else {
                        // IN data stage
                        dataBuffer = .address(buffer.baseAddress + UInt(bufferIndex), length)
                    }
                    let chain = bytesLeft > 0
                    let trb: TransferTRB
                    if useDataTRB {
                        trb = TransferTRB.dataStage(
                            dataBuffer, tdSize: totalTDs, interrupter: 0,
                            readData: trt == 3,
                            interruptOnComplete: false, //!chain,
                            chain: chain,
                            interruptOnShortPacket: false,
                            evaluateNextTRB: true
                        )
                    } else {
                        trb = TransferTRB.normal(
                            dataBuffer, tdSize: totalTDs, interrupter: 0,
                            blockInterrupt: false,
                            interruptOnComplete: false, //!chain,
                            chain: chain, noSnoop: false,
                            interruptOnShortPacket: false,
                            evaluateNextTrb: true
                        )
                    }
                    let addr = transferRing.addTRB(trb)
                    if XHCIDebug {
                        #kprintf("xhci-pipe: Added %s TRB @ %p of address: %p length: %u tdSize: %d chain: %s 0x%8.8x 0x%8.8x 0x%8.8x 0x%8.8x\n",
                                 useDataTRB ? "DATA  " : "NORMAL", addr.value,
                                 buffer.baseAddress + UInt(bufferIndex),
                                 length, totalTDs, bytesLeft > 0,
                                 trb.dwords[0], trb.dwords[1], trb.dwords[2], trb.dwords[3])
                    }
                    useDataTRB = false
                    bufferIndex += length

                }
            }

            let statusTrb = TransferTRB.statusStage(
                interrupter: 0, readData: trt != 3,
                interruptOnComplete: true,
                chain: false, evaluateNextTRB: false
            )
            let addr = transferRing.addTRB(statusTrb)
            self.expectedTRB = addr
            gotEvent = false
            if XHCIDebug {
                #kprintf("xhci-pipe: Added status TRB @ %p enabling TRB and ringing doorbell\n", addr)
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
            if gotEvent { return }
            #kprintf("xhci-pipe: %u/%d timedout waiting for urb\n",
                     self.deviceData.slotId, self.epContextSlot)
            self.expectedTRB = PhysAddress(0)
            // Needs to be atomic exchange
            guard let urb = self.urb.take() else {
                #kprintf("xhci-pipe: %u/%d Transfer timed out and there is no URB\n",
                         self.deviceData.slotId, self.epContextSlot)
                return
            }
            let response = USB.Response(status: .timedout, bytesTransferred: 0)
            let handler = urb.completionHandler
            handler(urb, response)
        }


        private func submitInterrupt(_ buffer: MMIOSubRegion, _ bytesToTransfer: UInt32) {
            let dataBuffer: TransferTRB.DataBuffer
            if self.endpointDescriptor.direction == .hostToDevice, bytesToTransfer <= 8 {
                var inlineBuffer: InlineArray<8, UInt8> = .init(repeating: 0)
                for idx in 0..<bytesToTransfer {
                    inlineBuffer[Int(idx)] = buffer[Int(idx)]
                }
                // FIXME: always Use urb.bytesToTransfer and allow for multiple
                dataBuffer = .data(inlineBuffer, bytesToTransfer)
            } else {
                dataBuffer = .address(buffer.baseAddress, bytesToTransfer)
            }
            let trb = TransferTRB.normal(
                dataBuffer, tdSize: 0, interrupter: 0, blockInterrupt: false,
                interruptOnComplete: true, chain: false, noSnoop: true,
                interruptOnShortPacket: true, evaluateNextTrb: false
            )
            self.expectedTRB = transferRing.addTRB(trb)
            deviceData.hcd.doorbells.ring(Int(deviceData.slotId), taskId: 0,
                                          target: UInt8(self.epContextSlot))
        }
    }
}


final class XHCIDeviceData: HCDData {
    let hcd: HCD_XHCI
    let slotId: UInt8
    let deviceContext: MMIORegion
    let inputDeviceContext: MMIORegion
    fileprivate var pipes: InlineArray<31, HCD_XHCI.XHCIPipe?> = .init(repeating: nil)

    init(hcd: HCD_XHCI) {
        self.hcd = hcd
        // Do the device setup
        (self.slotId, self.deviceContext) = hcd.enableSlot()
        self.inputDeviceContext = hcd.allocator.allocInputDeviceContect()

        if XHCIDebug {
            #kprintf("xhci-pipe: enableSlot returned slotId %d\n", self.slotId)
        }
        super.init()
        hcd.addDeviceData(self, forSlot: Int(self.slotId))
    }

    deinit {
        // TODO: Free deviceContext and inputDeviceContext
    }

    // Return the maximum Device Context Index for the slot context.
    // There are 31 potential endpoint (EP0 == pipe1) but the first context is not an endpoint
    // so the index into the array (0...30) needs to be +1 (1...31)
    func maxDCI() -> Int {
        var dci = 0
        for idx in pipes.indices {
            if pipes[idx] != nil {
                dci = idx + 1
            }
        }
        return dci
    }

    func processTRB(_ trb: HCD_XHCI.EventTRB.Transfer, endpointId: Int) -> Bool {
        if XHCIDebug {
            #kprintf("xhci-pipe: processing TRB for endpoint: %d\n", endpointId)
        }
        guard let pipe = self.pipes[endpointId - 1] else {
            #kprintf("xhci-pipe: No active pipe found for endpoint %d\n", endpointId)
            return false
        }
        pipe.processEventTRB(trb)
        return true
    }
}
