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

public typealias ExceptionRegisters = UnsafeMutablePointer<exception_regs>


private func stackTrace(_ registers: ExceptionRegisters) {
    let rsp = UInt(registers.pointee.rsp)
    let rbp = UInt(registers.pointee.rbp)
    stack_trace(rsp, rbp)
}

private func dumpRegisters(_ registers: ExceptionRegisters) {
    #kprintf("RAX: %16.16lx ", registers.pointee.rax)
    #kprintf("RBX: %16.16lx ", registers.pointee.rbx)
    #kprintf("RCX: %16.16lx\n", registers.pointee.rcx)
    #kprintf("RDX: %16.16lx ", registers.pointee.rdx)
    #kprintf("RSI: %16.16lx ", registers.pointee.rsi)
    #kprintf("RDI: %16.16lx\n", registers.pointee.rdi)
    #kprintf("RBP: %16.16lx ", registers.pointee.rbp)
    #kprintf("RSP: %16.16lx ", registers.pointee.rsp)
    #kprintf("RIP: %16.16lx\n", registers.pointee.rip)
    #kprintf("R8 : %16.16lx ", registers.pointee.r8)
    #kprintf("R9 : %16.16lx ", registers.pointee.r9)
    #kprintf("R10: %16.16lx\n", registers.pointee.r10)
    #kprintf("R11: %16.16lx ", registers.pointee.r11)
    #kprintf("R12: %16.16lx ", registers.pointee.r12)
    #kprintf("R13: %16.16lx\n", registers.pointee.r13)
    #kprintf("R14: %16.16lx ", registers.pointee.r14)
    #kprintf("R15: %16.16lx ", registers.pointee.r15)
    #kprintf("CR2: %16.16lx\n", getCR2());
    #kprintf("CS: %lx DS: %lx ES: %lx FS: %lx GS:%lx SS: %lx\n",
             registers.pointee.cs, registers.pointee.ds, registers.pointee.es,
             registers.pointee.fs, registers.pointee.gs, registers.pointee.ss)
}

func divideByZeroException(registers: ExceptionRegisters) {
    #kprint("divideByZero\n")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func debugException(registers: ExceptionRegisters) {
    #kprint("debugException\n")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func nonMaskableInterrupt(registers: ExceptionRegisters) {
    #kprint("NMI\n")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func singleStepBreakpoint(registers: ExceptionRegisters) {
    #kprint("Breakpoint\n")
    dumpRegisters(registers)
    stackTrace(registers)
}


func overflowException(registers: ExceptionRegisters) {
    #kprint("Overflow Exception\n")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func boundsException(registers: ExceptionRegisters) {
    #kprint("Bounds Exception\n")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func invalidOpcodeException(registers: ExceptionRegisters) {
    #kprint("Invalid Opcode Exception\n")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func doubleFault(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    #kprint("Double Fault\n")
    dumpRegisters(registers);
    let rsp = UInt(registers.pointee.rsp)
    let rbp = UInt(registers.pointee.rbp)
    let _stack_start_addr = VirtualAddress(bitPattern: &_stack_start)

    if rsp <= _stack_start_addr || rbp <= _stack_start_addr {
        #kprintf("Possible kernel stack overflow RSP: %016x RBP: %016x stack lowest address: %016x\n",
            registers.pointee.rsp, registers.pointee.rbp, UInt64(_stack_start_addr))
    } else {
        stackTrace(registers)
    }
    abort()
}


func invalidTSSException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    #kprint("Invalid Task State Segment\n");
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func segmentNotPresentException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    #kprint("Segment Not Present Exception\n")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func stackFault(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    #kprint("Stack Fault\n")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func generalProtectionFault(registers: ExceptionRegisters) {
    let errorCode = UInt32(registers.pointee.error_code)
    #kprintf("GP Fault code: %#x\n", errorCode)
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func pageFault(registers: ExceptionRegisters) {
    let errorCode = UInt32(registers.pointee.error_code)
    #kprintf("Page Fault: %#x\n", errorCode)
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func fpuFault(registers: ExceptionRegisters) {
    #kprint("FPU Fault")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func alignmentCheckException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    #kprint("Alignment Check Exception")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func machineCheckException(registers: ExceptionRegisters) {
    #kprint("Machine Check Exception")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func simdException(registers: ExceptionRegisters) {
    #kprint("SIMD Exception")
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}


func unhandledException(registers: ExceptionRegisters) {
    let errorCode = registers.pointee.error_code
    #kprintf("Unhandled Exception: %x\n", errorCode)
    dumpRegisters(registers)
    stackTrace(registers)
    abort()
}

func koops(_ string: StaticString) -> Never {
    #kprint(string)
    stop()
}
