;; PROGRAM SERIAL
; this program echoes whatever it receives over USB compile with 'make'
; and flash with 'make flash'


;; DEFINITIONS
; rom chip capacity
ROM_SIZE	equ	$8000

; stack
STACK_BOTTOM	equ 	$ffff

; serial port
SER_DATA	equ	$00
SER_FLAG	equ	$01
SER_BIT_RXE	equ	0
SER_BIT_TXF	equ	1


	org $0000
reset:
	di
	im 1
	ld sp, STACK_BOTTOM
	jp init
	

	org $0100
init:
	jp main


main:
	call receive_byte
	call send_byte
	jp main


;; SUBROUTINE RECEIVE_BYTE
;  waits until receive buffer full flag goes low (data is present)
;  and returns the data in register a
receive_byte:
	in a, (SER_FLAG)
        bit SER_BIT_RXE, a
        jp nz, receive_byte
	in a, (SER_DATA)
	ret
; end of RECEIVE_BYTE


;; SUBROUTINE SEND_BYTE
;  waits until the transmit buffer empty flag goes high (in case
;  there is a pending transmission) and then writes the 
;  byte from register a into the transmit buffer
send_byte:
	ld b, a
_send_byte_wait:
	in a, (SER_FLAG)
	bit SER_BIT_TXF, a
	jp nz, _send_byte_wait
	ld a, b
	out (SER_DATA), a
	ret
; end of SEND_BYTE


; pad file to eeprom size
	ds	ROM_SIZE - $
