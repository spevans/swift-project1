/*
 * kernel/devices/pit8254.swift
 *
 * Created by Simon Evans on 10/01/2016.
 * Copyright © 2016, 2018 Simon Evans. All rights reserved.
 *
 * 8254 PIT Programmable Interval Timer.
 *
 */


final class PIT8254Timer: Timer {
    fileprivate let pit: PIT8254
    override var description: String { return "PIT8254: IRQ: \(interrupt.irq)" }

    init(pit: PIT8254, irq: IRQSetting) {
        self.pit = pit
        super.init(interrupt: irq)
    }

    override func enablePeriodicInterrupt(hz: Int) -> Bool {
        pit.setChannel(.CHANNEL0, mode: .MODE_3, hz: hz)
        return true
    }
}


final class PIT8254: DeviceDriver {
    private let oscillator = 1193182         // Base frequency
    private let channel0Port: UInt16
    private let channel2Port: UInt16
    private let commandPort: UInt16
    let irq: IRQSetting

    // Raw Value is the I/O port
    enum TimerChannel: UInt16, CustomStringConvertible {
        case CHANNEL0 = 0x40
        // CHANNEL_1 is not valid
        case CHANNEL2 = 0x42

        var channelSelect: ChannelSelect {
            switch self {
                case .CHANNEL0: ChannelSelect.CHANNEL0
                case .CHANNEL2: ChannelSelect.CHANNEL2
            }
        }

        var description: String {
            switch self {
                case .CHANNEL0: "Channel0"
                case .CHANNEL2: "Channel2"
            }
        }
    }


    // Mode / Command Register commands
    enum ChannelSelect: UInt8, CustomStringConvertible {
        static let mask: UInt8 = 0b11000000

        case CHANNEL0 = 0b00000000
        case CHANNEL1 = 0b01000000
        case CHANNEL2 = 0b10000000
        case READBACK = 0b11000000

        init(statusByte: UInt8) {
            self.init(rawValue: statusByte & ChannelSelect.mask)!
        }

        var description: String {
            switch self {
                case .CHANNEL0: "Channel0"
                case .CHANNEL1: "Channel1"
                case .CHANNEL2: "Channel2"
                case .READBACK: "Readback"
            }
        }
    }


    enum AccessMode: UInt8, CustomStringConvertible {
        static let mask: UInt8 = 0b00110000

        case LATCH_COUNT  = 0b00000000
        case LO_BYTE_ONLY = 0b00010000
        case HI_BYTE_ONLY = 0b00100000
        case LO_HI_BYTE   = 0b00110000

        init(statusByte: UInt8) {
            self.init(rawValue: statusByte & AccessMode.mask)!
        }

        var description: String {
            switch self {
                case .LATCH_COUNT: "LatchCount"
                case .LO_BYTE_ONLY: "LoByteOnly"
                case .HI_BYTE_ONLY: "HiByteOnly"
                case .LO_HI_BYTE: "LoHiByte"
            }
        }
    }


    enum OperatingMode: UInt8, CustomStringConvertible {
        static let mask: UInt8 = 0b00001110

        case MODE_0 = 0b00000000
        case MODE_1 = 0b00000010
        case MODE_2 = 0b00000100
        case MODE_3 = 0b00000110
        case MODE_4 = 0b00001000
        case MODE_5 = 0b00001010
        case MODE_6 = 0b00001100    // Actually mode 2
        case MODE_7 = 0b00001110    // Actually mode 3

        init(statusByte: UInt8) {
            var value = UInt8(statusByte & OperatingMode.mask);
            if (value == OperatingMode.MODE_6.rawValue) {
                value = OperatingMode.MODE_2.rawValue
            } else if (value == OperatingMode.MODE_7.rawValue) {
                value = OperatingMode.MODE_3.rawValue
            }
            self.init(rawValue: value)!
        }

        var description: String {
            var mode = self.rawValue >> 1
            if mode > 5 { mode -= 4 }
            return #sprintf("Mode%u", mode)
        }
    }


    enum NumberMode: UInt8, CustomStringConvertible {
        static let mask: UInt8 = 0b00000001

        case BINARY = 0b00000000
        case BCD    = 0b00000001    // This mode is not supported

        init(statusByte: UInt8) {
            self = (statusByte & Self.mask) == 0 ? .BINARY : .BCD
        }

        var description: String {
            switch self {
                case .BINARY: "Binary"
                case .BCD: "BCD"
            }
        }
    }

    struct ChannelStatus {
        private let statusByte: UInt8

        init(_ statusByte: UInt8) {
            self.statusByte = statusByte
        }

        var outputPin: Bool { statusByte.bit(7) }
        var countAvailable: Bool { statusByte.bit(6) }
        var accessMode: AccessMode {
            AccessMode(statusByte: self.statusByte)
        }

        var operatingMode: OperatingMode {
            OperatingMode(statusByte: self.statusByte)
        }

        var numberMode: NumberMode {
            NumberMode(statusByte: self.statusByte)
        }
    }

    override func info() -> String {
        var result = #sprintf("PIT8254: cmd: 0x%2.2x chan0: 0x%2.2x chan2: 0x%2.2x irq: %s",
                              commandPort, channel0Port, channel2Port, irq.description)

        let status0 = statusFor(.CHANNEL0)
        let counter0 = counterFor(.CHANNEL0)

        let status2 = statusFor(.CHANNEL2)
        let counter2 = counterFor(.CHANNEL2)

