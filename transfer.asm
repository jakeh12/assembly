;; PROGRAM TRANSFER
; receives data over serial port and saves it in ram
; compile with 'make' and flash with 'make flash'


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
RAM_START	equ	$8000


	org $0000
;; JUMP TABLE
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
	;ld hl, RAM_START
	;call receive_data
	;jp RAM_START
	call receive_byte
	;ld hl, RAM_START
	;call conv_to_ascii_hex
	;ld hl, RAM_START
	call send_byte
	jp main


;; SUBROUTINE CONV_TO_ASCII_HEX
; takes in a byte in register a and saves the string in memory
; address saved in hl
conv_to_ascii_hex:
	push bc
	push hl
	ld b, a
	srl a			; extract the upper 4 bits
	srl a
	srl a
	srl a
	call __conv_to_ascii_hex_offset
	ld (hl), a
	inc hl
	ld a, b
	and %00001111		; extract the lower 4 bits
	call __conv_to_ascii_hex_offset
        ld (hl), a
	inc hl
	ld (hl), $00		; add terminating NULL
	pop hl
	pop bc
	ret

__conv_to_ascii_hex_offset:
        cp 10
        jp m, _conv_to_ascii_hex_offset_0_9
        add 87                  ; number is in range a-f
	jp _conv_to_ascii_hex_offset_done
_conv_to_ascii_hex_offset_0_9:         
        add 48                  ; number is in range 0-9
_conv_to_ascii_hex_offset_done:	
	ret
; end of CONV_TO_ASCII_HEX

;; SUBROUTINE RECEIVE_DATA
; waits two bytes which define the number of bytes
; to be subsequently received and stored in ram
; starting at address stored in hl
receive_data:
	call receive_byte	; store the data length in the
	ld c, a			; bc register, little endian
	call receive_byte	; ordering
	ld b, a
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld de, hl;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, receive_data_start;;;;;;;;;;;;
	call send_string;;;;;;;;;;;;;;;;;;;
	ld hl, de;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
_receive_data_loop:
	call receive_byte	; loop until all the data bytes
	ld (hl), a		; are received
	;;;;;;;;;;;;;;;;;;;;;;;;;
	ld de, hl;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, $ff00;;;;;;;;;;;;;;;;;
	call conv_to_ascii_hex;;;;;;;;;;;;;;
	ld hl, $ff00;;;;;;;;;;;;;;;;;
	call send_string;;;;;;;;;;;;;;;
	ld a, $20;;;;;;;;;;;;;;;;;;;;;;
	call send_byte;;;;;;;;;;
	ld hl, de;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	inc hl
	dec bc
	ld a, b
	cp 0      
	jp nz, _receive_data_loop
	ld a, c
	cp 0
	jp nz, _receive_data_loop
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, $0a;;;;;;;;;;;;;;;;;;;;;;;
	call send_byte;;;;;;;;;;;;;;;;;
	ld a, $0d;;;;;;;;;;;;;;;;;;;;;;
	call send_byte;;;;;;;;;;;;;;;;;;;;
	ld hl, receive_data_end;;;;;;;;;;;;;;;;;;;
	call send_string;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;
	ret


;; SUBROUTINE RECEIVE_STRING
; keeps reading string in byte-by-byte until a CR
; byte is received
receive_string:
	push hl
	call receive_byte
	cp $0d
	jp nz, _receive_string_continue
	ld (hl), 0
	pop hl
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
	push hl
	ld a, (hl)
	cp 0
	jp nz, _send_string_send_byte
	pop hl
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
	push bc
	ld b, a
_send_byte_wait:
	in a, (SER_FLAG)
	bit SER_BIT_TXF, a
	jp nz, _send_byte_wait
	ld a, b
	out (SER_DATA), a
	pop bc
	ret
; end of SEND_BYTE


;; SUBROUTINE DELAY
; makes processor busy for about half a second
delay:
	push bc
	push de
	ld b, $02
_delay0:
	ld c, $ff
_delay1:
	ld d, $ff
_delay2:
	dec d
	jp nz, _delay2
	dec c
	jp nz, _delay1
	dec b
	jp nz, _delay0
	pop de
	pop bc
	ret
; end of DELAY


receive_data_start:
	db "Receiving data...", $0a, $0d, $00

receive_data_end:
	db "Data transfer complete.", $0a, $0d, $00


; pad file to eeprom size
	ds	ROM_SIZE - $
