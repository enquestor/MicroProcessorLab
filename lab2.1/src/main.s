	.syntax unified
	.cpu cortex-m4
	.thumb

.data
	result: .zero 8

.text
	.global main
	.equ X, 0x12345678
	.equ Y, 0xABCDEF00

main:
	ldr R0, =X
	ldr R1, =Y
	ldr R2, =result
	bl kara_mul
	str R8, [R2]
	str R9, [R2, #4]

L: b L

# store result in R8(high), R9(low)
kara_mul:
	mov R8, #0
	mov R9, #0

	# X left
	mov R4, R0
	# X right
	mov R5, R0
	lsr R4, #16
	lsl R5, #16
	lsr R5, #16

	# Y left
	mov R6, R1
	# Y right
	mov R7, R1
	lsr R6, #16
	lsl R7, #16
	lsr R7, #16

	# XL * YL * 2^32
	mul R8, R4, R6

	# XL + XR
	add R10, R4, R5
	add R11, R6, R7
	mul R3, R10, R11

	mul R10, R4, R6
	mul R11, R5, R7
	add R10, R10, R11
	sub R3, R3, R10

	mov R10, R3
	lsr R10, #16
	add R8, R10

	mov R10, R3
	lsl R10, #16
	add R9, R10

	# XR * YR
	mul R3, R5, R7
	adds R9, R9, R3
	IT CS
	addcs R8, R8, #1

	bx lr
