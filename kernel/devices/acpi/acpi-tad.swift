/*
 * kernel/devices/acpi/acpi-tad.swift
 *
 * Created by Simon Evans on 02/04/2026.
 * Copyright © 2026 Simon Evans. All rights reserved.
 *
 * ACPI Time and Alarm Device driver (ACPI000E, ACPI 6.5 9.17).
 * Provides real-time clock read/write and programmable wake alarms
 * via ACPI control methods (_GCP, _GRT, _SRT, _GWS, _CWS, _STP,
 * _STV, _TIP, _TIV).  No I/O port or memory resources are used;
 * all access is through the AML namespace.
 *
 */


final class ACPITimeAlarmDevice: DeviceDriver {
    private let pnpDevice: PNPDevice

    // _GCP capability bitmask (9.17.2, Table 9.14)
    private struct Capabilities {
        let rawValue: UInt64
        var acWake: Bool        { rawValue.bit(0) }
        var dcWake: Bool        { rawValue.bit(1) }
        var realTime: Bool      { rawValue.bit(2) }
        var milliseconds: Bool  { rawValue.bit(3) }
        var wakeStatus: Bool    { rawValue.bit(4) }
        var acS4Wake: Bool      { rawValue.bit(5) }
        var acS5Wake: Bool      { rawValue.bit(6) }
        var dcS4Wake: Bool      { rawValue.bit(7) }
        var dcS5Wake: Bool      { rawValue.bit(8) }
    }

    /// Wake timer selector passed to _GWS, _CWS, _STP, _STV, _TIP, _TIV (9.17.5).
    enum TimerID: UInt64 {
        case ac = 0
        case dc = 1
    }

    /// Decoded representation of the 16-byte _GRT / _SRT buffer (9.17.3-4).
    struct ACPITime {
        var year: UInt16        // 1900-9999
        var month: UInt8        // 1-12
        var day: UInt8          // 1-31
        var hour: UInt8         // 0-23
        var minute: UInt8       // 0-59
        var second: UInt8       // 0-59
        var milliseconds: UInt16  // 1-1000
        var timeZone: Int16     // -1440..1440, 2047 = unspecified
        var daylight: UInt8     // bit[0]: DST in effect; bit[1]: adjusted for DST

        /// Decode from a 16-byte AMLBuffer. Returns nil if fewer than 16 bytes
        /// are present or the Valid byte (offset 7) is not 1.
        init?(_ buf: AMLBuffer) {
            guard buf.count >= 16, buf[7] == 1 else { return nil }
            year         = UInt16(buf[0]) | (UInt16(buf[1]) << 8)
            month        = buf[2]
            day          = buf[3]
            hour         = buf[4]
            minute       = buf[5]
            second       = buf[6]
            milliseconds = UInt16(buf[8]) | (UInt16(buf[9]) << 8)
            timeZone     = Int16(bitPattern: UInt16(buf[10]) | (UInt16(buf[11]) << 8))
            daylight     = buf[12]
        }

        /// Encode to the 16-byte AMLBuffer format required by _SRT (9.17.4).
        func encode() -> AMLBuffer {
            var buf = AMLBuffer(repeating: 0, count: 16)
            buf[0]  = UInt8(year & 0xFF)
            buf[1]  = UInt8(year >> 8)
            buf[2]  = month
            buf[3]  = day
            buf[4]  = hour
            buf[5]  = minute
            buf[6]  = second
            // buf[7] = Pad1, zero
            buf[8]  = UInt8(milliseconds & 0xFF)
            buf[9]  = UInt8(milliseconds >> 8)
            let tz  = UInt16(bitPattern: timeZone)
            buf[10] = UInt8(tz & 0xFF)
            buf[11] = UInt8(tz >> 8)
            buf[12] = daylight
            // buf[13..15] = Pad2, zero
            return buf
        }
    }


    init?(pnpDevice: PNPDevice) {
        self.pnpDevice = pnpDevice
        super.init(driverName: "acpi-tad", device: pnpDevice)
        self.setInstanceName(to: "tad0")
        system.deviceManager.tad = self
        #kprint("TAD: initialised:", self.info())
    }

    override func info() -> String {
        var result = "ACPI Time and Alarm Device (ACPI000E)"
        if let caps = getCapabilities() {
            result += #sprintf(" caps: 0x%x", caps.rawValue)
            if caps.realTime  { result += " real-time"   }
            if caps.acWake    { result += " ac-wake"     }
            if caps.dcWake    { result += " dc-wake"     }
        }
        if let t = getRealTime() {
            result += " time: " + formatTime(t)
        }
        return result
    }


    // MARK: - Public API (matches CMOSRTC interface)

    /// Returns the current time as "YYYY-MM-DD HH:MM:SS", or an error string.
    func readTime() -> String {
        guard let t = getRealTime() else {
            return "TAD: time unavailable"
        }
        return formatTime(t)
    }


    // MARK: - _GCP  Get Capabilities (9.17.2)

    private func getCapabilities() -> Capabilities? {
        guard let node = pnpDevice.acpiNode().childNode(named: "_GCP") else {
            #kprint("TAD no _GCP node")
            return nil
        }
        guard let result = try? node.amlObject() else {
            #kprint("TAD: no result")
            return nil
        }
        guard let raw = result.integerValue else {
            #kprint("TAD no integerValue", result.description)
            return nil
        }
        return Capabilities(rawValue: raw)
    }


    // MARK: - _GRT  Get Real Time (9.17.3)

    func getRealTime() -> ACPITime? {
        guard let node = pnpDevice.acpiNode().childNode(named: "_GRT") else {
            #kprint("TAD no _GRT node")
            return nil
        }
        do {
            let result = try node.amlObject()
            guard let buf = result.bufferValue else {
                #kprint("TAD no integerValue", result.description)
                return nil
            }
            return ACPITime(buf.asAMLBuffer())
        } catch {
            #kprint("TAD: no result", error.description)
            return nil
        }
    }


