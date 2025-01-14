
//===========================================================================
// ECE 362 lab experiment 9 -- I2C
//===========================================================================

#include "stm32f0xx.h"
#include <stdint.h> // for uint8_t
#include <string.h> // for strlen() and strcmp()

// Be sure to change this to your login...
const char login[] = "kim3244";

//===========================================================================
// Wait for n nanoseconds. (Maximum time: 4.294 seconds)
//===========================================================================
void nano_wait(unsigned int n) {
    asm(    "         mov r0,%0\n"
            "repeat:  sub r0,#83\n"
            "         bgt repeat\n" : : "r"(n) : "r0", "cc");
}

// Write your subroutines below...

void setup_i2c(){
    RCC->AHBENR    |= RCC_AHBENR_GPIOBEN;
    GPIOB->MODER   &= ~((1<<16)|(1<<18));
    GPIOB->MODER   |=  ((1<<17)|(1<<19));

    GPIOB->AFR[1]  &= ~0x0F000000;
    GPIOB->AFR[1]  |= 0x11;

    RCC->APB1ENR   |= RCC_APB1ENR_I2C1EN;
    I2C1->CR1      &= ~I2C_CR1_PE;
    I2C1->CR1      &= ~I2C_CR1_ANFOFF;
    I2C1->CR1      &= ~I2C_CR1_ERRIE;
    I2C1->CR1      &= ~I2C_CR1_NOSTRETCH;

    I2C1->TIMINGR  &= ~(0b1111<<28);
    I2C1->TIMINGR  &= ~(0b1100<<20);
    I2C1->TIMINGR  |=  (0b0011<<20);
    I2C1->TIMINGR  &= ~(0b1110<<16);
    I2C1->TIMINGR  |=  (0b0001<<16);
    I2C1->TIMINGR  &= ~(0b11111100<<8);
    I2C1->TIMINGR  |=  (0b00000011<<8);
    I2C1->TIMINGR  &= ~(0b11110110);
    I2C1->TIMINGR  |=  (0b00001001);

    I2C1->OAR1     &= ~I2C_OAR1_OA1EN;
    I2C1->OAR2     &= ~I2C_OAR1_OA1EN;
    I2C1->CR2      &= ~I2C_CR2_ADD10;
    I2C1->CR2      |=  I2C_CR2_AUTOEND;
    I2C1->CR1      |=  I2C_CR1_PE;
}

void i2c_start (uint32_t devaddr, uint8_t size, uint8_t dir) {
    uint32_t tmpreg = I2C1->CR2;
    tmpreg &= ~(I2C_CR2_SADD | I2C_CR2_NBYTES |
                    I2C_CR2_RELOAD | I2C_CR2_AUTOEND |
                    I2C_CR2_RD_WRN | I2C_CR2_START | I2C_CR2_STOP);
    if (dir == 1)
        tmpreg |= I2C_CR2_RD_WRN; // Read from slave
    else
        tmpreg &= ~I2C_CR2_RD_WRN; // Write to slave
    tmpreg |= ((devaddr<<1) & I2C_CR2_SADD) | ((size << 16) & I2C_CR2_NBYTES);
    tmpreg |= I2C_CR2_START;
    I2C1->CR2 = tmpreg;
}

void i2c_stop (void) {
    if (I2C1->ISR & I2C_ISR_STOPF)
        return;
    I2C1->CR2 |= I2C_CR2_STOP;
    while( (I2C1->ISR & I2C_ISR_STOPF) == 0);
    I2C1->ICR |= I2C_ICR_STOPCF;
}

void i2c_waitidle (void) {
    while ( (I2C1->ISR & I2C_ISR_BUSY) == I2C_ISR_BUSY);
}

