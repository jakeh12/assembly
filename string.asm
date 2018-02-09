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
RAM_START	equ	$8000
;-------------------------------------------------------------------------------


;===============================================================================
; PROGRAM
;===============================================================================

	org $0000
	
	; jump table
	jp reset
	jp init
	jp main


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
	ld hl, ready_to_receive_string
	call send_string
	
	ld hl, RAM_START
	call receive_data
	
	push bc	
	ld hl, $ff00
	ld a, b
	call to_hex
	ld hl, $ff00
	call send_string
	pop bc
	
	ld hl, $ff00
	ld a, c
	call to_hex
	ld hl, $ff00
	call send_string
	
	ld hl, bytes_received_string
	call send_string
	
	jp RAM_START

	jp main


;===============================================================================
; SUBROUTINES
;===============================================================================


;-------------------------------------------------------------------------------
; SUBROUTINE: RECEIVE_DATA
;-------------------------------------------------------------------------------
;  wait for two bytes which define the lenght of the byte stream to be received
;  and stores the received bytes in the memory
; 
;  inputs:
;    hl	- pointer to the beginning of the location where to store the data
;
;  outputs:
;    bc - the lenght of the data stored at location hl
;
;  modifies:
;    af, bc, de, hl
;-------------------------------------------------------------------------------
receive_data:
	call receive_byte
	ld c, a
	call receive_byte
	ld b, a
	ld de, bc
_receive_data_loop:
	call receive_byte
	ld (hl), a
	inc hl
	dec bc
	ld a, b
	cp 0
	jr nz, _receive_data_loop
	ld a, c
	cp 0
	jr nz, _receive_data_loop
	ld bc, de
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: RECEIVE DATA
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; SUBROUTINE: TO_HEX
;-------------------------------------------------------------------------------
;  converts a number into hex ascii string
; 
;  inputs:
;    a	- value to be converted to hex
;    hl	- pointer to the beginning of the string to be saved
;
;  outputs:
;    none
;
;  modifies:
;    af, bc, hl
;-------------------------------------------------------------------------------
to_hex:
	ld b, a
	ld c, 2
	srl a			; extract the upper 4 bits
	srl a
	srl a
	srl a
_to_hex_offset:
        cp 10
        jp m, _to_hex_offset_0_9
        add 'a'-10		; number is in range a-f
        jr _to_hex_offset_done
_to_hex_offset_0_9:
        add '0'			; number is in range 0-9
_to_hex_offset_done:
	ld (hl), a
	inc hl
	dec c
	jr z, _to_hex_done
	ld a, b
	and %00001111		; extract the lower 4 bits
	jr _to_hex_offset
_to_hex_done:
	ld (hl), $00		; add terminating NULL
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: TO_HEX
;-------------------------------------------------------------------------------


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
;    af, hl
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
;    af
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
;    c, de
;-------------------------------------------------------------------------------
delay:
	ld c, $02
_delay0:
	ld d, $ff
_delay1:
	ld e, $ff
_delay2:
	dec e
	jp nz, _delay2
	dec d
	jp nz, _delay1
	dec c
	jp nz, _delay0
	ret
;-------------------------------------------------------------------------------
; END OF SUBROUTINE: DELAY
;-------------------------------------------------------------------------------


;===============================================================================
; DATA
;===============================================================================

bytes_received_string:
	db " (hex) bytes received.", $0a, $0d, $00

ready_to_receive_string:
	db "Ready to receive data...", $0a, $0d, $00
;-------------------------------------------------------------------------------


;===============================================================================
; PADDING
;===============================================================================

; pad file to eeprom size
	ds	ROM_SIZE - $
;-------------------------------------------------------------------------------

