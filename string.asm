;===============================================================================
; STRING
;-------------------------------------------------------------------------------
; wait for a character to be received and prints out a message string
;===============================================================================


;-------------------------------------------------------------------------------
; DEFINITIONS
;-------------------------------------------------------------------------------

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
;-------------------------------------------------------------------------------


;===============================================================================
; PROGRAM
;===============================================================================

	org $0000
reset:
	di
	im 1
	ld sp, STACK_BOTTOM
	jp init
	

	org $0100
init:
	call delay	
	jp main


main:
	call receive_byte
	ld hl, message_string
	call send_string
	jp main


;===============================================================================
; SUBROUTINES
;===============================================================================

;-------------------------------------------------------------------------------
; SUBROUTINE: RECEIVE_STRING
;-------------------------------------------------------------------------------
;  keeps reading string in byte-by-byte until a CR byte is received
; 
;  inputs:
;    hl - pointer to the beginning of the string to be saved
;
;  outputs:
;    none
;
;  modifies:
;    a, f, hl
;-------------------------------------------------------------------------------
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
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: RECEIVE_STRING
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: SEND_STRING
;-------------------------------------------------------------------------------
;  keeps sending a string byte-by-byte until a NULL character is detected
; 
;  inputs:
;    hl - pointer to the beginning of the string
;
;  outputs:
;    none
;
;  modifies:
;    a, f, hl, b
;-------------------------------------------------------------------------------
send_string:
	ld a, (hl)
	cp 0
	jp nz, _send_string_send_byte
	ret
_send_string_send_byte:
	call send_byte
	inc hl
	jp send_string
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: SEND_STRING
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: RECEIVE_BYTE
;-------------------------------------------------------------------------------
;  waits until receive buffer full flag goes low (data is present)
;  and returns the data
;
;  inputs:
;    none
;
;  outputs:
;    a - byte received
;
;  modifies:
;    a, f
;-------------------------------------------------------------------------------
receive_byte:
	in a, (SER_FLAG)
        bit SER_BIT_RXE, a
        jp nz, receive_byte
	in a, (SER_DATA)
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: RECEIVE_BYTE
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: SEND_BYTE
;-------------------------------------------------------------------------------
;  waits until the transmit buffer empty flag goes high (in case
;  there is a pending transmission) and then writes the 
;  byte into the transmit buffer
;
;  inputs:
;    a - byte to be transmitted
;
;  outputs:
;    none
;
;  modifies:
;    a, b, f
;-------------------------------------------------------------------------------
send_byte:
	ld b, a
_send_byte_wait:
	in a, (SER_FLAG)
	bit SER_BIT_TXF, a
	jp nz, _send_byte_wait
	ld a, b
	out (SER_DATA), a
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: SEND_BYTE
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: DELAY
;-------------------------------------------------------------------------------
; makes processor busy for about half a second
;
;  inputs:
;    none
;
;  outputs:
;    none
;
;  modifies:
;    b, d, e
;-------------------------------------------------------------------------------
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
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: DELAY
;-------------------------------------------------------------------------------


;===============================================================================
; DATA
;===============================================================================

message_string:
	db "Z80 Computer by Jakub Hladik", $0a, $0d, $0a, $20, $3e, $20, $00
;-------------------------------------------------------------------------------


;===============================================================================
; PADDING
;===============================================================================

; pad file to eeprom size
	ds	ROM_SIZE - $
;-------------------------------------------------------------------------------

