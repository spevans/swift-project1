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

        init(rawValue: UInt32) {
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
        var physQueueHeadAddress: PhysAddress? {
            if isQueueHead && !isTerminator {
                //return PhysQueueHead(address: PhysAddress(RawAddress(address)))
                return PhysAddress(RawAddress(address))
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

            fileprivate init(rawValue: UInt32) {
                bits = BitArray32(rawValue)
            }

            static func terminator() -> QueueHeadLinkPointer {
                QueueHeadLinkPointer(rawValue: 1)
            }

            var isTerminator: Bool { bits[0] == 1 }
            var isQueueHead: Bool { bits[1] == 1 }
            var isTransferDescriptor: Bool { !isQueueHead }
            var address: UInt32 { bits.rawValue & 0xffff_fff0 }

            var nextQHAddress: PhysAddress? {
                if isQueueHead && !isTerminator {
                    //return PhysQueueHead(address: PhysAddress(RawAddress(address)))
                    return PhysAddress(RawAddress(address))
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
        let unused1: UInt32 = 0
        let unused2: UInt32 = 0

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


    struct PhysQueueHead: CustomStringConvertible {
        let mmioSubRegion: MMIOSubRegion

        init(mmioSubRegion: MMIOSubRegion) {
            self.mmioSubRegion = mmioSubRegion
        }

        var physAddress: UInt32 { UInt32(mmioSubRegion.baseAddress.value) }

        func setQH(_ queueHead: QueueHead) {
            mmioSubRegion.write(value: queueHead.headLinkPointer.bits.rawValue, toByteOffset: 0)
            mmioSubRegion.write(value: queueHead.elementLinkPointer.bits.rawValue, toByteOffset: 4)
            mmioSubRegion.write(value: queueHead.unused1, toByteOffset: 8)
            mmioSubRegion.write(value: queueHead.unused2, toByteOffset: 12)
            writeMemoryBarrier()
        }

        // Forward properties to the QueueHead
        var headLinkPointer: QueueHead.QueueHeadLinkPointer {
            get { QueueHead.QueueHeadLinkPointer(rawValue: mmioSubRegion.read(fromByteOffset: 0)) }
            set {
                mmioSubRegion.write(value: newValue.bits.rawValue, toByteOffset: 0)
                writeMemoryBarrier()
            }
        }
        var elementLinkPointer: QueueHead.QueueElementLinkPointer {
            get { QueueHead.QueueElementLinkPointer(rawValue: mmioSubRegion.read(fromByteOffset: 4)) }
            set {
                mmioSubRegion.write(value: newValue.bits.rawValue, toByteOffset: 4)
                writeMemoryBarrier()
            }
        }

        var description: String {
            let queueHead = QueueHead(headLinkPointer: headLinkPointer, elementLinkPointer: elementLinkPointer)
            return "PhysQH: \(mmioSubRegion.baseAddress): \(queueHead)"
        }

        func dump() -> String {
            let queueHead = QueueHead(headLinkPointer: headLinkPointer, elementLinkPointer: elementLinkPointer)
            return queueHead.dump()
        }
    }
}
