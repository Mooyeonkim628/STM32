
//===========================================================================
// ECE 362 lab experiment 7 -- Pulse-Width Modulation
//===========================================================================

#include "stm32f0xx.h"
#include <string.h>  // for memset() declaration
#include <math.h>    // for M_PI

// Be sure to change this to your login...
const char login[] = "kim3244";

//===========================================================================
// setup_tim1()    (Autotest #1)
// Configure Timer 1 and its PWM output pins.
// Parameters: none
//===========================================================================
void setup_tim1()
{
    RCC->AHBENR    |= RCC_AHBENR_GPIOAEN;
    GPIOA->MODER   |= 0xAA0000;

    GPIOA->AFR[1] &= ~0x0F000000;
    GPIOA->AFR[1] |= 0x2222;


    RCC->APB2ENR    |= RCC_APB2ENR_TIM1EN;
    TIM1->BDTR      |= 1<<15;

    TIM1->PSC      = 0;
    TIM1->ARR      = 2399;

    TIM1->CCMR1    |= 0x6060;
    TIM1->CCMR1    &= ~0x1<<4;

    TIM1->CCMR2    |= 0x6060;
    TIM1->CCMR2    &= ~0x1<<4;

    TIM1->CCMR2    |= 1<<11;

    TIM1->CCER     |= 1;
    TIM1->CCER     |= 1<<4;
    TIM1->CCER     |= 1<<8;
    TIM1->CCER     |= 1<<12;

    TIM1->CR1     |= TIM_CR1_CEN;
    NVIC->ISER[0]  = 1<<14;
}

//===========================================================================
// Parameters for the wavtable size and expected synthesis rate.
//===========================================================================
#define N 1000
#define RATE 20000
short int wavetable[N];

//===========================================================================
// init_wavetable()    (Autotest #2)
// Write the pattern for a complete cycle of a sine wave into the
// wavetable[] array.
// Parameters: none
//===========================================================================
void init_wavetable(void)
{
    for(int i=0; i < N; i++)
        wavetable[i] = 32767 * sin(2 * M_PI * i / N);
}

//===========================================================================
// The global variables used for four-channel synthesis.
//===========================================================================
int volume = 2048;
int stepa = 0;
int stepb = 0;
int stepc = 0;
int offseta = 0;
int offsetb = 0;
int offsetc = 0;

//===========================================================================
// set_freq_n()    (Autotest #2)
// Set the three step and three offset variables based on the frequency.
// Parameters: f: The floating-point frequency desired.
//===========================================================================
void set_freq_a(float f)
{
    if(f==0){
        stepa = 0;
        offseta = 0;
    }

    f= f * (1 << 16);
    stepa = f*N/RATE;

    int sample = wavetable[offseta>>16];
    sample = sample / 16 + 2048;
    TIM1->CCR4=sample;
}

void set_freq_b(float f)
{
    if(f==0){
        stepb = 0;
        offsetb = 0;
    }
    f= f * (1 << 16);
    stepb = f*N/RATE;

    int sample = wavetable[offsetb>>16];
    sample = sample / 16 + 2048;
    TIM1->CCR4=sample;
}

void set_freq_c(float f)
{
    if(f==0){
        stepc = 0;
        offsetc = 0;
    }
    f= f * (1 << 16);
    stepc = f*N/RATE;

    int sample = wavetable[offsetc>>16];
    sample = sample / 16 + 2048;
    TIM1->CCR4=sample;
}



//===========================================================================
// Timer 6 ISR    (Autotest #2)
// The ISR for Timer 6 computes the DAC samples.
// Parameters: none
// (Write the entire subroutine below.)
//===========================================================================
void TIM6_DAC_IRQHandler(void)
{
    TIM6->SR &= ~TIM_SR_UIF;

    offseta += stepa;
    offsetb += stepb;
    offsetc += stepc;

    if(offseta>>16 >= N)
        offseta -= N<<16;
    if(offsetb>>16 >= N)
        offsetb -= N<<16;
    if(offsetc>>16 >= N)
        offsetc -= N<<16;


    int sample = (wavetable[offseta>>16]+wavetable[offsetb>>16]+wavetable[offsetc>>16]);

    sample = ((sample * volume)>>17) + 1200;

    if(sample > 4095)
        sample = 4095;

    if(sample < 0)
        sample = 0;

    TIM1->CCR4=sample;

}

