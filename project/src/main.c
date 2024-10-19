
//===========================================================================
// ECE 362 lab experiment 10 -- Asynchronous Serial Communication
//===========================================================================

#include "stm32f0xx.h"
#include "ff.h"
#include "diskio.h"
#include "fifo.h"
#include "tty.h"
#include <string.h> // for memset()
#include <stdio.h> // for printf()

void advance_fattime(void);
void command_shell(void);

// Write your subroutines below.
void setup_usart5(){
    RCC->AHBENR |= RCC_AHBENR_GPIOCEN;
    RCC->AHBENR |= RCC_AHBENR_GPIODEN;

    GPIOC->MODER   &= ~(1<<24);
    GPIOC->MODER   |=  (1<<25);
    GPIOD->MODER   &= ~(1<<4);
    GPIOD->MODER   |=  (1<<5);

    GPIOC->AFR[1]  &= ~((0xD)<<16);
    GPIOC->AFR[1]  |=  ((0x2)<<16);

    GPIOD->AFR[0]  &= ~((0xD)<<8);
    GPIOD->AFR[0]  |=  ((0x2)<<8);

    RCC->APB1ENR |= RCC_APB1ENR_USART5EN;

    USART5->CR1  &= ~USART_CR1_UE;
    USART5->CR1  &= ~(1<<28);
    USART5->CR1  &= ~(1<<12);

    USART5->CR2  &= ~USART_CR2_STOP;
    USART5->CR1  &= ~USART_CR1_PCE;
    USART5->CR1  &= ~USART_CR1_OVER8;

    USART5->BRR  = 417;
    USART5->CR1  |= USART_CR1_RE;
    USART5->CR1  |= USART_CR1_TE;

    USART5->CR1  |= USART_CR1_UE;

    while(!(USART5->CR1 & USART_CR1_RE) && !(USART5->CR1 & USART_CR1_RE));
}

int simple_putchar(int n){
    while(!(USART5->ISR & USART_ISR_TXE));
    USART5->TDR = n;
    return n;
}

int simple_getchar(){
    while(!(USART5->ISR & USART_ISR_RXNE));
    return USART5->RDR;
}

int better_putchar(int n){
    if(n == '\n'){
        while(!(USART5->ISR & USART_ISR_TXE));
        USART5->TDR = '\r';
        while(!(USART5->ISR & USART_ISR_TXE));
        USART5->TDR = '\n';
        return n;
    }
    else{
        while(!(USART5->ISR & USART_ISR_TXE));
        USART5->TDR = n;
        return n;
    }
}

int better_getchar(){
    while(!(USART5->ISR & USART_ISR_RXNE));
    if(USART5->RDR == '\r')
        return '\n';
    else
        return USART5->RDR;
}

int __io_putchar(int ch) {
    return better_putchar(ch);
}

int __io_getchar(void) {
    return interrupt_getchar();
}

int interrupt_getchar(){
    while(!(fifo_newline(&input_fifo))){
        asm volatile ("wfi");
    }
    char ch = fifo_remove(&input_fifo);
    return ch;
}
void USART3_4_5_6_7_8_IRQHandler(){
    if (USART5->ISR & USART_ISR_ORE)
        USART5->ICR |= USART_ICR_ORECF;
    char c = USART5->RDR;
    if(fifo_newline(&input_fifo) == 1) {
        return;
    }
    insert_echo_char(c);
}

void enable_tty_interrupt(){
    USART5->CR1    |= USART_CR1_RXNEIE;
    USART5->CR1    |= USART_CR1_UE;
    NVIC->ISER[0]  |= 1<<29;
}

void setup_spi1(){
    RCC->AHBENR    |=  RCC_AHBENR_GPIOAEN;
    GPIOA->MODER   |=  (1<<24);
    GPIOA->MODER   &= ~(1<<25);

    GPIOA->MODER   |=   (1<<11)|(1<<13)|(1<<15);
    GPIOA->MODER   &= ~((1<<10)|(1<<12)|(1<<14));

    GPIOA->AFR[0]  &= ~((0xf)<<20);
    GPIOA->AFR[0]  &= ~((0xf)<<24);
    GPIOA->AFR[0]  &= ~((0xf)<<28);

    RCC  ->APB2ENR |=  RCC_APB2ENR_SPI1EN;
    SPI1 ->CR1     &=  ~SPI_CR1_SPE;
    SPI1 ->CR1     |=  SPI_CR1_BR_0|SPI_CR1_BR_1|SPI_CR1_BR_2;
    SPI1 ->CR1     &=  ~SPI_CR1_BIDIMODE;
    SPI1 ->CR1     &=  ~SPI_CR1_BIDIOE;
    SPI1 ->CR1     |=  SPI_CR1_MSTR;
    SPI1 ->CR2     |=  SPI_CR2_NSSP;
    SPI1 ->CR2     |=  SPI_CR2_DS_0|SPI_CR2_DS_1|SPI_CR2_DS_2;
    SPI1 ->CR2     &= ~SPI_CR2_DS_3;
    SPI1 ->CR2     |=  SPI_CR2_FRXTH;
    SPI1 ->CR1     |=  SPI_CR1_SPE;
}

void spi_high_speed(){
    SPI1 ->CR1     &=  ~SPI_CR1_SPE;
    SPI1 ->CR1     &=  ~(SPI_CR1_BR_0|SPI_CR1_BR_1|SPI_CR1_BR_2);
    SPI1 ->CR1     |=  SPI_CR1_BR_0;
    SPI1 ->CR1     |=  SPI_CR1_SPE;
}

void TIM14_IRQHandler(){
    TIM14->SR &= ~TIM_SR_UIF;
    advance_fattime();
}

void setup_tim14(){
    RCC->APB1ENR    |= RCC_APB1ENR_TIM14EN;
    TIM14->PSC      = 15999;
    TIM14->ARR      = 5999;
    TIM14->DIER     = TIM_DIER_UIE;
    TIM14->CR1     |= TIM_CR1_CEN;
    NVIC->ISER[0]   = 1<<19;
}
// Write your subroutines above.

const char testline[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\r\n";

int main()
{
    setup_usart5();

    // Uncomment these when you're asked to...
    setbuf(stdin,0);
    setbuf(stdout,0);
    setbuf(stderr,0);

    // Test for 2.2 simple_putchar()
    //
    //for(;;)
        //for(const char *t=testline; *t; t++)
            //simple_putchar(*t);

    // Test for 2.3 simple_getchar()
    //
    //for(;;)
        //simple_putchar( simple_getchar() );

    // Test for 2.4 and 2.5 __io_putchar() and __io_getchar()
    //
/*    printf("Hello!\n");
    for(;;)
       putchar( getchar() );
*/
    // Test 2.6
    //
    /*for(;;) {
       printf("Enter string: ");
       char line[100];
        fgets(line, 99, stdin);
        line[99] = '\0'; // just in case
        printf("You entered: %s", line);
    }*/

    // Test for 2.7
    //
 /*   enable_tty_interrupt();
    for(;;) {
        printf("Enter string: ");
        char line[100];
        fgets(line, 99, stdin);
        line[99] = '\0'; // just in case
        printf("You entered: %s", line);
    }
*/
    // Test for 2.8 Test the command shell and clock
    //
    enable_tty_interrupt();
    setup_tim14();
    FATFS fs_storage;
    FATFS *fs = &fs_storage;
    f_mount(fs, "", 1);
    command_shell();

    return 0;
}
