	.syntax unified
	.cpu cortex-m4
	.thumb
.data
	password: .byte 0b0101
.text
.global main
	.equ RCC_AHB2ENR, 0x4002104C
	.equ GPIOA_MODER, 0x48000000
	.equ GPIOA_OTYPER, 0x48000004
	.equ GPIOA_OSPEEDR, 0x48000008
	.equ GPIOA_PUPDR, 0x4800000C
	.equ GPIOA_ODR, 0x48000014

	@.equ GPIOB_MODER  , 0x48000400
	@.equ GPIOB_OTYPER , 0x48000404
	@.equ GPIOB_OSPEEDR, 0x48000408
	@.equ GPIOB_PUPDR  , 0x4800040C
	@.equ GPIOB_ODR    , 0x48000414

	.equ GPIOC_MODER  , 0x48000800
	.equ GPIOC_OTYPER ,	0x48000804
	.equ GPIOC_OSPEEDR,	0x48000808
	.equ GPIOC_PUPDR  ,	0x4800080c
	.equ GPIOC_IDR    , 0x48000810

	.equ DELAY_TIME, 0x3FFFF

main:
	bl gpio_init
	mov r6, #0
	mov   r8, #0       @ init debounce counter
	bl run

@ checks if fingers match password
@ if so, r0 is set to 1; else 0
check_password:
	ldr   r7,  [r2]        @ load fingers to r7
	ldr   r8,  =password @ load password to r8
	ldr   r8,  [r8]
	mov   r0,  #0        @ test if finger matches password
	teq   r7,  r8        @ if so, set r0 to 1; else 0
	IT EQ
	moveq r0,  #1
	bx    lr

@ queries fingers information and loads to r2
gpio_init:
	@ enable PA and PC
	mov  r0, #0x5
	ldr  r1, =RCC_AHB2ENR
	str  r0, [r1]

	@ enable PA5 (LED) to output (0b10)
	mov  r0, #0x400
	ldr  r1, =GPIOA_MODER
	ldr  r2, [r1]
	and  r2, #0xFFFFF3FF
	orr  r2, r2, r0
	str  r2, [r1]

	mov  r0, #0x800
	ldr  r1, =GPIOA_OSPEEDR
	strh r0, [r1]

	@ enable PC0, 1, 2, 3, 13 to input (0b00)
	ldr  r1, =GPIOC_MODER
	ldr  r2, [r1]
	ldr  r3, =0b11110011111111111111111100000000
	and  r2, r3
	str  r2, [r1]

	ldr  r0, =0b00001000000000000000000010101010
	ldr  r1, =GPIOC_OSPEEDR
	strh r0, [r1]

	@ save LED address to r1
	@ save fingers information to r2
	ldr  r1, =GPIOA_ODR
	ldr  r2, =GPIOC_IDR
	@ldr  r2, [r2]
	bx   lr

run:
	push  { lr }
	bl    check_button
	pop   { lr }
	cmp   r6, #1
	bne   no_check_password

	push  { lr }
	bl    check_password
	pop   { lr }

	teq   r0, #0
	beq   password_unmatch

password_match:
    mov   r9, #3
    push  { lr }
    bl    blink
    pop   { lr }
    b     password_checking_done

password_unmatch:
	mov   r9, #1
	push  { lr }
	bl    blink
	pop   { lr }

password_checking_done:
	mov r6, #0
	mov r8, #0

no_check_password:
	b run

delay:
	ldr r3, =DELAY_TIME
loop1:
	sub r3, r3, #1
	cmp r3, #0
	bne loop1

	bx lr

blink:
loop2:
	// on
	mov   r10, #0b1111111111111111
	strh  r10, [r1]
	push  {lr}
	bl    delay
	pop   {lr}

	// off
	mov   r10, #0b1111111111011111
	strh  r10, [r1]

	push  {lr}
	bl    delay
	pop   {lr}

	sub   r9, r9, #1
	cmp   r9, #0
	bne   loop2
	bx    lr

check_button:
	ldr   r5, [r2]
	lsr   r5, r5, #13
	and   r5, r5, #0x1
	cmp   r5, #0
	it eq
	addeq r8, r8, #1
	cmp r5, #1
	it eq
	moveq r8, #1
	cmp r8, #1000
	it eq
	eoreq r6, r6, #1
	bx lr
