; seq7 — 2-voice round sequencer
; run: cargo run -- examples/round.scm
; then press Space to start
;
; Two independent mono voices on channels 1 and 2.
; Voice 1 ascends, voice 2 descends — creates a simple canon.

(set-tick-speed 200)  ; 200ms per tick = 5 notes/sec

(define t 0)

(define voice1 (list 60 62 64 65 67 65 64 62))
(define voice2 (list 79 77 76 74 72 74 76 77))

(define i1 0)
(define i2 0)
(define note1 #f)
(define note2 #f)

(define (tickfn)
  (set! t (+ t 1))

  ; voice 1 — ascends, steps every 3 ticks
  (when (= (modulo t 3) 0)
    (when note1 (raw-midi-write (list #x80 note1 0)))
    (set! note1 (list-ref voice1 i1))
    (raw-midi-write (list #x90 note1 100))
    (set! i1 (modulo (+ i1 1) (length voice1))))

  ; voice 2 — descends, steps every 6 ticks
  (when (= (modulo t 6) 0)
    (when note2 (raw-midi-write (list #x81 note2 0)))
    (set! note2 (list-ref voice2 i2))
    (raw-midi-write (list #x91 note2 80))
    (set! i2 (modulo (+ i2 1) (length voice2)))))
