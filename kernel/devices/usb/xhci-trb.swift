/*
 *  xhci-trb.swift
 *  Kernel
 *
 *  Created by Simon Evans on 25/08/2025.
 *
 *  Transfer Request Buffer
 */

extension HCD_XHCI {
    protocol ProducerTRB {
        var dwords: InlineArray<4, UInt32> { get }
    }

    struct TransferTRB: ProducerTRB {
        enum TRBType: Int {
            case normal = 1
            case setupStage = 2
            case dataStage = 3
            case statusStage = 4
            case isoch = 5
            case link = 6
            case eventData = 7
            case noop = 8
        }

        enum DataBuffer {
            case address(PhysAddress, UInt32)
            case data(InlineArray<8, UInt8>, UInt32)

            var rawValue: UInt64 {
                return switch self {
                    case .address(let physAddr, _):
                        UInt64(physAddr.value)

                    case .data(let data, _):
                        data.indices.reduce(0, { result, idx in
                            result | UInt64(data[idx]) << (idx * 8)
                        })
                }
            }

            var count: UInt32 {
                return switch self {
                    case .address(_, let count): count & 0x1_ffff
                    case .data(_, let count): count & 0x1_ffff
                }
            }

            var isData: Bool {
                return switch self {
                    case .address: false
                    case .data: true
                }
            }

            var isAddress: Bool { !isData }
        }


        let dwords: InlineArray<4, UInt32>

        init(_ trbType: TRBType,_ dword0: UInt32, _ dword1: UInt32,
             _ dword2: UInt32, _ dword3: UInt32) {
            dwords = [dword0, dword1, dword2, dword3 | (UInt32(trbType.rawValue) << 10) ]
        }

        // When TRB contains a 64bit address or 8bytes of data
        init(_ trbType: TRBType, _ dword0_1: UInt64, _ dword2: UInt32, _ dword3: UInt32) {
            dwords = [ UInt32(truncatingIfNeeded: dword0_1),
                       UInt32(dword0_1 >> 32),
                       dword2, dword3 | (UInt32(trbType.rawValue) << 10)
            ]
        }

        // 6.4.1.1 - Normal TRB
        static func normal(_ data: DataBuffer, tdSize: Int,
                           interrupter: Int, blockInterrupt: Bool,
                           interruptOnComplete: Bool, chain: Bool,
                           noSnoop: Bool, interruptOnShortPacket: Bool,
                           evaluateNextTrb: Bool) -> TransferTRB {

            let tdSize = UInt32(min(tdSize, 31))    // Only 5 bits
            let dword2 = UInt32(interrupter) << 22 | tdSize << 17 | data.count
            let dword3 = UInt32(blockInterrupt ? 1 << 9 : 0)
            | UInt32(data.isData ? 1 << 8 : 0)
            | UInt32(interruptOnComplete ? 1 << 5 : 0)
            | UInt32(chain ? 1 << 4 : 0)
            | UInt32(noSnoop ? 1 << 3 : 0)
            | UInt32(interruptOnShortPacket ? 1 << 2 : 0)
            | UInt32(evaluateNextTrb ? 1 << 1 : 0)

            return TransferTRB.init(.normal, data.rawValue, dword2, dword3)
        }

        // 6.4.1.2.1 - Setup Stage TRB
        static func setupStage(request: USB.ControlRequest, interrupter: Int,
                              interruptOnComplete: Bool, trt: Int) -> TransferTRB {
            let dword0 = UInt32(request.wValue) << 16
            | UInt32(request.bRequest) << 8
            | UInt32(request.bmRequestType)

            let dword1 = UInt32(request.wLength) << 16 | UInt32(request.wIndex)
            // Transfer Length is always 8
            let dword2 = UInt32(interrupter << 22) | UInt32(8)
            let dword3 = UInt32(trt) << 16
            | UInt32(1 << 6) // Intermediate Data, always set on Setup State TRB
            | UInt32(interruptOnComplete ? 1 << 5 : 0)

            return TransferTRB.init(.setupStage, dword0, dword1, dword2, dword3)
        }

