	.syntax unified
	.cpu cortex-m4
	.thumb

.text
.global main
	.equ RCC_AHB2ENR, 0x4002104C

	.equ GPIOB_MODER,   0x48000400
	.equ GPIOB_OTYPER,  0x48000404
	.equ GPIOB_OSPEEDR, 0x48000408
	.equ GPIOB_PUPDR,   0x4800040C
	.equ GPIOB_ODR ,    0x48000414

	.equ DELAY_TIME,    0x3FFFF

main:
	bl gpio_init

led:
@ update led
    lsl   r7, #3
	strh  r7, [r1]
	bl    delay

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
	@lsl   r7, #3

@ if r7 == 0b0001 then set r2 = 0
@          0b1000 then set r2 = 1
	teq   r7, #0b0001
	IT EQ
	moveq r2, #0
	teq   r7, #0b1000
	IT EQ
	moveq r2, #1

    b led

gpio_init:
	mov   r0, #0x2
	ldr   r1, =RCC_AHB2ENR
	str   r0, [r1]

	mov   r0, #0x1540
	ldr   r1, =GPIOB_MODER
	ldr   r2, [r1]
	and   r2, #0xFFFFC03F
	orr   r2, r2, r0
	str   r2, [r1]

	mov   r0, #0x2A80
	ldr   r1, =GPIOB_OSPEEDR
	strh  r0, [r1]

	ldr   r1, =GPIOB_ODR
	mov   r0, #0b00011   @ 0...00011
	mov   r7, #0b0001    @ 0001
	mov   r2, #0

	bx    lr

delay:
	ldr   r3, =DELAY_TIME
loop:
	cmp   r3, #0
	sub   r3, r3, #1
	bne   loop

	bx    lr
