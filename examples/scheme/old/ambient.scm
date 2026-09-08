; seq7 — generative ambient phase machine
; run: cargo run -- examples/ambient.scm
; then press Space to start
;
; A generative phase-shifting ambient piece. 
; - Two voices play the same
; pentatonic melody; one gradually drifts out of phase 
; 
; (inspired by
; Steve Reich's "Piano Phase"). A bass voice provides evolving pedal
; tones, while CC modulation adds timbral movement.
;
; Voice 1 (ch1): 16-note pattern, loops straight
; Voice 2 (ch2): same pattern, phase-shifted every 3 cycles
; Voice 3 (ch3): slow bass, random walks through the scale
; CC 1 (mod wheel): triangle LFO across all voices
; CC 91 (reverb): slow evolving sweep

(load "lib/scheme/lib.scm")

(set-tick-speed 20)
; use /dbg at the REPL to toggle MIDI debug logging

; --- C major pentatonic, 3 octaves ---
(define scale (list 48 50 52 55 57 60 62 64 67 69 72 74 76 79 81 84))
(define s-len (length scale))

; --- the pattern (indices into scale) ---
(define pat (list 4 6 9 11 9 6 4 2 4 7 9 11 9 7 4 2))
(define p-len (length pat))

; --- voice state ---
(define t 0)

(define v1-idx 0)
(define v1-note #f)

(define v2-idx 0)
(define v2-note #f)
(define v2-cycles 0)

(define v3-idx 2)
(define v3-note #f)

(define lfo-pos 0)

; --- main tick ---
(define (tick)
  (set! t (+ t 1))

  ; --- CC 1: mod wheel LFO (triangle, period 512 ticks ≈ 20s) ---
  (set! lfo-pos (modulo (+ lfo-pos 1) 512))
  (let ((lv (if (< lfo-pos 256) lfo-pos (- 511 lfo-pos))))
    (c-c 0 1 (quotient lv 4))
    (c-c 1 1 (quotient lv 4))
    (c-c 2 1 (quotient lv 4)))

  ; --- CC 91: reverb sweep (period 2048 ticks ≈ 80s) ---
  (let ((rv (modulo t 2048)))
    (c-c 0 91 (+ 40 (quotient (if (< rv 1024) rv (- 2047 rv)) 26))))

  ; --- Voice 1 (ch1): straight pattern, steps every 8 ticks ---
  (when (= (modulo t 8) 0)
    (when v1-note (n-off 0 v1-note))
    (set! v1-note (+ (list-ref scale (list-ref pat v1-idx)) 12))
    (n-on 0 v1-note 72)
    (set! v1-idx (modulo (+ v1-idx 1) p-len)))

  ; --- Voice 2 (ch2): phase-shifted pattern, steps every 8 ticks ---
  (when (= (modulo t 8) 0)
    (when v2-note (n-off 1 v2-note))
    (set! v2-note (+ (list-ref scale (list-ref pat v2-idx)) 12))
    (n-on 1 v2-note 72)
    (set! v2-idx (+ v2-idx 1))
    (when (= v2-idx p-len)
      (set! v2-idx 0)
      (set! v2-cycles (+ v2-cycles 1))
      (when (= (modulo v2-cycles 3) 0)
        (set! v2-idx 1))))

  ; --- Voice 3 (ch3): bass pedal, steps every 48 ticks ---
  (when (= (modulo t 48) 0)
    (when v3-note (n-off 2 v3-note))
    (let* ((step (+ -2 (rng->gen-range 0 5)))
           (raw (+ v3-idx step))
           (ni (if (< raw 0) 0 (if (>= raw s-len) (- s-len 1) raw))))
      (set! v3-idx ni)
      (set! v3-note (list-ref scale v3-idx))
      (n-on 2 v3-note 85))))
