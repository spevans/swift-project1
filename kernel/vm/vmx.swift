/*
 * kernel/devices/vmx.swift
 *
 * Created by Simon Evans on 28/06/2019.
 * Copyright © 2019 Simon Evans. All rights reserved.
 *
 * VMX functionality.
 *
 */

private var globalVmcs: VMCS?  // pointer to global VMCS

private var guestVmcs: VMCS?

enum VMXError: Error, Equatable {

    enum VMFailValidError: UInt32 {
    case vmcallInNonRootOperation = 1
    case vmclearWithInvalidAddress = 2
    case vmclearWithVxmonPointer = 3
    case vmlaunchWithNonClearVMCS = 4
    case vmresumeWithNonLaunchedVMCS = 5
    case vmresumeWithCorruptedVMCS = 6
    case vmentryWithInvalidControlField = 7
    case vmentryWithInvalidHostStateField = 8
    case vmptrldWithInvalidAddress = 9
    case vmptrldWithVxmonPointer = 10
    case vmptrldWithIncorrectVMCSRevisionId = 11
    case readWriteUsingUnsupportedVMCSComponent = 12
    case vmwriteToReadonlyComponent = 13
    case vxmonExecutedInRootOperation = 15
    case vmentryWithEventsBlockedByMOVSS = 26
    }


    case vmSucceed
    case vmFailInvalid
    case vmFailValid(VMFailValidError)

    init(_ error: UInt64) {
        switch(error) {
        case 0x0: self = .vmSucceed
        case 0x1: self = .vmFailInvalid
        case 0x40:
            var errorCode: UInt64 = 0
            let ret = vmread(0x4400, &errorCode)
            guard ret == 0x0 else {
                fatalError("vmread of errorcode returned \(String(ret, radix: 16))")
            }
            let validError = VMFailValidError(rawValue: UInt32(errorCode))!
            self = .vmFailValid(validError)

        default: fatalError("Invalid VMX error state: \(String(error, radix: 16))")
        }
    }
}

enum VMXExitReason: UInt16 {
    case exceptionOrNMI = 0
    case externalINT = 1
    case tripleFault = 2
    case initSignal = 3
    case startupIPI = 4
    case ioSMI = 5
    case otherSMI = 6
    case intWindow = 7
    case nmiWindow = 8
    case taskSwitch = 9
    case cpuid = 10
    case getsec = 11
    case hlt = 12
    case invd = 13
    case invlpg = 14
    case rdpmc = 15
    case rdtsc = 16
    case rsm = 17
    case vmcall = 18
    case vmclear = 19
    case vmlaunch = 20
    case vmptrld = 21
    case vmptrst = 22
    case vmread = 23
    case vmresume = 24
    case vmwrite = 25
    case vmxoff = 26
    case vmxon = 27
    case crAccess = 28
    case drAccess = 29
    case ioInstruction = 30
    case rdmsr = 31
    case wrmsr = 32
    case vmentryFailInvalidGuestState = 33
    case vmentryFailMSRLoading = 34
    case mwait = 36
    case monitorTrapFlag = 37
    case monitor = 39
    case pause = 40
    case vmentryFaileMCE = 41
    case tprBelowThreshold = 43
    case apicAccess = 44
    case virtualisedEOI = 45
    case accessToGDTRorIDTR = 46
    case accessToLDTRorTR = 47
    case eptViolation = 48
    case eptMisconfiguration = 49
    case invept = 50
    case rdtscp = 51
    case vmxPreemptionTimerExpired = 52
    case invvpid = 53
    case wbinvd = 54
    case xsetbv = 55
    case apicWrite = 56
    case rdrand = 57
    case invpcid  = 58
    case vmfunc = 59
    case envls = 60
    case rdseed = 61
    case pmlFull = 62
    case xsaves = 63
    case xrstors = 64
    case subPagePermissionEvent = 66
    case umwait = 67
    case tpause = 68
}


struct VMXExit: Error {
    let value: BitArray32

    var exitReason: VMXExitReason { VMXExitReason(rawValue: UInt16(value[0...15]))! }
    var vmExitInEnclaveMode: Bool { Bool(value[27]) }
    var pendingMTFvmExit: Bool { Bool(value[28]) }
    var vmExitFromVMXrootOperation: Bool { Bool(value[29]) }
    var vmEntryFailure: Bool { Bool(value[31]) }

    init(_ result: UInt32) {
        value = BitArray32(result)
    }
}


