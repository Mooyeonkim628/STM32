#include "stm32f0xx.h"
#include <math.h>
#include <stdint.h>
#define SAMPLES 200
uint16_t array[SAMPLES];

int main(void)
{
    for(int x=0; x < SAMPLES; x += 1)
        array[x] = 2048 + 1952 * sin(2 * M_PI * x / SAMPLES);

    RCC->AHBENR  |= RCC_AHBENR_GPIOAEN;
    GPIOA->MODER |= (1<<8)|(1<<9);
    GPIOA->MODER &= ~((1<<27)|(1<<29));

    RCC->APB1ENR          |= RCC_APB1ENR_TIM3EN;
    TIM3->PSC              = 0;
    TIM3->ARR              = 2399;
    TIM3->CR2             |= 1<<5;
    TIM3->CR2             &= ~((1<<4)|(1<<6));
    TIM3->DIER            |= TIM_DIER_UDE;
    TIM3->CR1             |= TIM_CR1_CEN;
    NVIC->ISER[0]         |= 1<<DMA1_Channel2_3_IRQn;

    RCC->AHBENR          |= RCC_AHBENR_DMA1EN;
    DMA1_Channel3->CNDTR  = 0xc8;
    DMA1_Channel3->CMAR   = (uint32_t)array;
    DMA1_Channel3->CPAR   = (uint32_t)(&(DAC->DHR12R1));
    DMA1_Channel3->CCR   |= DMA_CCR_DIR;
    DMA1_Channel3->CCR   &= ~(1<<11);
    DMA1_Channel3->CCR   |= 1<<10;
    DMA1_Channel3->CCR   &= ~(1<<9);
    DMA1_Channel3->CCR   |= 1<<8;
    DMA1_Channel3->CCR   |= DMA_CCR_MINC;
    DMA1_Channel3->CCR   |= DMA_CCR_CIRC;
    DMA1_Channel3->CCR   |= DMA_CCR_EN;

    RCC->APB1ENR   |= RCC_APB1ENR_DACEN;
    DAC->CR        &= ~((DAC_CR_TSEL1_0)|(DAC_CR_TSEL1_1)|(DAC_CR_TSEL1_2));
    DAC->CR        |= DAC_CR_TSEL1_0;
    DAC->CR        |= DAC_CR_TEN1;
    DAC->CR        |= DAC_CR_EN1;
}

void DMA1_CH2_3_DMA2_CH1_2_IRQHandler(void){
    DMA1->IFCR |= DMA_IFCR_CTCIF3;
    TIM3->CR1  |= TIM_CR1_ARPE;
    if(TIM3->ARR < 2400){
        TIM3->ARR = (((TIM3->ARR)+1)*4)-1;
    }
    else
        TIM3->ARR = 2399;
}