//===========================================================================
// setup_tim6()    (Autotest #2)
// Set the three step and three offset variabls based on the frequency.
// Parameters: f: The floating-point frequency desired.
//===========================================================================
void setup_tim6()
{
    RCC->APB1ENR    |= RCC_APB1ENR_TIM6EN;
    TIM6->PSC      = 39;
    TIM6->ARR      = 59;
    TIM6->DIER     = TIM_DIER_UIE;
    TIM6->CR1     |= TIM_CR1_CEN;
    NVIC->ISER[0]  = 1<<17;
}

//===========================================================================
// enable_ports()    (Autotest #3)
// Configure the pins for GPIO Ports B and C.
// Parameters: none
//===========================================================================
void enable_ports()
{
    RCC->AHBENR    |= RCC_AHBENR_GPIOBEN;
    GPIOB->MODER   |= 0x55;
    GPIOB->MODER   &= ~(0xAA);
    GPIOB->MODER   &= ~(0xff00);

    GPIOB->PUPDR   |= 0xAA00;
    GPIOB->PUPDR   &= ~(0x5500);

    RCC->AHBENR    |= RCC_AHBENR_GPIOCEN;
    GPIOC->MODER   |= 0x155555;
    GPIOC->MODER   &= ~(0x2AAAAA);
}

char offset;
char history[16];
char display[8];
char queue[2];
int  qin;
int  qout;

//===========================================================================
// show_digit()    (Autotest #4)
// Output a single digit on the seven-segmnt LED array.
// Parameters: none
//===========================================================================
void show_digit()
{
    int off = offset & 7;
    GPIOC->ODR = (off << 8) | display[off];
}

//===========================================================================
// set_row()    (Autotest #5)
// Set the row active on the keypad matrix.
// Parameters: none
//===========================================================================
void set_row()
{
    int row = offset & 3;
    GPIOB->BSRR = 0xf0000 | (1<<row);

}

//===========================================================================
// get_cols()    (Autotest #6)
// Read the column pins of the keypad matrix.
// Parameters: none
// Return value: The 4-bit value read from PC[7:4].
//===========================================================================
int get_cols()
{
    int i = (GPIOB->IDR>>4) & 0xf;
    return i;
}

//===========================================================================
// insert_queue()    (Autotest #7)
// Insert the key index number into the two-entry queue.
// Parameters: n: the key index number
//===========================================================================
void insert_queue(int n)
{
    n |= 0x80;
    queue[qin] = n;
    qin ^= 1;
}

//===========================================================================
// update_hist()    (Autotest #8)
// Check the columns for a row of the keypad and update history values.
// If a history entry is updated to 0x01, insert it into the queue.
// Parameters: none
//===========================================================================
void update_hist(int cols)
{
    int row = offset & 3;
    for(int i=0; i < 4; i++){
        history[4*row+i] = (history[4*row+i]<<1) + ((cols>>i)&1);
        if(history[4*row+i]==0x1){
            insert_queue(4*row+i);
        }
    }
}

//===========================================================================
// Timer 7 ISR()    (Autotest #9)
// This is the Timer 7 ISR
// Parameters: none
// (Write the entire subroutine below.)
//===========================================================================
void TIM7_IRQHandler(void)
{
    TIM7->SR &= ~TIM_SR_UIF;

    show_digit();
    int cols = get_cols();
    update_hist(cols);
    offset = (offset + 1) & 0x7;
    set_row();
}
//===========================================================================
// setup_tim7()    (Autotest #10)
// Configure timer 7
// Parameters: none
//===========================================================================
void setup_tim7()
{
    RCC->APB1ENR |= RCC_APB1ENR_TIM7EN;
    TIM7->PSC      = 479;
    TIM7->ARR      = 99;
    TIM7->DIER     = TIM_DIER_UIE;
    TIM7->CR1     |= TIM_CR1_CEN;
    NVIC->ISER[0]  = 1<<18;
}

//===========================================================================
// getkey()    (Autotest #11)
// Wait for an entry in the queue.  Translate it to ASCII.  Return it.
// Parameters: none
// Return value: The ASCII value of the button pressed.
//===========================================================================
int getkey()
{
    while(queue[qout]==0){
        asm volatile("wfi");
    }

    int q = queue[qout];
    queue[qout] = 0;
    qout ^= 1;
    q &= 0x7f;
    if (q == 0)
        return '1';
    if (q == 1)
        return '2';
    if (q == 2)
        return '3';
    if (q == 3)
        return 'A';
    if (q == 4)
        return '4';
    if (q == 5)
        return '5';
    if (q == 6)
        return '6';
    if (q == 7)
        return 'B';
    if (q == 8)
        return '7';
    if (q == 9)
        return '8';
    if (q == 10)
        return '9';
    if (q == 11)
        return 'C';
    if (q == 12)
        return '*';
    if (q == 13)
        return '0';
    if (q == 14)
        return '#';
    if (q == 15)
        return 'D';
    else
        return 0;
}

