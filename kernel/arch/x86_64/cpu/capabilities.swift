/*
 * kernel/arch/x86_64/cpu/capabilities.swift
 *
 * Created by Simon Evans on 24/04/2026.
 * Copyright © 2026 Simon Evans. All rights reserved.
 *
 */


extension CPUID {

        var apicId:      UInt8 { return UInt8(self.cpuid01.regs.ebx >> 24) }
        var sse3:        Bool { return self.cpuid01.regs.ecx.bit(0) }
        var pclmulqdq:   Bool { return self.cpuid01.regs.ecx.bit(1) }
        var dtes64:      Bool { return self.cpuid01.regs.ecx.bit(2) }
        var monitor:     Bool { return self.cpuid01.regs.ecx.bit(3) }
        var dscpl:       Bool { return self.cpuid01.regs.ecx.bit(4) }
        var vmx:         Bool { return self.cpuid01.regs.ecx.bit(5) }
        var smx:         Bool { return self.cpuid01.regs.ecx.bit(6) }
        var eist:        Bool { return self.cpuid01.regs.ecx.bit(7) }
        var tm2:         Bool { return self.cpuid01.regs.ecx.bit(8) }
        var ssse3:       Bool { return self.cpuid01.regs.ecx.bit(9) }
        var cnxtid:      Bool { return self.cpuid01.regs.ecx.bit(10) }
        var sdbg:        Bool { return self.cpuid01.regs.ecx.bit(11) }
        var fma:         Bool { return self.cpuid01.regs.ecx.bit(12) }
        var cmpxchg16b:  Bool { return self.cpuid01.regs.ecx.bit(13) }
        var xptr:        Bool { return self.cpuid01.regs.ecx.bit(14) }
        var pdcm:        Bool { return self.cpuid01.regs.ecx.bit(15) }
        var pcid:        Bool { return self.cpuid01.regs.ecx.bit(17) }
        var dca:         Bool { return self.cpuid01.regs.ecx.bit(18) }
        var sse4_1:      Bool { return self.cpuid01.regs.ecx.bit(19) }
        var sse4_2:      Bool { return self.cpuid01.regs.ecx.bit(20) }
        var x2apic:      Bool { return self.cpuid01.regs.ecx.bit(21) }
        var movbe:       Bool { return self.cpuid01.regs.ecx.bit(22) }
        var popcnt:      Bool { return self.cpuid01.regs.ecx.bit(23) }
        var tscDeadline: Bool { return self.cpuid01.regs.ecx.bit(24) }
        var aesni:       Bool { return self.cpuid01.regs.ecx.bit(25) }
        var xsave:       Bool { return self.cpuid01.regs.ecx.bit(26) }
        var osxsave:     Bool { return self.cpuid01.regs.ecx.bit(27) }
        var avx:         Bool { return self.cpuid01.regs.ecx.bit(28) }
        var f16c:        Bool { return self.cpuid01.regs.ecx.bit(29) }
        var rdrand:      Bool { return self.cpuid01.regs.ecx.bit(30) }

