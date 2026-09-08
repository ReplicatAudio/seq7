; seq7 — 8-note arpeggiator
; run: cargo run -- examples/arp.scm
; then press Space to start
; use /dbg at the REPL to toggle MIDI debug logging
(define tick-count 0)
(define current-note #f)
(define step 0)
(define notes (list 60 64 67 72 65 69 71 60))

(define (note-on note vel)
  (raw-midi-write (list #x90 note vel)))

(define (note-off note)
  (raw-midi-write (list #x80 note 0)))

(define (tick)
  (when (= (modulo tick-count 1000) 0)
  (display tick-count)
  (newline))
  (set! tick-count (+ tick-count 1))
  (when (= (modulo tick-count 250) 0)
    (when current-note
      (note-off current-note))
    (set! current-note (list-ref notes step))
    (note-on current-note 100)
    (set! step (modulo (+ step 1) (length notes)))))
