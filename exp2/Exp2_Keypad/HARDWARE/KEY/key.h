/**
  ******************************************************************************
  * @file    key.h
  * @brief   4x4 matrix keypad driver
  * @note    MCU   : STM32F103C8T6
  *          Rows  : KEY8~KEY5 -> PA7, PA6, PA5, PA4  (push-pull output)
  *          Cols  : KEY4~KEY1 -> PB11, PB10, PB1, PB0 (pull-up input)
  *          Key   : 0,1,2,3 / 4,5,6,7 / 8,9,A,B / C,D,E,F
  ******************************************************************************
  */

#ifndef __KEY_H
#define __KEY_H

#include "stm32f10x.h"

#define KEY_NONE        0xFF    /* no key pressed */
#define KEY_NUM         16      /* 4 x 4 */

void KEY_Init(void);
u8   KEY_Scan(void);            /* return 0..15, or KEY_NONE */
u8   KEY_IsPressed(void);       /* 1 = at least one key is down */
char KEY_GetChar(u8 key);       /* 0..15 -> '0'..'F' */

#endif
