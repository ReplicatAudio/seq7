; seq7 — random pentatonic melody
; run: cargo run -- examples/random.scm

(require-builtin steel/random)

(define tick-count 0)
(define current-note #f)
(define pentatonic (list 60 62 64 67 69 72 74 76 79 81))

(define (tick)
  (set! tick-count (+ tick-count 1))
  (when (= (modulo tick-count 200) 0)
    (when current-note
      (raw-midi-write (list #x82 current-note 0)))
    (set! current-note (list-ref pentatonic (rng->gen-range 0 10)))
    (raw-midi-write (list #x92 current-note (+ 60 (rng->gen-range 0 40))))))
