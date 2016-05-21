/*
 * kernel/tasks/tasks.swift
 *
 * Created by Simon Evans on 30/04/2016.
 * Copyright © 2016 Simon Evans. All rights reserved.
 *
 * Simple initial task switching with 2 tasks that print to the screen
 * Task switching is done in entry.asm:_irq_handler for now.
 * yield() just round robins to the next task
 * Currently NO locking, atomics or any safety, just the
 */


private let stackPages = 2
private let stackSize = stackPages * Int(PAGE_SIZE)
private var tasks: [Task] = []
private var currentTask = 0
private var nextTask = 0
private var nextPID: UInt = 1


func runTasks() {
    addTask(task: testTaskA)
    addTask(task: testTaskB)
}


@discardableResult
func addTask(task: @convention(c)() -> ()) -> UInt {
    let newTask = Task(entry: task)
    print("Task:", newTask)
    printf("Adding task @ %p\n", newTask.state.pointee.rip)
    tasks.append(newTask)
    return newTask.pid
}


func noInterrupt(_ task: @noescape () -> ()) {
    let flags = local_irq_save()
    task()
    load_eflags(flags)
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


private func testTaskA() {
    let ch = Character("A")
    while true {
        for _ in 1...5 {
            TTY.sharedInstance.printChar(ch)
        }
        yield()
    }
}


private func testTaskB() {
    let ch = Character("B")
    while true {
        for _ in 1...5 {
            TTY.sharedInstance.printChar(ch)
        }
        yield()
    }
}


class Task: CustomStringConvertible {
    let stack: UnsafeMutablePointer<Void>!
    var state: UnsafeMutablePointer<exception_regs>
    let pid: UInt
    var rsp: UnsafeMutablePointer<UInt>

    var description: String {
        var r = "Stack: \(stack) state: \(state)\n"
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


    init(entry: @convention(c)() -> ()) {
        pid = nextPID
        nextPID += 1
        let addr = unsafeBitCast(entry, to: UInt.self)
        stack = alloc_pages(stackPages)
        let stateOffset = stackSize - sizeof(exception_regs)
        rsp = stack.advancedBy(bytes: stateOffset - sizeof(UInt))
        state = stack.advancedBy(bytes: stateOffset)
        state.initialize(with: exception_regs())
        state.pointee.es = 0x10
        state.pointee.ds = 0x10
        state.pointee.ss = 0x10
        state.pointee.rax = 0xaaaaaaaaaaaaaaaa
        state.pointee.rbx = 0xbbbbbbbbbbbbbbbb
        state.pointee.rcx = 0xcccccccccccccccc
        state.pointee.rdx = 0xdddddddddddddddd
        state.pointee.fs = 0x18
        state.pointee.rip = UInt64(addr)
        state.pointee.cs = UInt64(CODE_SEG)
        state.pointee.eflags = 512 + 2  // Default flags has interrupts enabled

        // Alignment hack. See ALIGN_STACK / UNALIGN_STACK in entry.asm
        let topOfStack: UnsafeMutablePointer<Void> = stack.advancedBy(bytes: stackSize)
        state.pointee.rsp = UInt64(topOfStack.address)
        rsp.pointee = state.address
        rsp -= 1
    }
}
