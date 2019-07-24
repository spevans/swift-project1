/*
* kernel/devices/vmcs.swift
*
* Created by Simon Evans on 20/07/2019.
* Copyright © 2019 Simon Evans. All rights reserved.
*
* VMCS functionality.
*
*/


final class VMCS {
    static let vmxInfo = VMXBasicInfo()

    let vmExecPrimary = VMXPrimaryProcessorBasedControls()
    let vmExecSecondary: VMXSecondaryProcessorBasedControls?
    
    let address: VirtualAddress
    var vcpu: vcpu_info = vcpu_info()

    
    var physicalAddress: UInt64 {
        let physAddr = PhysAddress(address - PHYSICAL_MEM_BASE)
        let mask = UInt(maskFromBitCount: Int(VMCS.vmxInfo.physAddressWidthMaxBits))
        let addr = physAddr.value & mask
        return UInt64(addr)
    }


    init() {
        address = alloc_pages(pages: 1)
        UnsafeMutableRawPointer(bitPattern: address)!
        .storeBytes(of: VMCS.vmxInfo.vmcsRevisionId, toByteOffset: 0,
            as: UInt32.self)

        if vmExecPrimary.activateSecondaryControls.allowedToBeOne {
            vmExecSecondary = VMXSecondaryProcessorBasedControls()
        } else {
            vmExecSecondary = nil
        }
    }


    func vmClear() -> VMXError {
        let error = vmclear(physicalAddress)
        return VMXError(error)
    }


    func vmPtrLoad() -> VMXError {
        let error = vmptrld(physicalAddress)
        return VMXError(error)
    }

    deinit {
        freePages(at: address, count: 1)
    }


    var vpid: UInt16 {
        get { vmread16(0x0) }
        set { vmwrite16(0x0, newValue) }
    }

    var interruptNotificationVector: UInt16 {
        get { vmread16(0x2) }
        set { vmwrite16(0x2, newValue) }
    }

    var eptpIndex: UInt16 {
        get { vmread16(0x4) }
        set { vmwrite16(0x4, newValue) }
    }


    // Guest Selectors
    var guestESSelector: UInt16 {
        get { vmread16(0x800) }
        set { vmwrite16(0x800, newValue) }
    }

    var guestCSSelector: UInt16 {
        get { vmread16(0x802) }
        set { vmwrite16(0x802, newValue) }
    }

    var guestSSSelector: UInt16 {
        get { vmread16(0x804) }
        set { vmwrite16(0x804, newValue) }
    }

    var guestDSSelector: UInt16 {
        get { vmread16(0x806) }
        set { vmwrite16(0x806, newValue) }
    }

    var guestFSSelector: UInt16 {
        get { vmread16(0x808) }
        set { vmwrite16(0x808, newValue) }
    }

    var guestGSSelector: UInt16 {
        get { vmread16(0x80A) }
        set { vmwrite16(0x80A, newValue) }
    }

    var guestLDTRSelector: UInt16 {
        get { vmread16(0x80C) }
        set { vmwrite16(0x80C, newValue) }
    }

    var guestTRSelector: UInt16 {
        get { vmread16(0x80E) }
        set { vmwrite16(0x80E, newValue) }
    }

    var guestInterruptStatus: UInt16 {
        get { vmread16(0x810) }
        set { vmwrite16(0x810, newValue) }
    }

    var pmlIndex: UInt16 {
        get { vmread16(0x812) }
        set { vmwrite16(0x812, newValue) }
    }

    
    // Host Selectors
    var hostESSelector: UInt16 {
        get { vmread16(0xC00) }
        set { vmwrite16(0xC00, newValue) }
    }

    var hostCSSelector: UInt16 {
        get { vmread16(0xC02) }
        set { vmwrite16(0xC02, newValue) }
    }

    var hostSSSelector: UInt16 {
        get { vmread16(0xC04) }
        set { vmwrite16(0xC04, newValue) }
    }

    var hostDSSelector: UInt16 {
        get { vmread16(0xC06) }
        set { vmwrite16(0xC06, newValue) }
    }

    var hostFSSelector: UInt16 {
        get { vmread16(0xC08) }
        set { vmwrite16(0xC08, newValue) }
    }

    var hostGSSelector: UInt16 {
        get { vmread16(0xC0A) }
        set { vmwrite16(0xC0A, newValue) }
    }

    var hostTRSelector: UInt16 {
        get { vmread16(0xC0C) }
        set { vmwrite16(0xC0C, newValue) }
    }

    // 64Bit Control Fields
    var ioBitmapAAddress: UInt64 {
        get { vmread64(0x2000) }
        set { vmwrite64(0x2000, newValue) }
    }

    var ioBitmapBAddress: UInt64 {
        get { vmread64(0x2002) }
        set { vmwrite64(0x2002, newValue) }
    }

    var msrBitmapAddress: UInt64 {
        get { vmread64(0x2004) }
        set { vmwrite64(0x2004, newValue) }
    }

    var vmExitMSRStoreAddress: UInt64 {
        get { vmread64(0x2006) }
        set { vmwrite64(0x2006, newValue) }
    }

