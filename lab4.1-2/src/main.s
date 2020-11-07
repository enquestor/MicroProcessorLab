	.syntax unified
	.cpu cortex-m4
	.thumb
.data
	// put 0 to F 7-Seg LED pattern here
	arr: .byte 0x1C, 0x19, 0x15, 0xD, 0x1C, 0x19, 0x15, 0xD
.text
	.global main
	// GPIO
	.equ	RCC_AHB2ENR,	0x4002104C
	.equ	GPIOC_MODER,	0x48000800
	.equ	GPIOC_OTYPER,	0x48000804
	.equ	GPIOC_OSPEEDER,	0x48000808
	.equ	GPIOC_PUPDR,	0x4800080C
	.equ	GPIOC_IDR,		0x48000810
	.equ	GPIOC_ODR,		0x48000814
	.equ	GPIOC_BSRR,		0x48000818  // set bit
	.equ	GPIOC_BRR,		0x48000828  // clear bit

	// Din, CS, CLK offset
	.equ 	DIN,	        0b1 	// PC0
	.equ	CS,		        0b10	// PC1
	.equ	CLK,	        0b100	// PC2

	// MAX7219
	.equ	DECODE,			0x09    // Decode control
	.equ	INTENSITY,		0x0A    // Brightness
	.equ	SCAN_LIMIT,		0x0B    // How many digits to display
	.equ	SHUT_DOWN,		0x0C    //
	.equ	DISPLAY_TEST,	0x0F    //

	//timer
	.equ	SECOND,		    500000

main:
	BL   gpio_init
	BL   max7219_init
main_loop:
	BL   display_digit

gpio_init:
	// enable GPIOC
	LDR   R1, =RCC_AHB2ENR
	LDR   R0, =0b100
	STR   R0, [R1]

	// set PC0-2 as output
	LDR   R1, =GPIOC_MODER
	LDR   R2, [R1]
	AND   R2, #0xFFFFFFC0 // clear right 6 bits
	ORR   R2, #0b010101
	STR   R2, [R1]

	// set PC0-2 as high speed
	LDR   R1, =GPIOC_OSPEEDER
	LDR   R2, [R1]
	LDR   R8, =0xFFFFFC00
	AND   R2, R8
	LDR   R0, =0b101010
	ORR   R2, R0
	STR   R0, [R1]

	BX LR

display_digit:

	LDR   R2, =arr

	MOV   R3, #0
clear_loop:
	MOV   R0, R3
	MOV   R1, #0
	PUSH  { R2, R3, LR }
	BL    send_message
	POP   { R2, R3, LR }
	CMP   R3, #8
	ADD   R3, #1
	BNE   clear_loop

	MOV   R3, R2
	ADD   R3, #0x8
	MOV   R4, #1

display_loop:
	CMP   R2, R3
	IT EQ
	LDREQ R2, =arr
	IT EQ
	MOVEQ R4, #1
	IT EQ
	BLEQ  delay

    MOV   R0, R4  // this is where controls the first digit
    LDRB  R1, [R2]
    PUSH  { R2, R3, R4, LR }
    BL    send_message
    BL    delay
    POP   { R2, R3, R4, LR }

	MOV   R0, R4
	MOV   R1, #0
	PUSH  { R2, R3, R4, LR }
	BL    send_message
	POP   { R2, R3, R4, LR }

    ADD   R2, #1
    ADD   R4, #1
    B     display_loop

// Given address (R0) and data (R1), send message to MAX7219.
send_message:
	LSL	  R0, #8
	ORR   R0, R1

	LDR   R1, =DIN
	LDR   R2, =CS
	LDR   R3, =CLK
	LDR   R4, =GPIOC_BSRR
	LDR   R5, =GPIOC_BRR
	LDR   R6, =0xF        // the R6-th bit is sent

	STR   R2, [R5]        // clear CS

send_loop:
    STR   R3, [R5] // clear clock
    LDR   R7, =1
    LSL   R7, R6
    ANDS  R7, R0
    ITE NE
    STRNE R1, [R4] // the bit is set
    STREQ R1, [R5] // the bit is not set
    STR   R3, [R4] // set clock

	TEQ   R6, #0
	BEQ   send_done
    sub   R6, #1
	B     send_loop

send_done:
    STR   R2, [R4]  // set CS
    STR   R3, [R5]  // clear clock
	BX LR

max7219_init:
	PUSH  {LR}

    // disable code B decode since character A-F is not available
	LDR   R0, =DECODE
	LDR   R1, =0x0
	BL    send_message

	// normal operation
	LDR   R0, =DISPLAY_TEST
	LDR   R1, =0x0
	BL    send_message

	// brightest
	LDR   R0, =INTENSITY
	LDR   R1, =0xF
	BL    send_message

	// light up 1 digit only
	LDR   R0, =SCAN_LIMIT
	LDR   R1, =0x7
	BL    send_message

	// no shutdown
	LDR   R0, =SHUT_DOWN
	LDR   R1, =0x1
	BL    send_message

	POP   {LR}
	BX    LR

delay:
	LDR   R0, =SECOND

delay_loop:
    TEQ   R0, #0
    BEQ   delay_end
    SUB   R0, #1
    B     delay_loop

delay_end:
	BX    LR
