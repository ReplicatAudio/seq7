(define (string-split str delim)
  (let loop ((chars (string->list str)) (cur '()) (result '()))
    (cond
      ((null? chars)
       (reverse (cons (list->string (reverse cur)) result)))
      ((char=? (car chars) delim)
       (loop (cdr chars) '() (cons (list->string (reverse cur)) result)))
      (else
       (loop (cdr chars) (cons (car chars) cur) result)))))

;;(string-split "a,b,c" #\,)
;; => ("a" "b" "c")
;; (string-split "hello world how are you" #\space)
;; => ("hello" "world" "how" "are" "you")

(define (string-split-space str)
  (string-split str #\space))

(define (string-split-space-line str)
  (string-split-space (string-trim (string-replace str "\n" " "))))

(define (string-trim str)
  (let ((len (string-length str)))
    (define (find-start i)
      (cond ((= i len) 0)
            ((char-whitespace? (string-ref str i)) (find-start (+ i 1)))
            (else i)))
    (define (find-end i)
      (cond ((< i 0) (- len 1))
            ((char-whitespace? (string-ref str i)) (find-end (- i 1)))
            (else i)))
    (let ((start (find-start 0))
          (end   (find-end (- len 1))))
      (if (> start end)
          ""
          (substring str start (+ 1 end))))))
