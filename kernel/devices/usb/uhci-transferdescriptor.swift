/*
 * kernel/devices/usb/uhci-transferdescriptor.swift
 *
 * Created by Simon Evans on 14/12/2020.
 * Copyright © 2020 Simon Evans. All rights reserved.
 *
 * UHCI Transfer Descriptor.
 *
 */


extension HCD_UHCI {

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
            var physAddress: PhysAddress { PhysAddress(RawAddress(address)) }
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
        var controlStatus: ControlStatus
        let token: Token
        let bufferPointer: UInt32

        var description: String {
            return token.description + " " + controlStatus.description + " buffer: \(String(bufferPointer, radix: 16))"
        }
    }

    typealias TransferDescriptorPtr = UnsafeMutablePointer<TransferDescriptor>

    struct PhysTransferDescriptor: CustomStringConvertible {
        let address: PhysAddress

        init(address: PhysAddress) {
            self.address = address
        }

        var pointer: TransferDescriptorPtr {
            return address.rawPointer.bindMemory(to: TransferDescriptor.self, capacity: 1)
        }

        var physAddress: UInt32 { UInt32(address.value) }

        func setTD(_ transferdescriptor: TransferDescriptor) {
            self.address.rawPointer.storeBytes(of: transferdescriptor, as: TransferDescriptor.self)
        }

        var linkPointer: TransferDescriptor.LinkPointer { pointer.pointee.linkPointer }
        var controlStatus: TransferDescriptor.ControlStatus {
            get { pointer.pointee.controlStatus }
            set { pointer.pointee.controlStatus = newValue }
        }


        var description: String {
            return "PhysTD: \(address): " + pointer.pointee.description
        }
    }
}
