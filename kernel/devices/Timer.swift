/*
 * kernel/devices/Timer.swift
 *
 * Created by Simon Evans on 18/04/2021.
 * Copyright © 2021 Simon Evans. All rights reserved.
 *
 * Timer setup and related routines.
 *
 */


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


private(set) var timerCore = TimerCore()

struct TimerCore: ~Copyable {
    private var timers: [Timer] = []

    init() {}

    private func initialise() {
        // Setup periodic timers so that sleep() etc can be used while initialising
        // other devices. Needed before ACPI DSDT/SSDT AML can be parsed as that can
        // use sleep().
        // Look for an HPET or PIT
        if HPET.init() != nil {
            #kprint("Found an HPET")
        } else if PIT8254.init() != nil {
            #kprint("Found a PIT")
        }

        guard TimerCore.setupPeriodicTimer() else {
            koops("Cannot find a HPET or PIT to use for periodic clock")
        }
    }

    static func initialise() {
        timerCore.initialise()
    }

    static func addTimer(_ timer: Timer) {
        timerCore.timers.append(timer)
    }

    static func timer(matching: (Timer) -> Bool) -> Timer? {
        for timer in timerCore.timers {
            if matching(timer) {
                return timer
            }
        }
        return nil
    }

    static func walkTimers( _ body: (Timer) -> Bool) {
        for timer in timerCore.timers {
            guard body(timer) else { return }
        }
    }


    // Setup a periodic timer using either a PIT or HPET. This is set to 1Khz and
    // used to increment a counter that can be used for sleep etc.
    static func setupPeriodicTimer() -> Bool {
        // Find a timer and set the timer interrupt for 1kHz
        if APIC.setupTimer() {
            #kprint("time: Using APIC for periodic timer")
            return true
        }
        guard let timer = timerCore.timers.first, timer.enablePeriodicInterrupt(hz: Int(TICKS_PER_SECOND))  else {
            #kprint("time: Failed to setup periodic timer")
            return false
        }
        #kprint(timer)
        InterruptManager.setIrqHandler(timer.interruptHandler, forInterrupt: timer.interrupt)
        #kprintf("timer: Setup for 1000Hz on irq: %d\n", timer.interrupt.irq)
        return true
    }
}

let TICKS_PER_SECOND: UInt64 = 100
private var _currentTicks: UInt64 = 0
func currentTicks() -> UInt64 {
    return _currentTicks
}

func timerInterrupt() -> Bool {
    atomic_uinc(&_currentTicks)
    rearmAPICTimer()
    return true
}


func sleep(milliseconds: Int) {
    let now = _currentTicks
    let ticks = UInt64(milliseconds) * TICKS_PER_SECOND / 1000
    if ticks < 2 {
        ACPI.wait(milliSeconds: UInt32(milliseconds))
    } else {
        let required = now + ticks
        while _currentTicks < required {
            hlt()
        }
    }
}
