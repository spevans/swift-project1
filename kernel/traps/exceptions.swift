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


func divideByZeroException(registers: ExceptionRegisters) {
    kprint("divideByZero\n")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func debugException(registers: ExceptionRegisters) {
    kprint("debugException\n")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func nonMaskableInterrupt(registers: ExceptionRegisters) {
    kprint("NMI\n")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func singleStepBreakpoint(registers: ExceptionRegisters) {
    kprint("Breakpoint\n")
    dump_registers(registers)
    stackTrace(registers)
}


func overflowException(registers: ExceptionRegisters) {
    kprint("Overflow Exception\n")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func boundsException(registers: ExceptionRegisters) {
    kprint("Bounds Exception\n")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func invalidOpcodeException(registers: ExceptionRegisters) {
    kprint("Invalid Opcode Exception\n")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func doubleFault(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Double Fault\n")
    dump_registers(registers);
    let rsp = UInt(registers.pointee.rsp)
    let rbp = UInt(registers.pointee.rbp)
    if rsp <= _stack_start_addr || rbp <= _stack_start_addr {
        printf("Possible kernel stack overflow RSP: %016x RBP: %016x stack lowest address: %016x\n",
            registers.pointee.rsp, registers.pointee.rbp, UInt64(_stack_start_addr))
    } else {
        stackTrace(registers)
    }
    abort()
}


func invalidTSSException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Invalid Task State Segment\n");
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func segmentNotPresentException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Segment Not Present Exception\n")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func stackFault(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Stack Fault\n")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func generalProtectionFault(registers: ExceptionRegisters) {
    let errorCode = UInt32(registers.pointee.error_code)
    printf("GP Fault code: %#x\n", errorCode)
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func pageFault(registers: ExceptionRegisters) {
    let errorCode = UInt32(registers.pointee.error_code)
    printf("Page Fault: %#x\n", errorCode)
    dump_registers(registers)
    stackTrace(registers)
    kprint("\nSTOP\n")
    abort()
}


func fpuFault(registers: ExceptionRegisters) {
    kprint("FPU Fault")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func alignmentCheckException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Alignment Check Exception\n")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func machineCheckException(registers: ExceptionRegisters) {
    kprint("Machine Check Exception")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func simdException(registers: ExceptionRegisters) {
    kprint("SIMD Exception")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func unhandledException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Unhandled Exception\n")
    dump_registers(registers)
    stackTrace(registers)
    abort()
}


func koops(_ format: StaticString, _ arguments: CVarArg...) -> Never {
    kprint("oops: ")
    _ = withVaList(arguments) {
        let args = $0
         _ = format.utf8Start.withMemoryRebound(to: CChar.self,
            capacity: format.utf8CodeUnitCount) {
            kvlprintf($0, format.utf8CodeUnitCount, args)
        }
    }
    kprint("\n")
    stop()
}