        // 6.4.1.2.2 Data Stage TRB
        static func dataStage(_ data: DataBuffer, tdSize: Int, interrupter: Int,
                             readData: Bool, interruptOnComplete: Bool,
                             chain: Bool, interruptOnShortPacket: Bool,
                             evaluateNextTRB: Bool) -> TransferTRB {
            let tdSize = UInt32(min(tdSize, 31))    // Only 5 bits
            let dword2 = UInt32(interrupter << 22) | tdSize << 17 | data.count
            let dword3 = UInt32(readData ? 1 << 16 : 0)
            | UInt32(data.isData ? 1 << 6 : 0)
            | UInt32(interruptOnComplete ? 1 << 5 : 0)
            | UInt32(chain ? 1 << 4 : 0)
            | UInt32(interruptOnShortPacket ? 1 << 2 : 0)
            | UInt32(evaluateNextTRB ? 1 << 1 : 0)

            return TransferTRB.init(.dataStage, data.rawValue, dword2, dword3)
        }

        // 6.4.1.2.3 Status Stage TRB
        static func statusStage(interrupter: Int, readData: Bool,
                                interruptOnComplete: Bool, chain: Bool,
                                evaluateNextTRB: Bool) -> TransferTRB {

            let dword2 = UInt32(interrupter << 22)
            let dword3 = UInt32(readData ? 1 << 16 : 0)
            | UInt32(interruptOnComplete ? 1 << 5 : 0)
            | UInt32(chain ? 1 << 4 : 0)
            | UInt32(evaluateNextTRB ? 1 << 1 : 0)

            return TransferTRB.init(.statusStage, 0, 0, dword2, dword3)
        }

        // 6.4.1.3 Isoch TRB
        // TODO:

        // 6.4.1.4 No Op TRB
        static func noop(interrupter: Int, interruptOnComplete: Bool,
                         chain: Bool, evaluateNextTRB: Bool) -> TransferTRB {

            let dword2 = UInt32(interrupter << 22)
            let dword3 = UInt32(interruptOnComplete ? 1 << 5 : 0)
            | UInt32(chain ? 1 << 4 : 0)
            | UInt32(evaluateNextTRB ? 1 << 1 : 0)

            return TransferTRB.init(.noop, 0, 0, dword2, dword3)
        }

        // 6.4.4.2 Event Data TRB
        static func eventData(_ event: DataBuffer,
                              interrupter: Int, blockEventInterrupt: Bool,
                              interruptOnComplete: Bool, chain: Bool,
                              evaluateNextTRB: Bool) -> TransferTRB {

            precondition(event.isAddress)
            let dword2 = UInt32(interrupter << 22)
            let dword3 = UInt32(blockEventInterrupt ? 1 << 9 : 0)
            | UInt32(interruptOnComplete ? 1 << 5 : 0)
            | UInt32(chain ? 1 << 4 : 0)
            | UInt32(evaluateNextTRB ? 1 << 1 : 0)

            return TransferTRB.init(.eventData, event.rawValue, dword2, dword3)
        }


        // 6.4.4.1 Link TRB
        static func link(ringSegmentPointer: PhysAddress, interrupter: Int,
                         toggleCycle: Bool, chain: Bool, interruptOnComplete: Bool,
                         cycle: Bool) -> TransferTRB {
            TransferTRB.init(.link, UInt64(ringSegmentPointer.value),
                             UInt32(interrupter << 22),
                             UInt32(interruptOnComplete ? 1 << 5 : 0)
                             | UInt32(chain ? 1 << 4 : 0)
                             | UInt32(toggleCycle ? 1 << 1 : 0)
                             | UInt32(cycle ? 1 : 0)
            )
        }
    }

    enum EventTRB: CustomStringConvertible {
        enum TRBType: Int {
            case transfer = 32
            case commandCompletion = 33
            case portStatusChange = 34
            case bandwidthRequest = 35
            case doorbellEvent = 36
            case hostController = 37
            case deviceNotification = 38
            case mfIndexWrap = 39
        }

        case transfer(Transfer)
        case commandCompletion(CommandCompletion)
        case portStatusChange(PortStatusChange)
        case bandwidthRequest(BandwidthRequest)
        case doorbell(Doorbell)
        case hostController(HostController)
        case deviceNotification(DeviceNotification)
        case mfIndexWrap(MFIndexWrap)
        case invalid(Int)

