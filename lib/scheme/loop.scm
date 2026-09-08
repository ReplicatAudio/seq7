(define (loop n lmb . arg)
  (define (lp i)
    (when (< i n)
      (apply lmb i arg)
      (lp (+ i 1))))
  (lp 0))

;; Usage
; (loop 10 (lambda (i) (display i)(newline)))
; (loop 10 (lambda (i a b) (display i)(display a)(display b)(newline)) 33 22)