    var vmExitMSRLoadAddress: UInt64 {
        get { vmread64(0x2008) }
        set { vmwrite64(0x2008, newValue) }
    }

    var vmEntryMSRLoadAddress: UInt64 {
        get { vmread64(0x200A) }
        set { vmwrite64(0x200A, newValue) }
    }

    var executiveVMCSPtr: UInt64 {
        get { vmread64(0x200C) }
        set { vmwrite64(0x200C, newValue) }
    }

    var pmlAddress: UInt64 {
        get { vmread64(0x200E) }
        set { vmwrite64(0x200E, newValue) }
    }

    var tscOffset: UInt64 {
        get { vmread64(0x2010) }
        set { vmwrite64(0x2010, newValue) }
    }

    var virtualAPICAddress: UInt64 {
        get { vmread64(0x2012) }
        set { vmwrite64(0x2012, newValue) }
    }

    var apicAccessAddress: UInt64 {
        get { vmread64(0x2014) }
        set { vmwrite64(0x2014, newValue) }
    }

    var postedInterruptDescAddress: UInt64 {
        get { vmread64(0x2016) }
        set { vmwrite64(0x2016, newValue) }
    }

    var vmFunctionControls: UInt64 {
        get { vmread64(0x2018) }
        set { vmwrite64(0x2018, newValue) }
    }

    var eptp: UInt64 {
        get { vmread64(0x201A) }
        set { vmwrite64(0x201A, newValue) }
    }

    var eoiExitBitmap0: UInt64 {
        get { vmread64(0x201C) }
        set { vmwrite64(0x201C, newValue) }
    }

    var eoiExitBitmap1: UInt64 {
        get { vmread64(0x201E) }
        set { vmwrite64(0x201E, newValue) }
    }

    var eoiExitBitmap2: UInt64 {
        get { vmread64(0x2020) }
        set { vmwrite64(0x2020, newValue) }
    }

    var eoiExitBitmap3: UInt64 {
        get { vmread64(0x2022) }
        set { vmwrite64(0x2022, newValue) }
    }

    var eptpListAddress: UInt64 {
        get { vmread64(0x2024) }
        set { vmwrite64(0x2024, newValue) }
    }

    var vmreadBitmapAddress: UInt64 {
        get { vmread64(0x2026) }
        set { vmwrite64(0x2026, newValue) }
    }

    var vmwriteBitmapAddress: UInt64 {
        get { vmread64(0x2028) }
        set { vmwrite64(0x2028, newValue) }
    }

    var vExceptionInfoAddress: UInt64 {
        get { vmread64(0x202A) }
        set { vmwrite64(0x202A, newValue) }
    }

    var xssExitingBitmap: UInt64 {
        get { vmread64(0x202C) }
        set { vmwrite64(0x202C, newValue) }
    }

    var enclsExitingBitmap: UInt64 {
        get { vmread64(0x202E) }
        set { vmwrite64(0x202E, newValue) }
    }

    var subPagePermissionTP: UInt64 {
        get { vmread64(0x2030) }
        set { vmwrite64(0x2030, newValue) }
    }

    var tscMultiplier: UInt64 {
        get { vmread64(0x2032) }
        set { vmwrite64(0x2032, newValue) }
    }

    // 64-Bit Read-Only Data Field
    var guestPhysAddress: UInt64 { vmread64(0x2400) }

    // 64-Bit Guest-State Fields
    var vmcsLinkPointer: UInt64 {
        get { vmread64(0x2800) }
        set { vmwrite64(0x2800, newValue) }
    }

    var guestIA32DebugCtl: UInt64 {
        get { vmread64(0x2802) }
        set { vmwrite64(0x2802, newValue) }
    }

    var guestIA32PAT: UInt64 {
        get { vmread64(0x2804) }
        set { vmwrite64(0x2804, newValue) }
    }

    var guestIA32EFER: UInt64 {
        get { vmread64(0x2806) }
        set { vmwrite64(0x2806, newValue) }
    }

    var guestIA32PerfGlobalCtrl: UInt64 {
        get { vmread64(0x2808) }
        set { vmwrite64(0x2808, newValue) }
    }

    var guestPDPTE0: UInt64 {
        get { vmread64(0x280A) }
        set { vmwrite64(0x280A, newValue) }
    }

    var guestPDPTE1: UInt64 {
        get { vmread64(0x280C) }
        set { vmwrite64(0x280C, newValue) }
    }

    var guestPDPTE2: UInt64 {
        get { vmread64(0x280E) }
        set { vmwrite64(0x280E, newValue) }
    }

    var guestPDPTE3: UInt64 {
        get { vmread64(0x2810) }
        set { vmwrite64(0x2810, newValue) }
    }

    var guestIA32bndcfgs: UInt64 {
        get { vmread64(0x2812) }
        set { vmwrite64(0x2812, newValue) }
    }

    var guestIA32RtitCtl: UInt64 {
        get { vmread64(0x2814) }
        set { vmwrite64(0x2814, newValue) }
    }

