.cpu cortex-m0
.thumb
.syntax unified
.fpu softvfp

//==================================================================
// ECE 362 Lab Experiment 5
// Timers
//==================================================================

// RCC configuration registers
.equ  RCC,      0x40021000
.equ  AHBENR,   0x14
.equ  GPIOCEN,  0x00080000
.equ  GPIOBEN,  0x00040000
.equ  GPIOAEN,  0x00020000
.equ  APB1ENR,  0x1c
.equ  TIM6EN,   1<<4
.equ  TIM7EN,   1<<5

// NVIC configuration registers
.equ NVIC, 0xe000e000
.equ ISER, 0x100
.equ ICER, 0x180
.equ ISPR, 0x200
.equ ICPR, 0x280
.equ IPR,  0x400
.equ TIM6_DAC_IRQn, 17
.equ TIM7_IRQn,     18

// Timer configuration registers
.equ TIM6, 0x40001000
.equ TIM7, 0x40001400
.equ TIM_CR1,  0x00
.equ TIM_CR2,  0x04
.equ TIM_DIER, 0x0c
.equ TIM_SR,   0x10
.equ TIM_EGR,  0x14
.equ TIM_CNT,  0x24
.equ TIM_PSC,  0x28
.equ TIM_ARR,  0x2c

// Timer configuration register bits
.equ TIM_CR1_CEN,  1<<0
.equ TIM_DIER_UDE, 1<<8
.equ TIM_DIER_UIE, 1<<0
.equ TIM_SR_UIF,   1<<0

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

