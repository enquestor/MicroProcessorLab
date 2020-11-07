	.syntax unified
	.cpu cortex-m4
	.thumb
.data
	DISPLAYED_NUMBER: .byte 0, 0, 0, 0, 0, 0, 0, 0
	FIBBO_SEQUENCE: .asciz "0112358132134558914423337761098715972584418167651094617711286574636875025121393196418317811514229832040134626921783093524578570288792274651493035224157817390881696324598699999999"
    FIBBO_DIGIT_COUNT: .byte 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8
	FIBBO_N: .word 0
	BUTTON_COUNTER: .word 0

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

main:
	BL    gpio_init
	BL    max7219_init
	BL    reset

main_loop:
	BL    button_status
	TEQ   R0, #1  // checks if button is pressed
	BEQ   main_increment
	TEQ   R0, #2
	BEQ   main_reset
	B	  main_loop

main_increment:
	LDR   R1, =FIBBO_N
	LDR   R0, [R1]
	ADD   R0, #1
	STR   R0, [R1]
	BL    fibonacci
	BL    display_number
	B     main_loop

main_reset:
	BL    reset
	B     main_loop

reset:
	PUSH  { LR }

	// light up 1 digits
	LDR   R0, =SCAN_LIMIT
	LDR   R1, =0x0
	BL    send_message

	// show 0 on display
	MOV   R0, 0x1
	MOV   R1, #0
	BL    send_message

	// reset FINNO_N to 0
	LDR   R1, =FIBBO_N
	MOV   R0, #0
	STR   R0, [R1]

	POP   { LR }
	BX    LR

// Given the location of fibbonacci sequence (R0) and the digit count to be displayed (R1), updates MAX7912
display_number:
	PUSH  { LR }
	MOV   R2, #0

display_loop:
	TEQ   R2, R1
	BEQ   display_end

	LDRB  R3, [R0,R2]
	SUB   R3, 0x30   // convert '0' to 0
	PUSH  { R0, R1, R2 }
	MOV   R0, R1
	SUB   R0, R2
	MOV   R1, R3
	BL    send_message
	POP   { R0, R1, R2 }

	ADD   R2, #1
	B     display_loop

display_end:
	// set to light up enough digits
	LDR   R0, =SCAN_LIMIT
	SUB   R1, #1
	BL    send_message

	POP   { LR }
	BX    LR

gpio_init:
	// enable GPIOC
	LDR   R1, =RCC_AHB2ENR
	LDR   R0, =0b100
	STR   R0, [R1]

	// set PC0-2 as output, PC13 (blue button) as input
	LDR   R1, =GPIOC_MODER
	LDR   R2, [R1]
	LDR   R3, =0b11110011111111111111111111000000
	AND   R2, R3
	ORR   R2, #0b010101
	STR   R2, [R1]

	// set PC0-2 as high speed
	// since PC13 is input, no need to set speed
	LDR   R1, =GPIOC_OSPEEDER
	LDR   R2, [R1]
	LDR   R8, =0xFFFFFC00
	AND   R2, R8
	LDR   R0, =0b101010
	ORR   R2, R0
	STR   R0, [R1]

	BX LR

max7219_init:
	PUSH  { LR }

    // enable code B decode since character A-F is not available
	LDR   R0, =DECODE
	LDR   R1, =0xFF
	BL    send_message

	// normal operation
	LDR   R0, =DISPLAY_TEST
	LDR   R1, =0x0
	BL    send_message

	// brightest
	LDR   R0, =INTENSITY
	LDR   R1, =0xF
	BL    send_message

	// no shutdown
	LDR   R0, =SHUT_DOWN
	LDR   R1, =0x1
	BL    send_message



	POP   { LR }
	BX    LR

// Given address (R0) and data (R1), sends message to MAX7219.
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

// Queries the n-th fibbonacci numbers, where n=R0.
// Sets R0="starting address of fibbonacci sequence" and R1="digit count of F(n)"
// If F(n) is greater than 99999999, sets R0=99999999 and R1=8
fibonacci:
	LDR   R1, =FIBBO_DIGIT_COUNT
	LDR   R2, =FIBBO_SEQUENCE
	MOV   R3, #0

fibonacci_loop:
	TEQ   R3, #40
	BEQ   fibonacci_done
	TEQ   R3, R0
	BEQ   fibonacci_done

	LDRB  R4, [R1]
	ADD   R2, R4
	ADD   R1, #1
	ADD   R3, #1
	B     fibonacci_loop

fibonacci_done:
	LDRB  R1, [R1]
	MOV   R0, R2
	BX    LR

// Queires if button is pressed. The retuened value is in R0.
// Returns: 1 if button is short-pressed,
//          2 if button is long-pressed,
//          0 if button is not pressed.
button_status:
	LDR   R0, =GPIOC_IDR
	LDR   R0, [R0]
	LSR   R0, #13
	AND   R0, #0x1
	LDR   R2, =BUTTON_COUNTER
	LDR   R1, [R2]

	TEQ   R0, #0
	IT EQ
	ADDEQ R1, #1     // button is pressed
	BNE   button_not_pressed

	TEQ   R1, #2000  // short press threshold
	BEQ   button_short_pressed
	LDR   R4, =77777 // long press threshold
	TEQ   R1, R4
	BEQ   button_long_pressed
	B     button_status_done

button_short_pressed:
	MOV   R0, #1
	B     button_status_done

button_long_pressed:
	MOV   R0, #2
	B     button_status_done

button_not_pressed:
	MOV   R1, #0
	MOV   R0, #0

button_status_done:
	STR   R1, [R2]
	BX    LR
