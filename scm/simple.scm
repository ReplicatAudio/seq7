;; Minimal tick-loop example — Scheme counterpart of lua/tick.lua.
(load "scm/lib/lib.scm")

(set-tick-speed 250)

(define t 0)

(define (tickfn)
  (midi-note-on 0 (modulo (+ t 21) 60) 127)
  (set! t (+ 1 t)))