        init(dwords: InlineArray<4, UInt32>) {
            let trbtValue = dwords[3].bits(10...15)
            guard let trbType = TRBType(rawValue: trbtValue) else {
                self = .invalid(trbtValue)
                return
            }

            self = switch trbType {
                case .transfer: .transfer(Transfer(dwords: dwords))
                case .commandCompletion: .commandCompletion(CommandCompletion(dwords: dwords))
                case .portStatusChange: .portStatusChange(PortStatusChange(dwords: dwords))
                case .bandwidthRequest: .bandwidthRequest(BandwidthRequest(dwords: dwords))
                case .doorbellEvent: .doorbell(Doorbell(dwords: dwords))
                case .hostController: .hostController(HostController(dwords: dwords))
                case .deviceNotification: .deviceNotification(DeviceNotification(dwords: dwords))
                case .mfIndexWrap: .mfIndexWrap(MFIndexWrap(dwords: dwords))
            }
        }

        var description: String {
            switch self {
                case .transfer(let event):
                    #sprintf("transfer: 0x%8.8x/0x%8.8x/0x%8.8x/0x%8.8x",
                             event.dwords[0], event.dwords[1], event.dwords[2], event.dwords[3])

                case .commandCompletion(let event):
                    #sprintf("cmd complete: 0x%8.8x/0x%8.8x/0x%8.8x/0x%8.8x",
                             event.dwords[0], event.dwords[1], event.dwords[2], event.dwords[3])

                case .portStatusChange(let event):
                    #sprintf("portStatusCahange: 0x%8.8x/0x%8.8x/0x%8.8x/0x%8.8x",
                             event.dwords[0], event.dwords[1], event.dwords[2], event.dwords[3])