int8_t i2c_senddata (uint8_t devaddr, void *pdata, uint8_t size) {
    int i;
    if (size <= 0 || pdata == 0)
        return -1;
    uint8_t *udata = (uint8_t*)pdata;
    i2c_waitidle();
    i2c_start(devaddr, size, 0);
    for(i=0; i<size; i++) {
        int count = 0;
        while( (I2C1->ISR & I2C_ISR_TXIS) == 0) {
            count += 1;
            if (count > 1000000)
                return -1;
            if (I2C1->ISR & I2C_ISR_NACKF){
                I2C1->ICR |= I2C_ICR_NACKCF;
                i2c_stop();
                return -1;
            }
        }
        I2C1->TXDR = udata[i] & I2C_TXDR_TXDATA;
     }
     while((I2C1->ISR & I2C_ISR_TC) == 0 && (I2C1->ISR & I2C_ISR_NACKF) == 0);
     if ( (I2C1->ISR & I2C_ISR_NACKF) != 0)
         return -1;
     i2c_stop();
     return 0;
}

int8_t i2c_recvdata(uint8_t SlaveAddress, uint8_t *pData, uint8_t Size) {
    int i;
    if (Size <= 0 || pData == NULL) return -1;
    i2c_waitidle();
    i2c_start(SlaveAddress, Size, 1);
    for (i = 0; i < Size; i++){
        while( (I2C1->ISR & I2C_ISR_RXNE) == 0);
        pData[i] = I2C1->RXDR & I2C_RXDR_RXDATA;
    }
    while((I2C1->ISR & I2C_ISR_TC) == 0);
    i2c_stop();
    return 0;
}

void i2c_set_iodir(int n){
    uint8_t data[]={0x00,n};
    i2c_senddata(0x27, data, 2);
}

void i2c_set_gpio(int n){
    uint8_t data[]={0x09,n};
    i2c_senddata(0x27, data, 2);
}

int i2c_get_gpio(){

    char data[]={0x09};
    char line[1];

    i2c_senddata(0x27, data, 1);
    i2c_recvdata(0x27, line, 1);

    int i = (int)*line;

    return i;
}

void i2c_write_flash(uint16_t loc, const char *data, uint8_t len){
    char buff[34];
    int upper = (loc>>8) & 0xf;
    int under = (loc & 0xff);

    buff[0] = upper;
    buff[1] = under;

    for(int i=2;i<len+2;i++){
        buff[i] = data[i-2];
    }

    i2c_senddata(0x57, buff, len+2);
}

int i2c_write_flash_complete(){
    i2c_waitidle();
    i2c_start(0x57, 0, 0);

    while(!(I2C1->ISR & I2C_ISR_TC) && !(I2C1->ISR & I2C_ISR_NACKF));

    if((I2C1->ISR & I2C_ISR_NACKF) == 16){
        I2C1->ISR &= ~I2C_ISR_NACKF;
        i2c_stop();
        return 0;
    }
    else {
        i2c_stop();
        return 1;
    }
}

void i2c_read_flash(uint16_t loc, char data[], uint8_t len){
    char buff[] = {0,0};
    i2c_write_flash(loc, buff, 0);
    i2c_recvdata(0x57, data, len);
}

void internal_clock();
void demo();
void autotest();

int main(void)
{
    //internal_clock();
    //demo();
    //autotest();

    setup_i2c();
    //i2c_test();

    while(1) {
     i2c_waitidle();
     i2c_start(0x57, 0, 0);
     int x=0;
     while((I2C1->ISR & I2C_ISR_TC) == 0 &&
     (I2C1->ISR & I2C_ISR_STOPF) == 0 &&
     (I2C1->ISR & I2C_ISR_NACKF) == 0)
     x++; // Wait until TC flag is set
     if (I2C1->ISR & I2C_ISR_NACKF)
     I2C1->ICR |= I2C_ICR_NACKCF;
     if (I2C1->ISR & I2C_ISR_STOPF)
     I2C1->ICR |= I2C_ICR_STOPCF;
     else
     i2c_stop();
     nano_wait(1000000);
     }
}