func enableVMX() -> VMXError {
    guard CPU.capabilities.vmx else {
        print("VMX extensions not supported")
        return .vmFailInvalid
    }
    guard globalVmcs == nil else {
        print("VMX already enabled")
        return .vmFailInvalid
    }

    let vmxInfo = VMXBasicInfo()
    print(vmxInfo)

    let vmxMiscInfo = VMXMiscInfo()
    print("VMX: MiscInfo:", vmxMiscInfo)

    var fc = CPU.IA32FeatureControl()
    if !fc.lock || !fc.enableVMXOutsideSMX {
        fc.enableVMXOutsideSMX = true
        fc.lock = true
        guard fc.update() else {
            print("Cant update lock or enableVMXOutsideSMX")
            return .vmFailInvalid
        }
    }

    // Check fixed 0 and 1 bits in CR0 and CR4 are set
    print("VMX: Setting CR0 and CR4 Fixed0 and Fixed1 bits")
    var cr0 = CPU.cr0
    var cr4 = CPU.cr4
    let vmxFixedBits = VMXFixedBits()

    print("VMX: cr0Fixed0Bits:", String(vmxFixedBits.cr0Fixed0Bits, radix: 16),
        CPU.CR0Register(vmxFixedBits.cr0Fixed0Bits))
    print("VMX: cr0Fixed1Bits:", String(vmxFixedBits.cr0Fixed1Bits, radix: 16),
        CPU.CR0Register(vmxFixedBits.cr0Fixed1Bits))
    print("VMX: cr4Fixed0Bits:", String(vmxFixedBits.cr4Fixed0Bits, radix: 16),
        CPU.CR4Register(vmxFixedBits.cr4Fixed0Bits))
    print("VMX: cr4Fixed1Bits:", String(vmxFixedBits.cr4Fixed1Bits, radix: 16),
        CPU.CR4Register(vmxFixedBits.cr4Fixed1Bits))

    let vmxPrimaryCtrl = VMXPrimaryProcessorBasedControls()
    let vmxSecondaryCtrl = VMXSecondaryProcessorBasedControls()
    print("vmxPrimaryCtrl:", String(vmxPrimaryCtrl.bits.rawValue, radix: 16))
    print("vmxSecondaryCtrl:", String(vmxSecondaryCtrl.bits.rawValue, radix: 16))
    print("vmxPrimaryCtrl.activateSecondaryControls:", vmxPrimaryCtrl.activateSecondaryControls)
    if vmxPrimaryCtrl.activateSecondaryControls.allowedToBeOne {
        print("VMX: Secondary Ctrl:", vmxSecondaryCtrl.unrestrictedGuest)
    }

    if !vmxFixedBits.allowsUnrestrictedGuest {
        print("VMX: Unrestricted guest not allowed")
    }

    cr0 = vmxFixedBits.updateCR0(bits: cr0)
    CPU.cr0 = cr0
    cr4 = vmxFixedBits.updateCR4(bits: cr4)
    CPU.cr4 = cr4

    let newVMCS = VMCS()
    let paddr = newVMCS.page.address
    print("VMX: Enabling @ \(String(paddr.value, radix: 16))")
    let error = vmxon(UInt64(newVMCS.physicalAddress))
    let result = VMXError(error)
    if result != .vmSucceed {
        print("VMX: VMXON failed, error: \(result)")
    } else {
        globalVmcs = newVMCS
        print("VMX: Enabled @ \(String(newVMCS.physicalAddress, radix: 16))")
    }
    return result
}


func disableVMX() {
    guard globalVmcs != nil else {
        print("VMX not enabled")
        return
    }
    let error = vmxoff()
    let result = VMXError(error)
    if  result != .vmSucceed {
        printf("VMXOFF failed:", result)
        return
    }
    globalVmcs = nil
    guestVmcs = nil
    print("VMX disabled")
}