                case .bandwidthRequest(let event):
                    #sprintf("bandwidthRequest: 0x%8.8x/0x%8.8x/0x%8.8x/0x%8.8x",
                             event.dwords[0], event.dwords[1], event.dwords[2], event.dwords[3])

                case .doorbell(let event):
                    #sprintf("doorbell: 0x%8.8x/0x%8.8x/0x%8.8x/0x%8.8x",
                             event.dwords[0], event.dwords[1], event.dwords[2], event.dwords[3])
                case .hostController(let event):
                    #sprintf("hostController: 0x%8.8x/0x%8.8x/0x%8.8x/0x%8.8x",
                             event.dwords[0], event.dwords[1], event.dwords[2], event.dwords[3])
                case .deviceNotification(let event):
                    #sprintf("deviceNotification: 0x%8.8x/0x%8.8x/0x%8.8x/0x%8.8x",
                             event.dwords[0], event.dwords[1], event.dwords[2], event.dwords[3])
                case .mfIndexWrap(let event):
                    #sprintf("mfIndexWrap: 0x%8.8x/0x%8.8x/0x%8.8x/0x%8.8x",
                             event.dwords[0], event.dwords[1], event.dwords[2], event.dwords[3])
                case .invalid(let trbType):
                    #sprintf("invalid(%d)", trbType)
            }
        }


        // 6.4.2.1 Transfer Event TRB
        struct Transfer: CustomStringConvertible {
            let dwords: InlineArray<4, UInt32>

            var trbPointer: UInt64? { edFlag ? nil : UInt64(dwords[0]) | UInt64(dwords[1]) << 32 }
            var eventData: UInt64? { edFlag ? UInt64(dwords[0]) | UInt64(dwords[1]) << 32 : nil }
            var trbTransferLength: UInt32 { UInt32(dwords[2].bits(0...23)) }
            var completionCode: Int { dwords[2].bits(24...31) }
            var cycle: Bool { dwords[3].bit(0) }
            var edFlag: Bool { dwords[3].bit(2) }
            var trbTypeValue: Int { dwords[3].bits(10...15) }
            var trbType: TRBType? { TRBType(rawValue: trbTypeValue) }
            var endpointId: Int { dwords[3].bits(16...20) }
            var slotId: UInt8 { UInt8(dwords[3].bits(24...31)) }

            var description: String {
                #sprintf("cc: %d trbp: %p ed: %p ttlen: %u trbt: %d ep: %d sl: %u",
                         completionCode,
                         trbPointer ?? 0,
                         eventData ?? 0,
                         trbTransferLength,
                         trbTypeValue,
                         endpointId,
                         slotId)
            }

            init(dwords: InlineArray<4, UInt32>) {
                self.dwords = dwords
            }
        }


        // 6.4.2.2 Command Completion Event TRB
        struct CommandCompletion: CustomStringConvertible {
            let dwords: InlineArray<4, UInt32>

            var commandPointer: PhysAddress { PhysAddress(UInt(dwords[0]) | UInt(dwords[1]) << 32) }
            var completionCode: Int { dwords[2].bits(24...31) }
            var completionParameter: UInt32 { dwords[2] & 0x00ff_ffff }
            var cycle: Bool { dwords[3].bit(0) }
            var trbTypeValue: Int { dwords[3].bits(10...15) }
            var trbType: TRBType? { TRBType(rawValue: trbTypeValue) }
            var vfId: Int { dwords[3].bits(16...23) }
            var slotId: UInt8 { UInt8(dwords[3].bits(24...31)) }

            var description: String {
                #sprintf("cmdPtr: %p code: %d parameter: %u cycle: %s TRBType: %d vfId: %d slotId: %d",
                         commandPointer, completionCode, completionParameter,
                         cycle, trbTypeValue, vfId, slotId
                )
            }

            init(dwords: InlineArray<4, UInt32>) {
                self.dwords = dwords
            }
        }


        // 6.4.2.3 Port Status Change Event TRB
        struct PortStatusChange {
            let dwords: InlineArray<4, UInt32>

            var portId: UInt8 { UInt8(dwords[0].bits(24...31)) }
            var completionCode: Int { dwords[2].bits(24...31) }
            var cycle: Bool { dwords[3].bit(0) }
            var trbTypeValue: Int { dwords[3].bits(10...15) }
            var trbType: TRBType? { TRBType(rawValue: trbTypeValue) }

            init(dwords: InlineArray<4, UInt32>) {
                self.dwords = dwords
            }
        }

        // 6.4.2.4 Bandwidth Request Event TRB
        struct BandwidthRequest {
            let dwords: InlineArray<4, UInt32>

            var completionCode: Int { dwords[2].bits(24...31) }
            var cycle: Bool { dwords[3].bit(0) }
            var trbTypeValue: Int { dwords[3].bits(10...15) }
            var trbType: TRBType? { TRBType(rawValue: trbTypeValue) }
            var slotId: UInt8 { UInt8(dwords[3].bits(24...31)) }

            init(dwords: InlineArray<4, UInt32>) {
                self.dwords = dwords
            }
        }

        // 6.4.2.5 Doorbell Event TRB
        struct Doorbell {
            let dwords: InlineArray<4, UInt32>

            var reason: Int { dwords[0].bits(0...4) }
            var completionCode: Int { dwords[2].bits(24...31) }
            var cycle: Bool { dwords[3].bit(0) }
            var trbTypeValue: Int { dwords[3].bits(10...15) }
            var trbType: TRBType? { TRBType(rawValue: trbTypeValue) }
            var vfId: Int { dwords[3].bits(16...23) }
            var slotId: UInt8 { UInt8(dwords[3].bits(24...31)) }

            init(dwords: InlineArray<4, UInt32>) {
                self.dwords = dwords
            }
        }

        // 6.4.2.6 Host Controller Event TRB
        struct HostController {
            let dwords: InlineArray<4, UInt32>

            var completionCode: Int { dwords[2].bits(24...31) }
            var cycle: Bool { dwords[3].bit(0) }
            var trbTypeValue: Int { dwords[3].bits(10...15) }
            var trbType: TRBType? { TRBType(rawValue: trbTypeValue) }

            init(dwords: InlineArray<4, UInt32>) {
                self.dwords = dwords
            }
        }

        // 6.4.2.7 Device Notification Event TRB
        struct DeviceNotification {
            let dwords: InlineArray<4, UInt32>

            var notificationType: Int { dwords[0].bits(4...7) }
            var notificationData: UInt64 { UInt64(dwords[0] & 0xffff_ff00) | UInt64(dwords[1]) << 32 }
            var completionCode: Int { dwords[2].bits(24...31) }
            var cycle: Bool { dwords[3].bit(0) }
            var trbTypeValue: Int { dwords[3].bits(10...15) }
            var trbType: TRBType? { TRBType(rawValue: trbTypeValue) }
            var slotId: UInt8 { UInt8(dwords[3].bits(24...31)) }

            init(dwords: InlineArray<4, UInt32>) {
                self.dwords = dwords
            }
        }


        // 6.4.2.8 MFINDEX Wrap Event TRB
        struct MFIndexWrap {
            let dwords: InlineArray<4, UInt32>

            var completionCode: Int { dwords[2].bits(24...31) }
            var cycle: Bool { dwords[3].bit(0) }
            var trbTypeValue: Int { dwords[3].bits(10...15) }
            var trbType: TRBType? { TRBType(rawValue: trbTypeValue) }

            init(dwords: InlineArray<4, UInt32>) {
                self.dwords = dwords
            }
        }
    }


    struct CommandTRB: ProducerTRB {
        enum TRBType: Int {
            case link = 6
            case enableSlot = 9
            case disableSlot = 10
            case addressDevice = 11
            case configureEndpoint = 12
            case evaluateContext = 13
            case resetEndpoint = 14
            case stopEndpoint = 15
            case setTRDequeuePtr = 16
            case resetDevice = 17
            case forceEvent = 18
            case negotiateBW = 19
            case setLatencyTolerance = 20
            case getPortBW = 21
            case forceHeader = 22
            case noop = 23
            case getExtendedProperty = 24
            case setExtendedProperty = 25
        }

        let dwords: InlineArray<4, UInt32>

        @inline(__always)
        init(_ trbType: TRBType, dwords: InlineArray<4, UInt32>) {
            self.dwords = [
                dwords[0], dwords[1], dwords[2],
                (dwords[3] | (UInt32(trbType.rawValue) << 10))
            ]
        }

        // 6.4.4.1 Link TRB
        static func link(ringSegmentPointer: PhysAddress, interrupter: Int,
                         toggleCycle: Bool, chain: Bool, interruptOnComplete: Bool
            ) -> CommandTRB {
            .init(.link, dwords: [
                UInt32(truncatingIfNeeded: ringSegmentPointer.value),
                UInt32(ringSegmentPointer.value >> 32),
                UInt32(interrupter << 22),
                UInt32(interruptOnComplete ? 1 << 5 : 0)
                    | UInt32(chain ? 1 << 4 : 0)
                | UInt32(toggleCycle ? 1 << 1 : 0)
            ])
        }

        static func noOp() -> CommandTRB {
            .init(.noop, dwords: [0, 0, 0, 0])
        }

        static func enableSlot() -> CommandTRB {
            .init(.enableSlot, dwords: [0, 0, 0, 0])
        }

        static func addressDevice(_ slotId: UInt8,
                                  _ addr: PhysAddress,
                                  blockSetAddress bsr: Bool) -> CommandTRB {
            .init(.addressDevice, dwords: [
                UInt32(truncatingIfNeeded: addr.value),
                UInt32(addr.value >> 32),
                0,
                UInt32(slotId) << 24 | UInt32(bsr ? 1 << 9 : 0)
            ])
        }

        // Section 6.4.3.5
        static func configureEndpoint(_ slotId: UInt8,
                                      _ addr: PhysAddress,
                                      deconfigure: Bool = false) -> CommandTRB {
            .init(.configureEndpoint, dwords: [
                UInt32(truncatingIfNeeded: addr.value),
                UInt32(addr.value >> 32),
                0,
                UInt32(slotId) << 24 | UInt32(deconfigure ? 1 << 9 : 0)
            ])
        }

        // Section 6.4.3.6
        static func evaluateContext(_ slotId: UInt8,
                                    _ addr: PhysAddress) -> CommandTRB {
            .init(.evaluateContext, dwords: [
                UInt32(truncatingIfNeeded: addr.value),
                UInt32(addr.value >> 32),
                0,
                UInt32(slotId) << 24
            ])
        }
    }
}
