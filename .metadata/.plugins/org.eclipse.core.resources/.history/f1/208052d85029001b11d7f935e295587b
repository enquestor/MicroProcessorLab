	.syntax unified
	.cpu cortex-m4
	.thumb
.data
//TODO: put your student id here
	//student_id: .byte 0, 7, 1, 3, 4, 0, 7
.text
	.global max7219_init, max7219_send
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

max7219_init:
	PUSH  {R0, R1, LR}

    // enable code B decode
	LDR   R0, =DECODE
	LDR   R1, =0xFF
	BL    max7219_send

	// normal operation
	LDR   R0, =DISPLAY_TEST
	LDR   R1, =0x0
	BL    max7219_send

	// brightest
	LDR   R0, =INTENSITY
	LDR   R1, =0xF
	BL    max7219_send

	// light up 7 digits
	LDR   R0, =SCAN_LIMIT
	LDR   R1, =0x7
	BL    max7219_send

	// no shutdown
	LDR   R0, =SHUT_DOWN
	LDR   R1, =0x1
	BL    max7219_send

	POP   {R0, R1, LR}
	BX    LR

// Given address (R0) and data (R1), send message to MAX7219.
max7219_send:
	PUSH  {R0, R1, R2, R3, R4, R5, R6, R7}
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
    POP   {R0, R1, R2, R3, R4, R5, R6, R7}
	BX LR
