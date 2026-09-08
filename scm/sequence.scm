(load "scm/lib/lib.scm")

(set-tick-speed 300)

(define seqa1 (string-split-space-line "
1 2 4 1 2 4 5 6
"))

(define seqb1 (string-split-space-line "
1 r r r r r r r
4 r r r 6 r r r
"))

(define seqc1 (string-split-space-line "
1 r r r r r r r
4 r r r r r r r
"))

(define seqc2 (string-split-space-line "
7 2 5 3 5 2 4 6
7 2 5 3 5 2 4 6
5 2 5 3 5 2 4 6
5 2 5 3 5 2 4 6
"))

(define seqd1 (string-split-space-line "
1
"))

(define seqd2 (string-split-space-line "
2 2 2 2 1 1 1 1
"))

(define seqd3 (string-split-space-line "
6 3 5 3 1 1 1 2
"))

(define seqe1 (string-split-space-line "
1 r r r r r r r
r r 1 r r r r r
1 r r r r r r r
r r 1 r r r 1 r
"))

(define seqf1 (string-split-space-line "
r r r r 1 r r r
"))

(define seqg1 (string-split-space-line "
1 r
"))

(define seqg2 (string-split-space-line "
1
"))

(define seqh1 (string-split-space-line "
r r r r r r 1 r
r r r r r r r r
r r r r r r r r
r r r r r r 1 1
"))

(define llen 32)

(define t 0)
(define tt 0)
(define mode 2)

(define (tickfn)
  (if (= t 0) (midi-start))
  (when (= (modulo t 8) 0)
    (midi-clock)
  )
  (when (= (modulo t llen) 0) 
    (set! tt (+ 1 tt))
    (set! mode (modulo (+ 1 mode) 7))
  )
  (when (= tt 10)
    (set! tt 1)
    (set! mode (modulo (+ 4 mode) 7))
  )
  (when (= tt 1)
    (sequencer 0 seqa1 48 0 mode 127 t)
  )
  (when (= tt 2)
    (sequencer 0 seqa1 48 0 mode 127 t)
    (sequencer 1 seqb1 36 0 mode 127 t)
    (sequencer 2 seqc1 60 0 mode 127 t)
    (sequencer 3 seqd1 72 0 mode 127 t)
    (sequencer 4 seqe1 0 0 mode 127 t)
  )
  (when (= tt 3)
    (sequencer 0 seqa1 48 0 mode 127 t)
    (sequencer 1 seqb1 36 0 mode 127 t)
    (sequencer 4 seqe1 0 0 mode 127 t)
    (sequencer 5 seqf1 0 0 mode 127 t)
    (sequencer 6 seqg1 0 0 mode 127 t)
    (sequencer 7 seqh1 0 0 mode 127 t)
  )
  (when (= tt 4)
    (sequencer 0 seqa1 48 0 mode 127 t)
    (sequencer 1 seqb1 36 0 mode 127 t)
    (sequencer 2 seqc2 60 0 mode 127 t)
    (sequencer 3 seqd1 72 0 mode 127 t)
    (sequencer 4 seqe1 0 0 mode 127 t)
    (sequencer 5 seqf1 0 0 mode 127 t)
    (sequencer 6 seqg2 0 0 mode 127 t)
    (sequencer 7 seqh1 0 0 mode 127 t)
  )
  (when (= tt 5)
    (sequencer 1 seqb1 36 0 mode 127 t)
    (sequencer 2 seqc1 60 0 mode 127 t)
    (sequencer 3 seqd2 72 0 mode 127 t)
    (sequencer 4 seqe1 0 0 mode 127 t)
    (sequencer 6 seqg2 0 0 mode 127 t)
    (sequencer 7 seqh1 0 0 mode 127 t)
  )
  (when (= tt 6)
    (sequencer 0 seqa1 48 0 mode 127 t)
    (sequencer 1 seqb1 36 0 mode 127 t)
    (sequencer 2 seqc2 60 0 mode 127 t)
    (sequencer 3 seqd3 72 0 mode 127 t)
    (sequencer 4 seqe1 0 0 mode 127 t)
    (sequencer 5 seqf1 0 0 mode 127 t)
    (sequencer 6 seqg1 0 0 mode 127 t)
    (sequencer 7 seqh1 0 0 mode 127 t)
  )
  (when (= tt 7)
    (sequencer 0 seqa1 48 0 mode 127 t)
    (sequencer 1 seqb1 36 0 mode 127 t)
    (sequencer 2 seqc1 60 0 mode 127 t)
    (sequencer 3 seqd1 72 0 mode 127 t)
    (sequencer 4 seqe1 0 0 mode 127 t)
    (sequencer 5 seqf1 0 0 mode 127 t)
    (sequencer 6 seqg1 0 0 mode 127 t)
    (sequencer 7 seqh1 0 0 mode 127 t)
  )
  (when (= tt 8)
    (sequencer 0 seqa1 48 0 mode 127 t)
    (sequencer 1 seqb1 36 0 mode 127 t)
    (sequencer 2 seqc2 60 0 mode 127 t)
    (sequencer 3 seqd1 72 0 mode 127 t)
    (sequencer 5 seqf1 0 0 mode 127 t)
    (sequencer 6 seqg2 0 0 mode 127 t)
    (sequencer 7 seqh1 0 0 mode 127 t)
  )
  (when (= tt 9)
    (sequencer 1 seqb1 36 0 mode 127 t)
    (sequencer 3 seqd1 72 0 mode 127 t)
    (sequencer 6 seqg1 0 0 mode 127 t)
    (sequencer 7 seqh1 0 0 mode 127 t)
  )
  (set! t (+ 1 t))
)
