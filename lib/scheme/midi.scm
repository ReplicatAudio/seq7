;; MIDI Helpers 
(define (midi-note-on ch note vel)
  (raw-midi-write (list (+ #x90 ch) note vel)))

(define (midi-note-off ch note)
  (raw-midi-write (list (+ #x80 ch) note 0)))

(define (midi-cc ch cc vel)
  (raw-midi-write (list (+ #xB0 ch) cc vel)))

;; MIDI System Real-Time messages
(define (midi-clock)
  (raw-midi-write (list #xF8)))

(define (midi-start)
  (raw-midi-write (list #xFA)))

(define (midi-stop)
  (raw-midi-write (list #xFC)))

(define (midi-continue)
  (raw-midi-write (list #xFB)))
