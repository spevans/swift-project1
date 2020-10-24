/*
 * kernel/devices/usb/uhci-datastructures.swift
 *
 * Created by Simon Evans on 01/11/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * UHCI Queue Head and Transfer Descriptors.
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

        var terminate: Bool { bits[0] == 1 }
        var emptyFrame: Bool { terminate }
        var queueHead: Bool { bits[1] == 1 }
        var transferDescriptor: Bool { !queueHead }

        // FIXME: This should be a PhyiscalAddress in the 1st 4G with correct type
        var frameListPointer: UInt32 { bits.rawValue & 0xffff_fff0 }
    }

    struct TransferDescriptor: CustomStringConvertible {
        struct LinkPointer {
            let bits: BitArray32

            init(queueHead address: UInt32) {
                precondition(address & 0xf == 0)
                bits = BitArray32(address | 1 << 1)
            }

            init(transferDescriptor address: UInt32, depthFirst: Bool) {
                precondition(address & 0xf == 0)
                var lp = BitArray32(address)
                lp[2] = (depthFirst ? 1 : 0)
                bits = lp
            }

            private init(rawValue: UInt32) {
                bits = BitArray32(rawValue)
            }

            static func terminator() -> LinkPointer {
                return LinkPointer(rawValue: 1)
            }

            var terminate: Bool { bits[0] == 1 }
            var isQueueHead: Bool { bits[1] == 1 }
            var isTransferDescriptor: Bool { !isQueueHead }
            var address: UInt32 { bits.rawValue & 0xffff_fff0 }
        }

        struct ControlStatus: CustomStringConvertible {
            private var bits: BitArray32

            init() {
                bits = BitArray32(0)
            }

            init(active: Bool, lowSpeedDevice: Bool, maxErrorCount: Int) {
                bits = BitArray32(0)
                bits[23] = active ? 1 : 0
                bits[26] = lowSpeedDevice ? 1 : 0
                bits[27...28] = UInt32(maxErrorCount)
            }

            var actualLength: UInt {
                let len = UInt(bits[0...10])
                return (len == 0x7ff) ? 0 : len + 1
            }

            var bitstuffError: Bool { Bool(bits[17]) }
            var crcTimeoutError: Bool { Bool(bits[18]) }
            var nakReceived: Bool { Bool(bits[19]) }
            var babbleDetected: Bool { Bool(bits[20]) }
            var dataBufferError: Bool { Bool(bits[21]) }
            var stalled: Bool { Bool(bits[22]) }
            var anyError: Bool { bits[17...22] != 0 }

            var active: Bool {
                get { Bool(bits[23]) }
                set { bits[23] = (newValue ? 1 : 0) }
            }

            var interruptOnComplete: Bool {
                get { Bool(bits[24]) }
                set { bits[24] = (newValue ? 1 : 0) }
            }

            var isochronousTransferDescriptor: Bool {
                get { Bool(bits[25]) }
                set { bits[25] = (newValue ? 1 : 0) }
            }

            var lowSpeedDevice: Bool {
                get { Bool(bits[26]) }
                set { bits[26] = (newValue ? 1 : 0) }
            }

            var maxErrorCount: UInt {
                get { UInt(bits[27...28]) }
                set { bits[27...28] = UInt32(newValue) }
            }

            var shortPacketDetect: Bool {
                get { Bool(bits[29]) }
                set { bits[29] = (newValue ? 1 : 0) }
            }

            var description: String {
                var result = "actLen: \(actualLength) active: \(active ? 1 : 0) IOC: \(interruptOnComplete ? 1 : 0) isoTD: \(isochronousTransferDescriptor ? 1 : 0) "
                    + "LoSD: \(lowSpeedDevice ? 1 : 0) maxErrorCount: \(maxErrorCount) shortPacket: \(shortPacketDetect ? 1 : 0)"
                if bitstuffError { result += " bitStuffError" }
                if crcTimeoutError { result += " crcToError" }
                if nakReceived { result += " NAK" }
                if babbleDetected { result += " babble" }
                if dataBufferError { result += " dataBufferError" }
                if stalled { result += " stalled" }
                return result
            }
        }

        struct Token: CustomStringConvertible {
            private let bits: BitArray32

            enum PID: UInt8 {
                case pidIn = 0x69
                case pidOut = 0xe1
                case pidSetup = 0x2d
            }


            init(pid: PID, deviceAddress: UInt8, endpoint: UInt, dataToggle: Bool, maximumLength: UInt) {
                precondition(maximumLength <= 1280)
                precondition(deviceAddress <= 128)
                precondition(endpoint <= 0xf)

                var bits = BitArray32(UInt32(pid.rawValue))
                bits[8...14] = UInt32(deviceAddress)
                bits[15...18] = UInt32(endpoint)
                bits[19] = dataToggle ? 0 : 1
                bits[21...31] = (maximumLength == 0) ? 0x7FF : UInt32(maximumLength - 1)
                self.bits = bits
            }

            var pid: PID { PID(rawValue: UInt8(bits[0...7]))! }
            var deviceAddress: UInt8 { UInt8(bits[8...14]) }
            var endpoint: UInt { UInt(bits[15...18]) }
            var dataToggle: Bool { Bool(bits[19]) }
            var data0: Bool { dataToggle }
            var data1: Bool { !dataToggle }
            var maximumLength: UInt {
                let len = UInt(bits[21...31])
                return (len == 0x7ff) ? 0 : len + 1
            }

            var description: String { "\(pid) addr: \(deviceAddress).\(endpoint) data\(data0 ? "0" : "1") maxLen: \(maximumLength)" }
        }


        let linkPointer: LinkPointer
        let controlStatus: ControlStatus
        let token: Token
        let bufferPointer: UInt32

        var description: String {
            return token.description + " " + controlStatus.description + " buffer: \(String(bufferPointer, radix: 16))"
        }
    }


    struct QueueHead: CustomStringConvertible {
        var description: String {
            return "headLP: \(headLinkPointer.description) elementLP: \(elementLinkPointer.description)"
        }

        struct QueueHeadLinkPointer: CustomStringConvertible {
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

            var terminate: Bool { bits[0] == 1 }
            var isQueueHead: Bool { bits[1] == 1 }
            var isTransferDescriptor: Bool { !isQueueHead }
            var address: UInt32 { bits.rawValue & 0xffff_fff0 }

            var description: String {
                if terminate {
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

            var terminate: Bool { bits[0] == 1 }
            var isQueueHead: Bool { bits[1] == 1 }
            var isTransferDescriptor: Bool { !isQueueHead }
            var address: UInt32 { bits.rawValue & 0xffff_fff0 }

            var description: String {
                if terminate {
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
            if headLinkPointer.terminate {
                result += "Terminates\n"
            } else {
                result += (headLinkPointer.isQueueHead ? "QH" : "TD") + ": \(String(headLinkPointer.address, radix: 16))\n"
            }
            var idx = 0
            var lp = elementLinkPointer
            while !lp.terminate {
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
}
