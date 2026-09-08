(load "lib/scheme/lib.scm")

(set-tick-speed 250)

(define t 0)
(define n 40)

(define bass1 (list 0 3 3 5 7 1 1 1 3 4 4 5 6 1 1))
(define bass2 (list 0 0 0 5 6 1 1 2 4 5 5 7 8 1 2))
(define bass bass1)
(define lead1 (list 0 5 5 4 0 5 5 3 2))

(define (seq notes interval)
  (list-ref notes (modulo interval (length notes))))

(define (tick)
    (set! t (+ 1 t))
    (define bassn (mode-get 0 0 (+ 21 (seq bass t))))
    (n-on 0 bassn 127)
    (dbg (string-append "tick: " (number->string t)))
    (when (> t 20) (set! bass bass2))
)

