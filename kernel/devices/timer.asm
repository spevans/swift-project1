;;; kernel/traps/timer.asm
;;;
;;; Created by Simon Evans on 11/10/2020.
;;; Copyright © 2020 Simon Evans. All rights reserved.
;;;
;;; Timer interrupt and current tick count

        GLOBAL  timer_callback
        GLOBAL  current_ticks
        DEFAULT ABS

timer_callback:
        inc     qword [ticks]
        ret

current_ticks:
        mov     rax, [ticks]
        ret

sleep_in_milliseconds:
        add     rdi, [ticks]

.loop:
        hlt
        cmp     rdi, [ticks]
        jg      .loop
        ret


        SECTION .data

ticks   DQ      0