        var fpu:         Bool { return self.cpuid01.regs.edx.bit(0) }
        var vme:         Bool { return self.cpuid01.regs.edx.bit(1) }
        var de:          Bool { return self.cpuid01.regs.edx.bit(2) }
        var pse:         Bool { return self.cpuid01.regs.edx.bit(3) }
        var tsc:         Bool { return self.cpuid01.regs.edx.bit(4) }
        var msr:         Bool { return self.cpuid01.regs.edx.bit(5) }
        var pae:         Bool { return self.cpuid01.regs.edx.bit(6) }
        var mce:         Bool { return self.cpuid01.regs.edx.bit(7) }
        var cx8:         Bool { return self.cpuid01.regs.edx.bit(8) }
        var apic:        Bool { return self.cpuid01.regs.edx.bit(9) }
        var sysenter:    Bool { return self.cpuid01.regs.edx.bit(11) }
        var mtrr:        Bool { return self.cpuid01.regs.edx.bit(12) }
        var pge:         Bool { return self.cpuid01.regs.edx.bit(13) }
        var mca:         Bool { return self.cpuid01.regs.edx.bit(14) }
        var cmov:        Bool { return self.cpuid01.regs.edx.bit(15) }
        var pat:         Bool { return self.cpuid01.regs.edx.bit(16) }
        var pse36:       Bool { return self.cpuid01.regs.edx.bit(17) }
        var psn:         Bool { return self.cpuid01.regs.edx.bit(18) }
        var clfsh:       Bool { return self.cpuid01.regs.edx.bit(19) }
        var ds:          Bool { return self.cpuid01.regs.edx.bit(21) }
        var acpi:        Bool { return self.cpuid01.regs.edx.bit(22) }
        var mmx:         Bool { return self.cpuid01.regs.edx.bit(23) }
        var fxsr:        Bool { return self.cpuid01.regs.edx.bit(24) }
        var sse:         Bool { return self.cpuid01.regs.edx.bit(25) }
        var sse2:        Bool { return self.cpuid01.regs.edx.bit(26) }
        var ss:          Bool { return self.cpuid01.regs.edx.bit(27) }
        var htt:         Bool { return self.cpuid01.regs.edx.bit(28) }
        var tm:          Bool { return self.cpuid01.regs.edx.bit(29) }
        var pbe:         Bool { return self.cpuid01.regs.edx.bit(31) }

        var lahfsahf:    Bool { return self.cpuid80000001.regs.ecx.bit(0) }
        var lzcnt:       Bool { return self.cpuid80000001.regs.ecx.bit(5) }
        var prefetchw:   Bool { return self.cpuid80000001.regs.ecx.bit(8) }

        var syscall:     Bool { return self.cpuid80000001.regs.edx.bit(11) }
        var nxe:         Bool { return self.cpuid80000001.regs.edx.bit(20) }
        var rdtscp:      Bool { self.cpuid80000001.regs.edx.bit(27) }

        // FIXME: 1G Pages seem to break using qemu on macos with hypervisor framework.
        // Not sure where bug is atm.
        //var pages1G:     Bool { return self.cpuid80000001.regs.edx.bit(26) }
        var pages1G:     Bool { return false }
        var IA32_EFER:   Bool { return self.cpuid80000001.regs.edx.bit(29) }

        var pageSizes: [UInt] {
            var sizes: [UInt] = [ 4096, 2 * mb]
            if self.pages1G {
                sizes.append(1 * gb)
            }
            return sizes
        }

        var maxPhyAddrBits: UInt {
            let max = UInt(self.cpuid80000008.regs.eax & 0xff)
            if max > 0 {
                return max
            } else {
                return 36
            }
        }

        var invariantTSC: Bool {
            guard let info = self.cpuidExtended(for: 0x8000_0007) else { return false }
            return info.regs.edx.bit(8)
        }
    }


extension CPUID {
    var capabilityString: String {
        var str = #sprintf("CPU: [%s] [%s] APICId: %u\nCPU: ",
                           self.vendorName,
                           self.processorBrandString,
                           self.apicId)
        if self.pages1G         { str += "1GPages "     }
        if self.msr             { str += "msr "         }
        if self.IA32_EFER       { str += "IA32_EFER "   }
        if self.nxe             { str += "nxe "         }
        if self.apic            { str += "apic "        }
        if self.x2apic          { str += "x2apic "      }
        if self.rdrand          { str += "rdrand "      }
        if self.tsc             { str += "tsc "         }
        if self.tscDeadline     { str += "tscDeadline " }
        if self.invariantTSC    { str += "invariantTSC "}
        if self.sysenter        { str += "sysenter "    }
        if self.syscall         { str += "syscall "     }
        if self.mtrr            { str += "mtrr "        }
        if self.pat             { str += "pat "         }
        if self.vmx             { str += "vmx "         }

        return str
    }
}
