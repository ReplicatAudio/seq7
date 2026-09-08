(load "lib/scheme/lib.scm")

(set-tick-speed 150)

(define seq1 (string-split-space-line "
1 5 6 7 1 5 6 7
1 5 6 7 3 5 6 7
1 5 6 7 3 5 6 7
1 r 6 r 3 r 6 r
1 5 6 7 1 5 6 7
1 5 6 7 3 5 6 7
1 5 6 7 3 5 6 7
1 r 6 r 3 r 6 r
7 7 8 6 1 5 6 7
7 7 8 6 1 5 6 7
7 7 8 9 1 5 6 7
7 r 8 r 1 r 6 r
1 r 6 r 3 r 6 r
7 r 8 r 1 r 6 r
1 r 6 r 3 r 6 r
7 r 8 r 1 r 6 r
"))

(define seq2 (string-split-space-line "
1 r r r 1 r 6 r
1 r r r 3 r 6 r
1 r r r 3 r 6 r
1 r 6 r 3 r 6 r
"))

(define t 0)

(define (tickfn)
  (sequencer 0 seq1 48 0 1 127 t)
  (sequencer 1 seq2 36 0 1 127 t)
  (set! t (+ 1 t))
)
