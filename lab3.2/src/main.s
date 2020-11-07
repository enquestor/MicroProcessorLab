	.syntax unified
	.cpu cortex-m4
	.thumb

.text
.global main
	.equ RCC_AHB2ENR, 0x4002104C
	@ .equ GPIOA_MODER, 0x48000000
	@ .equ GPIOA_OTYPER, 0x48000004
	@ .equ GPIOA_OSPEEDR, 0x48000008
	@ .equ GPIOA_PUPDR, 0x4800000C
	@ .equ GPIOA_ODR, 0x48000014

	.equ GPIOB_MODER  , 0x48000400
	.equ GPIOB_OTYPER , 0x48000404
	.equ GPIOB_OSPEEDR, 0x48000408
	.equ GPIOB_PUPDR  , 0x4800040C
	.equ GPIOB_ODR    , 0x48000414

	.equ GPIOC_MODER  , 0x48000800
	.equ GPIOC_OTYPER ,	0x48000804
	.equ GPIOC_OSPEEDR,	0x48000808
	.equ GPIOC_PUPDR  ,	0x4800080c
	.equ GPIOC_IDR    , 0x48000810

	.equ DELAY_TIME, 0x2FFFF

main:
	bl gpio_init

led:
@ update led
	strh  r7, [r1]
	bl delay
	teq r6,   #0
	IT EQ
	beq led

@ r2 = 0 indicates led going left
@      1                     right
	teq   r2, #0
	ITE EQ
	roreq r0, #31  @ rotate left
	rorne r0, #1   @ rotate right

@ let r7 = r0[1:4]
	mov   r7, r0
	lsr   r7, #1
	and   r7, #0x0F
	lsl   r7, #3

@ if r7 == 0b1110000 then set r2 = 0
@          0b0111000 then set r2 = 1
	teq   r7, #0x70
	IT EQ
	moveq r2, #0
	teq   r7, #0x38
	IT EQ
	moveq r2, #1

    b led

gpio_init:
	mov r0, #0x6
	ldr r1, =RCC_AHB2ENR
	str r0, [r1]

	movs r0, #0x1540
	ldr r1, =GPIOB_MODER
	ldr r2, [r1]
	and r2, #0xFFFFC03F
	orrs r2, r2, r0
	str r2, [r1]

	movs r0, #0x2A80
	ldr r1, =GPIOB_OSPEEDR
	strh r0, [r1]

	ldr r0, =GPIOC_MODER
	ldr r1, [r0]
	and r1, r1, 0xf3ffffff
	str r1,	[r0]
	@ldr r1, =GPIOB_ODR
	ldr r4, =GPIOC_IDR

	ldr r1, =GPIOB_ODR
	mov r0, #0xFFFFFFFC @ 1...11100
	mov r7, #0x0E
	mov r2, #0
	mov r6, #1



	bx lr

delay:
	ldr r3, =DELAY_TIME
	mov r8, #0

loop:
	b check_button
	check_finish:
	sub r3, r3, #1
	cmp r3, #0
	bne loop

	bx lr

check_button:
	ldr r5, [r4]
	lsr r5, r5, #13
	and r5, r5, #0x1

	cmp r5, #0
	it eq
	addeq r8, r8, #1

	cmp r5, #1
	it eq
	moveq r8, #1

	cmp r8, #1000
	it eq
	eoreq r6, r6, #1

	@cmp r8,
	b check_finish
