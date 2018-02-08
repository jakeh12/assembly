;; PROGRAM STRING
; prints a string over serial port, compile with 'make'
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

; ram
STRING_LOC	equ	$8000


	org $0000
reset:
	di
	im 1
	ld sp, STACK_BOTTOM
	jp init
	

	org $0100
init:
	call delay	
	call receive_byte
	ld hl, message_string
	call send_string
	jp main


main:
	ld hl, STRING_LOC
	call receive_string
	ld hl, STRING_LOC
	call send_string
	jp main


;; SUBROUTINE RECEIVE_STRING
; keeps reading string in byte-by-byte until a CR
; byte is received
receive_string:
	call receive_byte
	cp $0d
	jp nz, _receive_string_continue
	ld (hl), 0
	ret
_receive_string_continue:
	ld (hl), a
	inc hl
	call send_byte
	jp receive_string
; end of RECEIVE_STRING


;; SUBROUTINE SEND_STRING
; keeps sending a string byte-by-byte using SEND_BYTE until 
; NULL character is detected
send_string:
	ld a, (hl)
	cp 0
	jp nz, _send_string_send_byte
	ret
_send_string_send_byte:
	call send_byte
	inc hl
	jp send_string
; end of SEND_STRING


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


;; SUBROUTINE DELAY
; makes processor busy for about half a second
delay:
	ld b, $02
_delay0:
	ld d, $ff
_delay1:
	ld e, $ff
_delay2:
	dec e
	jp nz, _delay2
	dec d
	jp nz, _delay1
	dec b
	jp nz, _delay0
	ret
; end of DELAY


message_string:
	db "Z80 Computer by Jakub Hladik", $0a, $0d, $0a, $20, $3e, $20, $00

; pad file to eeprom size
	ds	ROM_SIZE - $
