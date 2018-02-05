;; this program echoes whatever it receives over USB
;; compile with
;; make
;; and flash with
;; make flash
;;
	org $0000
reset:
	di
	jp init
	org $0100
init:
	nop
main:
	in a,($01)
	bit 0,a		;; check rxe flag (1 = empty)
	jp z, rxtx
	jp main
rxtx:
	in a,($00)	;; read byte from serial
	out ($00),a	;; trasmit byte over serial
	jp main	
	
	;; pad file to eeprom size
	ds	0x8000 - $

