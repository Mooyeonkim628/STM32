#include "stm32f0xx.h"

extern volatile int counter;

unsigned int subfoo(unsigned int x) {
    if (x < 2)
        return 0;
    if ((x & 1) == 0)
        return 2 + subfoo(x - 1);
    return 1 + subfoo(x >> 1);
}

void enable_portb(){
    RCC->AHBENR    |= RCC_AHBENR_GPIOBEN;
}

void enable_portc(){
    RCC->AHBENR    |= RCC_AHBENR_GPIOCEN;
}

void setup_pb3(){
    GPIOB->MODER   &= ~(0xc0);
    GPIOB->PUPDR   |=   0x80;
    GPIOB->PUPDR   &= ~(0x40);
}

void setup_pb4(){
    GPIOB->MODER   &= ~(0x300);
    GPIOB->PUPDR   &= ~(0x300);
}

void setup_pc8(){
    GPIOC->MODER   |= 0x10000;
    GPIOC->MODER   &= ~(0x20000);
    GPIOC->OSPEEDR |= 0x30000;
}

void setup_pc9(){
    GPIOC->MODER   |= 0x40000;
    GPIOC->MODER   &= ~(0x80000);
    GPIOC->OSPEEDR |= (0x40000);
    GPIOC->OSPEEDR &= ~(0x80000);
}

void action8(){
    if((GPIOB->IDR >>3 & 1) && !(GPIOB->IDR >>4 & 1))
        GPIOC->ODR &= ~(0x100);
    else
        GPIOC->ODR |= 0x100;
}

void action9(){
    if(!(GPIOB->IDR >>3 & 1) && (GPIOB->IDR >>4 & 1))
        GPIOC->ODR |= 0x200;
    else
        GPIOC->ODR &= ~(0x200);
}

void EXTI2_3_IRQHandler(){
    EXTI->PR = 1<<3;
    counter++;
}

void enable_exti(){
    RCC->APB2ENR      |= 1;
    SYSCFG->EXTICR[0] |= 0x100;
    SYSCFG->EXTICR[0] &= ~(0x600);
    EXTI->RTSR        |= 1<<2;
    EXTI->IMR         |= 1<<2;
    NVIC->ISER[0]      =(1<<EXTI2_3_IRQn);
}

void TIM3_IRQHandler(){
    TIM3->SR &= ~(0x1);
    GPIOC->ODR ^= 1 << 9;
}


void enable_tim3(){
    RCC->APB1ENR  |= 2;
    TIM3->PSC      = 19999;
    TIM3->ARR      = 599;
    TIM3->DIER     = TIM_DIER_UIE;
    NVIC->ISER[0]  = (1<<TIM3_IRQn);
    TIM3->CR1     |= TIM_CR1_CEN;
}
