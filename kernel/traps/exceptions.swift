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


func divideByZeroException(registers: UnsafeMutablePointer<exception_regs>) {
    kprint("divideByZero\n")
    dump_registers(registers)
    stop()
}


func debugException(registers: UnsafeMutablePointer<exception_regs>) {
    kprint("debugException\n")
    dump_registers(registers)
    stop()
}


func nonMaskableInterrupt(registers: UnsafeMutablePointer<exception_regs>) {
    kprint("NMI\n")
    dump_registers(registers)
    stop()
}


func singleStepBreakpoint(registers: UnsafeMutablePointer<exception_regs>) {
    kprint("Breakpoint\n")
    dump_registers(registers)
}


func overflowException(registers: UnsafeMutablePointer<exception_regs>) {
    kprint("Overflow Exception\n")
    dump_registers(registers)
    stop()
}


func boundsException(registers: UnsafeMutablePointer<exception_regs>) {
    kprint("Bounds Exception\n")
    dump_registers(registers)
    stop()
}


func invalidOpcodeException(registers: UnsafeMutablePointer<exception_regs>) {
    kprint("Invalid Opcode Exception\n")
    dump_registers(registers)
    stop()
}


func doubleFault(registers: UnsafeMutablePointer<exception_regs>) {
    //let errorCode = registers.pointee.error_code
    kprint("Double Fault\n")
    dump_registers(registers)
    stop()
}


func invalidTSSException(registers: UnsafeMutablePointer<exception_regs>) {
    //let errorCode = registers.pointee.error_code
    kprint("Invalid Task State Segment\n");
    dump_registers(registers)
    stop()
}


func segmentNotPresentException(registers: UnsafeMutablePointer<exception_regs>) {
    //let errorCode = registers.pointee.error_code
    kprint("Segment Not Present Exception\n")
    dump_registers(registers)
    stop()
}


func stackFault(registers: UnsafeMutablePointer<exception_regs>) {
    //let errorCode = registers.pointee.error_code
    kprint("Stack Fault\n")
    dump_registers(registers)
    stop()
}


func generalProtectionFault(registers: UnsafeMutablePointer<exception_regs>) {
    let errorCode = UInt32(registers.pointee.error_code)
    kprint("GP Fault code: ")
    print_dword(errorCode)
    kprintf("\n")
    dump_registers(registers)
    stop()
}


func pageFault(registers: UnsafeMutablePointer<exception_regs>) {
    let errorCode = UInt32(registers.pointee.error_code)
    kprint("Page Fault: ")
    print_dword(errorCode)
    kprint("\n")
    dump_registers(registers)
    stop()
}


func fpuFault(registers: UnsafeMutablePointer<exception_regs>) {
    kprint("FPU Fault")
    dump_registers(registers)
    stop()
}


func alignmentCheckException(registers: UnsafeMutablePointer<exception_regs>) {
    //let errorCode = registers.pointee.error_code
    kprint("Alignment Check Exception\n")
    dump_registers(registers)
    stop()
}


func machineCheckException(registers: UnsafeMutablePointer<exception_regs>) {
    kprint("Machine Check Exception")
    dump_registers(registers)
    stop()
}


func simdException(registers: UnsafeMutablePointer<exception_regs>) {
    kprint("SIMD Exception")
    dump_registers(registers)
    stop()
}


func unhandledException(registers: UnsafeMutablePointer<exception_regs>) {
    //let errorCode = registers.pointee.error_code
    kprint("Unhandled Exception\n")
    dump_registers(registers)
    stop()
}


@noreturn func koops(format: StaticString, _ arguments: CVarArg...) {
    kprint("oops: ")
    withVaList(arguments) {
        kvlprintf(UnsafePointer<Int8>(format.utf8Start), format.utf8CodeUnitCount,
            $0)
    }
    kprint("\n")
    stop()
}
