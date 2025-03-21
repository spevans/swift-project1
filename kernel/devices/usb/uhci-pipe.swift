/*
 * kernel/devices/usb/uhci-pipe.swift
 *
 * Created by Simon Evans on 01/11/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * UHCI Pipes.
 *
 */


extension HCD_UHCI {
    // FIXME: The HCD should probably track any interrupt pipes that are allocated so that it can poll
    // all of the interrupt pipes when an IRQ actually occurs.
    func allocatePipe(device: USBDevice, endpointDescriptor: USB.EndpointDescriptor) -> USBPipe? {
        return UHCIPipe(hcd: self, device: device, endpointDescriptor: endpointDescriptor)
    }
}


fileprivate extension HCD_UHCI {
    final class UHCIPipe: USBPipe {
        private /*unowned*/ let hcd: HCD_UHCI
        private /*unowned*/ let device: USBDevice
        private let maxPacketSize: UInt16 = 8
        private let isLowSpeedDevice: Bool
        private var queueHead: PhysQueueHead
        private var physBuffer: MMIOSubRegion? = nil
        private let transferDescriptors: [PhysTransferDescriptor]

        // General USB
        let endpointDescriptor: USB.EndpointDescriptor


        init?(hcd: HCD_UHCI, device: USBDevice, endpointDescriptor: USB.EndpointDescriptor) {
            switch device.speed {
                case .lowSpeed: isLowSpeedDevice = true
                case .fullSpeed: isLowSpeedDevice = false
                default: #kprint("UHCI: Unsupported speed: \(device.speed)")
                return nil
            }
            self.hcd = hcd
            self.device = device
            self.endpointDescriptor = endpointDescriptor
            queueHead = hcd.allocator.allocQueueHead()

            var _tds: [PhysTransferDescriptor] = []

            switch endpointDescriptor.transferType {
                case .control:
                    // Allocate the setup and status TDs
                    _tds.append(hcd.allocator.allocTransferDescriptor())
                    _tds.append(hcd.allocator.allocTransferDescriptor())

                case .interrupt:
                    // Allocate a buffer and the TDs to process it
                    // FIXME, at the moment the QH for the interrupt is set to link to the ControlQH, it needs to link to the next interrupt (if there is one).
                    // Also, if interrupts are added in at different intervals, the linkPointer for each entry may be different depending on the frequencty of the interrupts.
                    // Eg consider 1 intr added to every frame and one added to every other frame. This will require adding more QHs.
                    physBuffer = hcd.allocator.allocPhysBuffer(length: Int(endpointDescriptor.maxPacketSize))
                    let td = hcd.allocator.allocTransferDescriptor()
                    td.setTD(TransferDescriptor(
                        linkPointer: TransferDescriptor.LinkPointer.terminator(),
                        controlStatus: TransferDescriptor.ControlStatus(active: true, lowSpeedDevice: isLowSpeedDevice, maxErrorCount: 3),
                        token: TransferDescriptor.Token(pid: .pidIn, deviceAddress: device.address, endpoint: endpointDescriptor.endpoint, dataToggle: false, maximumLength: UInt(endpointDescriptor.maxPacketSize)),
                        bufferPointer: physBuffer!.physAddress32
                    ))
                    #kprint("UHCI-PIPE: Interrupt TD:", td, td.mmioSubRegion) // FIXME td.pointer.pointee causes GP
                    _tds.append(td)
                    queueHead.elementLinkPointer = QueueHead.QueueElementLinkPointer(transferDescriptorAddress: td.physAddress)
                    // Add the interrupt queue head into the global chain (TEMP since it was removed below)
                    hcd.addQueueHead(queueHead, transferType: endpointDescriptor.transferType, interval: endpointDescriptor.bInterval)

                default:
                    #kprint("Pipes of type \(endpointDescriptor.transferType) are not currently supported")
                    return nil
            }

            transferDescriptors = _tds
        }

        deinit {
            if endpointDescriptor.transferType == .interrupt {
                hcd.removeQueueHead(queueHead, transferType: endpointDescriptor.transferType)
            }
            hcd.allocator.freeQueueHead(queueHead)
            for td in transferDescriptors {
                hcd.allocator.freeTransferDescriptor(td)
            }
            if let buffer = physBuffer {
                hcd.allocator.freePhysBuffer(buffer)
            }
        }


        override    func pollInterruptPipe() -> [UInt8]? {
            guard case .interrupt = endpointDescriptor.transferType else {
                #kprint("UHCI-PIPE: Attempting to poll an non interrupt pipe")
                return nil
            }
            var td = transferDescriptors.first!
            guard !td.controlStatus.active else {
                return nil
            }

            var result: [UInt8] = []
            result.reserveCapacity(Int(endpointDescriptor.maxPacketSize))
            for index in 0..<physBuffer!.count {
                let byte: UInt8 = physBuffer!.read(fromByteOffset: index)
                result.append(byte)
            }
            // Reenable the Interrupt TD
            queueHead.elementLinkPointer = QueueHead.QueueElementLinkPointer(transferDescriptorAddress: td.physAddress)
            td.controlStatus.active = true
            return result
        }


        override func allocateBuffer(length: Int) -> MMIOSubRegion {
            return hcd.allocator.allocPhysBuffer(length: length)
        }

        override func freeBuffer(_ buffer: MMIOSubRegion) {
            hcd.allocator.freePhysBuffer(buffer)
        }

        override func send(request: USB.ControlRequest, withBuffer: MMIOSubRegion?) -> Bool {
            #uhciDebug("Sending request:", request, "withBuffer:", (withBuffer?.description ?? "nil"))
            // copy the request into a 32byte low buffer
            let buffer = hcd.allocator.allocPhysBuffer(length: MemoryLayout<USB.ControlRequest>.size)
            #uhciDebug("Allocated buffer:", buffer)
            buffer.storeBytes(of: request, as: USB.ControlRequest.self)
            if UHCI_DEBUG { hexDump(buffer: buffer) }

            let dataPid: TransferDescriptor.Token.PID
            let statusPid: TransferDescriptor.Token.PID

            // The Status PID is the opposite direction to the setup request. VMware didnt seem to care if this was wrong
            // for SetAddress() but QEMU definitely needs it set correctly.
            if case .hostToDevice = request.direction {
                dataPid = .pidOut
                statusPid = .pidIn
            } else {
                dataPid = .pidIn
                statusPid = .pidOut
            }

            let setupTd = hcd.allocator.allocTransferDescriptor()
            let statusTd = hcd.allocator.allocTransferDescriptor()

            var tdAllocations = 0
            var nextTd: PhysTransferDescriptor
            if withBuffer != nil {
                #uhciDebug("Allocating first dataTD, physBuffer is nil:", physBuffer == nil)
                nextTd = hcd.allocator.allocTransferDescriptor()
                #uhciDebug("Allocated dataTd:", String(nextTd.physAddress, radix: 16))
                tdAllocations = 1
            } else {
                // No data to add so the statusPid is the setupPid's next TD
                nextTd = statusTd
            }

            // Setup PID
            let requestLength = UInt(MemoryLayout<USB.ControlRequest>.size)
            assert(requestLength == 8)

            let endpoint = endpointDescriptor.endpoint
            setupTd.setTD(TransferDescriptor(
                linkPointer: TransferDescriptor.LinkPointer(transferDescriptor: UInt32(nextTd.physAddress), depthFirst: true),
                controlStatus: TransferDescriptor.ControlStatus(active: true, lowSpeedDevice: isLowSpeedDevice, maxErrorCount: 3),
                token: TransferDescriptor.Token(pid: .pidSetup, deviceAddress: device.address, endpoint: endpoint, dataToggle: false, maximumLength: requestLength),
                bufferPointer: buffer.physAddress32
            ))
            var toggle = true

            // 0 or more data pids as necessary
            if let dataBuffer = withBuffer {
                #uhciDebug("request.wLength:", request.wLength, "dataBuffer.count:", dataBuffer.count)
                precondition(request.wLength == dataBuffer.count)
                precondition(request.wLength != 0)
                var bytesLeft = request.wLength
                var bufferPointer = dataBuffer.physAddress32
                while bytesLeft > 0 {
                    let length = min(bytesLeft, maxPacketSize)
                    let dataTd = nextTd

                    bytesLeft -= min(maxPacketSize, bytesLeft)

                    if bytesLeft > 0 {
                        #uhciDebug("Allocating next dataTD")
                        nextTd = hcd.allocator.allocTransferDescriptor()
                        #uhciDebug("Allocated:", String(nextTd.physAddress, radix: 16))

                        tdAllocations += 1
                    } else {
                        // This is the last loop so the nextTd will not be for data
                        nextTd = statusTd
                    }

                    dataTd.setTD(TransferDescriptor(
                        linkPointer: TransferDescriptor.LinkPointer(transferDescriptor: UInt32(nextTd.physAddress), depthFirst: true),
                        controlStatus: TransferDescriptor.ControlStatus(active: true, lowSpeedDevice: isLowSpeedDevice, maxErrorCount: 3),
                        token: TransferDescriptor.Token(pid: dataPid, deviceAddress: device.address, endpoint: endpoint, dataToggle: toggle, maximumLength: UInt(length)),
                        bufferPointer: bufferPointer
                    ))
                    bufferPointer += UInt32(maxPacketSize)
                    #uhciDebug("dataTd:  ", dataTd)
                    toggle.toggle()
                }
            }

            // Status PID
            statusTd.setTD(TransferDescriptor(
                linkPointer: TransferDescriptor.LinkPointer.terminator(),
                controlStatus: TransferDescriptor.ControlStatus(active: true, lowSpeedDevice: isLowSpeedDevice, maxErrorCount: 3),
                token: TransferDescriptor.Token(pid: statusPid, deviceAddress: device.address, endpoint: endpoint, dataToggle: true, maximumLength: 0),
                bufferPointer: 0
            ))
            #uhciDebug("statusTd:", statusTd)

            // Add the chain of Transfer Descriptors into the Queue Head.
            let queueElementLP = QueueHead.QueueElementLinkPointer(transferDescriptorAddress: setupTd.physAddress)
            #uhciDebug("queueElementLP:", queueElementLP)
            queueHead.elementLinkPointer = queueElementLP
            #uhciDebug("before send:", queueHead, queueHead.dump())

            // Add the queueHD into the global chain
            memoryBarrier()
            hcd.addQueueHead(queueHead, transferType: endpointDescriptor.transferType, interval: endpointDescriptor.bInterval)

            #uhciDebug("Waiting for response...")
            var result = false

            for _ in 1...10 {
                if queueHead.elementLinkPointer.isTerminator {
                    result = true
                    break
                }
                sleep(milliseconds: 50)
            }

            if !result {
                #uhciDebug("Send failed, queueHead dump\n", queueHead, queueHead.dump())
            }


            // Remove it from the global chain
            hcd.removeQueueHead(queueHead, transferType: endpointDescriptor.transferType)

            // Get list of TDs to free
            let mmioSubRegion = hcd.allocator.fromPhysical(address: setupTd.linkPointer.physAddress)
            var td = PhysTransferDescriptor(mmioSubRegion: mmioSubRegion)
            while td.physAddress != statusTd.physAddress {
                tdAllocations -= 1
                let address = td.linkPointer.physAddress
                #uhciDebug("Freeing:", String(td.physAddress, radix: 16))
                hcd.allocator.freeTransferDescriptor(td)
                let mmioSubRegion = hcd.allocator.fromPhysical(address: address)
                td = PhysTransferDescriptor(mmioSubRegion: mmioSubRegion)
            }
            hcd.allocator.freeTransferDescriptor(setupTd)
            hcd.allocator.freeTransferDescriptor(statusTd)

            // Free the control request buffer
            hcd.allocator.freePhysBuffer(buffer)

            guard tdAllocations == 0 else {
                fatalError("tdAllocation = \(tdAllocations), corrupted link pointers")
            }

            if UHCI_DEBUG {
                if result {
                    #kprint("UHCI: Send OK")
                    if let dataBuffer = withBuffer {
                        #kprint("UHCI: Returned Data @ \(dataBuffer):")
                        hexDump(buffer: dataBuffer)
                    }
                }
            }
            return result
        }
    }
}
