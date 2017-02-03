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


func divideByZeroException(registers: ExceptionRegisters) {
    kprint("divideByZero\n")
    dump_registers(registers)
    stop()
}


func debugException(registers: ExceptionRegisters) {
    kprint("debugException\n")
    dump_registers(registers)
    stop()
}


func nonMaskableInterrupt(registers: ExceptionRegisters) {
    kprint("NMI\n")
    dump_registers(registers)
    stop()
}


func singleStepBreakpoint(registers: ExceptionRegisters) {
    kprint("Breakpoint\n")
    dump_registers(registers)
}


func overflowException(registers: ExceptionRegisters) {
    kprint("Overflow Exception\n")
    dump_registers(registers)
    stop()
}


func boundsException(registers: ExceptionRegisters) {
    kprint("Bounds Exception\n")
    dump_registers(registers)
    stop()
}


func invalidOpcodeException(registers: ExceptionRegisters) {
    kprint("Invalid Opcode Exception\n")
    dump_registers(registers)
    stop()
}


func doubleFault(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Double Fault\n")
    dump_registers(registers)
    stop()
}


func invalidTSSException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Invalid Task State Segment\n");
    dump_registers(registers)
    stop()
}


func segmentNotPresentException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Segment Not Present Exception\n")
    dump_registers(registers)
    stop()
}


func stackFault(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Stack Fault\n")
    dump_registers(registers)
    stop()
}


func generalProtectionFault(registers: ExceptionRegisters) {
    let errorCode = UInt32(registers.pointee.error_code)
    kprint("GP Fault code: ")
    kprint_dword(errorCode)
    kprintf("\n")
    dump_registers(registers)
    stop()
}


func pageFault(registers: ExceptionRegisters) {
    let errorCode = UInt32(registers.pointee.error_code)
    kprint("Page Fault: ")
    kprint_dword(errorCode)
    kprint("\n")
    dump_registers(registers)
    stop()
}


func fpuFault(registers: ExceptionRegisters) {
    kprint("FPU Fault")
    dump_registers(registers)
    stop()
}


func alignmentCheckException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Alignment Check Exception\n")
    dump_registers(registers)
    stop()
}


func machineCheckException(registers: ExceptionRegisters) {
    kprint("Machine Check Exception")
    dump_registers(registers)
    stop()
}


func simdException(registers: ExceptionRegisters) {
    kprint("SIMD Exception")
    dump_registers(registers)
    stop()
}


func unhandledException(registers: ExceptionRegisters) {
    //let errorCode = registers.pointee.error_code
    kprint("Unhandled Exception\n")
    dump_registers(registers)
    stop()
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
