.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb

//==================================================================
// ECE 362 Lab Experiment 4
// Interrupts
//==================================================================

// RCC configuration registers
.equ  RCC,      0x40021000
.equ  AHBENR,   0x14
.equ  GPIOCEN,  0x00080000
.equ  GPIOBEN,  0x00040000
.equ  GPIOAEN,  0x00020000
.equ  APB2ENR,  0x18
.equ  SYSCFGCOMPEN, 1

// GPIO configuration registers
.equ  GPIOC,    0x48000800
.equ  GPIOB,    0x48000400
.equ  GPIOA,    0x48000000
.equ  MODER,    0x00
.equ  PUPDR,    0x0c
.equ  IDR,      0x10
.equ  ODR,      0x14
.equ  BSRR,     0x18
.equ  BRR,      0x28

// SYSCFG constrol registers
.equ SYSCFG, 0x40010000
.equ EXTICR1, 0x08
.equ EXTICR2, 0x0c
.equ EXTICR3, 0x10
.equ EXTICR4, 0x14

// External interrupt control registers
.equ EXTI, 0x40010400
.equ IMR, 0
.equ EMR, 0x4
.equ RTSR, 0x8
.equ FTSR, 0xc
.equ SWIER, 0x10
.equ PR, 0x14

// Variables to register things for EXTI on pin 0
.equ EXTI_RTSR_TR0, 1<<0
.equ EXTI_IMR_MR0,  1<<0
.equ EXTI_PR_PR0,   1<<0
// Variables to register things for EXTI on pin 1
.equ EXTI_RTSR_TR1, 1<<1
.equ EXTI_IMR_MR1,  1<<1
.equ EXTI_PR_PR1,   1<<1
// Variables to register things for EXTI on pin 2
.equ EXTI_RTSR_TR2, 1<<2
.equ EXTI_IMR_MR2,  1<<2
.equ EXTI_PR_PR2,   1<<2
// Variables to register things for EXTI on pin 3
.equ EXTI_RTSR_TR3, 1<<3
.equ EXTI_IMR_MR3,  1<<3
.equ EXTI_PR_PR3,   1<<3
// Variables to register things for EXTI on pin 4
.equ EXTI_RTSR_TR4, 1<<4
.equ EXTI_IMR_MR4,  1<<4
.equ EXTI_PR_PR4,   1<<4

// SysTick counter variables....
.equ STK, 0xe000e010
.equ CSR, 0x0
.equ RVR, 0x4
.equ CVR, 0x8

// NVIC configuration registers
.equ NVIC, 0xe000e000
.equ ISER, 0x100
.equ ICER, 0x180
.equ ISPR, 0x200
.equ ICPR, 0x280
.equ IPR,  0x400
.equ EXTI0_1_IRQn,5  // External interrupt number for pins 0 and 1 is IRQ 5.
.equ EXTI2_3_IRQn,6  // External interrupt number for pins 2 and 3 is IRQ 6.
.equ EXTI4_15_IRQn,7 // External interrupt number for pins 4 - 15 is IRQ 7.

// GPIO configuration registers
.equ  GPIOC,    0x48000800
.equ  GPIOB,    0x48000400
.equ  GPIOA,    0x48000000
.equ  MODER,    0x00
.equ  PUPDR,    0x0c
.equ  IDR,      0x10
.equ  ODR,      0x14
.equ  BSRR,     0x18
.equ  BRR,      0x28

//==========================================================
// gcd  (autotest #1)
// Euclid's algorithm for Greatest Common Denominator
// Find the GCD for the first two parameters.
// Parameter2 1 and 2 are unsigned integers
// Write the entire subroutine below.
.global gcd
gcd:
    push    {lr}
gcd_check:
	cmp  r0, r1
	beq  gcd_end
gcd_if:
	cmp  r0, r1
	blo  gcd_else
	subs r0, r1
	b    gcd_check
gcd_else:
	subs r1, r0
	b    gcd_check
gcd_end:
	movs r0, r0
    pop     {pc}

