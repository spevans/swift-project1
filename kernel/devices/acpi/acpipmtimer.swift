/*
 * kernel/devices/acpi/acpipmtimer.swift
 *
 * Created by Simon Evans on 29/03/2026.
 * Copyright © 2026 Simon Evans. All rights reserved.
 *
 * ACPI Power Management Timer (4.8.3.3).
 * Runs at exactly 3,579,545 Hz. Read-only; no interrupt.
 *
 */


extension ACPI {

    /// Frequency of the PM Timer in Hz (3.579545 MHz).
    static let pmTimerFrequency: UInt32 = 3_579_545

    /// Read the current PM Timer counter value.
    ///
    /// Returns the raw counter, masked to 24 or 32 bits depending on the
    /// `pmTimerIs32Bit` flag in the FADT. Returns nil if no PM Timer port
    /// is available.
    ///
    /// **Wrap periods** (counter resets to zero):
    ///   - 24-bit: 0xFFFFFF ticks / 3,579,545 Hz  **4.69 seconds**
    ///   - 32-bit: 0xFFFFFFFF ticks / 3,579,545 Hz  **1199.86 seconds (~20 min)**
    ///
    /// Callers that measure elapsed time must detect rollover by comparing
    /// successive readings and checking for wrap (new < old).
    func readPMTimer() -> UInt32? {
        guard let port = ACPI.fadt?.pmTimerPort else { return nil }
        let raw = inl(UInt16(port))
        if ACPI.fadt?.pmTimerIs32Bit == true {
            return raw
        } else {
            return raw & 0x00FF_FFFF
        }
    }

    /// Read the current PM Timer counter as nanoseconds.
    ///
    /// Converts the raw tick count to nanoseconds using the fixed
    /// 3,579,545 Hz timer frequency. UInt64 ticks * 1e9 cannot
    /// overflow for any 32-bit tick value. Returns nil if no PM
    /// Timer port is available.
    ///
    /// The returned value is a snapshot of the counter, **not** an
    /// absolute monotonic time. It wraps with the counter:
    ///   - 24-bit: wraps at ~4,687,500,000 ns (~4.69 s)
    ///   - 32-bit: wraps at ~1,199,862,007,000 ns (~1199.86 s)
    ///
    /// A monotonic clock built on top must accumulate ticks across
    /// rollovers; a UInt64 nanosecond accumulator would not itself
    /// overflow for ~584 years.
    func readPMTimerNanoseconds() -> UInt64? {
        guard let ticks = readPMTimer() else { return nil }
        return UInt64(ticks) * 1_000_000_000 / UInt64(ACPI.pmTimerFrequency)
    }

    @discardableResult
    static func wait(milliSeconds: UInt32) -> Bool {
        guard let timerPort = ACPI.fadt?.pmTimerPort else {
            fatalError("No PM TImer port")
        }

        let port = UInt16(timerPort)
        // Treat the timer as 24 bit and wrap appropiately
        let mask: UInt32 = (1 << 24) - 1
        let totalTicks = (UInt64(ACPI.pmTimerFrequency) &* UInt64(milliSeconds)) / 1000

        // Read the port until it enters the next tick then loop until total ticks have passed
        var start = inl(port) & mask
        while true {
            let now = inl(port) & mask
            if now != start {
                start = now
                break
            }
        }

        var elapsed: UInt32 = 0
        var last = start
        while elapsed <= totalTicks {
            let now = inl(port) & mask
            if now < last {
                elapsed += now + (mask + 1) - last
            } else {
                elapsed += (now - last)
            }
            last = now
            pause()
        }
        return true
    }
}