    // 64-Bit Host-State Fields
    var hostIA32PAT: UInt64 {
        get { vmread64(0x2C00) }
        set { vmwrite64(0x2C00, newValue) }
    }

    var hostIA32EFER: UInt64 {
        get { vmread64(0x2C02) }
        set { vmwrite64(0x2C02, newValue) }
    }

    var hostIA32PerfGlobalCtrl: UInt64 {
        get { vmread64(0x2C04) }
        set { vmwrite64(0x2C04, newValue) }
    }

    // 32Bit Control Fields
    var pinBasedVMExecControls: UInt32 {
        get { vmread32(0x4000) }
        set { vmwrite32(0x4000, newValue) }
    }

    var primaryProcVMExecControls: UInt32 {
        get { vmread32(0x4002) }
        set { vmwrite32(0x4002, newValue) }
    }
    
    var exceptionBitmap: UInt32 {
        get { vmread32(0x4004) }
        set { vmwrite32(0x4004, newValue) }
    }
    
    var pagefaultErrorCodeMask: UInt32 {
        get { vmread32(0x4006) }
        set { vmwrite32(0x4006, newValue) }
    }
    
    var pagefaultErrorCodeMatch: UInt32 {
        get { vmread32(0x4008) }
        set { vmwrite32(0x4008, newValue) }
    }
    
    var cr3TargetCount: UInt32 {
        get { vmread32(0x400A) }
        set { vmwrite32(0x400A, newValue) }
    }
    
    var vmExitControls: UInt32 {
        get { vmread32(0x400C) }
        set { vmwrite32(0x400C, newValue) }
    }
    
    var vmExitMSRStoreCount: UInt32 {
        get { vmread32(0x400E) }
        set { vmwrite32(0x400E, newValue) }
    }
    
    var vmExitMSRLoadCount: UInt32 {
        get { vmread32(0x4010) }
        set { vmwrite32(0x4010, newValue) }
    }
    
    var vmEntryControls: UInt32 {
        get { vmread32(0x4012) }
        set { vmwrite32(0x4012, newValue) }
    }
    
    var vmEntryMSRLoadCount: UInt32 {
        get { vmread32(0x4014) }
        set { vmwrite32(0x4014, newValue) }
    }
    
    var vmEntryInterruptInfo: UInt32 {
        get { vmread32(0x4016) }
        set { vmwrite32(0x4016, newValue) }
    }
    
    var vmEntryExceptionErrorCode: UInt32 {
        get { vmread32(0x4018) }
        set { vmwrite32(0x4018, newValue) }
    }
    
    var vmEntryInstructionLength: UInt32 {
        get { vmread32(0x401A) }
        set { vmwrite32(0x401A, newValue) }
    }
    
    var tprThreshold: UInt32 {
        get { vmread32(0x401C) }
        set { vmwrite32(0x401C, newValue) }
    }
    
    var secondaryProcVMExecControls: UInt32 {
        get { vmread32(0x401E) }
        set { vmwrite32(0x401E, newValue) }
    }


    private var supportsPLE: Bool {
        if let flag = vmExecSecondary?.pauseLoopExiting.allowedToBeOne {
            return flag
        }
        return false
    }

    var pleGap: UInt32? {
        get { return supportsPLE ? vmread32(0x4020) : nil }
        set {
            if let newValue = newValue, supportsPLE {
                vmwrite32(0x4020, newValue)
            }
        }
    }
    
    var pleWindow: UInt32? {
        get { return supportsPLE ? vmread32(0x4022) : nil }
        set {
            if let newValue = newValue, supportsPLE {
                vmwrite32(0x4022, newValue)
            }
        }
    }
    
    // Read only Data fields
    var vmInstructionError: UInt32 { vmread32(0x4400) }
    var exitReason:         UInt32 { vmread32(0x4402) }
    var vmExitIntInfo:      UInt32 { vmread32(0x4404) }
    var vmExitIntErrorCode: UInt32 { vmread32(0x4406) }
    var idtVectorInfoField: UInt32 { vmread32(0x4408) }
    var idtVectorErrorCode: UInt32 { vmread32(0x440A) }
    var vmExitInstrLen:     UInt32 { vmread32(0x440C) }
    var vmExitInstrInfo:    UInt32 { vmread32(0x440E) }

    // 32bit Guest State Fields
    var guestESLimit: UInt32 {
        get { vmread32(0x4800) }
        set { vmwrite32(0x4800, newValue) }
    }

