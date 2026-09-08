(load "lib/scheme/lib.scm")

;; From https://en.wikipedia.org/wiki/L-system
(define rset (list 
  (list "a") ; axiom always a list
  "a" (list "a" "b") ; r1
  "b" "a" ; r2
  "?" "?" ; r3 (empty)
  "?" "?" ; r4 (empty)
))

(define mela (string-split-space-line "
5 5 5 5 4 4 4 4
1 1 1 1 1 1 1 1
5 5 5 5 4 4 4 4
2 2 2 2 2 2 2 2
"))

(define melb (string-split-space-line "
7 1 5 7 1 4 3 4
1 1 1 1 1 1 1 1
"))

(define lout (last (lsystem rset 16)))
(debug "LSYSTEM OUTPUT (FINAL GEN):")
(debug lout)

(define mode 1)

(set-tick-speed 150)
(define tt 0)
(define (tick)
  (if (= tt 0) (midi-start))
  (when (= (modulo tt 8) 0)
    (midi-clock)
  )
  (define v (list-ref lout (modulo tt (length lout))))
  (debug "v1")
  (debug v)
  (cond
    ((string=? v "a") (midi-note-on 0 60 127))
    ((string=? v "b") (midi-note-on 1 60 127))
  )
  ; ;;
  (define tt2 (floor (/ tt 32)))
  (define tt3 (floor (/ tt 2)))
  (define v (list-ref lout (modulo tt2 (length lout))))
  (debug "v2")
  (debug v)
  (cond
    ((string=? v "a") (sequencer 2 mela 48 0 mode 127 tt2))
    ((string=? v "b") (sequencer 2 melb 48 0 mode 127 tt2))
    )
  ;;
  (define tt4 (floor (/ tt 48)))
  (define v (list-ref lout (modulo tt3 (length lout))))
  (debug "v2")
  (debug v)
  (cond
    ((string=? v "a") (sequencer 3 mela 48 0 mode 127 tt4))
    ((string=? v "b") (sequencer 3 melb 48 0 mode 127 tt4))
    )
  ;;
  (set! tt (+ 1 tt))
)
