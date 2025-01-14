
//===========================================================================
// ECE 362 lab experiment 8 -- SPI and DMA
//===========================================================================

#include "stm32f0xx.h"
#include "lcd.h"
#include <stdio.h> // for sprintf()
#include <string.h>

// Be sure to change this to your login...
const char login[] = "kim3244";

// Prototypes for miscellaneous things in lcd.c
void nano_wait(unsigned int);

// Write your subroutines below
void setup_bb(){
    RCC->AHBENR    |=  RCC_AHBENR_GPIOBEN;
    GPIOB->MODER   |=    (1<<24)|(1<<26)|(1<<30);
    GPIOB->MODER   &=  ~((1<<25)|(1<<27)|(1<<31));
    GPIOB->ODR     |=    (1<<12);//nss
    GPIOB->ODR     &=   ~(1<<13);//sck
}
void small_delay(){
    nano_wait(3000000);
}

void bb_write_bit(int n){
    if(n==0)
        GPIOB->ODR     &= ~(1<<15);//Set the MOSI pin to the value of the parameter.
    else if(n==1)
        GPIOB->ODR     |=  (1<<15);
    small_delay();
    GPIOB->ODR     |=  (1<<13);//Set the SCK pin to high.
    small_delay();
    GPIOB->ODR     &= ~(1<<13);//Set the SCK pin to low.
}

void bb_write_byte(int n){
    bb_write_bit((n>>7)&1);
    bb_write_bit((n>>6)&1);
    bb_write_bit((n>>5)&1);
    bb_write_bit((n>>4)&1);
    bb_write_bit((n>>3)&1);
    bb_write_bit((n>>2)&1);
    bb_write_bit((n>>1)&1);
    bb_write_bit((n>>0)&1);
}

void bb_cmd(int n){
    GPIOB->ODR     &=  ~(1<<12);//nss
    small_delay();
    bb_write_bit(0);
    bb_write_bit(0);
    bb_write_byte(n);
    small_delay();
    GPIOB->ODR     |=   (1<<12);
    small_delay();
}

void bb_data(int n){
    GPIOB->ODR     &=  ~(1<<12);//nss
    small_delay();
    bb_write_bit(1);
    bb_write_bit(0);
    bb_write_byte(n);
    small_delay();
    GPIOB->ODR     |=   (1<<12);
    small_delay();
}

void bb_init_oled(){
    nano_wait(1000000); //wait 1 ms for the display to power up and stabilize.
    bb_cmd(0x38); // set for 8-bit operation
    bb_cmd(0x08); // turn display off
    bb_cmd(0x01); // clear display
    nano_wait(2000000); //wait 2 ms for the display to clear.
    bb_cmd(0x06); // set the display to scroll
    bb_cmd(0x02); // move the cursor to the home position
    bb_cmd(0x0c); // turn the display on
}

void bb_display1(const char *str){
    bb_cmd(0x02); // move the cursor to the home position
    for(int i=0;i<strlen(str);i++){
        if(str[i]!='\0')
            bb_data(str[i]);     //for each non-NUL character of the string.
    }
}

void bb_display2(const char *str){
    bb_cmd(0xc0); // move the cursor to the home position
    for(int i=0;i<strlen(str);i++){
       if(str[i]!='\0')
            bb_data(str[i]);     //for each non-NUL character of the string.
    }
}
//
void setup_spi2(){
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
}

void spi_cmd(int n){
    while((SPI2->SR & SPI_SR_TXE) == 0)
        ;
    SPI2->DR = n;
}

void spi_data(int n){
    while((SPI2->SR & SPI_SR_TXE) == 0)
        ;
    SPI2->DR = 0x200|n;
}

void spi_init_oled(){
    nano_wait(1000000); //wait 1 ms for the display to power up and stabilize.
    spi_cmd(0x38); // set for 8-bit operation
    spi_cmd(0x08); // turn display off
    spi_cmd(0x01); // clear display
    nano_wait(2000000); //wait 2 ms for the display to clear.
    spi_cmd(0x06); // set the display to scroll
    spi_cmd(0x02); // move the cursor to the home position
    spi_cmd(0x0c); // turn the display on
}

void spi_display1(const char *str){
    spi_cmd(0x02); // move the cursor to the home position
    for(int i=0;i<strlen(str);i++){
        if(str[i])
            spi_data(str[i]);     //for each non-NUL character of the string.
    }
}

void spi_display2(const char *str){
    spi_cmd(0xc0); // move the cursor to the home position
    for(int i=0;i<strlen(str);i++){
        if(str[i])
            spi_data(str[i]);     //for each non-NUL character of the string.
    }
}


