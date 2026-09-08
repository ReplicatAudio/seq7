(load "lib/scheme/lib.scm")

(define rset1 (list 
  (list "a") ; axiom always a list
  "a" (list "a" "b") ; r1
  "b" (list "a" "b" "b" "a") ; r2
  "?" "?" ; r3 (empty)
  "?" "?" ; r4 (empty)
))

(define rset2 (list 
  (list "a") ; axiom always a list
  "a" (list "a" "b" "c") ; r1
  "b" "a" ; r2
  "c" (list "a" "a" "c") ; r3 (empty)
  "?" "?" ; r4 (empty)
))

(define mel (string-split-space-line "
5 5 5 5 4 4 4 4
1 1 1 1 1 1 1 1
7 7 7 8 4 4 4 4
1 1 1 1 1 1 1 1
2 2 2 2 2 2 2 2
1 3 1 6 1 5 1 7
1 1 1 1 1 1 1 1
1 4 1 5 1 7 1 8
"))

(define lout (last (lsystem rset1 4)))
(debug "LSYSTEM OUTPUT (FINAL GEN):")
(debug lout)

(define lout2 (last (lsystem rset2 4)))
(debug "LSYSTEM OUTPUT 2 (FINAL GEN):")
(debug lout2)

(define rootn 0)
(define moden 4)
(define (mod o n) (+ o (modal rootn moden n)))

(set-tick-speed 125)
(define tt 0)
(define (tick)
  ;; Send clock
  (when (= (modulo tt 8) 0)
    (midi-clock)
  )
  ;; Drums
  (define v (list-ref lout (modulo tt (length lout))))
  (debug v)
  (cond
    ((string=? v "a") (midi-note-on 1 60 127))
    ((string=? v "b") (midi-note-on 0 60 127))
  )
  ;; Bass
  (define v (list-ref lout2 (modulo tt (length lout2))))
  (debug v)
  (cond
    ((string=? v "a") (midi-note-on 2 (mod 60 1) 127))
    ((string=? v "b") (midi-note-on 2 (mod 60 4) 127))
    ((string=? v "c") (midi-note-on 2 (mod 60 5) 127))
  )
  ;; Harmony
  (define v (list-ref lout2 (modulo (floor (/ tt 2)) (length lout2))))
  (debug v)
  (cond
    ((string=? v "a") (midi-note-on 3 (mod 36 1) 127))
    ((string=? v "b") (midi-note-on 3 (mod 36 4) 127))
    ((string=? v "c") (midi-note-on 3 (mod 36 5) 127))
  )
  ;; Melody
  (sequencer 4 mel 48 rootn moden 127 tt)
  ;; Modulate notes
  ; (define v (list-ref lout2 (modulo (floor (/ tt 16)) (length lout2))))
  ; (debug v)
  ; (cond
  ;   ((string=? v "b") (set! moden (modulo (+ moden 2) 7)))
  ;   ((string=? v "c") (set! moden (modulo (+ moden 3) 7)))
  ;   ;; ignore a, no change, stay
  ; )
  ; (debug (string-append "mode:" (number->string moden)))
  (when (= (modulo tt 16) 0) 
    (define v (list-ref lout2 (modulo (floor (/ tt 16)) (length lout2))))
    (debug v)
    (cond
      ((string=? v "b") (set! moden (modulo (+ moden 2) 7)))
      ((string=? v "c") (set! moden (modulo (+ moden 3) 7)))
      ;; ignore a, no change, stay
    )
    (debug (string-append "mode:" (number->string moden)))
  )
  ;;
  (set! tt (+ 1 tt))
)
