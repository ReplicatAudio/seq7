(load "lib/scheme/lib.scm")

(set-tick-speed 250)

(define t 0)

(define (tick)
    (debug (string-append "tick: " (number->string t)))
    (midi-note-on 0 (modulo (+ t 21) 60) 127)
    (set! t (+ 1 t))
)