    var guestCSLimit: UInt32 {
        get { vmread32(0x4802) }
        set { vmwrite32(0x4802, newValue) }
    }
    var guestSSLimit: UInt32 {
        get { vmread32(0x4804) }
        set { vmwrite32(0x4804, newValue) }
    }
    var guestDSLimit: UInt32 {
        get { vmread32(0x4806) }
        set { vmwrite32(0x4806, newValue) }
    }
    var guestFSLimit: UInt32 {
        get { vmread32(0x4808) }
        set { vmwrite32(0x4808, newValue) }
    }
    var guestGSLimit: UInt32 {
        get { vmread32(0x480A) }
        set { vmwrite32(0x480A, newValue) }
    }
    var guestLDTRLimit: UInt32 {
        get { vmread32(0x480C) }
        set { vmwrite32(0x480C, newValue) }
    }
    var guestTRLimit: UInt32 {
        get { vmread32(0x480E) }
        set { vmwrite32(0x480E, newValue) }
    }
    var guestGDTRLimit: UInt32 {
        get { vmread32(0x4810) }
        set { vmwrite32(0x4810, newValue) }
    }

    var guestIDTRLimit: UInt32 {
        get { vmread32(0x4812) }
        set { vmwrite32(0x4812, newValue) }
    }

    var guestESAccessRights: UInt32 {
        get { vmread32(0x4814) }
        set { vmwrite32(0x4814, newValue) }
    }

    var guestCSAccessRights: UInt32 {
        get { vmread32(0x4816) }
        set { vmwrite32(0x4816, newValue) }
    }

    var guestSSAccessRights: UInt32 {
        get { vmread32(0x4818) }
        set { vmwrite32(0x4818, newValue) }
    }
    
    var guestDSAccessRights: UInt32 {
        get { vmread32(0x481A) }
        set { vmwrite32(0x481A, newValue) }
    }
    
    var guestFSAccessRights: UInt32 {
        get { vmread32(0x481C) }
        set { vmwrite32(0x481C, newValue) }
    }

    var guestGSAccessRights: UInt32 {
        get { vmread32(0x481E) }
        set { vmwrite32(0x481E, newValue) }
    }
    
    var guestLDTRAccessRights: UInt32 {
        get { vmread32(0x4820) }
        set { vmwrite32(0x4820, newValue) }
    }

    var guestTRAccessRights: UInt32 {
        get { vmread32(0x4822) }
        set { vmwrite32(0x4822, newValue) }
    }

    var guestInterruptibilityState: UInt32 {
        get { vmread32(0x4824) }
        set { vmwrite32(0x4824, newValue) }
    }

    var guestActivityState: UInt32 {
        get { vmread32(0x4826) }
        set { vmwrite32(0x4826, newValue) }
    }

    var guestSMBASE: UInt32 {
        get { vmread32(0x4828) }
        set { vmwrite32(0x4828, newValue) }
    }

    var guestIA32SysenterCS: UInt32 {
        get { vmread32(0x482A) }
        set { vmwrite32(0x482A, newValue) }
    }

    var vmxPreemptionTimerValue: UInt32 {
        get { vmread32(0x482E) }
        set { vmwrite32(0x482E, newValue) }
    }

    var hostIA32SysenterCS: UInt32 {
        get { vmread32(0x4C00) }
        set { vmwrite32(0x4C00, newValue) }
    }

    var cr0mask: UInt {
        get { UInt(vmread64(0x6000)) }
        set { vmwrite64(0x6000, UInt64(newValue)) }
    }

    var cr4mask: UInt {
        get { UInt(vmread64(0x6002)) }
        set { vmwrite64(0x6002, UInt64(newValue)) }
    }
    
    var cr0ReadShadow: CPU.CR0Register {
        get { CPU.CR0Register(vmread64(0x6004)) }
        set { vmwrite64(0x6004, newValue.value) }
    }

    var cr4ReadShadow: CPU.CR4Register {
        get { CPU.CR4Register(vmread64(0x6006)) }
        set { vmwrite64(0x6006, newValue.value) }
    }

    var cr3TargetValue0: UInt {
        get { UInt(vmread64(0x6008)) }
        set { vmwrite64(0x6008, UInt64(newValue)) }
    }

    var cr3TargetValue1: UInt {
        get { UInt(vmread64(0x600A)) }
        set { vmwrite64(0x600A, UInt64(newValue)) }
    }
    
    var cr3TargetValue2: UInt {
        get { UInt(vmread64(0x600C)) }
        set { vmwrite64(0x600C, UInt64(newValue)) }
    }
    
    var cr3TargetValue3: UInt {
        get { UInt(vmread64(0x600E)) }
        set { vmwrite64(0x600E, UInt64(newValue)) }
    }

    // Natural width Read-Only data fields
    var exitQualification: UInt { UInt(vmread64(0x6400)) }
    var ioRCX: UInt { UInt(vmread64(0x6402)) }
    var ioRSI: UInt { UInt(vmread64(0x6404)) }
    var ioRDI: UInt { UInt(vmread64(0x6406)) }
    var ioRIP: UInt { UInt(vmread64(0x6408)) }
    var guestLinearAddress: UInt { UInt(vmread64(0x640A)) }

    // Natural width Guest state fields
    var guestCR0: CPU.CR0Register {
        get { CPU.CR0Register(vmread64(0x6800)) }
        set { vmwrite64(0x6800, newValue.value) }
    }

    var guestCR3: CPU.CR3Register {
        get { CPU.CR3Register(vmread64(0x6802)) }
        set { vmwrite64(0x6802, newValue.value) }
    }

