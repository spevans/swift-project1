//
// kernel/devices/Timer.swift
//
// Created by Simon Evans on 18/04/2021.
// Copyright © 2021 Simon Evans. All rights reserved.
//
// Timer setup and related routines.
//


// Generic Timer device
class Timer: CustomStringConvertible {
    var description: String { return "Generic Timer on IRQ: \(interrupt.irq)" }
    let interrupt: IRQSetting
    let interruptHandler: InterruptHandler

    init(interrupt: IRQSetting) {
        self.interrupt = interrupt
        interruptHandler = InterruptHandler(name: "timer",
                                            handler: timerInterrupt)
    }

    func enablePeriodicInterrupt(hz: Int) -> Bool {
        return false
    }
}


// Setup a periodic timer using either a PIT or HPET. This is set to 1Khz and
// used to increment a counter that can be used for sleep etc.
func setupPeriodicTimer() -> Bool {
    // Find a timer and set the timer interrupt for 1kHz
    guard let timer = system.deviceManager.timer, timer.enablePeriodicInterrupt(hz: 1000)  else {
        #kprint("Cant setup periodic timer")
        return false
    }
    #kprint(timer)
    system.deviceManager.setIrqHandler(timer.interruptHandler, forInterrupt: timer.interrupt)
    #kprintf("timer: Setup for 1000Hz on irq: %d\n", timer.interrupt.irq)
    return true
}


private func timerInterrupt() -> Bool {
    timer_callback()
    return true
}


func sleep(milliseconds: Int) {
    let current = current_ticks()
    let required = current + UInt64(milliseconds)
    while required > current_ticks() {
        hlt()
    }
}
