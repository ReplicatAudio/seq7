(load "scm/lib/lib.scm")

(define x "
a a a
b b b
c c c
")
(define xx (string-split-space-multiline x))
(debug (list-ref xx 0))