    var guestCR4: CPU.CR4Register {
        get { CPU.CR4Register(vmread64(0x6804)) }
        set { vmwrite64(0x6804, newValue.value) }
    }

    var guestESBase: UInt {
        get { UInt(vmread64(0x6806)) }
        set { vmwrite64(0x6806, UInt64(newValue)) }
    }
    
    var guestCSBase: UInt {
        get { UInt(vmread64(0x6808)) }
        set { vmwrite64(0x6808, UInt64(newValue)) }
    }

    var guestSSBase: UInt {
        get { UInt(vmread64(0x680A)) }
        set { vmwrite64(0x680A, UInt64(newValue)) }
    }

    var guestDSBase: UInt {
        get { UInt(vmread64(0x680C)) }
        set { vmwrite64(0x680C, UInt64(newValue)) }
    }

    var guestFSBase: UInt {
        get { UInt(vmread64(0x680E)) }
        set { vmwrite64(0x680E, UInt64(newValue)) }
    }

    var guestGSBase: UInt {
        get { UInt(vmread64(0x6810)) }
        set { vmwrite64(0x6810, UInt64(newValue)) }
    }

    var guestLDTRBase: UInt {
        get { UInt(vmread64(0x6812)) }
        set { vmwrite64(0x6812, UInt64(newValue)) }
    }

    var guestTRBase: UInt {
        get { UInt(vmread64(0x6814)) }
        set { vmwrite64(0x6814, UInt64(newValue)) }
    }

    var guestGDTRBase: UInt {
        get { UInt(vmread64(0x6816)) }
        set { vmwrite64(0x6816, UInt64(newValue)) }
    }

    var guestIDTRBase: UInt {
        get { UInt(vmread64(0x6818)) }
        set { vmwrite64(0x6818, UInt64(newValue)) }
    }

    var guestDR7: UInt {
        get { UInt(vmread64(0x681A)) }
        set { vmwrite64(0x681A, UInt64(newValue)) }
    }

    var guestRSP: UInt {
        get { UInt(vmread64(0x681C)) }
        set { vmwrite64(0x681C, UInt64(newValue)) }
    }

    var guestRIP: UInt {
        get { UInt(vmread64(0x681E)) }
        set { vmwrite64(0x681E, UInt64(newValue)) }
    }

    var guestRflags: UInt {
        get { UInt(vmread64(0x6820)) }
        set { vmwrite64(0x6820, UInt64(newValue)) }
    }

    var guestPendingDebugExceptions: UInt {
        get { UInt(vmread64(0x6822)) }
        set { vmwrite64(0x6822, UInt64(newValue)) }
    }

    var guestIA32SysenterESP: UInt {
        get { UInt(vmread64(0x6824)) }
        set { vmwrite64(0x6824, UInt64(newValue)) }
    }

    var guestIA32SysenterEIP: UInt {
        get { UInt(vmread64(0x6826)) }
        set { vmwrite64(0x6826, UInt64(newValue)) }
    }
    
    // Natural-Width Host-State Fields
    var hostCR0: CPU.CR0Register {
        get { CPU.CR0Register(vmread64(0x6C00)) }
        set { vmwrite64(0x6C00, newValue.value) }
    }

    var hostCR3: CPU.CR3Register {
        get { CPU.CR3Register(vmread64(0x6C02)) }
        set { vmwrite64(0x6C02, newValue.value) }
    }

    var hostCR4: CPU.CR4Register {
        get { CPU.CR4Register(vmread64(0x6C04)) }
        set { vmwrite64(0x6C04, newValue.value) }
    }

    var hostFSBase: UInt {
        get { UInt(vmread64(0x6C06)) }
        set { vmwrite64(0x6C06, UInt64(newValue)) }
    }

    var hostGSBase: UInt {
        get { UInt(vmread64(0x6C08)) }
        set { vmwrite64(0x6C08, UInt64(newValue)) }
    }

    var hostTRBase: UInt {
        get { UInt(vmread64(0x6C0A)) }
        set { vmwrite64(0x6C0A, UInt64(newValue)) }
    }

    var hostGDTRBase: UInt {
        get { UInt(vmread64(0x6C0C)) }
        set { vmwrite64(0x6C0C, UInt64(newValue)) }
    }

    var hostIDTRBase: UInt {
        get { UInt(vmread64(0x6C0E)) }
        set { vmwrite64(0x6C0E, UInt64(newValue)) }
    }

    var hostIA32SysenterESP: UInt {
        get { UInt(vmread64(0x6C10)) }
        set { vmwrite64(0x6C10, UInt64(newValue)) }
    }

    var hostIA32SysenterEIP: UInt {
        get { UInt(vmread64(0x6C12)) }
        set { vmwrite64(0x6C12, UInt64(newValue)) }
    }

    var hostRSP: UInt {
        get { UInt(vmread64(0x6C14)) }
        set { vmwrite64(0x6C14, UInt64(newValue)) }
    }

    var hostRIP: UInt {
        get { UInt(vmread64(0x6C16)) }
        set { vmwrite64(0x6C16, UInt64(newValue)) }
    }


