.cpu cortex-m0
.thumb
.syntax unified
.fpu softvfp

//===================================================================
// ECE 362 Midterm Lab Practical
//===================================================================

// RCC configuration registers
.equ  RCC,      0x40021000
.equ  AHBENR,   0x14
.equ  APB2ENR,  0x18
.equ  APB1ENR,  0x1C
.equ  GPIOFEN,  0x00400000
.equ  GPIOEEN,  0x00200000
.equ  GPIODEN,  0x00100000
.equ  GPIOCEN,  0x00080000
.equ  GPIOBEN,  0x00040000
.equ  GPIOAEN,  0x00020000

// GPIO base addresses
.equ  GPIOA,    0x48000000
.equ  GPIOB,    0x48000400
.equ  GPIOC,    0x48000800
.equ  GPIOD,    0x48000c00
.equ  GPIOE,    0x48001000
.equ  GPIOF,    0x48001400

// GPIO Registers
.equ  MODER,    0x00
.equ  OTYPER,   0x04
.equ  OSPEEDR,  0x08
.equ  PUPDR,    0x0c
.equ  IDR,      0x10
.equ  ODR,      0x14
.equ  BSRR,     0x18
.equ  LCKR,     0x1c
.equ  AFRL,     0x20
.equ  AFRH,     0x24
.equ  BRR,      0x28

// Timer base addresses
.equ  TIM1,  0x40012c00
.equ  TIM2,  0x40000000
.equ  TIM3,  0x40000400
.equ  TIM6,  0x40001000
.equ  TIM7,  0x40001400
.equ  TIM14, 0x40002000
.equ  TIM15, 0x40014000
.equ  TIM16, 0x40014400
.equ  TIM17, 0x40014800

.equ  TIM_CR1,   0x00
.equ  TIM_CR2,   0x04
.equ  TIM_DIER,  0x0c
.equ  TIM_SR,    0x10
.equ  TIM_EGR,   0x14
.equ  TIM_CNT,   0x24
.equ  TIM_PSC,   0x28
.equ  TIM_ARR,   0x2c

// Timer configuration register bits
.equ TIM_CR1_CEN,  1<<0
.equ TIM_DIER_UDE, 1<<8
.equ TIM_DIER_UIE, 1<<0
.equ TIM_SR_UIF,   1<<0

// NVIC configuration registers
.equ NVIC, 0xe000e000
.equ ISER, 0x100
.equ ICER, 0x180


// You will need to add your own configuration symbols as needed.


.global main
main:
    bl setup_pins
    bl setup_timer
endless: // Do nothing else
    wfi
    b endless

.global setup_pins
setup_pins:
    push    {lr}

	ldr  r0, =RCC
	ldr  r1, [r0, #AHBENR]
	ldr  r2, =GPIOBEN
	orrs r1, r2
	ldr  r2, =GPIOCEN
	orrs r1, r2
	ldr  r2, =GPIOFEN
	orrs r1, r2
	str  r1, [r0, #AHBENR]

    ldr  r0,=GPIOB
    ldr  r1, [r0, #MODER]
    ldr  r2,=0xffaa
    bics r1, r2
    ldr  r2,=0x55
    orrs r1, r2
    str  r1, [r0, #MODER]

    ldr  r0,=GPIOC
    ldr  r1, [r0, #MODER]
    ldr  r2,=0x2aaaaa
    bics r1, r2
    ldr  r2,=0x155555
    orrs r1, r2
    str  r1, [r0, #MODER]

    ldr  r0,=GPIOF
    ldr  r1, [r0, #MODER]
    ldr  r2,=0xdf22ce0c
    bics r1, r2
    ldr  r2,=0x40110100
    orrs r1, r2
    str  r1, [r0, #MODER]

    ldr  r0,=GPIOB
    ldr  r1, [r0, #PUPDR]
    ldr  r2,=0xaa00
    orrs r1, r2
    ldr  r2,=0x5500
    bics r1, r2
    str  r1, [r0, #PUPDR]

    ldr  r0,=GPIOF
    ldr  r1, [r0, #PUPDR]
    ldr  r2,=0xa801101
    orrs r1, r2
    ldr  r2,=0x5402202
    bics r1, r2
    str  r1, [r0, #PUPDR]

	ldr  r3, =0xe
	ldr  r0, =GPIOB
    str  r3, [r0, #BRR]
	ldr  r3, =0x1
	ldr  r0, =GPIOB
    str  r3, [r0, #BSRR]

	ldr  r3, =0x1
	ldr  r0, =GPIOC
    str  r3, [r0, #BRR]

    pop     {pc}

.global setup_timer
setup_timer:
    push    {lr}
	ldr  r0, =RCC
	ldr  r1, [r0, #APB2ENR]
	ldr  r2, =0x10000
	orrs r1, r2
	str  r1, [r0, #APB2ENR]

	ldr  r0, =TIM16
	ldr  r1, =23999
	str  r1, [r0, #TIM_PSC]
	ldr  r1, =2122
	str  r1, [r0, #TIM_ARR]

	ldr  r0, =TIM16
	ldr  r1, [r0, #TIM_DIER]
	ldr  r2, =TIM_DIER_UIE
	orrs r1, r2
	str  r1, [r0, #TIM_DIER]

	ldr  r0, =NVIC
	ldr  r1, =ISER
	ldr  r2, =(1<<21)
	str  r2, [r0, r1]

	ldr  r0, =TIM16
	ldr  r1, [r0, #TIM_CR1]
	ldr  r2, =TIM_CR1_CEN
	orrs r1, r2
	str  r1, [r0, #TIM_CR1]
    pop     {pc}

.global TIM16_IRQHandler
.type TIM16_IRQHandler, %function
TIM16_IRQHandler:
	push  {lr}

	ldr  r0, =TIM16
	ldr  r1, [r0, #TIM_SR]
	ldr  r2, =TIM_SR_UIF
	bics r1, r2
	str  r1, [r0, #TIM_SR]

	ldr  r0, =GPIOC
    ldr  r1, [r0, #ODR]
	ldr  r2, =0x100
	adds r1, r2
    str  r1, [r0, #ODR]

	ldr  r0, =GPIOB
    ldr  r1, [r0, #IDR]
	movs r2, 0xf0
	ands r1, r2
	lsrs r1, r1, #4

	ldr  r0, =GPIOC
    str  r1, [r0, #BSRR]
    mvns r1, r1
    str  r1, [r0, #BRR]

	pop   {pc}

