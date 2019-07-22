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


    // Host Selectgors
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
        get { vmread16(0xC0A) }
        set { vmwrite16(0xC0A, newValue) }
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
    
    var pleGap: UInt32 {
        get { vmread32(0x4020) }
        set { vmwrite32(0x4020, newValue) }
    }
    
    var pleWindow: UInt32 {
        get { vmread32(0x4022) }
        set { vmwrite32(0x4022, newValue) }
    }
    
    // Read only Data fields
    var vmInstructionError: UInt32 { vmread32(0x4400) }
    var exitReason:         UInt32 { vmread32(0x4402) }
    var vmExitIntInfo:      UInt32 { vmread32(0x4404) }
    var vmExitIntErorrCode: UInt32 { vmread32(0x4406) }
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
        set { vmwrite32(0x4c00, newValue) }
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
        get { UInt(vmread64(0x6824)) }
        set { vmwrite64(0x6824, UInt64(newValue)) }
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

    var hosttIA32SysenterEIP: UInt {
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
            let msg = "vmread32( \(String(index, radix: 16)): \(error)"
            fatalError(msg)
        }
        return UInt32(data)
    }


    private func vmread64(_ index: UInt32) -> UInt64 {
        var data: UInt64 = 0
        let error = vmread(index, &data)
        guard error == 0 else {
            let msg = "vmread64( \(String(index, radix: 16)): \(error)"
            fatalError(msg)
        }
        return data
    }


    private func vmwrite16(_ index: UInt32, _ data: UInt16)  {
        let error = vmwrite(index, UInt64(data))
        guard error == 0 else {
            let msg = "vmwrite16( \(String(index, radix: 16)): \(error)"
            fatalError(msg)
        }
    }


    private func vmwrite32(_ index: UInt32, _ data: UInt32) {
        let error = vmwrite(index, UInt64(data))
        guard error == 0 else {
            let msg = "vmwrite32( \(String(index, radix: 16)): \(error)"
            fatalError(msg)
        }
    }


    private func vmwrite64(_ index: UInt32, _ data: UInt64) {
        let error = vmwrite(index, data)
        guard error == 0 else {
            var msg = "vmwrite64( \(String(index, radix: 16)): \(error)\n"
            var errorCode: UInt64 = 0
            let ret = vmread(0x4400, &errorCode)
            msg += "errorCode: \(String(errorCode, radix: 16)), ret = \(ret)"
            fatalError(msg)
        }
    }
}