    func printVMCS() {
        print("physicalAddress:", String(physicalAddress, radix: 16))
        print("vpid:", String(vpid, radix: 16))
        print("interruptNotificationVector:", String(interruptNotificationVector, radix: 16))
        //print("eptpIndex:", String(eptpIndex, radix: 16))
        print("guestESSelector:", String(guestESSelector, radix: 16))
        print("guestCSSelector:", String(guestCSSelector, radix: 16))
        print("guestSSSelector:", String(guestSSSelector, radix: 16))
        print("guestDSSelector:", String(guestDSSelector, radix: 16))
        print("guestFSSelector:", String(guestFSSelector, radix: 16))
        print("guestGSSelector:", String(guestGSSelector, radix: 16))
        print("guestLDTRSelector:", String(guestLDTRSelector, radix: 16))
        print("guestTRSelector:", String(guestTRSelector, radix: 16))
        print("guestInterruptStatus:", String(guestInterruptStatus, radix: 16))
        print("pmlIndex:", String(pmlIndex, radix: 16))
        print("hostESSelector:", String(hostESSelector, radix: 16))
        print("hostCSSelector:", String(hostCSSelector, radix: 16))
        print("hostSSSelector:", String(hostSSSelector, radix: 16))
        print("hostDSSelector:", String(hostDSSelector, radix: 16))
        print("hostFSSelector:", String(hostFSSelector, radix: 16))
        print("hostGSSelector:", String(hostGSSelector, radix: 16))
        print("hostTRSelector:", String(hostTRSelector, radix: 16))
        print("ioBitmapAAddress:", String(ioBitmapAAddress, radix: 16))
        print("ioBitmapBAddress:", String(ioBitmapBAddress, radix: 16))
        print("msrBitmapAddress:", String(msrBitmapAddress, radix: 16))
        print("vmExitMSRStoreAddress:", String(vmExitMSRStoreAddress, radix: 16))
        print("vmExitMSRLoadAddress:", String(vmExitMSRLoadAddress, radix: 16))
        print("vmEntryMSRLoadAddress:", String(vmEntryMSRLoadAddress, radix: 16))
        //print("executiveVMCSPtr:", String(executiveVMCSPtr, radix: 16))
        print("pmlAddress:", String(pmlAddress, radix: 16))
        print("tscOffset:", String(tscOffset, radix: 16))
        print("virtualAPICAddress:", String(virtualAPICAddress, radix: 16))
        print("apicAccessAddress:", String(apicAccessAddress, radix: 16))
        print("postedInterruptDescAddress:", String(postedInterruptDescAddress, radix: 16))
        print("vmFunctionControls:", String(vmFunctionControls, radix: 16))
        print("eptp:", String(eptp, radix: 16))
        print("eoiExitBitmap0:", String(eoiExitBitmap0, radix: 16))
        print("eoiExitBitmap1:", String(eoiExitBitmap1, radix: 16))
        print("eoiExitBitmap2:", String(eoiExitBitmap2, radix: 16))
        print("eoiExitBitmap3:", String(eoiExitBitmap3, radix: 16))
        print("eptpListAddress:", String(eptpListAddress, radix: 16))
        print("vmreadBitmapAddress:", String(vmreadBitmapAddress, radix: 16))
        print("vmwriteBitmapAddress:", String(vmwriteBitmapAddress, radix: 16))
        //print("vExceptionInfoAddress:", String(vExceptionInfoAddress, radix: 16))
        //print("xssExitingBitmap:", String(xssExitingBitmap, radix: 16))
        //print("enclsExitingBitmap:", String(enclsExitingBitmap, radix: 16))
        //print("subPagePermissionTP:", String(subPagePermissionTP, radix: 16))
        //print("tscMultiplier:", String(tscMultiplier, radix: 16))
        print("guestPhysAddress:", String(guestPhysAddress, radix: 16))
        print("vmcsLinkPointer:", String(vmcsLinkPointer, radix: 16))
        print("guestIA32DebugCtl:", String(guestIA32DebugCtl, radix: 16))
        print("guestIA32PAT:", String(guestIA32PAT, radix: 16))
        print("guestIA32EFER:", String(guestIA32EFER, radix: 16))
        print("guestIA32PerfGlobalCtrl:", String(guestIA32PerfGlobalCtrl, radix: 16))
        print("guestPDPTE0:", String(guestPDPTE0, radix: 16))
        print("guestPDPTE1:", String(guestPDPTE1, radix: 16))
        print("guestPDPTE2:", String(guestPDPTE2, radix: 16))
        print("guestPDPTE3:", String(guestPDPTE3, radix: 16))
        print("guestIA32bndcfgs:", String(guestIA32bndcfgs, radix: 16))
        //print("guestIA32RtitCtl:", String(guestIA32RtitCtl, radix: 16))
        print("hostIA32PAT:", String(hostIA32PAT, radix: 16))
        print("hostIA32EFER:", String(hostIA32EFER, radix: 16))
        print("hostIA32PerfGlobalCtrl:", String(hostIA32PerfGlobalCtrl, radix: 16))
        print("pinBasedVMExecControls:", String(pinBasedVMExecControls, radix: 16))
        print("primaryProcVMExecControls:", String(primaryProcVMExecControls, radix: 16))
        print("exceptionBitmap:", String(exceptionBitmap, radix: 16))
        print("pagefaultErrorCodeMask:", String(pagefaultErrorCodeMask, radix: 16))
        print("pagefaultErrorCodeMatch:", String(pagefaultErrorCodeMatch, radix: 16))
        print("cr3TargetCount:", String(cr3TargetCount, radix: 16))
        print("vmExitControls:", String(vmExitControls, radix: 16))
        print("vmExitMSRStoreCount:", String(vmExitMSRStoreCount, radix: 16))
        print("vmExitMSRLoadCount:", String(vmExitMSRLoadCount, radix: 16))
        print("vmEntryControls:", String(vmEntryControls, radix: 16))
        print("vmEntryMSRLoadCount:", String(vmEntryMSRLoadCount, radix: 16))
        print("vmEntryInterruptInfo:", String(vmEntryInterruptInfo, radix: 16))
        print("vmEntryExceptionErrorCode:", String(vmEntryExceptionErrorCode, radix: 16))
        print("vmEntryInstructionLength:", String(vmEntryInstructionLength, radix: 16))
        print("tprThreshold:", String(tprThreshold, radix: 16))
        print("secondaryProcVMExecControls:", String(secondaryProcVMExecControls, radix: 16))
        print("supportsPLE:", supportsPLE)
        print("pleGap:", pleGap == nil ? "Unsupported" : String(pleGap!, radix: 16))
        print("pleWindow:", pleWindow == nil ? "Unsupported" : String(pleWindow!, radix: 16))
        print("vmInstructionError:", String(vmInstructionError, radix: 16))
        print("exitReason:", String(exitReason, radix: 16))
        print("vmExitIntInfo:", String(vmExitIntInfo, radix: 16))
        print("vmExitIntErrorCode:", String(vmExitIntErrorCode, radix: 16))
        print("idtVectorInfoField:", String(idtVectorInfoField, radix: 16))
        print("idtVectorErrorCode:", String(idtVectorErrorCode, radix: 16))
        print("vmExitInstrLen:", String(vmExitInstrLen, radix: 16))
        print("vmExitInstrInfo:", String(vmExitInstrInfo, radix: 16))
        print("guestESLimit:", String(guestESLimit, radix: 16))
        print("guestCSLimit:", String(guestCSLimit, radix: 16))
        print("guestSSLimit:", String(guestSSLimit, radix: 16))
        print("guestDSLimit:", String(guestDSLimit, radix: 16))
        print("guestFSLimit:", String(guestFSLimit, radix: 16))
        print("guestGSLimit:", String(guestGSLimit, radix: 16))
        print("guestLDTRLimit:", String(guestLDTRLimit, radix: 16))
        print("guestTRLimit:", String(guestTRLimit, radix: 16))
        print("guestGDTRLimit:", String(guestGDTRLimit, radix: 16))
        print("guestIDTRLimit:", String(guestIDTRLimit, radix: 16))
        print("guestESAccessRights:", String(guestESAccessRights, radix: 16))
        print("guestCSAccessRights:", String(guestCSAccessRights, radix: 16))
        print("guestSSAccessRights:", String(guestSSAccessRights, radix: 16))
        print("guestDSAccessRights:", String(guestDSAccessRights, radix: 16))
        print("guestFSAccessRights:", String(guestFSAccessRights, radix: 16))
        print("guestGSAccessRights:", String(guestGSAccessRights, radix: 16))
        print("guestLDTRAccessRights:", String(guestLDTRAccessRights, radix: 16))
        print("guestTRAccessRights:", String(guestTRAccessRights, radix: 16))
        print("guestInterruptibilityState:", String(guestInterruptibilityState, radix: 16))
        print("guestActivityState:", String(guestActivityState, radix: 16))
        //print("guestSMBASE:", String(guestSMBASE, radix: 16))
        print("guestIA32SysenterCS:", String(guestIA32SysenterCS, radix: 16))
        print("vmxPreemptionTimerValue:", String(vmxPreemptionTimerValue, radix: 16))
        print("hostIA32SysenterCS:", String(hostIA32SysenterCS, radix: 16))
        print("cr0mask:", String(cr0mask, radix: 16))
        print("cr4mask:", String(cr4mask, radix: 16))
        print("cr0ReadShadow:", String(cr0ReadShadow.bits.toUInt64(), radix: 16), cr0ReadShadow)
        print("cr4ReadShadow:", String(cr4ReadShadow.bits.toUInt64(), radix: 16), cr4ReadShadow)
        print("cr3TargetValue0:", String(cr3TargetValue0, radix: 16))
        print("cr3TargetValue1:", String(cr3TargetValue1, radix: 16))
        print("cr3TargetValue2:", String(cr3TargetValue2, radix: 16))
        print("cr3TargetValue3:", String(cr3TargetValue3, radix: 16))
        print("exitQualification:", String(exitQualification, radix: 16))
        //print("ioRCX:", String(ioRCX, radix: 16))
        //print("ioRSI:", String(ioRSI, radix: 16))
        //print("ioRDI:", String(ioRDI, radix: 16))
        //print("ioRIP:", String(ioRIP, radix: 16))
        print("guestLinearAddress:", String(guestLinearAddress, radix: 16))
        print("guestCR0:", String(guestCR0.bits.toUInt64(), radix: 16), guestCR0)
        print("guestCR3:", String(guestCR3.bits.toUInt64(), radix: 16), guestCR3)
        print("guestCR4:", String(guestCR4.bits.toUInt64(), radix: 16), guestCR4)
        print("guestESBase:", String(guestESBase, radix: 16))
        print("guestCSBase:", String(guestCSBase, radix: 16))
        print("guestSSBase:", String(guestSSBase, radix: 16))
        print("guestDSBase:", String(guestDSBase, radix: 16))
        print("guestFSBase:", String(guestFSBase, radix: 16))
        print("guestGSBase:", String(guestGSBase, radix: 16))
        print("guestLDTRBase:", String(guestLDTRBase, radix: 16))
        print("guestTRBase:", String(guestTRBase, radix: 16))
        print("guestGDTRBase:", String(guestGDTRBase, radix: 16))
        print("guestIDTRBase:", String(guestIDTRBase, radix: 16))
        print("guestDR7:", String(guestDR7, radix: 16))
        print("guestRSP:", String(guestRSP, radix: 16))
        print("guestRIP:", String(guestRIP, radix: 16))
        print("guestRflags:", String(guestRflags, radix: 16))
        print("guestPendingDebugExceptions:", String(guestPendingDebugExceptions, radix: 16))
        print("guestIA32SysenterESP:", String(guestIA32SysenterESP, radix: 16))
        print("guestIA32SysenterEIP:", String(guestIA32SysenterEIP, radix: 16))
        print("hostCR0:", String(hostCR0.bits.toUInt64(), radix: 16), hostCR0)
        print("hostCR3:", String(hostCR3.bits.toUInt64(), radix: 16), hostCR3)
        print("hostCR4:", String(hostCR4.bits.toUInt64(), radix: 16), hostCR4)
        print("hostFSBase:", String(hostFSBase, radix: 16))
        print("hostGSBase:", String(hostGSBase, radix: 16))
        print("hostTRBase:", String(hostTRBase, radix: 16))
        print("hostGDTRBase:", String(hostGDTRBase, radix: 16))
        print("hostIDTRBase:", String(hostIDTRBase, radix: 16))
        print("hostIA32SysenterESP:", String(hostIA32SysenterESP, radix: 16))
        print("hostIA32SysenterEIP:", String(hostIA32SysenterEIP, radix: 16))
        print("hostRSP:", String(hostRSP, radix: 16))
        print("hostRIP:", String(hostRIP, radix: 16))
    }

    
    private func vmread16(_ index: UInt32) -> UInt16 {
        var data: UInt64 = 0
        let error = vmread(index, &data)
        guard error == 0 else {
            let msg = "vmread16( \(String(index, radix: 16)): \(error)"
            fatalError(msg)
        }
        return UInt16(data)
    }


