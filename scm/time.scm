(load "scm/lib/lib.scm")

(set-tick-speed 150)

(define (tickfn)
  (midi-note-off 0 60)
  (midi-note-on 0 60 127)
)
