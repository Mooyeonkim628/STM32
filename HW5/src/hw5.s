.cpu cortex-m0
.thumb
.syntax unified
.fpu softvfp

.equ RCC,       0x40021000
.equ GPIOA,     0x48000000
.equ GPIOB,     0x48000400
.equ GPIOC,     0x48000800
.equ AHBENR,    0x14
.equ APB2ENR,   0x18
.equ APB1ENR,   0x1c
.equ IOPAEN,    0x20000
.equ IOPBEN,    0x40000
.equ IOPCEN,    0x80000
.equ SYSCFGCOMPEN, 1
.equ TIM3EN,    2
.equ MODER,     0x00
.equ OSPEEDR,   0x08
.equ PUPDR,     0x0c
.equ IDR,       0x10
.equ ODR,       0x14
.equ BSRR,      0x18
.equ BRR,       0x28
.equ PC8,       0x100

// SYSCFG control registers
.equ SYSCFG,    0x40010000
.equ EXTICR1,   0x08
.equ EXTICR2,   0x0c
.equ EXTICR3,   0x10
.equ EXTICR4,   0x14

// NVIC control registers
.equ NVIC,      0xe000e000
.equ ISER,      0x100

// External interrupt control registers
.equ EXTI,      0x40010400
.equ IMR,       0
.equ RTSR,      0x8
.equ PR,        0x14

.equ TIM3,      0x40000400
.equ TIMCR1,    0x00
.equ DIER,      0x0c
.equ TIMSR,     0x10
.equ PSC,       0x28
.equ ARR,       0x2c

// Popular interrupt numbers
.equ EXTI0_1_IRQn,   5
.equ EXTI2_3_IRQn,   6
.equ EXTI4_15_IRQn,  7
.equ EXTI4_15_IRQn,  7
.equ TIM2_IRQn,      15
.equ TIM3_IRQn,      16
.equ TIM6_DAC_IRQn,  17
.equ TIM7_IRQn,      18
.equ TIM14_IRQn,     19
.equ TIM15_IRQn,     20
.equ TIM16_IRQn,     21
.equ TIM17_IRQn,     22


//====================================================================
// Q1
//====================================================================
.global subfoo
subfoo:
subfoo_if:
	push {lr}
	movs  r0,#222
	movs r1, #2
	cmp  r0, r1
	bcs  subfoo_if2
	movs r0, #0
	pop  {pc}
subfoo_if2:
	movs r1, #1
	movs r3, r0
	ands r3, r1
	cmp  r3, #0
	bne  subfoo_end
	subs r0, #1
	bl   subfoo
	adds r0, #2
	pop  {pc}
subfoo_end:
	lsrs r0, r0, #1
	bl   subfoo
	adds r0, #1
	pop  {pc}

