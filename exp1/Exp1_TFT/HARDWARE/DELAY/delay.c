/**
  ******************************************************************************
  * @file    delay.c
  * @brief   SysTick based delay, 1 us resolution
  * @note    SystemInit() must have configured the core clock (72 MHz by default).
  ******************************************************************************
  */

#include "delay.h"

static u32 fac_us = 0;

void delay_init(void)
{
    SysTick->CTRL |= SysTick_CTRL_CLKSOURCE_Msk;    /* core clock as SysTick source */
    fac_us = SystemCoreClock / 1000000;
}

void delay_us(u32 nus)
{
    u32 temp;

    if(nus == 0) return;

    SysTick->LOAD = nus * fac_us;
    SysTick->VAL  = 0x00;
    SysTick->CTRL |= SysTick_CTRL_ENABLE_Msk;

    do
    {
        temp = SysTick->CTRL;
    }
    while((temp & 0x01) && !(temp & (1 << 16)));    /* wait for COUNTFLAG */

    SysTick->CTRL &= ~SysTick_CTRL_ENABLE_Msk;
    SysTick->VAL = 0x00;
}

void delay_ms(u16 nms)
{
    u16 chunk;

    while(nms)
    {
        chunk = (nms > 100) ? 100 : nms;            /* keep LOAD within 24 bits */
        delay_us((u32)chunk * 1000);
        nms -= chunk;
    }
}
