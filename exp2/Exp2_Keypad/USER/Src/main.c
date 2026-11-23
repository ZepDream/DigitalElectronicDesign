/**
  ******************************************************************************
  * @file    main.c
  * @brief   实验二：4x4 矩阵键盘驱动
  * @note    STM32F103C8T6 + 1.8 寸 ST7735S（竖屏 128x160，软件 SPI）
  *          TFT : CLK=PB9  SDA=PB8  RS=PB7  RST=PB6  CS=PB5
  *          KEY : 行 PA7~PA4（KEY8~KEY5），列 PB11/PB10/PB1/PB0（KEY4~KEY1）
  *          本文件编码：GB2312（Keil 默认 ANSI），请勿另存为 UTF-8
  ******************************************************************************
  */

#include "stm32f10x.h"
#include "delay.h"
#include "tft.h"
#include "key.h"

/*------------------------------- UI layout ---------------------------------*/
#define HEADER_H        28
#define STATUS_Y        33
#define GRID_X          16
#define GRID_Y          54
#define CELL_W          24
#define CELL_H          24

#define HEADER_COLOR    BLUE

static u8 last_key = KEY_NONE;

/* Digits 0-9 are white, letters A-F are yellow */
static u16 UI_KeyColor(u8 key)
{
    return (key < 10) ? WHITE : YELLOW;
}

/* Top area: fixed name and student ID */
static void UI_ShowHeader(void)
{
    LCD_Fill(0, 0, LCD_W - 1, HEADER_H - 1, HEADER_COLOR);
    LCD_DrawLine(0, HEADER_H, LCD_W - 1, HEADER_H, GRAY);

    LCD_ShowChinese(6, 1, CYAN, HEADER_COLOR, "姓名:", 12, 0);
    LCD_ShowChinese(36, 1, WHITE, HEADER_COLOR, "周则均", 12, 0);

    LCD_ShowChinese(6, 15, CYAN, HEADER_COLOR, "学号:", 12, 0);
    LCD_ShowChinese(36, 15, WHITE, HEADER_COLOR, "202409502216", 12, 0);
}

/* One cell of the 4x4 key grid; pressed = cyan background + black char */
static void UI_DrawKeyCell(u8 key, u8 pressed)
{
    u16 x = GRID_X + (u16)(key % 4) * CELL_W;
    u16 y = GRID_Y + (u16)(key / 4) * CELL_H;

    if(pressed)
    {
        LCD_Fill(x, y, x + CELL_W - 1, y + CELL_H - 1, CYAN);
        LCD_DrawRectangle(x, y, x + CELL_W - 1, y + CELL_H - 1, WHITE);
        LCD_ShowChar(x + 8, y + 4, BLACK, CYAN, (u8)KEY_GetChar(key), 16, 0);
    }
    else
    {
        LCD_Fill(x, y, x + CELL_W - 1, y + CELL_H - 1, BLACK);
        LCD_DrawRectangle(x, y, x + CELL_W - 1, y + CELL_H - 1, GRAY);
        LCD_ShowChar(x + 8, y + 4, UI_KeyColor(key), BLACK,
                     (u8)KEY_GetChar(key), 16, 0);
    }
}

static void UI_ShowGrid(void)
{
    u8 i;

    for(i = 0; i < KEY_NUM; i++)
    {
        UI_DrawKeyCell(i, 0);
    }
}

/* Current key value under the header: KEY: 0 .. KEY: F */
static void UI_ShowStatus(u8 key)
{
    LCD_Fill(0, STATUS_Y, LCD_W - 1, STATUS_Y + 15, BLACK);
    LCD_ShowString(8, STATUS_Y, CYAN, BLACK, "KEY:", 16, 0);

    if(key < KEY_NUM)
    {
        LCD_ShowChar(56, STATUS_Y, UI_KeyColor(key), BLACK,
                     (u8)KEY_GetChar(key), 16, 0);
    }
}

static void UI_ShowKey(u8 key)
{
    if(last_key < KEY_NUM)
    {
        UI_DrawKeyCell(last_key, 0);
    }

    UI_DrawKeyCell(key, 1);
    UI_ShowStatus(key);
    last_key = key;
}

int main(void)
{
    u8 key;

    delay_init();                   /* SysTick 延时 */
    LCD_Init();                     /* TFT 初始化，竖屏 128x160 */
    KEY_Init();                     /* 矩阵键盘 GPIO 初始化 */

    LCD_Clear(BLACK);
    UI_ShowHeader();
    UI_ShowStatus(KEY_NONE);
    UI_ShowGrid();

    while(1)
    {
        key = KEY_Scan();
        if(key < KEY_NUM)
        {
            UI_ShowKey(key);
        }
    }
}