//====================================================================
// Q2
//====================================================================
.global enable_portb
enable_portb:
    push    {lr}
	ldr  r0, =RCC
	ldr  r1, [r0, #AHBENR]
	ldr  r2, =IOPBEN
	orrs r1, r2
	str  r1, [r0, #AHBENR]
    pop     {pc}
//====================================================================
// Q3
//====================================================================
.global enable_portc
enable_portc:
    push    {lr}
	ldr  r0, =RCC
	ldr  r1, [r0, #AHBENR]
	ldr  r2, =IOPCEN
	orrs r1, r2
	str  r1, [r0, #AHBENR]
    pop     {pc}
//====================================================================
// Q4
//====================================================================
.global setup_pb3
setup_pb3:

    ldr  r0,=GPIOB
    ldr  r1, [r0, #MODER]
    ldr  r2,=0xc0
    bics r1, r2
    str  r1, [r0, #MODER]

    ldr  r0,=GPIOB
    ldr  r1, [r0, #PUPDR]
    ldr  r2,=0x80
    orrs r1, r2
    ldr  r2,=0x40
    bics r1, r2
    str  r1, [r0, #PUPDR]
    bx   lr
//====================================================================
// Q5
//====================================================================
.global setup_pb4
setup_pb4:
    push    {lr}
    ldr  r0,=GPIOB
    ldr  r1,[r0,#MODER]
    ldr  r2,=0x300
    bics r1, r2
    str  r1, [r0,#MODER]

    ldr  r1,[r0,#PUPDR]
    ldr  r2,=0x300
    bics r1, r2
    str  r1, [r0,#PUPDR]
    pop     {pc}
//====================================================================
// Q6
//====================================================================
.global setup_pc8
setup_pc8:
    push    {lr}
    ldr  r0, =GPIOC
    ldr  r1, [r0,#MODER]
    ldr  r2, =0x10000
    orrs r1, r2
    ldr  r2, =0x20000
    bics r1, r2

    str  r1, [r0,#MODER]
    ldr  r1, [r0,#OSPEEDR]
    ldr  r2, =0x30000
    orrs r1, r2
    str  r1, [r0,#OSPEEDR]
    pop     {pc}
//====================================================================
// Q7
//====================================================================
.global setup_pc9
setup_pc9:
    push    {lr}
    ldr  r0, =GPIOC
    ldr  r1, [r0,#MODER]
    ldr  r2, =0x40000
    orrs r1, r2
    ldr  r2, =0x80000
    bics r1, r2

    str  r1, [r0,#MODER]
    ldr  r1, [r0,#OSPEEDR]
    ldr  r2, =0x40000
    orrs r1, r2
    ldr  r2, =0x80000
    bics r1, r2
    str  r1, [r0,#OSPEEDR]
    pop     {pc}
//====================================================================
// Q8
//====================================================================
.global action8
action8:
	push	{lr}
	ldr  r0, =GPIOB
    ldr  r1, [r0, #IDR]
    ldr  r2, [r0, #IDR]

    lsrs r1, r1, #3
    movs r0, #1
	ands r1, r0

    lsrs r2, r2, #4
    movs r0, #1
	ands r1, r0

	cmp  r1, #1
	bne  action8_else
	cmp  r2, #0
	bne  action8_else

	movs r0, #1
	lsls r0, r0, #8
	bics r3, r0
	ldr  r0, =GPIOC
    str  r3, [r0, #ODR]
 	pop		{pc}
action8_else:
	movs r0, #1
	lsls r0, r0, #8
	orrs r3, r0
	ldr  r0, =GPIOC
    str  r3, [r0, #ODR]
	pop		{pc}
//====================================================================
// Q9
//====================================================================
.global action9
action9:
	push	{r4, lr}
	ldr  r0, =GPIOB
    ldr  r1, [r0, #IDR]
    ldr  r2, [r0, #IDR]
	ldr  r0, =GPIOC
    ldr  r3, [r0, #ODR]

    lsrs r1, r1, #3
    movs r4, #1
	ands r1, r4

    lsrs r2, r2, #4
    movs r4, #1
	ands r1, r4

	cmp  r1, #0
	bne  action9_else
	cmp  r2, #1
	bne  action9_else

	movs r4, #1
	lsls r4, r4, #9
	orrs r3, r4
	ldr  r0, =GPIOC
    str  r3, [r0, #ODR]
	pop {r4, pc}
action9_else:
	movs r4, #1
	lsls r4, r4, #9
	bics r3, r4
	ldr  r0, =GPIOC
    str  r3, [r0, #ODR]
	pop {r4, pc}
//====================================================================
// Q10
//====================================================================
// Do everything needed to write the ISR here...
.global EXTI2_3_IRQHandler
.type EXTI2_3_IRQHandler, %function
EXTI2_3_IRQHandler:
	push  {lr}
	ldr  r0, =EXTI
	movs r1, #1<<3
	str  r1, [r0, #PR]
	ldr  r2, =counter
	ldr  r3, [r2]
	adds r3, #1
	str  r3, [r2]
	pop   {pc}
//====================================================================
// Q11
//====================================================================
.global enable_exti
enable_exti:
	push {lr}
	ldr  r0, =RCC
	ldr  r1, [r0, #APB2ENR]
	ldr  r2, =SYSCFGCOMPEN
	orrs r1, r2
	str  r1, [r0, #APB2ENR]

	ldr  r0, =SYSCFG
	ldr  r1, =0x100
	ldr  r3, [r0, #EXTICR1]
	orrs r1, r3
	ldr  r3, =0x600
	bics r1, r3
	str  r1, [r0, #EXTICR1]

	ldr  r0, =EXTI
	ldr  r1, =1<<2
	ldr  r3, [r0, #RTSR]
	orrs r1, r3
	str  r1, [r0, #RTSR]
	ldr  r1, =1<<2
	ldr  r3, [r0, #IMR]
	orrs r1, r3
	str  r1, [r0, #IMR]

	ldr  r0, =NVIC
	ldr  r1, =ISER
	ldr  r2, =(1<<EXTI2_3_IRQn)
	str  r2, [r0, r1]

	pop  {pc}
//====================================================================
// Q12
//====================================================================
// Do everything needed to write the ISR here...
.global TIM3_IRQHandler
.type TIM3_IRQHandler, %function
TIM3_IRQHandler:
	push  {lr}
	ldr  r0, =TIM3
	ldr  r1, [r0, #TIMSR]
	ldr  r2, =0x1
	bics r1, r2
	str  r1, [r0, #TIMSR]
	ldr  r1,=GPIOC
	movs r2, #1
    lsls r2, r2, #9
    ldr  r3, [r1, #ODR]
    ands r3, r2
    cmp  r3, r2
    beq    toggle_portc_pin_off
toggle_portc_pin_on:
	str r2, [r1, #BSRR]
	pop		{pc}
toggle_portc_pin_off:
	str r2, [r1, #BRR]
	pop		{pc}
//====================================================================
// Q13
//====================================================================
.global enable_tim3
enable_tim3:

	push {lr}

	ldr  r0, =RCC
	ldr  r1, [R0, #APB1ENR]
	ldr  r2, =TIM3EN
	orrs r1, r2
	str  r1, [r0, #APB1ENR]

	ldr  r0, =TIM3
	ldr  r1, =19999
	str  r1, [r0, #PSC]
	ldr  r1, =599
	str  r1, [r0, #ARR]

	ldr  r0, =TIM3
	ldr  r1, [r0, #12]
	ldr  r2, =1
	orrs r1, r2
	str  r1, [r0, #12]

	ldr  r0, =NVIC
	ldr  r1, =ISER
	ldr  r2, =(1<<TIM3_IRQn)
	str  r2, [r0, r1]

	ldr  r0, =TIM3
	ldr  r1, [r0, #0]
	ldr  r2, =1
	orrs r1, r2
	str  r1, [r0, #0]

	pop  {pc}
