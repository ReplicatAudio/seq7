(require-builtin steel/random)

(set-tick-speed 250)

; use /dbg at the REPL to toggle MIDI debug logging

(define t 0)
(define step 0)

(define note 0)

(define npool-len 16)
(define npool (list 48 50 52 55 57 60 62 64 67 69 72 74 76 79 81 84))
(define A '())
(define B '())
(define T '())
(define phrase 0)
(define section 0)

;; Get a random note from the pool
(define (rnote)
  (list-ref npool (rng->gen-range 0 npool-len)))

(define (gen)
  (list (rnote) (rnote) (rnote) (rnote))
)

(set! A (gen))
(set! B (gen))
(set! T A)

(define (tickfn)
  (set! t (+ t 1))

  (raw-midi-write (list #x80 note 80))
  (set! note (list-ref T step))
  (raw-midi-write (list #x90 note 80))

  (display step)(newline)

  (set! step (+ step 1))
  (when (= step (length T))
    (display "done")(newline)
    (set! step 0))
    
)

; AB 
; B->new
; AB
; A->new
