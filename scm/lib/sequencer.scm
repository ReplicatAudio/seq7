;; Per-channel state: the note currently sounding on each channel, or #f.
;; sequencer releases the previous note on every step so patterns don't
;; pile up sustained voices.
(define sequencer-notes (make-vector 16 #f))

(define (sequencer ch notes off root mode vel interval)
  (define nt (list-ref notes (modulo interval (length notes))))
  (let ((prev (vector-ref sequencer-notes ch)))
    (when prev
      (midi-note-off ch prev)))
  (if (string=? nt "r")
      (vector-set! sequencer-notes ch #f)
      (let ((note (+ off (modal root mode (string->number nt)))))
        (vector-set! sequencer-notes ch note)
        (midi-note-on ch note vel)))
)
