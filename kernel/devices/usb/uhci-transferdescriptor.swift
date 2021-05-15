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
        struct LinkPointer: CustomStringConvertible {
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

            fileprivate init(rawValue: UInt32) {
                bits = BitArray32(rawValue)
            }

            static func terminator() -> LinkPointer {
                return LinkPointer(rawValue: 1)
            }

            var terminate: Bool { bits[0] == 1 }
            var isQueueHead: Bool { bits[1] == 1 }
            var depthFirst: Bool { bits[2] == 1 }
            var isTransferDescriptor: Bool { !isQueueHead }
            var address: UInt32 { bits.rawValue & 0xffff_fff0 }
            var physAddress: PhysAddress { PhysAddress(RawAddress(address)) }

            var description: String {
                "isTerm: \(bits[0]) isQH: \(bits[1]) depth: \(bits[2])"
            }
        }

        struct ControlStatus: CustomStringConvertible {
            private(set) fileprivate var bits: BitArray32

            init() {
                bits = BitArray32(0)
            }

            init(rawValue: UInt32) {
                bits = BitArray32(rawValue)
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
                    + "LoSD: \(lowSpeedDevice ? 1 : 0) maxErr: \(maxErrorCount) SPD: \(shortPacketDetect ? 1 : 0)"
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
            fileprivate let bits: BitArray32

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

            fileprivate init(rawValue: UInt32) {
                bits = BitArray32(rawValue)
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

            var description: String { "\(pid) addr: \(deviceAddress).\(endpoint) data\(data0 ? "0" : "1") maxLen: \(maximumLength) [\(String(bits.rawValue, radix: 16))]" }
        }


        let linkPointer: LinkPointer
        var controlStatus: ControlStatus
        let token: Token
        let bufferPointer: UInt32

        var description: String {
            return "\(linkPointer) \(token) \(controlStatus) buffer: \(String(bufferPointer, radix: 16))"
        }
    }


    struct PhysTransferDescriptor: CustomStringConvertible {

        let mmioSubRegion: MMIOSubRegion

        init(mmioSubRegion: MMIOSubRegion) {
            self.mmioSubRegion = mmioSubRegion
        }

        var physAddress: UInt32 { UInt32(mmioSubRegion.physicalAddress.value) }

        func setTD(_ transferdescriptor: TransferDescriptor) {
            mmioSubRegion.write(value: transferdescriptor.linkPointer.bits.rawValue, toByteOffset: 0 )
            mmioSubRegion.write(value: transferdescriptor.controlStatus.bits.rawValue, toByteOffset: 4)
            mmioSubRegion.write(value: transferdescriptor.token.bits.rawValue, toByteOffset: 8)
            mmioSubRegion.write(value: transferdescriptor.bufferPointer, toByteOffset: 12)
            writeMemoryBarrier()
        }


        func getTD() -> TransferDescriptor {
            TransferDescriptor(linkPointer: self.linkPointer, controlStatus: self.controlStatus,
                               token: self.token, bufferPointer: self.bufferPointer)
        }

        var linkPointer: TransferDescriptor.LinkPointer {
            TransferDescriptor.LinkPointer(rawValue: mmioSubRegion.read(fromByteOffset: 0))
        }

        var controlStatus: TransferDescriptor.ControlStatus {
            get { TransferDescriptor.ControlStatus(rawValue: mmioSubRegion.read(fromByteOffset: 4)) }
            set {
                mmioSubRegion.write(value: newValue.bits.rawValue, toByteOffset: 4)
                writeMemoryBarrier()
            }
        }

        var token: TransferDescriptor.Token {
            TransferDescriptor.Token(rawValue: mmioSubRegion.read(fromByteOffset: 8))
        }

        var bufferPointer: UInt32 {
            mmioSubRegion.read(fromByteOffset: 12)
        }


        var description: String {
            return "PhysTD: \(asHex(physAddress)): " + getTD().description
        }
    }
}
