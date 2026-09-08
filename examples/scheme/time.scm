(load "lib/scheme/lib.scm")

(set-tick-speed 150)

(define (tick)
  (midi-note-off 0 60)
  (midi-note-on 0 60 127)
)
