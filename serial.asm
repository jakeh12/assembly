;; SERIAL
; this program echoes whatever it receives over USB
; compile with
; make
; and flash with
; make flash

	org $0000
reset:
	di
	im 1
	ld sp, $ffff
	jp init
	

	org $0100
init:
	nop
	jp main


main:
	call receive_byte
	call send_byte
	jp main


;; RECEIVE_BYTE
;  waits until receive buffer full flag goes low (data is present)
;  and returns the data in register a
receive_byte:
	in a, ($01)
        bit 0, a
        jp nz, receive_byte
	in a, ($00)
	ret
; end of RECEIVE_BYTE


;; SEND_BYTE
;  waits until the transmit buffer empty flag goes high (in case
;  there is a pending transmission) and then writes the 
;  byte from register a into the transmit buffer
send_byte:
	ld b, a
	in a, ($01)
	bit 1, a
	jp nz, send_byte
	ld a, b
	out ($00), a
	ret
; end of SEND_BYTE


; pad file to eeprom size
	ds	0x8000 - $
