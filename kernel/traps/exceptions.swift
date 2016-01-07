/*
 * kernel/traps/exceptions.swift
 *
 * Created by Simon Evans on 01/01/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Handlers for CPU exceptions, currently they just dump the registers
 * and halt
 *
 */


// Simple stack backtrace using rbp to walk the stack
// Needs an update for eh_frame at some point
func stackTrace(rsp: UInt64, _ rbp: UInt64) {

    let rsp_ptr = UnsafePointer<UInt>(bitPattern: UInt(rsp))
    printf("RSP: %p = %p\n", rsp, rsp_ptr.memory);

    var rbp_addr = UInt(rbp)

    var rbp_ptr = UnsafePointer<UInt>(bitPattern: rbp_addr)
    var idx = 0
    while rbp_addr < _kernel_stack_addr {
        printf("[%p]: %p ret=%p\n", rbp_addr, rbp_ptr.memory, (rbp_ptr+1).memory)
        rbp_addr = rbp_ptr.memory
        rbp_ptr = UnsafePointer<UInt>(bitPattern: rbp_addr)
        idx += 1
        if idx > 10 {
            // temporary safety check
            print("Exceeded depth of 10")
            return
        }
    }
}


func dumpRegisters(inout registers: exception_regs) {
    printf("RAX: %16.16lx ", registers.rax)
    printf("RBX: %16.16lx ", registers.rbx)
    printf("RCX: %16.16lx\n", registers.rcx)
    printf("RDX: %16.16lx ", registers.rdx)
    printf("RSI: %16.16lx ", registers.rsi)
    printf("RDI: %16.16lx\n", registers.rdi)
    printf("RBP: %16.16lx ", registers.rbp)
    printf("RSP: %16.16lx ", registers.rsp)
    printf("RIP: %16.16lx\n", registers.rip)
    printf("R8 : %16.16lx ", registers.r8)
    printf("R9 : %16.16lx ", registers.r9)
    printf("R10: %16.16lx\n", registers.r10)
    printf("R11: %16.16lx ", registers.r11)
    printf("R12: %16.16lx ", registers.r12)
    printf("R13: %16.16lx\n", registers.r13)
    printf("R14: %16.16lx ", registers.r14)
    printf("R15: %16.16lx ", registers.r15)
    printf("CR2: %16.16lx\n", getCR2())
    printf("CS: %x DS: %x ES: %x FS: %x GS:%x SS: %x\n",
        registers.cs, registers.ds, registers.es,
        registers.fs, registers.gs, registers.ss)
    stackTrace(registers.rsp, registers.rbp)
}


func divideByZeroException(registers: UnsafeMutablePointer<exception_regs>) {
    print("divideByZero")
    dumpRegisters(&registers.memory)
    hlt()
}


func debugException(registers: UnsafeMutablePointer<exception_regs>) {
    print("debugException")
    dumpRegisters(&registers.memory)
    hlt()
}


func nonMaskableInterrupt(registers: UnsafeMutablePointer<exception_regs>) {
    print("NMI")
    dumpRegisters(&registers.memory)
    hlt()
}


func singleStepBreakpoint(registers: UnsafeMutablePointer<exception_regs>) {
    print("Breakpoint")
    dumpRegisters(&registers.memory)
}


func overflowException(registers: UnsafeMutablePointer<exception_regs>) {
    print("Overflow Exception")
    dumpRegisters(&registers.memory)
    hlt()
}


func boundsException(registers: UnsafeMutablePointer<exception_regs>) {
    print("Bounds Exception")
    dumpRegisters(&registers.memory)
    hlt()
}


func invalidOpcodeException(registers: UnsafeMutablePointer<exception_regs>) {
    print("Invalid Opcode Exception")
    dumpRegisters(&registers.memory)
    hlt()
}


func doubleFault(registers: UnsafeMutablePointer<exception_regs>) {
    let errorCode = registers.memory.error_code
    print("Double Fault code: \(errorCode)")
    dumpRegisters(&registers.memory)
    hlt()
}


func invalidTSSException(registers: UnsafeMutablePointer<exception_regs>) {
    let errorCode = registers.memory.error_code
    print("Invalid Task State Segment code: \(errorCode)")
    dumpRegisters(&registers.memory)
    hlt()
}


func segmentNotPresentException(registers: UnsafeMutablePointer<exception_regs>) {
    let errorCode = registers.memory.error_code
    print("Segment Not Present Exception code: \(errorCode)")
    dumpRegisters(&registers.memory)
    hlt()
}


func stackFault(registers: UnsafeMutablePointer<exception_regs>) {
    let errorCode = registers.memory.error_code
    print("Stack Fault code: \(errorCode)")
    dumpRegisters(&registers.memory)
    hlt()
}


func generalProtectionFault(registers: UnsafeMutablePointer<exception_regs>) {
    let errorCode = registers.memory.error_code
    print("GP Fault code: \(errorCode)")
    dumpRegisters(&registers.memory)
    hlt()
}


func pageFault(registers: UnsafeMutablePointer<exception_regs>) {
    let errorCode = registers.memory.error_code
    print("Page Fault code: \(errorCode)")
    dumpRegisters(&registers.memory)
    hlt()
}


func fpuFault(registers: UnsafeMutablePointer<exception_regs>) {
    print("FPU Fault")
    dumpRegisters(&registers.memory)
    hlt()
}


func alignmentCheckException(registers: UnsafeMutablePointer<exception_regs>) {
    let errorCode = registers.memory.error_code
    print("Alignment Check Exception code: \(errorCode)")
    dumpRegisters(&registers.memory)
    hlt()
}


func machineCheckException(registers: UnsafeMutablePointer<exception_regs>) {
    print("Machine Check Exception")
    dumpRegisters(&registers.memory)
    hlt()
}


func simdException(registers: UnsafeMutablePointer<exception_regs>) {
    print("SIMD Exception")
    dumpRegisters(&registers.memory)
    hlt()
}


func unhandledException(registers: UnsafeMutablePointer<exception_regs>) {
    let errorCode = registers.memory.error_code
    print("Unhandled Exception code: \(errorCode)")
    dumpRegisters(&registers.memory)
    hlt()
}