    private func vmread32(_ index: UInt32) -> UInt32 {
        var data: UInt64 = 0
        let error = vmread(index, &data)
        guard error == 0 else {
            let vmxError = VMXError(error)
            let msg = "vmread32( \(String(index, radix: 16)): \(error), \(vmxError)"
            fatalError(msg)
        }
        return UInt32(data)
    }


    private func vmread64(_ index: UInt32) -> UInt64 {
        var data: UInt64 = 0
        let error = vmread(index, &data)
        guard error == 0 else {
            let vmxError = VMXError(error)
            let msg = "vmread64( \(String(index, radix: 16)): \(error), \(vmxError)"
            fatalError(msg)
        }
        return data
    }


    private func vmwrite16(_ index: UInt32, _ data: UInt16)  {
        let error = vmwrite(index, UInt64(data))
        guard error == 0 else {
            let vmxError = VMXError(error)
            let msg = "vmwrite16( \(String(index, radix: 16)): \(error), \(vmxError)"
            fatalError(msg)
        }
    }


    private func vmwrite32(_ index: UInt32, _ data: UInt32) {
        let error = vmwrite(index, UInt64(data))
        guard error == 0 else {
            let vmxError = VMXError(error)
            let msg = "vmwrite32( \(String(index, radix: 16)): \(error), \(vmxError)"
            fatalError(msg)
        }
    }


    private func vmwrite64(_ index: UInt32, _ data: UInt64) {
        let error = vmwrite(index, data)
        guard error == 0 else {
            let vmxError = VMXError(error)
            let msg = "vmwrite64( \(String(index, radix: 16)): \(error), \(vmxError)"
            fatalError(msg)
        }
    }
}
