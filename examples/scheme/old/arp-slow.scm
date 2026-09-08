; seq7 — slow arpeggiator with explicit tick speed
; run: cargo run -- examples/arp-slow.scm
; then press Space to start
;
; Sets tick speed to 250ms, so tick() is called once per beat.
; No modulo needed — every call is a step.

(set-tick-speed 250)

(define step 0)
(define current-note #f)
(define notes (list 60 64 67 72 65 69 71 60))

(define (tickfn)
  (when current-note
    (raw-midi-write (list #x80 current-note 0)))
  (set! current-note (list-ref notes step))
  (raw-midi-write (list #x90 current-note 100))
  (set! step (modulo (+ step 1) (length notes))))
