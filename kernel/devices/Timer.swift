//
// kernel/devices/Timer.swift
//
// Created by Simon Evans on 18/04/2021.
// Copyright © 2021 Simon Evans. All rights reserved.
//
// Timer setup and related routines.
//


// Generic Timer device
protocol Timer {
    var irq: IRQSetting { get }
    func enablePeriodicInterrupt(hz: Int)
}


// Setup a periodic timer using either a PIT or HPET. This is set to 1Khz and
// used to increment a counter that can be used for sleep etc.
func setupPeriodicTimer() -> Bool {
    // Find a timer
    let irq: IRQSetting
    // Set the timer interrupt for 1kHz
    if let timer = system.deviceManager.timer {
        timer.enablePeriodicInterrupt(hz: 1000)
        irq = timer.irq
        print(timer)
    } else {
        // Try and use the HPET to emultate the PIT
        if var hpet = system.deviceManager.acpiTables.entry(of: HPET.self) {
            guard hpet.emulateLegacyPIT(ticksPerSecond: 1000) else {
                print("timer: HPET doesnt support PIT mode")
                return false
            }
        } else {
            print("timer: Cant find an HPET")
            return false
        }
        // HPET is put in legacy mode so IRQ should be 0 although.
        irq = IRQSetting(isaIrq: 0)
    }
    system.deviceManager.interruptManager.setIrqHandler(irq, handler: timerInterrupt)
    print("timer: Setup for 1000Hz on irq:", irq)
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
