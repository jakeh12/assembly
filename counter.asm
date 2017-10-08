	;; compile with
	;; make
	;; and flash with
	;; make flash
	;;
	;; put 0 into a
	ld a,$00
	;; put address FFFF into hl
	ld hl,$FFFF
	;; write a into (HL)
	ld (hl), a
start:
	;; read (HL) into a
	ld a,(hl)
	;; output a
	out ($00),a
	;; delay loop start
	ld c,$ff
loopon1:
	ld d,$ff
loopon2:
	dec d
  	jp nz,loopon2

  	dec c
  	jp nz,loopon1
	;; delay loop end

	;; increment a
  	inc a
  	;; save it back into (HL)
  	ld (hl), a
  	;; write zero into a to make sure RAM is working
  	ld a,$00
  	;; goto start
  	jp start