//===========================================================================
// This is a partial ASCII font for 7-segment displays.
// See how it is used below.
//===========================================================================
const char font[] = {
        [' '] = 0x00,
        ['0'] = 0x3f,
        ['1'] = 0x06,
        ['2'] = 0x5b,
        ['3'] = 0x4f,
        ['4'] = 0x66,
        ['5'] = 0x6d,
        ['6'] = 0x7d,
        ['7'] = 0x07,
        ['8'] = 0x7f,
        ['9'] = 0x67,
        ['A'] = 0x77,
        ['B'] = 0x7c,
        ['C'] = 0x39,
        ['D'] = 0x5e,
        ['*'] = 0x49,
        ['#'] = 0x76,
        ['.'] = 0x80,
        ['?'] = 0x53,
        ['b'] = 0x7c,
        ['r'] = 0x50,
        ['g'] = 0x6f,
        ['i'] = 0x10,
        ['n'] = 0x54,
        ['u'] = 0x1c,
};

// Shift a new character into the display.
void shift(char c)
{
    memcpy(display, &display[1], 7);
    display[7] = font[c];
}

// Turn on the dot of the rightmost display element.
void dot()
{
    display[7] |= 0x80;
}

// Read an entire floating-point number.
float getfloat()
{
    int num = 0;
    int digits = 0;
    int decimal = 0;
    int enter = 0;
    memset(display,0,8);
    display[7] = font['0'];
    while(!enter) {
        int key = getkey();
        if (digits == 8) {
            if (key != '#')
                continue;
        }
        switch(key) {
        case '0':
            if (digits == 0)
                continue;
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
        case '8':
        case '9':
            num = num*10 + key-'0';
            decimal <<= 1;
            digits += 1;
            if (digits == 1)
                display[7] = font[key];
            else
                shift(key);
            break;
        case '*':
            if (decimal == 0) {
                decimal = 1;
                dot();
            }
            break;
        case '#':
            enter = 1;
            break;
        default: continue; // ABCD
        }
    }
    float f = num;
    while (decimal) {
        decimal >>= 1;
        if (decimal)
            f = f/10.0;
    }
    return f;
}

// Read a 6-digit BCD number for RGB components.
int getrgb()
{
    memset(display, 0, 8);
    display[0] = font['r'];
    display[1] = font['r'];
    display[2] = font['g'];
    display[3] = font['g'];
    display[4] = font['b'];
    display[5] = font['b'];
    int digits = 0;
    int rgb = 0;
    for(;;) {
        int key = getkey();
        if (key >= '0' || key <= '9') {
            display[digits] = font[key];
            digits += 1;
            rgb = (rgb << 4) + (key - '0');
        }
        if (digits == 6)
            break;
    }
    return rgb;
}

//==========================================================================
// setrgb()    (Autotest #12)
// Accept a BCD-encoded value for the 3 color components.
// Then update the CCR values appropriately.
// Parameters: rgb: the RGB color component values
//==========================================================================
void setrgb(int rgb)
{
    int r = rgb>>16 & 0xff;
    int g = rgb>>8  & 0xff;
    int b = rgb     & 0xff;

    int r1 = r/16;
    int r2 = r-r1*16;
    r = r1*10+r2;
    r = 100 - r;

    int g1 = g/16;
    int g2 = g-g1*16;
    g = g1*10+g2;
    g = 100 - g;

    int b1 = b/16;
    int b2 = b-b1*16;
    b = b1*10+b2;
    b = 100 - b;

    TIM1->CCR1=r*24;
    TIM1->CCR2=g*24;
    TIM1->CCR3=b*24;
}

void internal_clock();
void demo();
void autotest();

int main(void)
{
    //internal_clock();
    //demo();
    //autotest();
    enable_ports();
    init_wavetable();
    set_freq_a(261.626); // Middle 'C'
    set_freq_b(329.628); // The 'E' above middle 'C'
    set_freq_c(391.996); // The 'G' above middle 'C'
    setup_tim1();
    setup_tim6();
    setup_tim7();

    display[0] = font['r'];
    display[1] = font['u'];
    display[2] = font['n'];
    display[3] = font['n'];
    display[4] = font['i'];
    display[5] = font['n'];
    display[6] = font['g'];
    for(;;) {
        char key = getkey();
        if (key == 'A')
            set_freq_a(getfloat());
        else if (key == 'B')
            set_freq_b(getfloat());
        else if (key == 'C')
            set_freq_c(getfloat());
        else if (key == 'D')
            setrgb(getrgb());
    }
}
