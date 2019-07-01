/*
 * kernel/devices/vmx.swift
 *
 * Created by Simon Evans on 28/06/2019.
 * Copyright © 2019 Simon Evans. All rights reserved.
 *
 * VMX functionality.
 *
 */

private var vmcs: VMCS?  // pointer to global VMCS

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

struct VMXExit: Error {
    let exitReason: UInt32

    init() {
        let result = VMRead32(at: 0x4402)
        switch result {
        case .success(let value):
            exitReason = value
        case .failure(let error):
            fatalError("Cant read exit reason: \(error)")
        }
    }
}


private class VMCS {

    static let vmxInfo = VMXBasicInfo()

    let address: VirtualAddress
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
}


func enableVMX() -> VMXError {
    guard CPU.capabilities.vmx else {
        print("VMX extensions not supported")
        return .vmFailInvalid
    }
    guard vmcs == nil else {
        print("VMX already enabled")
        return .vmFailInvalid
    }

    let vmxInfo = VMXBasicInfo()
    print(vmxInfo)

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
    let fixedBits = VMXFixedBits()

    cr0 = fixedBits.updateCR0(bits: cr0)
    CPU.cr0 = cr0
    cr4 = fixedBits.updateCR4(bits: cr4)
    CPU.cr4 = cr4

    let newVMCS = VMCS()
    print("VMX: Enabling @ \(String(newVMCS.address, radix: 16))")
    let error = vmxon(UInt64(newVMCS.physicalAddress))
    let result = VMXError(error)
    if result != .vmSucceed {
        print("VMX: VMXON failed, error: \(result)")
    } else {
        vmcs = newVMCS
        print("VMX: Enabled @ \(String(newVMCS.physicalAddress, radix: 16))")
    }
    return result
}


func disableVMX() {
    guard vmcs != nil else {
        print("VMX not enabled")
        return
    }
    let error = vmxoff()
    let result = VMXError(error)
    if  result != .vmSucceed {
        printf("VMXOFF failed:", result)
        return
    }
    vmcs = nil
    guestVmcs = nil
    print("VMX disabled")
}


func testVMX() {
    guard vmcs != nil else {
        print("VMX not enabled")
        return
    }
    guard guestVmcs == nil else {
        print("guestVMCS already setup")
        return
    }
    let vmcs = VMCS()
    let ok = vmcs.vmClear()
    print("clearing guest VMCS with good address:", ok)
    if ok == .vmSucceed {
        guestVmcs = vmcs
    }

    let ptre = vmcs.vmPtrLoad()
    print("vmptrld:", ptre)
}


func VMRead16(at index: UInt32) -> Result<UInt16, VMXError> {
    var data: UInt64 = 0
    let error = VMXError(vmread(index, &data))
    if error == .vmSucceed {
        return .success(UInt16(data))
    } else {
        return .failure(error)
    }
}


func VMRead32(at index: UInt32) -> Result<UInt32, VMXError> {
    var data: UInt64 = 0
    let error = VMXError(vmread(index, &data))
    if error == .vmSucceed {
        return .success(UInt32(data))
    } else {
        return .failure(error)
    }
}


func VMRead64(at index: UInt32) -> Result<UInt64, VMXError> {
    var data: UInt64 = 0
    let error = VMXError(vmread(index, &data))
    if error == .vmSucceed {
        return .success(data)
    } else {
        return .failure(error)
    }
}


func VMWrite16(at index: UInt32, data: UInt16) -> VMXError {
    let error = VMXError(vmwrite(index, UInt64(data)))
    return error
}



func VMWrite32(at index: UInt32, data: UInt32) -> VMXError {
    let error = VMXError(vmwrite(index, UInt64(data)))
    return error
}


func VMWrite64(at index: UInt32, data: UInt64) -> VMXError {
    let error = VMXError(vmwrite(index, data))
    return error
}


func VMXLaunch() -> Result<VMXExit, VMXError> {
    guard vmcs != nil else {
        print("VMX not enabled")
        return .failure(.vmFailInvalid)
    }

    let error = VMXError(vmlaunch())
    if error != .vmSucceed {
        print("VMX Launch:", error)
        return .failure(error)
    }
    let vmxExit = VMXExit()
    return .success(vmxExit)
}


func VMXResume() -> Result<VMXExit, VMXError> {
    guard vmcs != nil else {
        print("VMX not enabled")
        return .failure(.vmFailInvalid)
    }

    let error = VMXError(vmlaunch())
    if error != .vmSucceed {
        print("VMX Launch:", error)
        return .failure(error)
    }
    let vmxExit = VMXExit()
    return .success(vmxExit)
}
