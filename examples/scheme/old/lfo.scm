; seq7 — triangle-wave LFO on CC 1 (mod wheel)
; run: cargo run -- examples/lfo.scm
; then press Space to start

(define tick-count 0)

(define (tickfn)
  (set! tick-count (+ tick-count 1))
  (let* ((pos (modulo tick-count 256))
         (val (if (< pos 128) pos (- 255 pos))))
    (raw-midi-write (list #xB4 1 val))))
