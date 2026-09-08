; seq7 — moving ABAB pattern generator
; run: cargo run -- examples/random2.scm
;
; Generates 4 notes (A), plays them 2×.
; Generates 4 notes (B), plays them 2×.
; Plays A 2 more times.
; B becomes A, new B generated. Repeat.



(require-builtin steel/random)

(set-tick-speed 50)

(define t 0)
(define step 0)
(define play-count 0)
(define note #f)
(define A '())
(define B '())
(define phrase '())
(define state 'gen-A)

(define pent (list 48 50 52 55 57 60 62 64 67 69 72 74 76 79 81 84))

(define (gen)
  (list (list-ref pent (rng->gen-range 0 16))
        (list-ref pent (rng->gen-range 0 16))
        (list-ref pent (rng->gen-range 0 16))
        (list-ref pent (rng->gen-range 0 16))
        (list-ref pent (rng->gen-range 0 16))
        (list-ref pent (rng->gen-range 0 16))
        (list-ref pent (rng->gen-range 0 16))
        (list-ref pent (rng->gen-range 0 16))))

(define (advance)
  (when note (raw-midi-write (list #x80 note 0)))
  (set! note (list-ref phrase step))
  (raw-midi-write (list #x90 note 80))
  (set! step (+ step 1))
  (when (= step 8)
    (set! step 0)
    (set! play-count (+ play-count 1))))

(define (tickfn)
  (set! t (+ t 1))
  (when (= (modulo t 3) 0)
    (cond
      ((eq? state 'gen-A)
       (set! A (gen)) (set! phrase A)
       (set! state 'play-A) (set! play-count 0) (set! step 0) (advance))

      ((eq? state 'play-A)
       (display "A")(newline)
       (advance)
       (when (and (= play-count 2) (= step 0))
         (set! state 'gen-B)))

      ((eq? state 'gen-B)
       (set! B (gen)) (set! phrase B)
       (set! state 'play-B) (set! play-count 0) (set! step 0) (advance))

      ((eq? state 'play-B)
       (display "B")(newline)
       (advance)
       (when (and (= play-count 2) (= step 0))
         (set! state 'play-A2) (set! play-count 0) (set! step 0)))

      ((eq? state 'play-A2)
       (display "A2")(newline)
       (advance)
       (when (and (= play-count 2) (= step 0))
         (set! A B)
          (set! state 'gen-B))))))
