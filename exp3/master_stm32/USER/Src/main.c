/**
  ******************************************************************************
  * @file    main.c
  * @brief   实验三：STM32 作 SPI 主机，循环输出 16 位字符并读回从机响应
  * @note    课件作业（第 5 页）：新建 STM32F103 空工程，新增 SPI.c / SPI.h，
  *          在 main.c 里按 SPI 协议输出自己定义的字符，每个字符 16 bit。
  *
  *          这里用课件的两个独立函数：
  *              SPI_WriteMsg(g_tx, 1)   写一帧，把字符发出去
  *              SPI_ReadMsg(&g_rx, 1)   另起一帧，把从机的回答读回来
  *          从机的回答比命令晚一帧，所以 g_rx 读到的是上一条字符的响应。
  *
  *          这 6 个字符覆盖从机响应表的 4 种情况 + 2 个普通值：
  *              0x0000 -> 从机回 0x0123      0x0004 -> 从机回 0x1234
  *              0x0008 -> 从机回 0x2345      0x000A -> 从机回 0x3456
  *              0x0055 / 0x00AA -> 从机回 0xABAB
  *
  *          看结果的方法：Keil 调试时把 g_tx、g_rx 加到 Watch 窗口。
  ******************************************************************************
  */

#include "stm32f10x.h"
#include "delay.h"
#include "spi.h"

/* 自定义字符表：每个字符 16 bit */
const u16 CHAR_TAB[] = { 0x0000, 0x0004, 0x0008, 0x000A, 0x0055, 0x00AA };
#define CHAR_NUM     (sizeof(CHAR_TAB) / sizeof(CHAR_TAB[0]))

/* 放到全局，方便在调试器里观察 */
u16 g_tx = 0;
u16 g_rx = 0;

int main(void)
{
    u8 i = 0;

    delay_init();               /* SysTick 微秒延时，SPI 的半周期靠它 */
    SPI_GPIO_Config();          /* 引脚初始化（课件函数名） */

    while (1)
    {
        g_tx = CHAR_TAB[i];
        SPI_WriteMsg(g_tx, 1);      /* 写一帧：发出本字符 */
        SPI_ReadMsg(&g_rx, 1);      /* 读一帧：收回上一条字符的响应 */

        i = (u8)((i + 1) % CHAR_NUM);
        delay_ms(200);              /* 慢一点，方便用逻辑分析仪看波形 */
    }
}
