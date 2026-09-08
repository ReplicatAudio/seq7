(load "scm/lib/flatten.scm")

(define (mapfn c rset)
  (define (rule t) (string=? c t))
  (define (rref i) (list-ref rset i))
  (cond 
    ((rule (rref 1)) (rref 2))
    ((rule (rref 3)) (rref 4))
    ((rule (rref 5)) (rref 6))
    ((rule (rref 7)) (rref 8))
    (else c) ))

(define (lsystem rset it)
  (define (rref i) (list-ref rset i))
  (define axiom (rref 0))
  (define gen axiom)
  (define gens '())
  (loop it (lambda (i)
    (set! gen (map 
      (lambda (c) (mapfn c rset)) 
      (flatten gen)))
    (set! gens (append gens (list (flatten gen))))
    ))
  gens)

;; Usage
; (define algae (list 
;   (list "a") ; axiom always a list
;   "a" (list "a" "b") ; r1
;   "b" "a" ; r2
;   "?" "?" ; r3 (empty)
;   "?" "?" ; r4 (empty)
; ))
;
; (lsystem algae 5)
; (last (lsystem algae 5)) ; final gen