    // MARK: - _SRT  Set Real Time (9.17.4)

    /// Sets the hardware clock. Returns true on success (firmware returns 0).
    @discardableResult
    func setRealTime(_ time: ACPITime) -> Bool {
        guard let node = pnpDevice.acpiNode().childNode(named: "_SRT"),
              let method = node.object.methodValue else {
            return false
        }
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()))
        context.args[0] = AMLObject(time.encode())
        do {
            try method.execute(context: &context)
        } catch {
            #kprintf("TAD: _SRT failed: %s\n", error.description)
            return false
        }
        return (context.returnValue?.integerValue ?? 0xFFFF_FFFF) == 0
    }


    // MARK: - _GWS  Get Wake Alarm Status (9.17.5)

    /// Returns (expired: Bool, causedWake: Bool) for `timer`, or nil on error.
    func getWakeStatus(timer: TimerID) -> (expired: Bool, causedWake: Bool)? {
        guard let node = pnpDevice.acpiNode().childNode(named: "_GWS"),
              let method = node.object.methodValue else {
            return nil
        }
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()))
        context.args[0] = AMLObject(timer.rawValue)
        do {
            try method.execute(context: &context)
        } catch {
            #kprintf("TAD: _GWS failed: %s\n", error.description)
            return nil
        }
        let status = context.returnValue?.integerValue ?? 0
        return (expired: status & (1 << 0) != 0, causedWake: status & (1 << 1) != 0)
    }


    // MARK: - _CWS  Clear Wake Alarm Status (9.17.6)

    /// Clears the wake-alarm status for `timer`. Returns true on success.
    @discardableResult
    func clearWakeStatus(timer: TimerID) -> Bool {
        guard let node = pnpDevice.acpiNode().childNode(named: "_CWS"),
              let method = node.object.methodValue else {
            return false
        }
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()))
        context.args[0] = AMLObject(timer.rawValue)
        do {
            try method.execute(context: &context)
        } catch {
            #kprintf("TAD: _CWS failed: %s\n", error.description)
            return false
        }
        return (context.returnValue?.integerValue ?? 1) == 0
    }


    // MARK: - _STP  Set Expired Timer Wake Policy (9.17.7)

    /// Sets the policy applied when a timer expires while on the wrong power source.
    /// `delay`: 0 = wake immediately on power-source change,
    ///          1-0xFFFFFFFE = seconds to wait after power-source change,
    ///          0xFFFFFFFF = never wake.
    /// Returns true on success.
    @discardableResult
    func setTimerPolicy(timer: TimerID, delay: UInt64) -> Bool {
        guard let node = pnpDevice.acpiNode().childNode(named: "_STP"),
              let method = node.object.methodValue else {
            return false
        }
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()))
        context.args[0] = AMLObject(timer.rawValue)
        context.args[1] = AMLObject(delay)
        do {
            try method.execute(context: &context)
        } catch {
            #kprintf("TAD: _STP failed: %s\n", error.description)
            return false
        }
        return (context.returnValue?.integerValue ?? 1) == 0
    }


    // MARK: - _STV  Set Timer Value (9.17.8)

    /// Arms `timer` to fire after `seconds`. Pass 0xFFFFFFFF to disarm.
    /// Returns true on success.
    @discardableResult
    func setTimerValue(timer: TimerID, seconds: UInt64) -> Bool {
        guard let node = pnpDevice.acpiNode().childNode(named: "_STV"),
              let method = node.object.methodValue else {
            return false
        }
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()))
        context.args[0] = AMLObject(timer.rawValue)
        context.args[1] = AMLObject(seconds)
        do {
            try method.execute(context: &context)
        } catch {
            #kprintf("TAD: _STV failed: %s\n", error.description)
            return false
        }
        return (context.returnValue?.integerValue ?? 1) == 0
    }


    // MARK: - _TIP  Get Expired Timer Wake Policy (9.17.9)

    /// Returns the current expired-timer wake policy for `timer` in seconds,
    /// 0xFFFFFFFF if disabled, or nil on error.
    func getTimerPolicy(timer: TimerID) -> UInt64? {
        guard let node = pnpDevice.acpiNode().childNode(named: "_TIP"),
              let method = node.object.methodValue else {
            return nil
        }
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()))
        context.args[0] = AMLObject(timer.rawValue)
        do {
            try method.execute(context: &context)
        } catch {
            #kprintf("TAD: _TIP failed: %s\n", error.description)
            return nil
        }
        return context.returnValue?.integerValue
    }


    // MARK: - _TIV  Get Remaining Timer Value (9.17.10)

    /// Returns seconds until `timer` fires, 0xFFFFFFFF if disarmed, or nil on error.
    func getTimerValue(timer: TimerID) -> UInt64? {
        guard let node = pnpDevice.acpiNode().childNode(named: "_TIV"),
              let method = node.object.methodValue else {
            return nil
        }
        var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()))
        context.args[0] = AMLObject(timer.rawValue)
        do {
            try method.execute(context: &context)
        } catch {
            #kprintf("TAD: _TIV failed: %s\n", error.description)
            return nil
        }
        return context.returnValue?.integerValue
    }


    // MARK: - Helpers

    private func formatTime(_ time: ACPITime) -> String {
        #sprintf("%u-%2.2u-%2.2u %2.2u:%2.2u:%2.2u",
            UInt32(time.year), UInt32(time.month), UInt32(time.day),
            UInt32(time.hour), UInt32(time.minute), UInt32(time.second))
    }
}
