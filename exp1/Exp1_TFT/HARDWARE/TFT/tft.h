/**
  ******************************************************************************
  * @file    tft.h
  * @brief   ST7735S 1.8 inch TFT driver (software SPI)
  * @note    MCU  : STM32F103C8T6
  *          CLK  : PB9
  *          SDA  : PB8
  *          RS   : PB7   (0 = command, 1 = data)
  *          RST  : PB6
  *          CS   : PB5
  ******************************************************************************
  */

#ifndef __TFT_H
#define __TFT_H

#include "stm32f10x.h"

/*------------------------------- RGB565 colors ------------------------------*/
#define WHITE       0xFFFF
#define BLACK       0x0000
#define BLUE        0x001F
#define BRED        0xF81F
#define GRED        0xFFE0
#define GBLUE       0x07FF
#define RED         0xF800
#define MAGENTA     0xF81F
#define GREEN       0x07E0
#define CYAN        0x07FF
#define YELLOW      0xFFE0
#define BROWN       0xBC40
#define BRRED       0xFC07
#define GRAY        0x8410
#define DARKBLUE    0x01CF
#define LIGHTBLUE   0x7D7C
#define GRAYBLUE    0x5458
#define LIGHTGREEN  0x841F
#define LGRAY       0xC618
#define LGRAYBLUE   0xA651
#define LBBLUE      0x2B12

/*------------------------------- Panel size --------------------------------*/
#define LCD_W       128
#define LCD_H       160

/*------------------------------ LCD parameters -----------------------------*/
typedef struct
{
    u16 width;
    u16 height;
    u8  setxcmd;
    u8  setycmd;
    u8  wramcmd;
} _lcd_dev;

extern _lcd_dev lcddev;

extern u16 POINT_COLOR;
extern u16 BACK_COLOR;

/*-------------------------------- Functions --------------------------------*/
void LCD_Init(void);
void LCD_direction(u8 direction);
void LCD_SetWindows(u16 xStar, u16 yStar, u16 xEnd, u16 yEnd);
void LCD_SetCursor(u16 Xpos, u16 Ypos);
void LCD_DrawPoint(u16 x, u16 y);
void LCD_DrawPointColor(u16 x, u16 y, u16 color);
void LCD_Clear(u16 color);
void LCD_Fill(u16 x1, u16 y1, u16 x2, u16 y2, u16 color);
void LCD_DrawLine(u16 x1, u16 y1, u16 x2, u16 y2, u16 color);
void LCD_DrawRectangle(u16 x1, u16 y1, u16 x2, u16 y2, u16 color);

/* size is 12 or 16: 6x12/8x16 ASCII, 12x12/16x16 Chinese.
   mode: 0 overwrite, 1 overlay                                            */
void LCD_ShowChar(u16 x, u16 y, u16 fc, u16 bc, u8 num, u8 size, u8 mode);
void LCD_ShowString(u16 x, u16 y, u16 fc, u16 bc, const char *p, u8 size, u8 mode);
void LCD_ShowNum(u16 x, u16 y, u16 fc, u16 bc, u32 num, u8 len, u8 size);
void LCD_ShowChinese(u16 x, u16 y, u16 fc, u16 bc, const char *p, u8 size, u8 mode);

#endif