func testVMX() -> Result<VMXExit, VMXError> {
    guard globalVmcs != nil else {
        print("VMX not enabled")
        return .failure(.vmFailInvalid)
    }
    guard guestVmcs == nil else {
        print("guestVMCS already setup")
        return .failure(.vmFailInvalid)
    }
    let vmcs = VMCS()
    let ok = vmcs.vmClear()
    print("clearing guest VMCS with good address:", ok)
    if ok == .vmSucceed {
        guestVmcs = vmcs
    }

    let ptre = vmcs.vmPtrLoad()
    print("vmptrld:", ptre)


    var realModeTestProgram: [UInt8] = [
        0xb8, 0x34, 0x12,     // mov     ax, 0x1234
        0xbb, 0x78, 0x56,     // mov     bx, 0x5678
        0xb9, 0xad, 0xde,     // mov     cx, 0xdead
        0xba, 0xef, 0xbe,     // mov     dx, 0xbeef
        0xf4                  // hlt
    ]


    // Allocate a page for the 'physical' RAM for the VM
    let vmMemory = alloc(pages: 1)
    vmMemory.rawBufferPointer.initializeMemory(as: UInt8.self, repeating: 0)
    vmMemory.rawPointer.copyMemory(from: &realModeTestProgram,
                                   byteCount: realModeTestProgram.count)
    // Map this page into address space (currently shared with the kernel)
    // @ 16K (0x4000)
    let physAddress = vmMemory.address
    addMapping(start: 0x4000, size: PAGE_SIZE, physStart: physAddress,
        readWrite: false, noExec: false)


    // VM Execution control fields
    let vmxBasicInfo = VMXBasicInfo()
    if vmxBasicInfo.vmxControlsCanBeCleared == false {
        print("VMX: vmxControlsCanBeCleared == false")
        vmcs.pinBasedVMExecControls = VMXPinBasedControls().defaultValue
        vmcs.primaryProcVMExecControls = VMXPrimaryProcessorBasedControls().defaultValue
        vmcs.vmEntryControls = VMXEntryControls().defaultValue
        vmcs.vmExitControls = VMXExitControls().defaultValue
    } else {
        vmcs.pinBasedVMExecControls = VMXTruePinBasedControls().defaultValue
        vmcs.primaryProcVMExecControls = VMXTruePrimaryProcessorBasedControls().defaultValue
        vmcs.vmEntryControls = VMXTrueEntryControls().defaultValue
        vmcs.vmExitControls = VMXTrueExitControls().defaultValue
    }
    if VMXPrimaryProcessorBasedControls().activateSecondaryControls.allowedToBeOne {
        if let proc = vmcs.primaryProcVMExecControls {
            vmcs.primaryProcVMExecControls = proc | 0x80000000
        }
        let x = VMXSecondaryProcessorBasedControls()
        print("VMX unrestricted guest:", x.unrestrictedGuest.allowedToBeOne)
        print("VMX: VMXSecondaryProcessorBasedControls: low: \(String(x.low, radix: 16)), high: \(String(x.high, radix: 16)))")
        vmcs.secondaryProcVMExecControls = x.defaultValue //UInt32(2 | 128)
    }

    vmcs.cr3TargetCount = 0
    vmcs.vmExitMSRStoreCount = 0
    vmcs.vmExitMSRStoreAddress = 0
    vmcs.vmExitMSRLoadCount = 0
    vmcs.vmExitMSRLoadAddress = 0
    vmcs.vmEntryMSRLoadCount = 0
    vmcs.vmEntryMSRLoadAddress = 0

    vmcs.ioBitmapAAddress = 0
    vmcs.ioBitmapBAddress = 0
    vmcs.msrBitmapAddress = 0
    vmcs.virtualAPICAddress = 0

    // Setup guest state
    // segments first
    vmcs.guestCSSelector = 0xf000
    vmcs.guestCSBase = 0xffff0000
    vmcs.guestCSLimit = 0xffff
    vmcs.guestCSAccessRights = (0x93 | 8)

    vmcs.guestDSSelector = 0
    vmcs.guestDSBase = 0
    vmcs.guestDSLimit = 0xffff
    vmcs.guestDSAccessRights = 0x93

    vmcs.guestESSelector = 0
    vmcs.guestESBase = 0
    vmcs.guestESLimit = 0xffff
    vmcs.guestESAccessRights = 0x93

    vmcs.guestFSSelector = 0
    vmcs.guestFSBase = 0
    vmcs.guestFSLimit = 0xffff
    vmcs.guestFSAccessRights = 0x93

    vmcs.guestGSSelector = 0
    vmcs.guestGSBase = 0
    vmcs.guestGSLimit = 0xffff
    vmcs.guestGSAccessRights = 0x93

    vmcs.guestSSSelector = 0
    vmcs.guestSSBase = 0
    vmcs.guestSSLimit = 0xffff
    vmcs.guestSSAccessRights = 0x93

    vmcs.guestTRSelector = 0
    vmcs.guestTRBase = 0
    vmcs.guestTRLimit = 0xffff
    vmcs.guestTRAccessRights = 0x8b

    vmcs.guestLDTRSelector = 0
    vmcs.guestLDTRBase = 0
    vmcs.guestLDTRLimit = 0xffff
    vmcs.guestLDTRAccessRights = 0x82

    vmcs.guestGDTRBase = 0
    vmcs.guestGDTRLimit = 0xffff
    vmcs.guestIDTRBase = 0
    vmcs.guestIDTRLimit = 0xffff

    vmcs.guestActivityState = 0
    vmcs.guestInterruptibilityState = 0
    vmcs.guestPendingDebugExceptions = 0
    vmcs.vmEntryInterruptInfo = 0

    let gdt = currentGDT()
    vmcs.guestGDTRBase = UInt(bitPattern: gdt.base)
    let idt = currentIDT()
    vmcs.guestIDTRBase = UInt(bitPattern: idt.base)

    let vmxFixedBits = VMXFixedBits()

    var cr0 = CPU.CR0Register(0)
    cr0.notWriteThrough = true
    cr0.cacheDisable = true
    cr0.extensionType = true

    var hwcr0 = cr0
    hwcr0.notWriteThrough = false
    hwcr0.cacheDisable = false
    hwcr0.numericError = true

    vmcs.guestCR0 = vmxFixedBits.updateCR0(bits: hwcr0)
    vmcs.cr0ReadShadow = cr0
    vmcs.guestCR3 = CPU.CR3Register(0)

    let cr4 = CPU.CR4Register(0)
    var hwcr4 = cr4
    hwcr4.vmxe = true

    vmcs.cr4ReadShadow = cr4
    vmcs.guestCR4 = vmxFixedBits.updateCR4(bits: hwcr4)

    vmcs.hostCR0 = CPU.CR0Register()
    vmcs.hostCR3 = CPU.CR3Register()
    vmcs.hostCR4 = CPU.CR4Register()
    vmcs.hostCSSelector = UInt16(CODE_SELECTOR)
    vmcs.hostDSSelector = UInt16(DATA_SELECTOR)
    vmcs.hostESSelector = UInt16(DATA_SELECTOR)
    vmcs.hostFSSelector = UInt16(DATA_SELECTOR)
    vmcs.hostGSSelector = UInt16(DATA_SELECTOR)
    vmcs.hostSSSelector = UInt16(DATA_SELECTOR)
    vmcs.hostIA32SysenterESP = 0
    vmcs.hostIA32SysenterEIP = 0


    vmcs.printVMCS()

    print("Calling vmentry")
    let ret = vmentry(&vmcs.vcpu)
    print("ret:", ret)
    let vmxError = VMXError(UInt64(ret))
    print("vmxError:", vmxError)
    print("ExitReason:", vmcs.exitReason!)
    print("Guest Registers:")
    print("RAX:", String(vmcs.vcpu.rax, radix: 16), terminator: " ")
    print("RBX:", String(vmcs.vcpu.rbx, radix: 16), terminator: " ")
    print("RCX:", String(vmcs.vcpu.rcx, radix: 16), terminator: " ")
    print("RDX:", String(vmcs.vcpu.rdx, radix: 16))
    print("R8 :", String(vmcs.vcpu.rdx, radix: 16), terminator: " ")
    print("R9 :", String(vmcs.vcpu.r9 , radix: 16), terminator: " ")
    print("R10:", String(vmcs.vcpu.r10, radix: 16), terminator: " ")
    print("R11:", String(vmcs.vcpu.r11, radix: 16))
    print("R12:", String(vmcs.vcpu.r12, radix: 16), terminator: " ")
    print("R13:", String(vmcs.vcpu.r13, radix: 16), terminator: " ")
    print("R14:", String(vmcs.vcpu.r14, radix: 16), terminator: " ")
    print("R15:", String(vmcs.vcpu.r15, radix: 16))
    print("RDI:", String(vmcs.vcpu.rdi, radix: 16), terminator: " ")
    print("RSI:", String(vmcs.vcpu.rsi, radix: 16), terminator: " ")
    print("RBP:", String(vmcs.vcpu.rbp, radix: 16), terminator: " ")
    print("RSP:", String(vmcs.guestRSP!, radix: 16))
    print("RIP:", String(vmcs.guestRIP!, radix: 16))

    if vmxError == .vmSucceed {
        let vmxExit = VMXExit(vmcs.exitReason!)
        return .success(vmxExit)
    } else {
        return .failure(vmxError)
    }
}
