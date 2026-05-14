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
    func allocatePipe(usbDevice: USBDevice,
                      endpointDescriptor: USB.EndpointDescriptor) -> USBPipe? {
        return UHCIPipe(hcd: self, usbDevice: usbDevice, endpointDescriptor: endpointDescriptor)
    }
}

extension HCD_UHCI {

    final class UHCIPipe: USBPipe {
        private /*unowned*/ let hcd: HCD_UHCI
        private /*unowned*/ let usbDevice: USBDevice

        private var activeUrb: USB.Request?
        private var queueHead: PhysQueueHead
        private let transferDescriptors: [PhysTransferDescriptor]
        private let lastTdIndex: Int
        private var interruptDataToggle = false
        private var tdAllocations = 0

        // General USB
        private var timeout: UInt64 = 0


        init?(hcd: HCD_UHCI, usbDevice: USBDevice, endpointDescriptor: USB.EndpointDescriptor) {
            self.hcd = hcd
            self.usbDevice = usbDevice

            var _tds: [PhysTransferDescriptor] = []
            switch endpointDescriptor.transferType {
                case .control:
                    // Allocate the setup and status TDs
                    queueHead = hcd.allocator.allocQueueHead()
                    _tds.append(hcd.allocator.allocTransferDescriptor())
                    _tds.append(hcd.allocator.allocTransferDescriptor())
                    lastTdIndex = 1

                case .interrupt:
                    guard endpointDescriptor.bInterval > 0 else {
                        #uhciDebug("UHCI-PIPE Interrupt endpoint has interval of \(endpointDescriptor.bInterval), ignoring")
                        return nil
                    }
                    #uhciDebug("UHCI-PIPE: \(hcd.description)- Creating interrupt pipe, interval:", endpointDescriptor.bInterval)

                    // Allocate a buffer and the TDs to process it
                    let td = hcd.allocator.allocTransferDescriptor()
                    _tds.append(td)
                    lastTdIndex = 0

                    queueHead = hcd.allocator.allocQueueHead()
                    queueHead.elementLinkPointer = .terminator()
                    // Add the interrupt queue head into the global chain (TEMP since it was removed below)
                    hcd.addQueueHead(queueHead, transferType: endpointDescriptor.transferType, interval: endpointDescriptor.bInterval)

                default:
                    #kprint("Pipes of type \(endpointDescriptor.transferType) are not currently supported")
                    return nil
            }

            transferDescriptors = _tds
            super.init(endpointDescriptor: endpointDescriptor)
        }

        deinit {
            hcd.allocator.freeQueueHead(queueHead)
            for td in transferDescriptors {
                hcd.allocator.freeTransferDescriptor(td)
            }
        }


        override func allocateBuffer(length: Int) -> MMIOSubRegion {
            return hcd.allocator.allocPhysBuffer(length: length)
        }

        override func freeBuffer(_ buffer: MMIOSubRegion) {
            hcd.allocator.freePhysBuffer(buffer)
        }

