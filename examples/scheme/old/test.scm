(load "lib/scheme/lib.scm")

(set-tick-speed 250)

(define t 0)
(define n 40)

(define (tickfn)
    (set! t (+ 1 t))
    (set! n (+ 1 n))
    (n-on 1 n 127)
    (dbg (string-append "tick: " (number->string t)))
    (dbg (string-append "note: " (number->string n)))
)