//==========================================================
// enable_ports  (autotest #2)
// Enable the RCC clock for GPIO ports A, B, and C.
// Parameters: none
// Write the entire subroutine below.
.global enable_ports
enable_ports:
    push    {lr}
	ldr  r0, =RCC
	ldr  r1, [r0, #AHBENR]
	ldr  r2, =GPIOBEN
	ldr  r3, =GPIOCEN
	orrs r2, r3
	orrs r1, r2
	str  r1, [r0, #AHBENR]
    pop     {pc}

//==========================================================
// port_c_output  (autotest #3)
// Configure PC6, PC7, PC8, and PC9 to be outputs.
// Do not modify any other pin configuration.
// Parameters: none
// Write the entire subroutine below.
.global port_c_output
port_c_output:
    push    {lr}
    ldr  r0,=GPIOC
    ldr  r1,[r0,#MODER]
    ldr  r2,=0x55000
    orrs r1, r2
    str  r1, [r0,#MODER]
    pop     {pc}

//==========================================================
// port_b_input  (autotest #4)
// Configure PB2, PB3, and PB4 to be inputs.
// Enable the pull-down resistor for PB2.
// Do not modify any other pin's configuration.
// Parameters: none
// Write the entire subroutine below.
.global port_b_input
port_b_input:
    push    {lr}
    ldr  r0,=GPIOB
    ldr  r1,[r0,#MODER]
    ldr  r2,=0x3F0
    bics r1, r2
    str  r1, [r0,#MODER]

    ldr  r1,[r0,#PUPDR]
    ldr  r2,=0x20
    orrs r1, r2
    ldr  r2,=0x10
    bics r1, r2
    str  r1, [r0,#PUPDR]

    pop     {pc}

//==========================================================
// toggle_portc_pin  (autotest #5)
// Change the ODR value from 0 to 1 or 1 to 0 for a specified
// pin of Port C.
// Parameters: r0 holds the pin number to toggle
// Write the entire subroutine below.
.global toggle_portc_pin
toggle_portc_pin:
	push	{r4, lr}
	ldr  r1,=GPIOC
	movs r2, #1
    lsls r2, r2, r0
    ldr  r3, [r1, #ODR]
    movs r4, r3
    ands r3, r2
    cmp  r3, r2
    beq    toggle_portc_pin_off
toggle_portc_pin_on:
	str r2,[r1,#BSRR]
	pop		{r4, pc}
toggle_portc_pin_off:
	str r2,[r1,#BRR]
	pop		{r4, pc}

//==========================================================
// SysTick_Handler  (autotest #6)
// The ISR for the SysTick interrupt.
// Call toggle_portc_pin(7).
// Parameters: none
//
.global SysTick_Handler
.type SysTick_Handler, %function
SysTick_Handler:
	push {lr}
	// Student code goes below
	movs r0, #7
	bl   toggle_portc_pin
	// Student code goes above
	pop  {pc}

//==========================================================
// enable_systick  (autotest #7)
// Enable the SysTick interrupt to occur every 0.5 seconds.
// Parameters: none
.global enable_systick
enable_systick:
	push {lr}
	// Student code goes below
	ldr  r0, =STK
	ldr  r1, =0x0
	str  r1, [r0,#CVR]
	ldr  r1, =0x2DC6BF
	str  r1, [r0,#RVR]
	movs r1, #3
	str  r1, [r0,#CSR]
	// Student code goes above
	pop  {pc}

//==========================================================
//  (autotest #8)
// Write the EXTI interrupt handler for pins 2 and 3 below.
// Copy the name from startup/startup_stm32.s, create a label
// of that name below, declare it to be global, and declare
// it to be a function.
// It acknowledge the pending bit for pin 3, and it should
// call toggle_portc_pin(8).
.global EXTI2_3_IRQHandler
.type EXTI2_3_IRQHandler, %function
EXTI2_3_IRQHandler:
	push  {lr}
	ldr  r0, =EXTI
	movs r1, #EXTI_PR_PR3
	str  r1, [r0, #PR]
	movs r0, #8
	bl   toggle_portc_pin
	pop   {pc}
//==========================================================
//  (autotest #9)
// Write the EXTI interrupt handler for pins 4-15 below.
// It should acknowledge the pending bit for pin4, and it
// should call toggle_portc_pin(9).
.global EXTI4_15_IRQHandler
.type EXTI4_15_IRQHandler, %function
EXTI4_15_IRQHandler:
	push  {lr}
	ldr  r0, =EXTI
	movs r1, #EXTI_PR_PR4
	str  r1, [r0, #PR]
	movs r0, #9
	bl   toggle_portc_pin
	pop   {pc}
//==========================================================
// enable_exti  (autotest #10)
// Enable the SYSCFG subsystem, and select Port B for
// pins 2, 3, and 4.
// Parameters: none
.global enable_exti
enable_exti:
	push {lr}
	// Student code goes below
	ldr  r0, =RCC
	ldr  r1, [r0, #APB2ENR]
	ldr  r2, =SYSCFGCOMPEN
	orrs r1, r2
	str  r1, [r0, #APB2ENR]

	ldr  r0, =SYSCFG
	ldr  r1, =0x100000000
	str  r1, [r0, #EXTICR1]
	// Student code goes above
	pop  {pc}

//==========================================================
// init_rtsr  (autotest #11)
// Configure the EXTI_RTSR register so that an EXTI
// interrupt is generated on the rising edge of
// pins 2, 3, and 4.
// Parameters: none
.global init_rtsr
init_rtsr:
	push {lr}
	// Student code goes below
	ldr  r0, =EXTI
	ldr  r1, =EXTI_RTSR_TR2
	ldr  r2, =EXTI_RTSR_TR3
	orrs r1, r2
	ldr  r2, =EXTI_RTSR_TR4
	orrs r1, r2
	ldr  r3, [r0, #RTSR]
	orrs r1, r3
	str  r1, [r0, #RTSR]
	// Student code goes above
	pop  {pc}

///=========================================================
// init_imr  (autotest #12)
// Configure the EXTI_IMR register so that the EXTI
// interrupts are unmasked for pins 2, 3, and 4.
// Parameters: none
.global init_imr
init_imr:
	push {lr}
	// Student code goes below
	ldr  r0, =EXTI
	ldr  r1, =EXTI_IMR_MR2
	ldr  r2, =EXTI_IMR_MR3
	orrs r1, r2
	ldr  r2, =EXTI_IMR_MR4
	orrs r1, r2
	ldr  r3, [r0, #IMR]
	orrs r1, r3
	str  r1, [r0, #IMR]


	// Student code goes above
	pop  {pc}

//==========================================================
// init_iser  (autotest #13)
// Enable the two interupts for EXTI pins 2-3 and EXTI pins 4-15.
// Don't enable any other interrupts.
// Parameters: none
.global init_iser
init_iser:
	push {lr}
	// Student code goes below
    ldr  r2,=1<<EXTI2_3_IRQn
    ldr  r0,=NVIC
    ldr  r1,=ISER
	str  r2,[r0,r1]
    ldr  r2,=1<<EXTI4_15_IRQn
    str  r2,[r0,r1]
	// Student code goes above
	pop  {pc}

//==========================================================
// adjust_priorities  (autotest #14)
// Set the priority for EXTI pins 2-3 interrupt to 192.
// Set the priority for EXTI pins 4-15 interrupt to 128.
// Do not adjust the priority for any other interrupts.
.global adjust_priorities
adjust_priorities:
	push {r4,lr}
	// Student code goes below
	ldr  r0, =NVIC
    ldr  r1, =IPR
    adds r0, r1

	ldr  r1, [r0, #4]
    ldr  r3, =#0xFF000000
    bics r1, r3

    movs r2, #16
    ldr  r3, =0xc0
    lsls r3, r3, r2

    movs r2, #24
    ldr  r4, =0x80
    lsls r4, r4, r2

    orrs r3, r4
    orrs r1, r3

    str  r1, [r0, #4]
	// Student code goes above
	pop  {r4,pc}

//==========================================================
// The main subroutine will call everything else.
// It will never return.
.global login
login: .string "kim3244" // Change to your login
.align 2
.global main
main:
	bl autotest // Uncomment when most things are working
	ldr  r0,=3000000000 // 3 billion
	ldr  r1,=750000000  // 750 million
	bl   gcd            // find the GCD
	// CHECK: Result in R0 now should be 750 million
	ldr  r0,=1125000000
	ldr  r1,=3000000000
	bl   gcd
	// CHECK: Result in R0 now should be 375 million

	bl enable_ports
	bl port_c_output
	bl port_b_input
	bl enable_systick

	bl enable_exti
	bl init_rtsr
	bl init_imr
	bl adjust_priorities
	bl init_iser

endless_loop:
	movs r0,#6
	bl   toggle_portc_pin
	ldr  r0,=4000000000
	ldr  r1,=1000
	bl   gcd
	b    endless_loop
