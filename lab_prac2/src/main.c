#include "stm32f0xx.h"
#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

int counter;

char offset;

int main(void)
{
    //1.
    RCC->AHBENR    |= RCC_AHBENR_GPIOAEN;
    GPIOA->MODER   |= 0xc;
    RCC->APB2ENR   |= RCC_APB2ENR_ADC1EN;
    RCC->CR2       |= RCC_CR2_HSI14ON;
    while( !(RCC->CR2 & RCC_CR2_HSI14RDY) );
    ADC1->CFGR1    &= ~ADC_CFGR1_ALIGN;
    ADC1->CFGR1    |=  ADC_CFGR1_RES;
    ADC1->CR       |= ADC_CR_ADEN;
    //2.
    RCC->APB2ENR    |= RCC_APB2ENR_TIM15EN;
    TIM15->PSC      = 23999;
    TIM15->ARR      = 199;
    TIM15->DIER     = TIM_DIER_UIE;
    TIM15->CR1     |= TIM_CR1_ARPE;
    TIM15->CR1     |= TIM_CR1_CEN;
    NVIC->ISER[0]  = 1<<20;
    //3.
    RCC->AHBENR    |=  RCC_AHBENR_GPIOBEN;
    GPIOB->MODER   &= ~((1<<24)|(1<<26)|(1<<30));
    GPIOB->MODER   |=   (1<<25)|(1<<27)|(1<<31);
    RCC  ->APB1ENR |= RCC_APB1ENR_SPI2EN;
    SPI2 ->CR1      = SPI_CR1_BR_0|SPI_CR1_BR_1|SPI_CR1_BR_2;
    SPI2 ->CR2      = SPI_CR2_DS_0|SPI_CR2_DS_3;
    SPI2 ->CR1     |= SPI_CR1_MSTR;
    SPI2 ->CR2     |= SPI_CR2_NSSP;
    SPI2 ->CR2     |= SPI_CR2_SSOE;
    SPI2 ->CR1     |= SPI_CR1_SPE;

    GPIOB->MODER   |= 0x55;
    GPIOB->MODER   &= ~(0xAA);
    GPIOB->MODER   &= ~(0xff00);

    GPIOB->PUPDR   |= 0xAA00;
    GPIOB->PUPDR   &= ~(0x5500);

    nano_wait(1000000);
    spi_cmd(0x38);
    spi_cmd(0x08);
    spi_cmd(0x01);
    nano_wait(2000000);
    spi_cmd(0x06);
    spi_cmd(0x02);
    spi_cmd(0x0c);
}

void TIM15_IRQHandler(void)
{
    TIM15->SR &= ~TIM_SR_UIF;

    asm volatile("wfi");
    GPIOB->IDR |= 0xf0;
    int i = (GPIOB->IDR)&&0xf;

    if(i == 11)
        counter++;
    else
        counter = 0;

    ADC1->CHSELR  = 0;
    ADC1->CHSELR |= 1<<1;
    while( !(ADC1->ISR & ADC_ISR_ADRDY) );
    ADC1->CR    |= ADC_CR_ADSTART;
    while( !(ADC1->ISR & ADC_ISR_EOC) );
    int sample = ADC1->DR;
    TIM15->ARR = 100 * (1 + sample) - 1;

    char buffer[20];
    sprintf(buffer, "%08d", counter);

    display_oled(buffer);
}

void display_oled(char *str){
    spi_cmd(0x02);
    for(int i=0;i<strlen(str);i++){
        if(str[i])
            spi_data(str[i]);
    }
}

void spi_data(int n){
    while((SPI2->SR & SPI_SR_TXE) == 0) ;
    SPI2->DR = 0x200|n;
}

void spi_cmd(int n){
    while((SPI2->SR & SPI_SR_TXE) == 0);
    SPI2->DR = n;
}

void nano_wait(unsigned int n) {
    asm(    "        mov r0,%0\n"
            "repeat: sub r0,#83\n"
            "        bgt repeat\n" : : "r"(n) : "r0", "cc");
}

