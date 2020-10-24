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
    func allocatePipe(device: USBDevice, endpointDescriptor: USB.EndpointDescriptor) -> USBPipe {
        return UHCIPipe(hcd: self, device: device, endpointDescriptor: endpointDescriptor)
    }
}


fileprivate extension HCD_UHCI {
    final class UHCIPipe: USBPipe {
        private unowned let hcd: HCD_UHCI
        private unowned let device: USBDevice
        private let endpoint: UInt = 0
        private let maxPacketSize: UInt16 = 8
        private let isLowSpeedDevice: Bool
        private let queueHead: PhysQueueHead
        private var physBuffer: PhysBuffer32? = nil
        private let setupTd: PhysTransferDescriptor
        private let statusTd: PhysTransferDescriptor
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
            setupTd = hcd.allocator.allocTransferDescriptor()
            statusTd = hcd.allocator.allocTransferDescriptor()

            // Add the queue head into the global chain
            let queueHeadLP = hcd.qhStart.pointer.pointee.headLinkPointer
            hcd.qhStart.pointer.pointee.headLinkPointer = QueueHead.QueueHeadLinkPointer(queueHeadAddress: queueHead.physAddress)
            queueHead.pointer.pointee.headLinkPointer = queueHeadLP
        }

        deinit {
            hcd.allocator.freeQueueHead(queueHead)
            hcd.allocator.freeTransferDescriptor(setupTd)
            hcd.allocator.freeTransferDescriptor(statusTd)
            freeBuffer()
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
//            print("UHCI: Sending request:", request, "withBuffer:", withBuffer)
            // copy the request into a 32byte low buffer
            let buffer = hcd.allocator.allocPhysBuffer(length: MemoryLayout<USB.ControlRequest>.size)
            buffer.mutableRawPointer.storeBytes(of: request, as: USB.ControlRequest.self)
//            hexDump(buffer: buffer.rawBufferPointer)

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

            var tdAllocations = 0
            var nextTd: PhysTransferDescriptor
            if withBuffer {
//                print("UHCI: Allocating first dataTD, physBuffer is nil:", physBuffer == nil)
                nextTd = hcd.allocator.allocTransferDescriptor()
//                print("UHCI: Allocated:", String(nextTd.physAddress, radix: 16))
                tdAllocations = 1
            } else {
                // No data to add so the statusPid is the setupPid's next TD
                nextTd = statusTd
            }

            // Setup PID
            let requestLength = UInt(MemoryLayout<USB.ControlRequest>.size)
            assert(requestLength == 8)
            setupTd.pointer.pointee = TransferDescriptor(
                linkPointer: TransferDescriptor.LinkPointer(transferDescriptor: UInt32(nextTd.physAddress), depthFirst: true),
                controlStatus: TransferDescriptor.ControlStatus(active: true, lowSpeedDevice: isLowSpeedDevice, maxErrorCount: 3),
                token: TransferDescriptor.Token(pid: .pidSetup, deviceAddress: device.address, endpoint: endpoint, dataToggle: false, maximumLength: requestLength),
                bufferPointer: buffer.physAddress
            )
//            print("UHCI: setupTd: ", String(setupTd.physAddress, radix: 16), setupTd.pointer.pointee)
            var toggle = true

            // 0 or more data pids as necessary
            if withBuffer, let dataBuffer = physBuffer {
  //              print("UHCI: request.wLength:", request.wLength, "dataBuffer.rawBufferPointer.count:", dataBuffer.rawBufferPointer.count)
                precondition(request.wLength == dataBuffer.rawBufferPointer.count)
                precondition(request.wLength != 0)
                var bytesLeft = request.wLength
                var bufferPointer = dataBuffer.physAddress
                while bytesLeft > 0 {
                    let length = min(bytesLeft, maxPacketSize)
                    let dataTd = nextTd

                    bytesLeft -= min(maxPacketSize, bytesLeft)

                    if bytesLeft > 0 {
//                        print("UHCI: Allocating next dataTD")
                        nextTd = hcd.allocator.allocTransferDescriptor()
//                        print("UHCI: Allocated:", String(nextTd.physAddress, radix: 16))

                        tdAllocations += 1
                    } else {
                        // This is the last loop so the nextTd will not be for data
                        nextTd = statusTd
                    }

                    dataTd.pointer.pointee = TransferDescriptor(
                        linkPointer: TransferDescriptor.LinkPointer(transferDescriptor: UInt32(nextTd.physAddress), depthFirst: true),
                        controlStatus: TransferDescriptor.ControlStatus(active: true, lowSpeedDevice: isLowSpeedDevice, maxErrorCount: 3),
                        token: TransferDescriptor.Token(pid: dataPid, deviceAddress: device.address, endpoint: endpoint, dataToggle: toggle, maximumLength: UInt(length)),
                        bufferPointer: bufferPointer
                    )
                    bufferPointer += UInt32(maxPacketSize)
//                print("UHCI: dataTd:  ", String(dataTd.physAddress, radix: 16), dataTd.pointer.pointee)
                    toggle.toggle()
                }
            }

            // Status PID
            statusTd.pointer.pointee = TransferDescriptor(
                linkPointer: TransferDescriptor.LinkPointer.terminator(),
                controlStatus: TransferDescriptor.ControlStatus(active: true, lowSpeedDevice: isLowSpeedDevice, maxErrorCount: 3),
                token: TransferDescriptor.Token(pid: statusPid, deviceAddress: device.address, endpoint: endpoint, dataToggle: true, maximumLength: 0),
                bufferPointer: 0
            )
//            print("UHCI: statusTd:", String(statusTd.physAddress, radix: 16), statusTd.pointer.pointee)
//            print("UHCI: TD allocations:", tdAllocations)

            // Add the chain of Transfer Descriptors into the Queue Head.
            let queueElementLP = QueueHead.QueueElementLinkPointer(transferDescriptorAddress: setupTd.physAddress)
//            print("UHCI: queueElementLP:", queueElementLP)
            queueHead.pointer.pointee.elementLinkPointer = queueElementLP
//            print("UHCI: before send:", queueHead, queueHead.pointer.pointee.dump())

//            print("UHCI: Waiting for response...")
            var result = false

            for _ in 1...10 {
                if queueHead.pointer.pointee.elementLinkPointer.terminate {
                    result = true
                    break
                }
                sleep(milliseconds: 50)
            }

            // Get list of TDs to free
            var td = PhysTransferDescriptor(address: PhysAddress(RawAddress(setupTd.pointer.pointee.linkPointer.address)))
            while td.physAddress != statusTd.physAddress {
                tdAllocations -= 1
                let address = PhysAddress(RawAddress(td.pointer.pointee.linkPointer.address))
//                print("UHCI: Freeing:", String(td.physAddress, radix: 16))
                hcd.allocator.freeTransferDescriptor(td)
                td = PhysTransferDescriptor(address: address)
            }
            // Free the control request buffer
            hcd.allocator.freePhysBuffer(buffer)

            guard tdAllocations == 0 else {
                fatalError("tdAllocation = \(tdAllocations), corrupted link pointers")
            }

            if result {
  //              print("UHCI: Send OK")
//                if withBuffer, let dataBuffer = physBuffer {
//                    print("UHCI: Returned Data @ 0x\(String(dataBuffer.physAddress, radix: 16)), \(dataBuffer.rawBufferPointer):")
//                    hexDump(buffer: dataBuffer.rawBufferPointer)
//                }
            } else {
                print("UHCI: Send failed QueueHead after send:", queueHead, queueHead.pointer.pointee.dump())
            }

            return result
        }
    }
}
