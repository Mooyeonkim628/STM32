.cpu cortex-m0
.thumb
.syntax unified
.fpu softvfp

.global login
login: .string "kim3244"
hello_str: .string "Hello, %s!\n"
.align  2
.global hello
hello:
	push {lr}
	ldr  r0, =hello_str
	ldr  r1, =login
	bl   printf
	pop  {pc}

showmult2_str: .string "%d * %d = %d\n"
.align  2
.global showmult2
showmult2:
	push {lr}
	movs r2, r1
	movs r1, r0
	movs r3, r1
	muls r3, r2
	ldr  r0, =showmult2_str
	bl   printf
	pop  {pc}

showmult3_str: .string "%d * %d * %d = %d\n"
.align  2
.global showmult3
showmult3:
	push {r4-r7, lr}
	sub  sp, #4
	movs r3, r2
	movs r2, r1
	movs r1, r0
	ldr  r0, =showmult3_str
	movs r4, r1
	muls r4, r2
	muls r4, r3
	str  r4, [sp, #0]
	bl   printf
	add  sp, #4
	pop  {r4-r7, pc}

listing_str: .string "%s %05d %s %d students in %s, %d\n"
.align  2
.global listing
listing:
	push {r4-r7, lr}
	sub  sp, #8
	ldr  r4, [sp,#20]
	ldr  r5, [sp,#24]
	movs r6, r5
	movs r5, r4
	movs r4, r3
	str  r4, [sp,#0]
	str  r5, [sp,#20]
	str  r6, [sp,#24]
	movs r3, r2
	movs r2, r1
	movs r1, r0
	ldr  r0, =listing_str
	bl   printf
	add  sp, #8
	pop  {r4-r7, pc}

.global trivial
trivial:
	push {r4-r7, lr}
	sub  sp, #400
	mov  r7, sp
trivial_for:
	movs r4,#0
trivial_check:
	cmp  r4, #100
	bge  trivial_end
trivial_body:
	lsls r5, r4, #2
	str  r4, [r7, r5]
trivial_next:
	adds r4, #1
	b    trivial_check
trivial_end:
trivial_if:
	cmp  r0, #100
	bcc  trivial_else
	movs r0, #99
	b    trivial_end2
trivial_else:
trivial_end2:
	lsls r6, r0, #2
	add  sp, #400
	ldr  r0, [r7, r6]
	pop  {r4-r7, pc}

.global reverse_puts
reverse_puts:
	push {r4-r7,lr}
	movs r4, r0
	bl   strlen
	adds r1, r0, #4
	movs r2, #3
	bics r1, r2
	mov  r7, sp
	subs r7, r1
	mov  sp, r7
	movs r2, #0
	strb r2, [r7, r0]
reverse_puts_for:
	movs r2, #0
reverse_puts_check:
	cmp  r0, r2
	bcc  reverse_puts_next
reverse_puts_body:
	subs r3, r0, #1
	subs r3, r3, r2
	ldrb r5, [r4, r2]
	strb r5, [r7, r3]
reverse_puts_next:
	adds r2, #1
reverse_puts_end:
	adds r7, r1
	movs r7, r0
	bl   puts
	mov  sp, r7
	pop  {r4-r7,pc}

.global my_atoi
my_atoi:
	push {r4-r7,lr}
	movs r1, #0
	movs r2, #1
	movs r3, r0
my_atoi_for1:
my_atoi_check1:
	ldrb r4, [r3]
	cmp  r4, #'-'
	bne  my_atoi_for2
my_atoi_body1:
	rsbs r2, r2, #0
my_atoi_next1:
	adds r3, #1
	b    my_atoi_check1
my_atoi_for2:
	movs r3, r0
my_atoi_check2:
	ldrb  r4, [r3]
	cmp  r4, #0
	bne  my_atoi_end
my_atoi_if:
	ldrb r4, [r3]
	cmp  r4, #'0'
	blt  my_atoi_end
	cmp  r4, #'9'
	bgt  my_atoi_end
my_atoi_body2:
	movs r5, #10
	muls r1, r5
	adds r1, r4
	subs r1, #'0'
my_atoi_next2:
	adds r3, #1
	b    my_atoi_check2
my_atoi_end:
	muls r1, r2
	movs r0, r1
	pop  {r4-r7,pc}

.global fadd
fadd:
	push {r4-r7,lr}
	bl serial_init
fadd_if1:
	cmp  r0, #0
	bne  fadd_if2
	movs r0, r1
	pop  {r4-r7,pc}
fadd_if2:
	cmp  r1, #0
	bne  fadd_else
	movs r0, r0
	pop  {r4-r7,pc}
fadd_else:
	movs r4, #1
	lsrs r2, r0, #31
	ands r2, r4
	lsrs r3, r1, #31
	ands r3, r4
fadd_if3:
	cmp  r3, r4
	beq  fadd_else2
	movs r0, #0
	pop  {r4-r7,pc}
fadd_else2:
	ldr  r4, =#0xff
	lsrs r2, r0, #23
	ands r2, r4
	lsrs r3, r0, #23
	ands r3, r4
	movs r4, #1
	lsls r4, r4, #23
	subs r4, #1
	lsrs r5, r0, #0
	ands r5, r4
	lsrs r6, r1, #0
	ands r6, r4
	adds r4, #1
	orrs r5, r4
	orrs r6, r4
	subs r2, #127
	subs r3, #127
fadd_if4:
	cmp  r2, r3
	bge  fadd_if5
	movs r4, r2
	movs r2, r3
	movs r3, r4
	movs r4, r5
	movs r5, r6
	movs r6, r4
	movs r4, r0
	movs r0, r1
	movs r1, r4
fadd_if5:
	subs r4, r2, r3
	cmp  r4, #24
	ble  fadd_else3
	pop  {r4-r7,pc}
fadd_else3:
	lsls r5, r5, #7
	lsls r6, r6, #7
	subs r4, r2, r3
	lsrs r6, r6, r4
	adds r5, r6
	movs r7, #0
fadd_if6:
	ldr  r4, =0x80000000
	movs r6, r5
	ands r6, r4
	cmp  r6, #0
	beq  fadd_else4
	movs r7, #1
fadd_else4:
	adds r7, #7
	lsrs r5, r5, r7
	subs r7, #7
	movs r4, #1
	lsls r4, r4, #23
	subs r4, #1
	ands r5, r4
	adds r2, r7
	movs r4, #1
	lsrs r3, r0, #31
	ands r3, r4
	lsls r3, r3, #31
	lsls r2, r2, #23
	movs r0, r3
	ands r0, r2
	pop  {r4-r7,pc}
