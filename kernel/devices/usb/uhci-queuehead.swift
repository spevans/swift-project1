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

    struct FrameListPointer: CustomStringConvertible {
        private let bits: BitArray32
        var rawValue: UInt32 { bits.rawValue }
        var description: String {
            return #sprintf("FLP: %s, RAW: 0x%8.8X addr: 0x%8.8x %s", isTransferDescriptor ? "TD" : "QH",
                            rawValue, address, isTerminator ? "T" : "")
        }

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
        var framePointer: PhysAddress? {
            if !isTerminator {
                //return PhysQueueHead(address: PhysAddress(RawAddress(address)))
                return PhysAddress(RawAddress(address))
            } else {
                return nil
            }
        }
    }


    struct QueueHead: CustomStringConvertible {
        var description: String {
            return "HLP: " + headLinkPointer.description + " HEP: " + elementLinkPointer.description
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

            init(rawValue: UInt32) {
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
                #sprintf("RAW:%8.8X %s @ 0x%8.8x %s", bits.rawValue, isQueueHead ? "QH" : "TD", address,
                         isTerminator ? "T" : " ")
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
                #sprintf("RAW:%8.8X %s @ 0x%8.8X %s", bits.rawValue, isQueueHead ? "QH" : "TD", address,
                         isTerminator ? "T" : " ")
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
        func dump(allocator: UHCIAllocator) -> String {
            var result = self.description + "\n"

            var idx = 0
            var address = elementLinkPointer.address
            var terminates = elementLinkPointer.isTerminator
            var isQueueHead = elementLinkPointer.isQueueHead
            while !terminates {
                result += #sprintf("UHCI\t  TD%d: [0x%8.8x] ", idx, address)
                let physAddress = PhysAddress(RawAddress(address))
                let region = allocator.fromPhysical(address: physAddress)
                if isQueueHead {
                    let qh = PhysQueueHead(mmioSubRegion: region)
                    result += qh.description
                    address = qh.elementLinkPointer.address
                    isQueueHead = qh.elementLinkPointer.isQueueHead
                    terminates = qh.elementLinkPointer.isTerminator
                } else {
                    let td = PhysTransferDescriptor(mmioSubRegion: region)
                    result += td.description
                    address = td.linkPointer.address
                    isQueueHead = td.linkPointer.isQueueHead
                    terminates = td.linkPointer.terminate
                }
                result += "\n"
                idx += 1
                if idx > 20 {
                    result += "TOO MANY ELEMENTS\n"
                    break
                }
            }

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

        func getQH() -> QueueHead {
            return QueueHead(headLinkPointer: headLinkPointer, elementLinkPointer: elementLinkPointer)
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
            let queueHead = getQH()
            return "PhysQH: \(mmioSubRegion.baseAddress): \(queueHead)"
        }

        func dump(allocator: UHCIAllocator) -> String {
            return getQH().dump(allocator: allocator)
        }
    }
}
