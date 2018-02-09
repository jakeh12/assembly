;===============================================================================
; STRING
;-------------------------------------------------------------------------------
; wait for a character to be received and prints out a message string
;===============================================================================


;-------------------------------------------------------------------------------
; DEFINITIONS
;-------------------------------------------------------------------------------

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
;-------------------------------------------------------------------------------


;===============================================================================
; PROGRAM
;===============================================================================

	org RAM_START
	
main:	
	ld hl, message_string
	call send_string
	jp MAIN_MAIN


;===============================================================================
; SUBROUTINES
;===============================================================================

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
;    af, hl, b
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
;    af, b
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


;===============================================================================
; DATA
;===============================================================================

message_string:
	db "This string was created and sent by a program that was loaded through serial port directly in to RAM.", $0d, $0a, $00
;-------------------------------------------------------------------------------

