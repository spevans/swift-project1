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

import Klib


func dumpRegisters(inout registers: exception_regs) {
    String.printf("RAX: %16.16lx ", registers.rax)
    String.printf("RBX: %16.16lx ", registers.rbx)
    String.printf("RCX: %16.16lx\n", registers.rcx)
    String.printf("RDX: %16.16lx ", registers.rdx)
    String.printf("RSI: %16.16lx ", registers.rsi)
    String.printf("RDI: %16.16lx\n", registers.rdi)
    String.printf("RBP: %16.16lx ", registers.rbp)
    String.printf("RSP: %16.16lx ", registers.rsp)
    String.printf("RIP: %16.16lx\n", registers.rip)
    String.printf("R8 : %16.16lx ", registers.r8)
    String.printf("R9 : %16.16lx ", registers.r9)
    String.printf("R10: %16.16lx\n", registers.r10)
    String.printf("R11: %16.16lx ", registers.r11)
    String.printf("R12: %16.16lx ", registers.r12)
    String.printf("R13: %16.16lx\n", registers.r13)
    String.printf("R14: %16.16lx ", registers.r14)
    String.printf("R15: %16.16lx ", registers.r15)
    String.printf("CR2: %16.16lx\n", getCR2())
    String.printf("CS: %x DS: %x ES: %x FS: %x GS:%x SS: %x\n",
        registers.cs, registers.ds, registers.es,
        registers.fs, registers.gs, registers.ss)

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