//==========================================================================
// enable_ports  (Autotest 1)
// Enable RCC clock for GPIO ports B and C.
// Parameters: none
// Return value: none
.global enable_ports
enable_ports:
	push {lr}
	// Student code goes below
	ldr  r0, =RCC
	ldr  r1, [r0, #AHBENR]
	ldr  r2, =GPIOBEN
	ldr  r3, =GPIOCEN
	orrs r2, r3
	orrs r1, r2
	str  r1, [r0, #AHBENR]

    ldr  r0,=GPIOB
    ldr  r1,[r0,#MODER]
    ldr  r2,=0x55
    ldr  r3,=0xAA
    bics r1, r3
    orrs r1, r2
    str  r1, [r0,#MODER]

    ldr  r0,=GPIOB
    ldr  r1,[r0,#MODER]
    ldr  r2,=0xAA00
    bics r1, r2
    str  r1, [r0,#MODER]

    ldr  r1,[r0,#PUPDR]
    ldr  r2,=0xAA00
    orrs r1, r2
    ldr  r2,=0x5500
    bics r1, r2
    str  r1, [r0,#PUPDR]

    ldr  r0,=GPIOC
    ldr  r1,[r0,#MODER]
    ldr  r2,=0x155555
 	movs r3, #0
    ands r1, r3
    orrs r1, r2
    str  r1, [r0,#MODER]
	// Student code goes above
	pop  {pc}

//==========================================================================
// Timer 6 Interrupt Service Routine  (Autotest 2)
// Parameters: none
// Return value: none
// Write your entire subroutine below
.global TIM6_DAC_IRQHandler
.type TIM6_DAC_IRQHandler, %function
TIM6_DAC_IRQHandler:
	push  {lr}
	ldr  r0, =TIM6
	ldr  r1, [r0,#TIM_SR]
	ldr  r2, =TIM_SR_UIF
	bics r1, r2
	str  r1, [r0,#TIM_SR]

	ldr  r1, =GPIOC
	movs r2, #1
    lsls r2, r2, #6
    ldr  r3, [r1, #ODR]
    movs r4, r3
    ands r3, r2
    cmp  r3, r2
    beq    toggle_portc_pin_off
toggle_portc_pin_on:
	str r2, [r1, #BSRR]
	pop		{pc}
toggle_portc_pin_off:
	str r2, [r1, #BRR]
	pop		{pc}

//==========================================================================
// setup_tim6  (Autotest 3)
// Configure timer 6
// Parameters: none
// Return value: none
.global setup_tim6
setup_tim6:
	push {lr}
	// Student code goes below
	ldr  r0, =RCC
	ldr  r1, [R0, #APB1ENR]
	ldr  r2, =TIM6EN
	orrs r1, r2
	str  r1, [r0, #APB1ENR]

	ldr  r0, =TIM6
	ldr  r1, =47999
	str  r1, [r0, #TIM_PSC]
	ldr  r1, =499
	str  r1, [r0, #TIM_ARR]

	ldr  r0, =TIM6
	ldr  r1, [r0, #TIM_DIER]
	ldr  r2, =TIM_DIER_UIE
	orrs r1, r2
	str  r1, [r0, #TIM_DIER]

	ldr  r0, =TIM6
	ldr  r1, [r0, #TIM_CR1]
	ldr  r2, =TIM_CR1_CEN
	orrs r1, r2
	str  r1, [r0, #TIM_CR1]

	ldr  r0, =NVIC
	ldr  r1, =ISER
	ldr  r2, =(1<<TIM6_DAC_IRQn)
	str  r2, [r0, r1]
	// Student code goes above
	pop  {pc}

.data
.global display
display: .byte 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07
.global history
history: .space 16
.global offset
offset: .byte 0
.text

//==========================================================================
// show_digit  (Autotest 4)
// Setup Port C outputs to show the digit for the current
// value of the offset variable.
// Parameters: none
// Return value: none
// Write your entire subroutine below.
.global show_digit
show_digit:
	push {lr}
	// Student code goes below
	movs r0, #7
	ldr  r1, =offset
	ldr  r2, [r1]
	ands r0, r2

    ldr  r2, =display
    ldrb  r3, [r2, r0]
    lsls r0, r0, #8
   	orrs r0, r3

	ldr  r1, =GPIOC
    str  r0, [r1, #ODR]
	// Student code goes above
	pop   {pc}

//==========================================================================
// get_cols  (Autotest 5)
// Return the current value of the PC8 - PC4 pins.
// Parameters: none
// Return value: 4-bit result of columns active for the selected row
// Write your entire subroutine below.
.global get_cols
get_cols:
	push {lr}
	// Student code goes below
	ldr  r1, =GPIOB
	ldr  r0, [r1, #IDR]
	lsrs r0, r0, #4
	ldr  r3, =0xf
	ands r0, r3
	// Student code goes above
	pop  {pc}

//==========================================================================
// update_hist  (Autotest 6)
// Update history byte entries for the current row.
// Parameters: r0: cols: 4-bit value read from matrix columns
// Return value: none
// Write your entier subroutine below.
.global update_hist
update_hist:
	push {r4-r7,lr}
	// Student code goes below
	ldr  r2, =offset
	ldr  r3, [r2]
	movs r4, #3
	ands r3, r4//r3 = row
update_hist_for:
	movs r1, #0 //r1 = i
update_hist_check:
	cmp  r1, #4
	bge  update_hist_end
update_hist_body:
	movs r5, r3
	movs r4, #4
	muls r5, r4
	adds r5, r1
	ldr  r7, =history
	ldrb r6, [r7, r5]
	lsls r6, r6, #1
	movs r2, r0
	lsrs r2, r1
	movs r4, #1
	ands r2, r4
	adds r6, r2
	strb r6, [r7, r5]
update_hist_next:
	adds r1, #1
	b    update_hist_check
update_hist_end:
	// Student code goes above
	pop  {r4-r7,pc}
//==========================================================================
// set_row  (Autotest 7)
// Set PB3 - PB0 to represent the row being scanned.
// Parameters: none
// Return value: none
// Write your entire subroutine below.
.global set_row
set_row:
	push {lr}
	// Student code goes below
	ldr  r0, =offset
	ldr  r1, [r0]
	movs r0, #3
	ands r0, r1
	movs r2, #1
	lsls r2, r2, r0

	ldr  r1, =GPIOB
	ldr  r0, =0xf0000
	orrs r0, r2
	str  r0, [r1, #BSRR]
	// Student code goes above
	pop  {pc}

//==========================================================================
// Timer 7 Interrupt Service Routine  (Autotest 8)
// Parameters: none
// Return value: none
// Write your entire subroutine below
.global TIM7_IRQHandler
.type TIM7_IRQHandler, %function
TIM7_IRQHandler:
	push  {lr}

	ldr  r0, =TIM7
	ldr  r1, [r0, #TIM_SR]
	ldr  r2, =TIM_SR_UIF
	bics r1, r2
	str  r1, [r0, #TIM_SR]

	bl   show_digit
	bl   get_cols
	bl   update_hist

	ldr  r0, =offset
	ldr  r1, [r0]
	adds r1, #1
	ldr  r2, =0x7
	ands r1, r2
	strb r1, [r0]

	bl	 set_row

	pop	 {pc}

//==========================================================================
// setup_tim7  (Autotest 9)
// Configure Timer 7.
// Parameters: none
// Return value: none
.global setup_tim7
setup_tim7:
	push {lr}
	// Student code goes below
	ldr  r0, =RCC
	ldr  r1, [R0, #APB1ENR]
	ldr  r2, =TIM7EN
	orrs r1, r2
	ldr  r2, =TIM6EN
	bics r1, r2
	str  r1, [r0, #APB1ENR]

	ldr  r0, =TIM7
	ldr  r1, =479
	str  r1, [r0, #TIM_PSC]
	ldr  r1, =99
	str  r1, [r0, #TIM_ARR]

	ldr  r0, =TIM7
	ldr  r1, [r0, #TIM_DIER]
	ldr  r2, =TIM_DIER_UIE
	orrs r1, r2
	str  r1, [r0, #TIM_DIER]

	ldr  r0, =NVIC
	ldr  r1, =ISER
	ldr  r2, =(1<<TIM7_IRQn)
	str  r2, [r0, r1]

	ldr  r0, =TIM7
	ldr  r1, [r0, #TIM_CR1]
	ldr  r2, =TIM_CR1_CEN
	orrs r1, r2
	str  r1, [r0, #TIM_CR1]
	// Student code goes above
	pop  {pc}


//==========================================================================
// get_keypress  (Autotest 10)
// Wait for and return the number (0-15) of the ID of a button pressed.
// Parameters: none
// Return value: button ID
.global get_keypress
get_keypress:
	push {lr}
	// Student code goes below
get_keypress_for1:
get_keypress_body:
	wfi
get_keypress_if:
	ldr  r0, =offset
	ldr  r1, [r0]
	movs r0, #3
	ands r0, r1
	cmp  r0, #0
	bne  get_keypress_for1
get_keypress_for2:
	movs r0, #0
get_keypress_check:
	cmp  r0, #16
	bge  get_keypress_for1
get_keypress_body2:
	ldr  r1, =history
	ldrb r2, [r1, r0]
	cmp  r2, #1
	beq  get_keypress_end
get_keypress_next:
	adds r0, #1
	b    get_keypress_check
get_keypress_end:
	// Student code goes above
	pop  {pc}

//==========================================================================
// handle_key  (Autotest 11)
// Shift all symbols in the display left and add a new digit
// in the rightmost digit.
// ALSO: Create your "font" array just above.
// Parameters: ID of new button to display
// Return value: none
.data
.global font
font: .byte 0x06,0x5b,0x4f,0x77,0x66,0x6d,0x7d,0x7c,0x07,0x7f,0x67,0x39,0x49,0x3f,0x76,0x5e
.text

.global handle_key
handle_key:
	push {r4-r7,lr}
	// Student code goes below
	ldr  r1, =0xf
	ands r0, r1 //r0 = key&0xf
handle_key_for:
	movs r1, #0 //r1=i
handle_key_check:
	cmp  r1, #7
	bge  handle_key_end
handle_key_body:
	ldr  r2, =display
	adds r3, r1, #1
	ldrb r4, [r2, r3]
	strb r4, [r2, r1]
handle_key_next:
	adds r1, #1
	b    handle_key_check
handle_key_end:
	ldr  r1, =font
	ldrb r5, [r1, r0]
	strb r5, [r2, #7]
	// Student code goes above
	pop  {r4-r7,pc}

.global login
login: .string "kim3244"
.align 2

//==========================================================================
// main
// Already set up for you.
// It never returns.
.global main
main:
	//bl  check_wiring
	bl  autotest
	bl  enable_ports
	bl  setup_tim6
	bl  setup_tim7

endless_loop:
	bl   get_keypress
	bl   handle_key
	b    endless_loop