        // FIXME: This needs to do more checks from the queue head and also timeout transfers better.
        // Also need to maintain a ptr to the current active TD to check that on eack poll a transfer is progressing
        private func _pollPipe(_ error: Bool) -> USBPipe.Status {
            // Walk the list of TransferDescriptors until an active one is found and report on its status
            // If the end of the list is reached then the request was processed successfully
            let startTd = transferDescriptors[0]
            let endTd = transferDescriptors[lastTdIndex]
            if error {
                #kprintf("pollPipe startTD: %8.8x endTd: %8.8x\n", startTd.physAddress, endTd.physAddress)
            }
            let mmioSubRegion = hcd.allocator.fromPhysical(address: PhysAddress(RawAddress(startTd.physAddress)))
            var td = PhysTransferDescriptor(mmioSubRegion: mmioSubRegion)

            repeat {
                if error {
                    #kprintf("Looking at TD @ %8.8x\n", td.physAddress)
                    #kprintf("Active TD:  actLen: %d active: %d IOC: %d isoTD: %d LoSD: %d maxErr: %d SPD: %d\n",
                             td.controlStatus.actualLength,
                             td.controlStatus.active ? 1 : 0,
                             td.controlStatus.interruptOnComplete ? 1 : 0,
                             td.controlStatus.isochronousTransferDescriptor ? 1 : 0,
                             td.controlStatus.lowSpeedDevice ? 1 : 0,
                             td.controlStatus.maxErrorCount,
                             td.controlStatus.shortPacketDetect ? 1 : 0)
                    #kprintf("MaxLen: %d dataToggle: %s\n", td.token.maximumLength, td.token.dataToggle)

                    if td.controlStatus.bitstuffError { #kprint("bitStuffError") }
                    if td.controlStatus.crcTimeoutError { #kprint("crcToError") }
                    if td.controlStatus.nakReceived { #kprint("NAK") }
                    if td.controlStatus.babbleDetected { #kprint("babble") }
                    if td.controlStatus.dataBufferError { #kprint("dataBufferError") }
                    if td.controlStatus.stalled { #kprint("stalled") }
                }
                if td.controlStatus.stalled {
                    #kprint(self.endpointDescriptor.transferType.description, "pipe has stalled!")
                    self.removeControl()
                    return .stalled
                }
                if td.controlStatus.nakReceived {
                    // ignore
                }
                if td.controlStatus.crcTimeoutError {
                    #kprint("Timedout")
                    self.removeControl()
                    return .timedout
                }

                if td.physAddress == endTd.physAddress { break }
                if td.linkPointer.terminate { break }

                let address = td.linkPointer.physAddress
                if error {
                    #kprintf("linkPointer.physAddress: %8.8x\n", address)
                }
                let mmioSubRegion = hcd.allocator.fromPhysical(address: address)
                td = PhysTransferDescriptor(mmioSubRegion: mmioSubRegion)
            } while td.physAddress != endTd.physAddress

            if td.physAddress == endTd.physAddress, !td.controlStatus.active {
                if self.endpointDescriptor.transferType == .control {
                    self.removeControl()
                }

                return .finished
                // Reached end and last TD is not active
            }
            return .inprogress
        }

        func pollPipe(_ error: Bool) -> USBPipe.Status {
            guard self.activeUrb != nil  else {
                fatalError("uhci-pipe: No active URB")
            }
            let status = self._pollPipe(error)
            if status != .inprogress {
                if let urb = self.activeUrb.take() {
                    self.activeUrb = nil
                    // FIXME, find the correct number of bytes for other statuses
                    let bytes = (status == .finished) ? urb.transfer.bytesToTransfer : 0
                    let response = USB.Response(status: status, bytesTransferred: bytes)
                    // FIXME
                    // urb.completionHandler(urb, response) has error:
                    // error: copy of noncopyable typed value. This is a compiler bug. Please file a bug with a small example of the bug
                    let handler = urb.completionHandler
                    handler(urb, response)
                }
            }
            return status
        }


        override func submitURB(_ urb: consuming USB.Request) {
            self.timeout = currentTicks() + 1000

            guard self.activeUrb == nil else {
                fatalError("uhci-pipe: Endpoint already processing URB")
            }
            let transfer = urb.transfer
            self.activeUrb = consume urb
            self.hcd.addActivePipe(self)

            switch transfer {
                case .control(let request):
                    self.submitControl(request, nil, 0)

                case .controlWithBuffer(let request, let buffer, let bytes):
                    self.submitControl(request, buffer, bytes)

                case .interrupt(let buffer, _):
                    self.submitInterrupt(buffer)

                case .bulk, .isochronous:
                    fatalError("Cannot process URBs for bulk/ISO yet")
            }
        }


        private func submitControl(
            _ request: USB.ControlRequest, _ withBuffer: MMIOSubRegion?, _ bytesToTransfer: UInt32)
        {
            let requestBuffer = self.hcd.allocator.allocPhysBuffer(
                length: MemoryLayout<USB.ControlRequest>.size
            )
            requestBuffer.storeBytes(of: request, as: USB.ControlRequest.self)
            defer { self.hcd.allocator.freePhysBuffer(requestBuffer) }

            let direction = request.direction
            let dataPid: TransferDescriptor.Token.PID
            let statusPid: TransferDescriptor.Token.PID

            // The Status PID is the opposite direction to the setup request. VMware didnt seem to care if this was wrong
            // for SetAddress() but QEMU definitely needs it set correctly.
            let enableSPD: Bool
            if case .hostToDevice = direction {
                dataPid = .pidOut
                statusPid = .pidIn
                enableSPD = true
            } else {
                dataPid = .pidIn
                statusPid = .pidOut
                enableSPD = false
            }

            let setupTd = transferDescriptors[0] // hcd.allocator.allocTransferDescriptor()
            var _statusTd: PhysTransferDescriptor?


            var nextTd: PhysTransferDescriptor
            if withBuffer != nil {
                nextTd = hcd.allocator.allocTransferDescriptor()
                tdAllocations = 1
            } else {
                // No data to add so the statusPid is the setupPid's next TD
                _statusTd = transferDescriptors[1] // hcd.allocator.allocTransferDescriptor()
                nextTd = _statusTd!
            }

            // Setup PID
            let requestLength = UInt(requestBuffer.count)
            assert(requestLength == 8)

            let endpoint = endpointDescriptor.endpoint
            setupTd.setTD(TransferDescriptor(
                linkPointer: TransferDescriptor.LinkPointer(transferDescriptor: UInt32(nextTd.physAddress), depthFirst: true),
                controlStatus: TransferDescriptor.ControlStatus(
                    active: true, lowSpeedDevice: self.usbDevice.isLowSpeedDevice,
                    maxErrorCount: 3, interruptOnComplete: false
                ),
                token: TransferDescriptor.Token(
                    pid: .pidSetup, deviceAddress: self.usbDevice.address,
                    endpoint: endpoint, dataToggle: false, maximumLength: requestLength
                ),
                bufferPointer: requestBuffer.physAddress32
            ))
            var toggle = true

            // 0 or more data pids as necessary
            if let dataBuffer = withBuffer {
                var bytesLeft = Int(bytesToTransfer)
                precondition(dataBuffer.count >= bytesLeft)
                var bufferPointer = dataBuffer.physAddress32
                while bytesLeft > 0 {
                    let length = min(bytesLeft, self.usbDevice.maxPacketSize0)
                    let dataTd = nextTd

                    bytesLeft -= length

                    if bytesLeft > 0 {
                        //#uhciDebug("Allocating next dataTD")
                        nextTd = hcd.allocator.allocTransferDescriptor()
                        //#uhciDebug("Allocated:", String(nextTd.physAddress, radix: 16))

                        tdAllocations += 1
                    } else {
                        // This is the last loop so the nextTd will not be for data
                        _statusTd = transferDescriptors[1] //hcd.allocator.allocTransferDescriptor()
                        nextTd = _statusTd!
                    }

                    //let spd = dataPid == .pidIn
                    dataTd.setTD(TransferDescriptor(
                        linkPointer: TransferDescriptor.LinkPointer(transferDescriptor: UInt32(nextTd.physAddress), depthFirst: true),
                        controlStatus: TransferDescriptor.ControlStatus(
                            active: true, lowSpeedDevice: self.usbDevice.isLowSpeedDevice,
                            maxErrorCount: 3, shortPacketDetect: enableSPD,
                            interruptOnComplete: false
                        ),
                        token: TransferDescriptor.Token(
                            pid: dataPid, deviceAddress: self.usbDevice.address,
                            endpoint: endpoint, dataToggle: toggle,
                            maximumLength: UInt(length)
                        ),
                        bufferPointer: bufferPointer
                    ))

                    bufferPointer += UInt32(self.usbDevice.maxPacketSize0)
                    toggle.toggle()
                }
            }

            guard let statusTd = _statusTd else { fatalError("statusTD was not allocated") }

            // Status PID
            statusTd.setTD(TransferDescriptor(
                linkPointer: TransferDescriptor.LinkPointer.terminator(),
                controlStatus: TransferDescriptor.ControlStatus(
                    active: true, lowSpeedDevice: self.usbDevice.isLowSpeedDevice,
                    maxErrorCount: 3, interruptOnComplete: true
                ),
                token: TransferDescriptor.Token(
                    pid: statusPid, deviceAddress: self.usbDevice.address,
                    endpoint: endpoint, dataToggle: true, maximumLength: 0),
                bufferPointer: 0
            ))

            // Add the chain of Transfer Descriptors into the Queue Head.
            //let queueHead = queueHeads[0]
            let queueElementLP = QueueHead.QueueElementLinkPointer(
                transferDescriptorAddress: setupTd.physAddress)
            queueHead.setQH(QueueHead(headLinkPointer: .terminator(),
                                      elementLinkPointer: queueElementLP
                                     ))
            // Add the queueHD into the global chain
            writeMemoryBarrier()
            //            hcd.statusRegister = hcd.statusRegister // clear bits
            hcd.addQueueHead(queueHead, transferType: endpointDescriptor.transferType, interval: endpointDescriptor.bInterval)
        }

        private func removeControl() {
            // Remove it from the global chain
            hcd.removeQueueHead(queueHead, transferType: endpointDescriptor.transferType)

            // Get list of TDs to free
            let setupTd = transferDescriptors[0]
            let statusTd = transferDescriptors[1]
            let mmioSubRegion = hcd.allocator.fromPhysical(address: setupTd.linkPointer.physAddress)
            var td = PhysTransferDescriptor(mmioSubRegion: mmioSubRegion)
            while td.physAddress != statusTd.physAddress {
                tdAllocations -= 1
                let address = td.linkPointer.physAddress
                hcd.allocator.freeTransferDescriptor(td)
                let mmioSubRegion = hcd.allocator.fromPhysical(address: address)
                td = PhysTransferDescriptor(mmioSubRegion: mmioSubRegion)
            }

            guard tdAllocations == 0 else {
                #kprintf("tdAllocations != 0 (%d), corrupted link pointers\n", tdAllocations)
                fatalError()
            }
        }


        private func submitInterrupt(_ physBuffer: MMIOSubRegion) {
            guard case .interrupt = endpointDescriptor.transferType,
                  let td = transferDescriptors.first else {
                fatalError("UHCI-PIPE: Attempting to poll a non interrupt pipe")
            }

            let transferDescriptor = TransferDescriptor(
                linkPointer: TransferDescriptor.LinkPointer.terminator(),
                controlStatus: TransferDescriptor.ControlStatus(
                    active: true, lowSpeedDevice: self.usbDevice.isLowSpeedDevice,
                    maxErrorCount: 3, interruptOnComplete: true
                ),
                token: TransferDescriptor.Token(
                    pid: .pidIn,
                    deviceAddress: self.usbDevice.address,
                    endpoint: endpointDescriptor.endpoint,
                    dataToggle: interruptDataToggle,
                    maximumLength: UInt(endpointDescriptor.maxPacketSize)
                ),
                bufferPointer: physBuffer.physAddress32
            )
            td.setTD(transferDescriptor)

            queueHead.elementLinkPointer = QueueHead.QueueElementLinkPointer(transferDescriptorAddress: td.physAddress)
            interruptDataToggle.toggle()
        }
    }
}
