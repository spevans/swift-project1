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
    func allocatePipe(device: USBDevice, endpointDescriptor: USB.EndpointDescriptor) -> USBPipe {
        return UHCIPipe(hcd: self, device: device, endpointDescriptor: endpointDescriptor)
    }
}


private let UHCI_DEBUG = false
private func uhciDebug(_ msg: Any...) {
    if UHCI_DEBUG {
        for m in msg {
            print(m, terminator: "")
        }
        print("")
    }
}

fileprivate extension HCD_UHCI {
    final class UHCIPipe: USBPipe {
        private unowned let hcd: HCD_UHCI
        private unowned let device: USBDevice
        private let maxPacketSize: UInt16 = 8
        private let isLowSpeedDevice: Bool
        private var queueHead: PhysQueueHead
        private var physBuffer: PhysBuffer32? = nil
        private let transferDescriptors: [PhysTransferDescriptor]

        // General USB
        let endpointDescriptor: USB.EndpointDescriptor


        init(hcd: HCD_UHCI, device: USBDevice, endpointDescriptor: USB.EndpointDescriptor) {
            switch device.speed {
                case .lowSpeed: isLowSpeedDevice = true
                case .fullSpeed: isLowSpeedDevice = false
                default: fatalError("UHCI: Unsupported speed: \(device.speed)")
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
                        bufferPointer: physBuffer!.physAddress
                    ))
                    print("UHCI-PIPE: Interrupt TD:", td, td.pointer) // FIXME td.pointer.pointee causes GP
                    _tds.append(td)
                    queueHead.elementLinkPointer = QueueHead.QueueElementLinkPointer(transferDescriptorAddress: td.physAddress)

                default:
                    fatalError("Pipes of type \(endpointDescriptor.transferType) are not currently supported")
            }

            transferDescriptors = _tds

            // Add the queue head into the global chain
            print("queueHead:", queueHead, "hcd.controlQH:", hcd.controlQH)
            hcd.addQueueHead(queueHead, transferType: endpointDescriptor.transferType, interval: endpointDescriptor.bInterval)
        }

        deinit {
            hcd.removeQueueHead(queueHead, transferType: endpointDescriptor.transferType)
            hcd.allocator.freeQueueHead(queueHead)
            for td in transferDescriptors {
                hcd.allocator.freeTransferDescriptor(td)
            }
            freeBuffer()
        }


        func pollInterruptPipe() -> [UInt8]? {
            guard case .interrupt = endpointDescriptor.transferType else {
                print("UHCI-PIPE: Attempting to poll an non interrupt pipe")
                return nil
            }
            var td = transferDescriptors.first!
            guard !td.controlStatus.active else {
                return nil
            }

            var result: [UInt8] = []
            result.reserveCapacity(Int(endpointDescriptor.maxPacketSize))
            for byte in physBuffer!.rawBufferPointer {
                result.append(byte)
            }
            // Reenable the Interrupt TD
            queueHead.elementLinkPointer = QueueHead.QueueElementLinkPointer(transferDescriptorAddress: td.physAddress)
            td.controlStatus.active = true
            return result
        }


        func allocateBuffer(length: Int) -> UnsafeRawBufferPointer {
            if physBuffer != nil {
                physBuffer!.length = UInt32(length)
            } else {
                physBuffer = hcd.allocator.allocPhysBuffer(length: length)
            }
            return physBuffer!.rawBufferPointer
        }

        func freeBuffer() {
            if let buffer = physBuffer {
                hcd.allocator.freePhysBuffer(buffer)
                physBuffer = nil
            }
        }


        func send(request: USB.ControlRequest, withBuffer: Bool) -> Bool {
           uhciDebug("UHCI: Sending request:", request, "withBuffer:", withBuffer)
            // copy the request into a 32byte low buffer
            let buffer = hcd.allocator.allocPhysBuffer(length: MemoryLayout<USB.ControlRequest>.size)
            buffer.mutableRawPointer.storeBytes(of: request, as: USB.ControlRequest.self)
            if UHCI_DEBUG { hexDump(buffer: buffer.rawBufferPointer) }

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

            let setupTd = transferDescriptors[0]
            let statusTd = transferDescriptors[1]

            var tdAllocations = 0
            var nextTd: PhysTransferDescriptor
            if withBuffer {
                uhciDebug("UHCI: Allocating first dataTD, physBuffer is anil:", physBuffer == nil)
                nextTd = hcd.allocator.allocTransferDescriptor()
                uhciDebug("UHCI: Allocated:", String(nextTd.physAddress, radix: 16))
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
                bufferPointer: buffer.physAddress
            ))
            uhciDebug("UHCI: setupTd: ", setupTd)
            var toggle = true

            // 0 or more data pids as necessary
            if withBuffer, let dataBuffer = physBuffer {
                uhciDebug("UHCI: request.wLength:", request.wLength, "dataBuffer.rawBufferPointer.count:", dataBuffer.rawBufferPointer.count)
                precondition(request.wLength == dataBuffer.rawBufferPointer.count)
                precondition(request.wLength != 0)
                var bytesLeft = request.wLength
                var bufferPointer = dataBuffer.physAddress
                while bytesLeft > 0 {
                    let length = min(bytesLeft, maxPacketSize)
                    let dataTd = nextTd

                    bytesLeft -= min(maxPacketSize, bytesLeft)

                    if bytesLeft > 0 {
                        uhciDebug("UHCI: Allocating next dataTD")
                        nextTd = hcd.allocator.allocTransferDescriptor()
                        uhciDebug("UHCI: Allocated:", String(nextTd.physAddress, radix: 16))

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
                    uhciDebug("UHCI: dataTd:  ", dataTd)
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
            uhciDebug("UHCI: statusTd:", statusTd)
            uhciDebug("UHCI: TD allocations:", tdAllocations)

            // Add the chain of Transfer Descriptors into the Queue Head.
            let queueElementLP = QueueHead.QueueElementLinkPointer(transferDescriptorAddress: setupTd.physAddress)
            uhciDebug("UHCI: queueElementLP:", queueElementLP)
            queueHead.elementLinkPointer = queueElementLP
            uhciDebug("UHCI: before send:", queueHead, queueHead.dump())

            uhciDebug("UHCI: Waiting for response...")
            var result = false

            for _ in 1...10 {
                if queueHead.elementLinkPointer.isTerminator {
                    result = true
                    break
                }
                sleep(milliseconds: 50)
            }

            // Get list of TDs to free
            var td = PhysTransferDescriptor(address: setupTd.linkPointer.physAddress)
            while td.physAddress != statusTd.physAddress {
                tdAllocations -= 1
                let address = td.linkPointer.physAddress
                uhciDebug("UHCI: Freeing:", String(td.physAddress, radix: 16))
                hcd.allocator.freeTransferDescriptor(td)
                td = PhysTransferDescriptor(address: address)
            }
            // Free the control request buffer
            hcd.allocator.freePhysBuffer(buffer)

            guard tdAllocations == 0 else {
                fatalError("tdAllocation = \(tdAllocations), corrupted link pointers")
            }

            if UHCI_DEBUG {
                if result {
                    print("UHCI: Send OK")
                    if withBuffer, let dataBuffer = physBuffer {
                        print("UHCI: Returned Data @ 0x\(String(dataBuffer.physAddress, radix: 16)), \(dataBuffer.rawBufferPointer):")
                        hexDump(buffer: dataBuffer.rawBufferPointer)
                    }
                } else {
                    print("UHCI: Send failed QueueHead after send:", queueHead, queueHead.dump())
                }
            }
            return result
        }
    }
}
