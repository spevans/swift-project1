/*
 * kernel/tasks/tasks.swift
 *
 * Created by Simon Evans on 30/04/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Simple initial task switching
 * Task switching is done in entry.asm:_irq_handler for now.
 * yield() just round robins to the next task
 * Currently NO locking, atomics or any safety, just the
 *
 */


// FIXME: The stack allocated for a task should be in a defined region away from the heap
// There should also be a better guard page setup to capture stack overflow and underflow
private let stackPages = 3
private let stackSize = stackPages * Int(PAGE_SIZE)
private var tasks: [Task] = []
private var currentTask = 0
private var nextTask = 0
private var nextPID: UInt = 1


// FIXME, tasks currently must not exit
@discardableResult
func addTask(name: String, task: @escaping @convention(c)() -> ()) -> UInt {
    let newTask = Task(name: name, entry: task)
    print("Adding task:", newTask)
    tasks.append(newTask)
    return newTask.pid
}


func noInterrupt<Result>(_ task: () -> Result) -> Result {
    let flags = local_irq_save()
    let result: Result = task()
    load_eflags(flags)
    return result
}


// Takes the stack pointer of the current task to save
// Returns the stack pointer of the task to switch to
@_silgen_name("getNextTask")
public func getNextTask(rsp: UnsafeMutablePointer<UInt>) -> UInt {
    tasks[currentTask].rsp = rsp
    currentTask = nextTask

    return tasks[nextTask].rsp.address
}


// Returns the stack pointer of the first task
@_silgen_name("getFirstTask")
public func getFirstTask() -> UInt {
    return tasks[currentTask].rsp.address
}


// Currently decides the next task to run but doesnt switch to it
@_silgen_name("sched_yield")
@discardableResult  // return value is only to satisfy the C definition
public func yield() -> Int {
    if tasks.count > 0 {
        nextTask = (currentTask + 1) % tasks.count
    }
    return 0
}


final class Task: CustomStringConvertible {
    let name: String
    let stackPage: PhysPageRange
    var state: UnsafeMutablePointer<exception_regs>
    let pid: UInt
    var rsp: UnsafeMutablePointer<UInt>

    var description: String {
        let stack = stackPage.rawPointer

        var r = "\(name)\nStack: \(stack) state: \(state)\n"
 /*       r += String.sprintf("RAX: %16.16lx ", state.pointee.rax)
        r += String.sprintf("RBX: %16.16lx ", state.pointee.rbx)
        r += String.sprintf("RCX: %16.16lx\n", state.pointee.rcx)
        r += String.sprintf("RDX: %16.16lx ", state.pointee.rdx)
        r += String.sprintf("RSI: %16.16lx ", state.pointee.rsi)
        r += String.sprintf("RDI: %16.16lx\n", state.pointee.rdi)*/
        r += String.sprintf("RBP: %16.16lx ", state.pointee.rbp)
        r += String.sprintf("RSP: %16.16lx ", state.pointee.rsp)
        r += String.sprintf("RIP: %16.16lx\n", state.pointee.rip)
/*        r += String.sprintf("R8 : %16.16lx ", state.pointee.r8)
        r += String.sprintf("R9 : %16.16lx ", state.pointee.r9)
        r += String.sprintf("R10: %16.16lx\n", state.pointee.r10)
        r += String.sprintf("R11: %16.16lx ", state.pointee.r11)
        r += String.sprintf("R12: %16.16lx ", state.pointee.r12)
        r += String.sprintf("R13: %16.16lx\n", state.pointee.r13)
        r += String.sprintf("R14: %16.16lx ", state.pointee.r14)
        r += String.sprintf("R15: %16.16lx ", state.pointee.r15)
        r += String.sprintf("CR2: %16.16lx\n", getCR2())*/
        r += String.sprintf("CS: %lx DS: %lx ES: %lx FS: %lx GS:%lx SS: %lx\n",
            state.pointee.cs, state.pointee.ds, state.pointee.es,
            state.pointee.fs, state.pointee.gs, state.pointee.ss)
        return r
    }

    init(name: String, entry: @escaping @convention(c)() -> ()) {
        self.name = name
        pid = nextPID
        nextPID += 1
        let addr = unsafeBitCast(entry, to: UInt64.self)
        stackPage = alloc(pages: stackPages)
        let stack = stackPage.rawPointer
        let stateOffset = stackSize - MemoryLayout<exception_regs>.size
        rsp = stack.advanced(by: stateOffset - MemoryLayout<UInt>.size).bindMemory(to: UInt.self, capacity: 1)
        state = stack.advanced(by: stateOffset).bindMemory(to: exception_regs.self, capacity: 1)
        state.initialize(to: exception_regs())
        state.pointee.es = UInt64(DATA_SELECTOR)
        state.pointee.ds = UInt64(DATA_SELECTOR)
        state.pointee.ss = UInt64(DATA_SELECTOR)
        state.pointee.rax = 0xaaaaaaaaaaaaaaaa
        state.pointee.rbx = 0xbbbbbbbbbbbbbbbb
        state.pointee.rcx = 0xcccccccccccccccc
        state.pointee.rdx = 0xdddddddddddddddd
        state.pointee.fs = 0
        state.pointee.rip = UInt64(addr)
        state.pointee.cs = UInt64(CODE_SELECTOR)
        state.pointee.eflags = 512 + 2  // Default flags has interrupts enabled

        // Alignment hack. See ALIGN_STACK / UNALIGN_STACK in entry.asm
        let topOfStack = stack.advanced(by: stackSize)
        state.pointee.rsp = UInt64(topOfStack.address)
        rsp.pointee = state.address
        rsp -= 1
    }
}
