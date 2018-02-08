;; PROGRAM RAM_PROG
; program to be loaded from pc to Z80 ram and ran
; compile with 'make' and flash with 'make flash'


;; DEFINITIONS

; stack
STACK_BOTTOM	equ 	$ffff

; serial port
SER_DATA	equ	$00
SER_FLAG	equ	$01
SER_BIT_RXE	equ	0
SER_BIT_TXF	equ	1

; ram
RAM_START	equ	$8000
MAIN_MAIN	equ	$0006


	org RAM_START
main:	
	call receive_byte
	call send_byte
	jp MAIN_MAIN

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

