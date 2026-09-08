(load "lib/scheme/lib.scm")

;; From https://en.wikipedia.org/wiki/L-system
(define algae (list 
  (list "a") ; axiom always a list
  "a" (list "a" "b") ; r1
  "b" "a" ; r2
  "?" "?" ; r3 (empty)
  "?" "?" ; r4 (empty)
))
(define fractree (list 
  (list "0") ; axiom always a list
  "1" (list "1" "1") ; r1
  "0" (list "1" "a" "0" "b" "0") ; r2
  "?" "?" ; r3 (empty)
  "?" "?" ; r4 (empty)
))

(define lout (last (lsystem algae 4)))
(debug "LSYSTEM OUTPUT (FINAL GEN):")
(debug lout)

(set-tick-speed 150)
(define tt 0)
(define (tick)
  (define v (list-ref lout (modulo tt (length lout))))
  (debug v)
  (cond
    ((string=? v "a") (midi-note-on 0 60 127))
    ((string=? v "b") (midi-note-on 1 60 127))
    (else (midi-note-on 10 99 127)); noop
  )
  (set! tt (+ 1 tt))
)
