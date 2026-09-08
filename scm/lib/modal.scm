(define (modal root mode interval)
  ;; Mode tables: 0=Ionian, 1=Dorian, 2=Phrygian, 3=Lydian,
  ;;              4=Mixolydian, 5=Aeolian, 6=Locrian
  ;; Each entry is the semitone offsets for degrees 1..7
  (define modes
    '#((0 2 4 5 7 9 11)      ; 0=Ionian
       (0 2 3 5 7 9 10)      ; 1=Dorian
       (0 1 3 5 7 8 10)      ; 2=Phrygian
       (0 2 4 6 7 9 11)      ; 3=Lydian
       (0 2 4 5 7 9 10)      ; 4=Mixolydian
       (0 2 3 5 7 8 10)      ; 5=Aeolian
       (0 1 3 5 6 8 10)))    ; 6=Locrian
  (let* ((offsets (vector-ref modes mode))
         (d (- interval 1))
         (degree (floor-remainder d 7))
         (octave (floor-quotient d 7)))
    (+ root (list-ref offsets degree) (* octave 12))))

; (modal 0 0 1)  => 0   ; C Ionian tonic
; (modal 0 0 3)  => 4   ; C Ionian 3rd
; (modal 9 5 7)  => 7   ; A Aeolian 7th
; (modal 5 1 4)  => 10  ; F Dorian 4th

(define (pentatonic root mode interval)
  (define pentatonic-modes
    '#((0 2 4 7 9)      ; 0=Major pentatonic
       (0 2 5 7 10)     ; 1=Suspended pentatonic
       (0 3 5 7 10)     ; 2=Blues minor pentatonic
       (0 2 5 7 9)      ; 3=Ritusen (Japanese)
       (0 4 5 7 11)))   ; 4=Prometheus
  (let* ((offsets (vector-ref pentatonic-modes mode))
         (d (- interval 1))
         (degree (floor-remainder d 5))
         (octave (floor-quotient d 5)))
    (+ root (list-ref offsets degree) (* octave 12))))


; (pentatonic 0 0 1)   => 0   ; C major pentatonic tonic
; (pentatonic 0 0 2)   => 2   ; 2nd
; (pentatonic 0 0 5)   => 9   ; 5th
; (pentatonic 0 0 6)   => 12  ; 6th = octave above tonic
; (pentatonic 0 0 10)  => 21  ; 10th = 5th up an octave
; (pentatonic 9 0 40)  => 69  ; A major pentatonic, 8 octaves up
