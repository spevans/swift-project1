/*
 * kernel/devices/usb/uhci-queuehead.swift
 *
 * Created by Simon Evans on 01/11/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * UHCI QueueHead and FrameList Entry.
 *
 */


extension HCD_UHCI {

    struct FrameListPointer {
        private let bits: BitArray32
        var rawValue: UInt32 { bits.rawValue }


        init(queueHead address: UInt32) {
            precondition(address & 0xf == 0)
            bits = BitArray32(address | (1 << 1))
        }

        init(transferDescriptor address: UInt32) {
            precondition(address & 0xf == 0)
            bits = BitArray32(address)
        }

        private init(rawValue: UInt32) {
            bits = BitArray32(rawValue)
        }

        static func terminator() -> FrameListPointer {
            return FrameListPointer(rawValue: 1)
        }

        var isTerminator: Bool { bits[0] == 1 }
        var isEmptyFrame: Bool { isTerminator }
        var isQueueHead: Bool { bits[1] == 1 }
        var isTransferDescriptor: Bool { !isQueueHead }
        // FIXME: This should be a PhyiscalAddress in the 1st 4G with correct type
        var address: UInt32 { bits.rawValue & 0xffff_fff0 }
        var physQueueHead: PhysQueueHead? {
            if isQueueHead && !isTerminator {
                return PhysQueueHead(address: PhysAddress(RawAddress(address)))
            } else {
                return nil
            }
        }
    }


    struct QueueHead: CustomStringConvertible {
        var description: String {
            return "headLP: \(headLinkPointer.description) elementLP: \(elementLinkPointer.description)"
        }

        struct QueueHeadLinkPointer: Equatable, CustomStringConvertible {
            let bits: BitArray32

            init(queueHeadAddress: UInt32) {
                precondition(queueHeadAddress & 0xf == 0)
                var bits = BitArray32(queueHeadAddress)
                bits[1] = 1
                self.bits = bits
            }

            init(transferDescriptorAddress: UInt32) {
                precondition(transferDescriptorAddress & 0xf == 0)
                self.bits = BitArray32(transferDescriptorAddress)
            }

            private init(rawValue: UInt32) {
                bits = BitArray32(rawValue)
            }

            static func terminator() -> QueueHeadLinkPointer {
                QueueHeadLinkPointer(rawValue: 1)
            }

            var isTerminator: Bool { bits[0] == 1 }
            var isQueueHead: Bool { bits[1] == 1 }
            var isTransferDescriptor: Bool { !isQueueHead }
            var address: UInt32 { bits.rawValue & 0xffff_fff0 }

            var nextQH: PhysQueueHead? {
                if isQueueHead && !isTerminator {
                    return PhysQueueHead(address: PhysAddress(RawAddress(address)))
                } else {
                    return nil
                }
            }

            var description: String {
                if isTerminator {
                    return "Terminate"
                } else {
                    return (isQueueHead ? "QH" : "TD") + " \(String(address, radix: 16))"
                }
            }
        }

        struct QueueElementLinkPointer: CustomStringConvertible {
            let bits: BitArray32

            init(queueHeadAddress: UInt32) {
                precondition(queueHeadAddress & 0xf == 0)
                var bits = BitArray32(queueHeadAddress)
                bits[1] = 1
                self.bits = bits
            }

            init(transferDescriptorAddress: UInt32) {
                precondition(transferDescriptorAddress & 0xf == 0)
                self.bits = BitArray32(transferDescriptorAddress)
            }

            init(rawValue: UInt32) {
                bits = BitArray32(rawValue)
            }

            static func terminator() -> QueueElementLinkPointer {
                QueueElementLinkPointer(rawValue: 1)
            }

            var isTerminator: Bool { bits[0] == 1 }
            var isQueueHead: Bool { bits[1] == 1 }
            var isTransferDescriptor: Bool { !isQueueHead }
            var address: UInt32 { bits.rawValue & 0xffff_fff0 }

            var description: String {
                if isTerminator {
                    return "Terminate"
                } else {
                    return (isQueueHead ? "QH" : "TD") + " \(String(address, radix: 16))"
                }
            }
        }

        var headLinkPointer: QueueHeadLinkPointer
        var elementLinkPointer: QueueElementLinkPointer
        // QueueHeads are on 16byte boundaries so there is unused space that the driver can use
        private let unused1: UInt32 = 0
        private let unused2: UInt32 = 0

        init(headLinkPointer: QueueHeadLinkPointer, elementLinkPointer: QueueElementLinkPointer) {
            self.headLinkPointer = headLinkPointer
            self.elementLinkPointer = elementLinkPointer
        }

        // Dump a QueueHead showing the list of TDs and QHs below it
        func dump() -> String {
            var result = "QHLP: "
            if headLinkPointer.isTerminator {
                result += "Terminates\n"
            } else {
                result += (headLinkPointer.isQueueHead ? "QH" : "TD") + ": \(String(headLinkPointer.address, radix: 16))\n"
            }
            var idx = 0
            var lp = elementLinkPointer
            while !lp.isTerminator {
                result += "\(idx): \(lp.isQueueHead ? "QH" : "TD") "
                let ptr = PhysAddress(RawAddress(lp.address))
                result += String(lp.address, radix: 16) + " "
                if lp.isQueueHead {
                    let qh = ptr.rawPointer.assumingMemoryBound(to: QueueHead.self)
                    result += qh.pointee.description + "\n"
                    lp = qh.pointee.elementLinkPointer
                } else {
                    let td = ptr.rawPointer.assumingMemoryBound(to: TransferDescriptor.self)
                    result += td.pointee.description + "\n"
                    lp = QueueElementLinkPointer(rawValue: td.pointee.linkPointer.bits.rawValue)
                }
                idx += 1
            }
            result += "\(idx): Terminates\n"

            return result
        }
    }

    typealias QueueHeadPtr = UnsafeMutablePointer<QueueHead>

    struct PhysQueueHead: CustomStringConvertible {
        let address: PhysAddress

        init(address: PhysAddress) {
            self.address = address
        }

        var pointer: QueueHeadPtr {
            return address.rawPointer.bindMemory(to: QueueHead.self, capacity: 1)
        }

        var physAddress: UInt32 { UInt32(address.value) }

        func setQH(_ queueHead: QueueHead) {
            self.address.rawPointer.storeBytes(of: queueHead, as: QueueHead.self)
        }

        // Forward properties to the QueueHead
        var headLinkPointer: QueueHead.QueueHeadLinkPointer {
            get { pointer.pointee.headLinkPointer }
            set { pointer.pointee.headLinkPointer = newValue }
        }
        var elementLinkPointer: QueueHead.QueueElementLinkPointer {
            get { pointer.pointee.elementLinkPointer }
            set { pointer.pointee.elementLinkPointer = newValue }
        }

        var description: String {
            return "PhysQH: \(address): " + pointer.pointee.description
        }

        func dump() -> String {
            pointer.pointee.dump()
        }
    }
}