        result += #sprintf("\n\tChannel0: access: %s, opmode: %s, number: %s Pin: %d validCount: %s count: %u",
                           status0.accessMode.description,
                           status0.operatingMode.description,
                           status0.numberMode.description,
                           status0.outputPin, status0.countAvailable,
                           counter0
        )

        result += #sprintf("\n\tChannel2: access: %s, opmode: %s, number: %s Pin: %d validCount: %s count: %u",
                           status2.accessMode.description,
                           status2.operatingMode.description,
                           status2.numberMode.description,
                           status2.outputPin, status2.countAvailable,
                           counter2)

        return result
    }

    private static func alreadyInitialised() -> PIT8254? {
        let timer = TimerCore.timer(matching: { timer in
            timer is PIT8254Timer
        })
        return (timer as? PIT8254Timer)?.pit
    }


    // Probed at early startup to see if it is available for clock timing
    init?() {
        #kprint("PIT8254: probed init")

        self.channel0Port = TimerChannel.CHANNEL0.rawValue
        self.channel2Port = TimerChannel.CHANNEL2.rawValue
        self.commandPort = 0x43
        self.irq = IRQSetting(isaIrq: 0)   // Default IRQ = 0
        #kprint("PIT8254: ", self.irq)
        super.init(driverName: "pit8254-early", device: Device())
        self.setInstanceName(to: "pit0-early")

        // Readback command, latch status, readback for channels 0,1,2
        let readBackCmd: UInt8 = ChannelSelect.READBACK.rawValue | 0b00101110
        outb(commandPort, readBackCmd)
        let command = inb(self.mapChannelToPort(.CHANNEL0))
        if command == 0xff {
            #kprint("PIT8254: probing readback 0xff, not present")
            return nil
        }
        let timer = PIT8254Timer(pit: self, irq: irq)
        TimerCore.addTimer(timer)
    }

    init?(pnpDevice: PNPDevice) {
        guard let resources = pnpDevice.getResources() else {
            return nil
        }
        #kprint("PIT8254: init:", resources)
        if let driver = Self.alreadyInitialised() {
            #kprintf("PIT8254: Driver already attached, updating device to %s\n", pnpDevice.pnpName)
            pnpDevice.setDriver(driver)
            return nil
        }

        guard let ports = resources.ioPorts.first, ports.count > 3 else {
            #kprint("PIT8254: Requires 4 IO ports and 1 IRQ")
            return nil
        }

        let idx = ports.startIndex
        self.channel0Port = ports[ports.index(idx, offsetBy: 0)]
        self.channel2Port = ports[ports.index(idx, offsetBy: 2)]
        self.commandPort = ports[ports.index(idx, offsetBy: 3)]
        self.irq = resources.interrupts.first ?? IRQSetting(isaIrq: 0)   // Default IRQ = 0
        #kprint("PIT8254: IRQ\(self.irq)")
        super.init(driverName: "pit8254", device: pnpDevice)
        self.setInstanceName(to: "pit0")
        let timer = PIT8254Timer(pit: self, irq: irq)
        TimerCore.addTimer(timer)
        // FIXME, Nothing to do currently, maybe read status to check for presence of device?
    }


    fileprivate func setChannel(_ channel: TimerChannel, mode: OperatingMode, hz: Int) {
        let cmd = toCommandByte(mapChannelToSelect(channel),
                                AccessMode.LO_HI_BYTE, mode, NumberMode.BINARY)
        outb(self.commandPort, cmd)
        setHz(channel, hz)
    }


    private func toCommandByte(_ channel: ChannelSelect, _ access: AccessMode,
        _ mode: OperatingMode, _ number: NumberMode) -> UInt8 {
            return channel.rawValue | access.rawValue | mode.rawValue | number.rawValue
    }


    private func statusFor(_ channel: TimerChannel) -> ChannelStatus {
        var readBackCmd: UInt8 = ChannelSelect.READBACK.rawValue | 0b0010_0000
        switch channel {
            case .CHANNEL0: readBackCmd |= 0b0000_0010
            case .CHANNEL2: readBackCmd |= 0b0000_1000
        }
        outb(self.commandPort, readBackCmd)
        let statusByte = inb(mapChannelToPort(channel))
        return ChannelStatus(statusByte)
    }


    private func counterFor(_ channel: TimerChannel) -> UInt16 {
        var readBackCmd: UInt8 = ChannelSelect.READBACK.rawValue | 0b0001_0000
        switch channel {
            case .CHANNEL0: readBackCmd |= 0b0000_0010
            case .CHANNEL2: readBackCmd |= 0b0000_1000
        }
        outb(self.commandPort, readBackCmd)
        let port = mapChannelToPort(channel)
        let lsb = inb(port)
        let msb = inb(port)

        return UInt16(msb) << 8 | UInt16(lsb)
    }


    private func mapChannelToSelect(_ channel: TimerChannel) -> ChannelSelect {
        switch(channel) {
            case .CHANNEL0: ChannelSelect.CHANNEL0
            case .CHANNEL2: ChannelSelect.CHANNEL2
        }
    }


    private func mapChannelToPort(_ channel: TimerChannel) -> UInt16 {
        switch(channel) {
            case .CHANNEL0: self.channel0Port
            case .CHANNEL2: self.channel2Port
        }
    }


    private func getCount(_ channel: TimerChannel) -> UInt16 {
        let latchCmd = channel.channelSelect.rawValue
        outb(self.commandPort, latchCmd)
        let port = mapChannelToPort(channel)
        let lsb = inb(port)
        let msb = inb(port)

        return UInt16.init(withBytes: lsb, msb)
    }


    private func setDivisor(_ channel: TimerChannel, _ value: UInt16) {
        let v = ByteArray2(value)
        let port = mapChannelToPort(channel)
        outb(port, v[0])
        outb(port, v[1])
    }


    @discardableResult
    private func setHz(_ channel: TimerChannel, _ hz: Int) -> Int {
        let divisor = UInt16(oscillator / hz)
        setDivisor(channel, divisor)

        return Int(oscillator / Int(divisor))
    }
}
