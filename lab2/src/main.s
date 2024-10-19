.cpu cortex-m0
.thumb
.syntax unified
.fpu softvfp

.data
.align 4
.global value
value: .word 0
.global source
source: .word 1, 2, 2, 4, 5, 9, 12, 8, 9, 10, 11
.global str
str: .string "HELLO, 01234 WorlD! 56789+-"



.text
.global intsub
intsub:
    movs r1, #0
check1:
    cmp  r1, #10
    bge  end1
ifcond1:
	movs r2, #2
	ands r2, r1
	cmp  r2, #2
	bne  else1
	ldr  r0, =value
	ldr  r2, [r0]
	ldr  r0, =source
	lsls r1, r1, #2
	adds r1, #4
	ldr  r3, [r0, r1]
	subs r1, #4
	adds r2, r3
	ldr  r3, [r0, r1]
	lsrs r1, r1, #2
	subs r2, r3
	ldr  r0, =value
	str  r2, [r0]
	b next1
else1:
	ldr  r0, =value
	ldr  r2, [r0]
	ldr  r0, =source
	lsls r1, r1, #2
	ldr  r3, [r0, r1]
	adds r2, r3
	lsrs r1, r1, #2
	ldr  r0, =value
	str  r2, [r0]
next1:
    adds r1, #1
    b check1
end1:
    bx lr

.global charsub
charsub:
	movs r1, #0
check2:
	ldr r0, =str
	ldrb  r2, [r0, r1]
    cmp  r2, #0
    beq  end2
ifcond2:
	ldr  r0, =str
	ldrb  r2, [r0, r1]
	cmp  r2, #0x41
	blt  next2
	cmp  r2, #0x5a
	bgt  next2
	movs r3, #0x3d
	strb  r3, [r0, r1]
next2:
    adds r1, #1
    b check2
end2:
    bx lr

.global login
login: .string "kim3244" // Make sure you put your login here.
.align 2
.global main
main:
    bl autotest // uncomment AFTER you debug your subroutines
    bl intsub
    bl charsub
    bkpt
