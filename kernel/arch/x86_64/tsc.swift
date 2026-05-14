/*
 * kernel/arch/x86_64/tsc.swift
 *
 * Created by Simon Evans on 18/04/2026.
 * Copyright © 2026 Simon Evans. All rights reserved.
 *
 * TSC and CPU frequency determination
 *
 */


struct TimesourceTSC: CustomStringConvertible {
    let isInvariant: Bool
    let tscFrequency: UInt64   // Hz
    let hasRDTSCP: Bool
    let hasTSCAdjust: Bool
    let hasDeadline: Bool
    let hasTPause: Bool
    let highQuality: Bool

    var description: String {
        #sprintf("TSC: %u MHz TSC invariant: %s RDTSCP: %s TSC adjust: %s Deadline: %s TPause: %s",
                tscFrequency / 1_000_000,
                 isInvariant, hasRDTSCP, hasTSCAdjust, hasDeadline, hasTPause
        )
    }


    init?() {
        self.isInvariant = CPU.capabilities.invariantTSC
        if let cpuid07 = CPU.cpuId.cpuidLeaf(0x7) {
            // WaitPKG
            self.hasTPause = cpuid07.regs.ecx.bit(5)
            self.hasTSCAdjust = cpuid07.regs.ebx.bit(1)
        } else {
            self.hasTPause = false
            self.hasTSCAdjust = false
        }
        self.hasRDTSCP = CPU.capabilities.rdtscp
        self.hasDeadline = CPU.capabilities.tscDeadline
        // Determine CPU frequency

        if cpu.tscFrequency > 0 {
            self.tscFrequency = cpu.tscFrequency
            self.highQuality = true
        } else if cpu.cpuFrequency > 0 {
            self.tscFrequency = cpu.cpuFrequency
            self.highQuality = false
        } else {
            return nil
        }
    }
}


// Read the TSC and CPU frequency from CPUID if possible
func readTSCFrequency() -> (UInt64, UInt64)? {
    guard let cpuid15 = CPU.cpuId.cpuidLeaf(0x15),
          cpuid15.regs.ecx > 0, cpuid15.regs.ebx > 0 else {
        return nil
    }
    let denominator = UInt64(cpuid15.regs.eax)
    let numerator = UInt64(cpuid15.regs.ebx)
    var crystalHz = UInt64(cpuid15.regs.ecx)

    if crystalHz == 0 {
        guard let cpuid16 = CPU.cpuId.cpuidLeaf(0x16), cpuid16.regs.eax > 0 else {
            return nil
        }
        crystalHz = UInt64(cpuid16.regs.eax) * 1_000_000   // eax = base MHZ
    }
    let tscHz = crystalHz * numerator / denominator
    return (tscHz, crystalHz)
}

// This is only valid for certain CPUs
private func readMSRFrequency() -> UInt64? {
    return nil
/*
    TODO: implement this properly
    let platformInfo = UInt64(CPU.readMSR(0xCE) & 0xff00) >> 8
    if platformInfo > 0 {
        return platformInfo * 100_000_000 // 100MHz
    } else {
        return nil
    }
*/
}


func busFrequency() -> UInt64? {
    guard let cpuid16 = CPU.cpuId.cpuidLeaf(0x16), cpuid16.regs.eax > 0 else {
        return nil
    }
    return UInt64(cpuid16.regs.eax) * 1_000_000   // eax = base MHZ
}


// Measure the CPU frequency using the TSC and the ACPI PM timer
func quickPMTimerCalibrate() -> UInt64? {

    guard let timerPort = ACPI.fadt?.pmTimerPort, timerPort > 0 else {
        fatalError("no PM timer")
    }
    let milliSeconds = 100
    let port = UInt16(timerPort)
    // Treat the timer as 24 bit and wrap appropiately
    let mask: UInt32 = 0xfff_fff //(1 << 24) - 1
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

    let startTSC = rdtsc()
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
    let endTSC = rdtsc()

    let frequency = (endTSC - startTSC) * 10;
    guard frequency > 0 else {
        return nil
    }
    return frequency
}
