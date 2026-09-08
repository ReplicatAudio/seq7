;; Flatten a list
;; (a b (a b)) -> (a b a b)
(define (flatten lst)
  (cond ((null? lst) '())
        ((pair? (car lst)) (append (flatten (car lst)) (flatten (cdr lst))))
        (else (cons (car lst) (flatten (cdr lst))))))
