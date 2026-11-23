/**
  ******************************************************************************
  * @file    main.c
  * @brief   实验一：TFT 竖屏显示姓名、专业、班级、学号
  * @note    STM32F103C8T6 + 1.8 寸 ST7735S，软件 SPI
  *          CLK=PB9  SDA=PB8  RS=PB7  RST=PB6  CS=PB5
  *          竖屏 128x160，12x12 汉字 / 6x12 ASCII，靠左上紧凑排版
  *          本文件编码：GB2312（Keil 默认 ANSI），请勿另存为 UTF-8
  ******************************************************************************
  */

#include "stm32f10x.h"
#include "delay.h"
#include "tft.h"

int main(void)
{
    delay_init();                   /* SysTick 延时初始化 */
    LCD_Init();                     /* TFT 初始化，竖屏 128x160 */

    LCD_Clear(BLACK);               /* 黑色背景 */

    /* 四行信息紧贴左上角，行距 14 像素，无空行 */
    LCD_ShowChinese(0, 0, CYAN, BLACK, "姓名:", 12, 0);
    LCD_ShowChinese(32, 0, WHITE, BLACK, "周则均", 12, 0);

    LCD_ShowChinese(0, 14, CYAN, BLACK, "专业:", 12, 0);
    LCD_ShowChinese(32, 14, WHITE, BLACK, "电子信息工程", 12, 0);

    LCD_ShowChinese(0, 28, CYAN, BLACK, "班级:", 12, 0);
    LCD_ShowChinese(32, 28, WHITE, BLACK, "24电本2班", 12, 0);

    LCD_ShowChinese(0, 42, CYAN, BLACK, "学号:", 12, 0);
    LCD_ShowChinese(32, 42, WHITE, BLACK, "202409502216", 12, 0);

    while(1)
    {
    }
}