//
void spi_setup_dma(const short *n){
    RCC->AHBENR          |=  RCC_AHBENR_DMAEN;
    DMA1_Channel5->CPAR   = (uint32_t)(&(SPI2->DR));
    DMA1_Channel5->CMAR   = (uint32_t)n;
    DMA1_Channel5->CNDTR |=  34;
    DMA1_Channel5->CCR   |=  DMA_CCR_DIR;
    DMA1_Channel5->CCR   |=  DMA_CCR_MINC;
    DMA1_Channel5->CCR   |=  DMA_CCR_MSIZE_0;
    DMA1_Channel5->CCR   &= ~DMA_CCR_MSIZE_1;
    DMA1_Channel5->CCR   |=  DMA_CCR_PSIZE_0;
    DMA1_Channel5->CCR   &= ~DMA_CCR_PSIZE_1;
    DMA1_Channel5->CCR   |=  DMA_CCR_CIRC;
    SPI2 ->CR2           |=  SPI_CR2_TXDMAEN;
}

void enable_dma(){
    DMA1_Channel5->CCR   |=  DMA_CCR_EN;
}
//
void setup_spi1(){
    RCC->AHBENR    |=  RCC_AHBENR_GPIOAEN;
    RCC->AHBENR    |=  RCC_AHBENR_GPIOBEN;

    GPIOA->MODER   |=   (1<<11)|(1<<15);
    GPIOA->MODER   &= ~((1<<10)|(1<<24));
    GPIOA->MODER   &= ~(1<<7);
    GPIOA->MODER   |=  (1<<6);

    GPIOA->ODR     |= (1<<3);

    GPIOB->MODER   &= ~((1<<21)|(1<<23));
    GPIOB->MODER   |=   (1<<20)|(1<<22);

    GPIOB->ODR     |= (1<<10)|(1<<11);

    RCC->APB2ENR   |= RCC_APB2ENR_SPI1EN;

    SPI1 ->CR1     |=   SPI_CR1_MSTR;
    SPI1 ->CR1     &=   ~SPI_CR1_BR;
    SPI1 ->CR1     |=   SPI_CR1_SSM;
    SPI1 ->CR1     |=   SPI_CR1_SSI;
    SPI1 ->CR2      =   SPI_CR2_DS_0|SPI_CR2_DS_1|SPI_CR2_DS_2;
    SPI1 ->CR1     |=   SPI_CR1_SPE;
}

// Write your subroutines above

void show_counter(short buffer[])
{
    for(int i=0; i<10000; i++) {
        char line[17];
        sprintf(line,"% 16d", i);
        for(int b=0; b<16; b++)
            buffer[1+b] = line[b] | 0x200;
    }
}

void internal_clock();
void demo();
void autotest();

extern const Picture *image;

int main(void)
{
    //internal_clock();
    //demo();
    //autotest();

    setup_bb();
    bb_init_oled();
    bb_display1("Hello,");
    bb_display2(login);

    setup_spi2();
   spi_init_oled();
    spi_display1("Hello again,");
    spi_display2(login);

    short buffer[34] = {
            0x02, // This word sets the cursor to beginning of line 1.
            // Line 1 consists of spaces (0x20)
            0x220, 0x220, 0x220, 0x220, 0x220, 0x220, 0x220, 0x220,
            0x220, 0x220, 0x220, 0x220, 0x220, 0x220, 0x220, 0x220,
            0xc0, // This word sets the cursor to beginning of line 2.
            // Line 2 consists of spaces (0x20)
            0x220, 0x220, 0x220, 0x220, 0x220, 0x220, 0x220, 0x220,
            0x220, 0x220, 0x220, 0x220, 0x220, 0x220, 0x220, 0x220,
    };

    spi_setup_dma(buffer);
    enable_dma();
    show_counter(buffer);

    setup_spi1();
    LCD_Init(0,0,0);
    LCD_Clear(BLACK);
    LCD_DrawLine(10,20,100,200, WHITE);
    LCD_DrawRectangle(10,20,100,200, GREEN);
    LCD_DrawFillRectangle(120,20,220,200, RED);
    LCD_Circle(50, 260, 50, 1, BLUE);
    LCD_DrawFillTriangle(130,130, 130,200, 190,160, YELLOW);
    LCD_DrawChar(150,155, BLACK, WHITE, 'X', 16, 1);
    LCD_DrawString(140,60,  WHITE, BLACK, "ECE 362", 16, 0);
    LCD_DrawString(140,80,  WHITE, BLACK, "has the", 16, 1);
    LCD_DrawString(130,100, BLACK, GREEN, "best toys", 16, 0);
    LCD_DrawPicture(110,220,(const Picture *)&image);
}
